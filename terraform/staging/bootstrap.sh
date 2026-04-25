#!/usr/bin/env bash
set -euo pipefail
exec > /var/log/bootstrap.log 2>&1

RUBY_VERSION="3.4.4"
APP_USER="ubuntu"
APP_NAME="${app_name}"
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

# --- master.key ---
sudo -u "$APP_USER" bash -c "echo '${rails_master_key}' > $DEPLOY_TO/shared/config/master.key"
chmod 600 "$DEPLOY_TO/shared/config/master.key"

# --- App secrets env file ---
mkdir -p /etc/stocks
tee /etc/stocks/env > /dev/null << ENVEOF
RAILS_ENV=${rails_env}
RAILS_MASTER_KEY=${rails_master_key}
DATABASE_URL=postgres://stocks_user:${db_password}@FILL_IN_DB_ENDPOINT_FROM_TERRAFORM_OUTPUT:5432/stocks_staging
STOCKS_IN_THE_FUTURE_DATABASE_PASSWORD=${db_password}
ALPHA_VANTAGE_API_KEY=${alpha_vantage_api_key}
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
EnvironmentFile=/etc/stocks/env
ExecStart=/home/ubuntu/.rbenv/versions/3.4.4/bin/ruby bin/rails server
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
echo "1. Get db_endpoint from: terraform output db_endpoint"
echo "2. SSH in and update DATABASE_URL in /etc/stocks/env:"
echo "   sudo nano /etc/stocks/env"
echo "3. Run first deploy from your local machine:"
echo "   STAGING_SERVER_IP=<instance_public_ip> cap staging deploy"
echo "4. Generate and set SECRET_KEY_BASE:"
echo "   ssh ubuntu@<ip> 'cd /home/ubuntu/stocks-in-the-future/current && bundle exec rails secret'"
echo "   sudo nano /etc/stocks/env"
echo "5. Seed the database:"
echo "   cap staging rails:rake[db:seed]"
echo "6. Start nginx:"
echo "   sudo systemctl start nginx"
