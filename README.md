[![Continuous Integration](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/ci.yml/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/ci.yml)
[![Lint](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/lint.yml/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/lint.yml)
[![Dependabot Updates](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/dependabot/dependabot-updates)

[![Help wanted](https://badgen.net/github/label-issues/rubyforgood/stocks-in-the-future/help%20wanted/open??color=green&icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/labels/help%20wanted)
[![Open PRs](https://badgen.net/github/open-prs/rubyforgood/stocks-in-the-future??color=green&icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/pulls)
[![Last commit](https://badgen.net/github/last-commit/rubyforgood/stocks-in-the-future??icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/commits)

# Requirements

- A ruby version manager such as [rvm](https://rvm.io/rvm/install), [rbenv](https://formulae.brew.sh/formula/rbenv) or [asdf](https://asdf-vm.com/guide/getting-started.html)
- Ruby 3.4.4 (Installed via ruby manager ^)
- [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) and yarn (`npm install -g yarn`)

# Easy Docker Scripts
Go to the [Easy Docker Scripts](docker/README.md) page for an easy way to set up this app, test this app, seed data, run RuboCop, and execute other routine tasks.

# Installation

Create `config/database.yml`. A copy of `config/database.yml.sample` should be adequate.

## With Docker

Build and start the application with `docker compose up`. Once the application has successfully started, you should be able to visit it at http://localhost:3000/

Run commands in docker with the `bin/dc` helper script on macos or Linux.

```console
$ bin/dc rails db:setup
$ bin/dc rails test
```

Or by prefacing `rails` commands with `docker compose run stocks`.

```console
$ docker compose run stocks rails db:setup
$ docker compose run stocks rails test
```

## Mac & Linux Users

- Run setup: `bin/setup`
- Run the Rails server locally: `bin/dev`

## Windows

It is **strongly** recommend to use Docker. See instructions above.

## Seed Data

After running `bin/rails db:setup`, the database will automatically be seeded with three default users.

| Role    | Username | Password |
|---------|----------|----------|
| Teacher | Teacher  | password |
| Student | Student  | password |
| Admin   | Admin    | password |

Use the **username** and **password** to log in and test the application locally.

## URL

Access the app via `localhost:3000`

## Linting

## ERB Linting

This project uses [erb_lint](https://github.com/Shopify/erb-lint) to catch ERB template errors during development.

### Running erb_lint

To check all ERB templates:

```console
$ bin/dc bundle exec erb_lint --lint-all
```

To see autocorrectable issues:

```console
$ bin/dc bundle exec erb_lint --lint-all --autocorrect
```

## Contributing

To understand the project better, read the [project documentation](docs/README.md).

Then follow our [contributing guide](CONTRIBUTING.md) to get started.

# About Stocks in the Future

## Mission

[Stocks in the Future](https://sifonline.org/) is a program with the mission of developing highly motivated middle school students who are eager to learn and dedicated to attending class through the use of incentives coupled with a financial literacy curriculum focused on investing that reinforces Math, Language Arts and Social Studies. Stocks in the Future pushes to educate, encourage, and empower the next generation of financially-literate individuals.

## Ruby for Good

If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack](https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). Stocks-in-the-future has a #stocks-in-the-future channel in the Slack. Feel free to join the community!
