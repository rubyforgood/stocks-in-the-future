# frozen_string_literal: true

lock "~> 3.19"

set :application, "stocks-in-the-future"
set :repo_url, "git@github.com:rubyforgood/stocks-in-the-future.git"
set :branch, :main

set :deploy_to, "/home/ubuntu/stocks-in-the-future"
set :keep_releases, 5

# rbenv - must match the version installed on the server
set :rbenv_type, :user
set :rbenv_ruby, "3.4.4"
set :rbenv_path, "/home/ubuntu/.rbenv"

# Shared files and directories that persist across releases
set :linked_files, %w[
  config/database.yml
]

set :linked_dirs, %w[
  log
  tmp/pids
  tmp/cache
  tmp/sockets
  storage
  public/assets
]

set :bundle_without, %w[development test].join(" ")
set :bundle_flags, "--quiet"

# Forward local SSH agent so server can clone from GitHub
set :ssh_options, forward_agent: true

# Read env vars from /etc/stocks/env on the server so Capistrano tasks
# (assets:precompile, db:migrate, etc.) have access to them.
ENV_VAR_FILE = "/etc/stocks/env"
RBENV_BIN = "/home/ubuntu/.rbenv/bin/rbenv"

def run_rake_with_env(task)
  # Source the env file directly so passwords with special chars never appear in the command string
  "set -a && . #{ENV_VAR_FILE} && set +a && #{RBENV_BIN} exec bundle exec rake #{task}"
end

# Override deploy:assets:precompile - skip the gem's default
begin
  Rake::Task["deploy:assets:precompile"].clear
rescue StandardError
  nil
end

namespace :deploy do
  namespace :assets do
    task :precompile do
      on roles(:app) do
        within release_path do
          # Delete credentials file if it exists (it's encrypted and causes issues)
          execute :rm, "-f", "#{release_path}/config/credentials.yml.enc"
          execute :sh, "-c '#{run_rake_with_env('assets:precompile')}'"
        end
      end
    end
  end
end

# Skip default migrate task entirely
set :migration_role, :none

# Add our own migration task after publishing
# Run on :app role since we don't have separate :db role in staging
namespace :deploy do
  task :run_migrations do
    on roles(:app) do
      within release_path do
        # Delete credentials file before migrations too
        execute :rm, "-f", "#{release_path}/config/credentials.yml.enc"
        execute :sh, "-c '#{run_rake_with_env('db:migrate')}'"
      end
    end
  end
end

# Run our custom migrations after publishing
after "deploy:publishing", "deploy:run_migrations"

# Manually precompile assets with env vars after the app is deployed

# Manually precompile assets with env vars after the app is deployed
namespace :deploy do
  task :restart do
    on roles(:app) do
      # Restart Puma
      execute :sudo, "systemctl restart stocks"

      # Fix permissions so nginx (www-data) can access the Puma socket
      # These are needed after deploy because Capistrano recreates the shared directories
      # Also fix /home and /home/ubuntu permissions for nginx to traverse
      execute :sudo, "chmod o+x /home"
      execute :sudo, "chmod o+x /home/ubuntu"
      execute :sudo, "chmod o+x #{deploy_to}/shared/tmp"
      execute :sudo, "chmod o+x #{deploy_to}/shared/tmp/sockets"
    end
  end

  after :published, :restart
end
