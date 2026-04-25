# frozen_string_literal: true

server ENV.fetch("STAGING_SERVER_IP", "STAGING_IP_PLACEHOLDER"), user: "ubuntu", roles: %w[app db web], ssh_options: { keys: ["~/.ssh/staging_web_ssh.pem"], forward_agent: true }

set :rails_env, "staging"
set :branch, "main"
