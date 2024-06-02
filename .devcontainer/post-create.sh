# force the use of Ruby matching the microsoft ruby devcontainer
# https://github.com/devcontainers/images/blob/main/src/ruby/history/dev.md#contents-6
echo "3.2.2" > .ruby-version
RUBY_VERSION="$(cat .ruby-version | tr -d '\n')"

# copy the file only if it doesn't already exist
cp -n .devcontainer/.env.codespaces .env

bin/setup
