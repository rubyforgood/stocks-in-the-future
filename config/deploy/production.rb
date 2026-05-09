# frozen_string_literal: true

server \
  ENV.fetch("PRODUCTION_SERVER_IP", "PRODUCTION_IP_PLACEHOLDER"),
  user: "ubuntu",
  roles: %w[app db web],
  ssh_options: {
    keys: ["~/.ssh/production_web_ssh.pem"],
    forward_agent: true
  }

set :rails_env, "production"
set :branch, "main"
