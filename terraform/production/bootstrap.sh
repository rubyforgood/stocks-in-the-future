#!/usr/bin/env bash
set -euo pipefail
exec > /var/log/bootstrap.log 2>&1

RUBY_VERSION="3.4.4"
APP_USER="ubuntu"
APP_NAME="stocks-in-the-future"
DEPLOY_TO="/home/ubuntu/$APP_NAME"

echo "=== Bootstrap starting: $(date) ==="

# --- System packages ---
apt-get update -qq
apt-get install -y --no-install-recommends \
  git curl unzip libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev nginx postgresql-client build-essential \
  libffi-dev libyaml-dev libgmp-dev \
  libvips-dev imagemagick

# --- rbenv for ubuntu user ---
sudo -u "$APP_USER" bash -c '
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  echo "export PATH=\"\$HOME/.rbenv/bin:\$PATH\"" >> ~/.bashrc
  echo "eval \"\$(rbenv init -)\"" >> ~/.bashrc
  echo "export PATH=\"\$HOME/.rbenv/bin:\$PATH\"" >> ~/.profile
  echo "eval \"\$(rbenv init -)\"" >> ~/.profile
'

# Ruby compilation takes ~10-15 minutes
sudo -u "$APP_USER" bash -lc "rbenv install $RUBY_VERSION && rbenv global $RUBY_VERSION"
sudo -u "$APP_USER" bash -lc "gem install bundler --no-document"

# --- Bun ---
sudo -u "$APP_USER" bash -lc 'curl -fsSL https://bun.sh/install | bash'

# --- Capistrano directory structure ---
sudo -u "$APP_USER" bash -c "
  mkdir -p $DEPLOY_TO/{releases,shared}
  mkdir -p $DEPLOY_TO/shared/{config,log,tmp/pids,tmp/cache,tmp/sockets,storage,public/assets}
"

# --- Shared database.yml (uses DATABASE_URL from /etc/stocks/env) ---
sudo -u "$APP_USER" tee "$DEPLOY_TO/shared/config/database.yml" > /dev/null << 'DBEOF'
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 3) %>

staging:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
DBEOF

# --- master.key (fill in after bootstrap) ---
sudo -u "$APP_USER" bash -c "echo 'FILL_IN_RAILS_MASTER_KEY' > $DEPLOY_TO/shared/config/master.key"
chmod 600 "$DEPLOY_TO/shared/config/master.key"

# --- App secrets env file (fill in real values after bootstrap) ---
mkdir -p /etc/stocks
tee /etc/stocks/env > /dev/null << 'ENVEOF'
RAILS_ENV=production
RAILS_MASTER_KEY=FILL_IN_RAILS_MASTER_KEY
DATABASE_URL=postgres://dbmasteruser:FILL_IN_DB_PASSWORD@FILL_IN_DB_ENDPOINT:5432/stocks_in_the_future_production
STOCKS_IN_THE_FUTURE_DATABASE_PASSWORD=FILL_IN_DB_PASSWORD
ALPHA_VANTAGE_API_KEY=FILL_IN_ALPHA_VANTAGE_KEY
SECRET_KEY_BASE=FILL_IN_RUN_bundle_exec_rails_secret
SOLID_QUEUE_IN_PUMA=1
RAILS_MAX_THREADS=3
RAILS_LOG_LEVEL=info
PUMA_SOCKET=/home/ubuntu/stocks-in-the-future/shared/tmp/sockets/puma.sock
ENVEOF
chown root:ubuntu /etc/stocks/env
chmod 640 /etc/stocks/env

# Source env vars in ubuntu user's shell so Capistrano SSH sessions get them
sudo -u "$APP_USER" bash -c 'echo "" >> ~/.profile && echo "# Load app env vars" >> ~/.profile && echo "set -a; source /etc/stocks/env; set +a" >> ~/.profile'

# --- nginx ---
tee /etc/nginx/sites-available/stocks > /dev/null << 'NGINXEOF'
upstream stocks_puma {
  server unix:/home/ubuntu/stocks-in-the-future/shared/tmp/sockets/puma.sock fail_timeout=0;
}

server {
  listen 80;
  server_name _;

  root /home/ubuntu/stocks-in-the-future/current/public;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  location /up {
    proxy_pass http://stocks_puma;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    access_log off;
  }

  location / {
    proxy_pass http://stocks_puma;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;
    proxy_read_timeout 60;
    proxy_connect_timeout 60;
  }

  error_page 500 502 503 504 /500.html;
  keepalive_timeout 10;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/stocks /etc/nginx/sites-enabled/stocks
rm -f /etc/nginx/sites-enabled/default
systemctl enable nginx
# Don't start nginx yet - no socket until first cap deploy

# --- systemd service ---
tee /etc/systemd/system/stocks.service > /dev/null << 'SVCEOF'
[Unit]
Description=Stocks in the Future Rails App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/stocks-in-the-future/current
Environment="PATH=/home/ubuntu/.rbenv/shims:/home/ubuntu/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="RBENV_ROOT=/home/ubuntu/.rbenv"
Environment="RBENV_VERSION=3.4.4"
EnvironmentFile=/etc/stocks/env
ExecStart=/home/ubuntu/.rbenv/versions/3.4.4/bin/bundle exec puma -C config/puma.rb
ExecReload=/bin/kill -USR2 $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stocks
KillMode=mixed
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable stocks
# Don't start - current/ symlink doesn't exist until first cap deploy

# --- sudoers: allow ubuntu to restart the service without a password ---
echo "ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart stocks, /bin/systemctl status stocks, /bin/systemctl reload nginx" \
  > /etc/sudoers.d/stocks-deploy
chmod 440 /etc/sudoers.d/stocks-deploy

echo "=== Bootstrap complete: $(date) ==="
echo ""
echo "=== NEXT STEPS ==="
echo "1. SSH in and fill in real values in /etc/stocks/env:"
echo "   sudo nano /etc/stocks/env"
echo "   - RAILS_MASTER_KEY: contents of config/master.key in the repo"
echo "   - DATABASE_URL: use db endpoint from: cd terraform/production && terraform output db_endpoint"
echo "   - STOCKS_IN_THE_FUTURE_DATABASE_PASSWORD: the db master password"
echo "   - ALPHA_VANTAGE_API_KEY: your API key"
echo "   - SECRET_KEY_BASE: run 'bundle exec rails secret' locally to generate"
echo "2. Also update shared/config/master.key:"
echo "   echo 'your-master-key' > ~/stocks-in-the-future/shared/config/master.key"
echo "3. Run first deploy from your local machine:"
echo "   PRODUCTION_SERVER_IP=54.224.224.77 bundle exec cap production deploy"
echo "4. Start nginx:"
echo "   sudo systemctl start nginx"
