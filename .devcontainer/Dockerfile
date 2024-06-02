# See https://github.com/devcontainers/images/blob/main/src/ruby/history/
FROM mcr.microsoft.com/devcontainers/ruby:dev-3.2
RUN apt -y update && \
    apt install -y vim curl gpg postgresql postgresql-contrib \
                   nodejs npm
RUN npm install -g yarn