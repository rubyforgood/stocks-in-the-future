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

## Contributing

- Read the [project documentation](docs/README.md) to understand how we work on this app
- Add tests with your PR
- Run `bin/dev rails test:all` and make sure all tests are passing
- Run `bin/dev rubocop` and fix any errors
- Create a PR with context in the description and in the comment use the key word `Resolves` and the issue number to link the issue to the desciption (For example Resolves #32)

# About Stocks in the Future

## Mission

[Stocks in the Future](https://sifonline.org/) is a program with the mission of developing highly motivated middle school students who are eager to learn and dedicated to attending class through the use of incentives coupled with a financial literacy curriculum focused on investing that reinforces Math, Language Arts and Social Studies. Stocks in the Future pushes to educate, encourage, and empower the next generation of financially-literate individuals.

## Ruby for Good

If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack](https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). Stocks-in-the-future has a #stocks-in-the-future channel in the Slack. Feel free to join the community!

# Contributing

## Workflow for Contributors

1. **Find an issue** to work on from our existing issues. If you've identified a bug or potential improvement, please discuss it in the #stocks-in-the-future Slack channel before starting work.

2. **Create a branch** from `main` with a descriptive name including the issue number

   ```console
   $ git checkout main
   $ git pull
   $ git checkout -b feature-description-123
   ```

3. **Make your changes** and commit them with descriptive messages

   ```console
   $ git add .
   $ git commit -m "Add feature X that solves problem Y"
   ```

4. **Run linting** to ensure code quality

   ```console
   $ bin/lint
   ```

   If issues are found, fix them or use auto-fix when appropriate:

   ```console
   $ bundle exec rubocop -A
   ```

5. **Run tests** to verify your changes don't break existing functionality

   ```console
   $ bin/rails test
   ```

   To check test coverage, run:

   ```console
   $ bin/coverage
   ```

   This generates an HTML coverage report at `coverage/index.html`

6. **Push your branch** to GitHub

   ```console
   # For the first push to a new branch
   $ git push --set-upstream origin feature-description-123

   # For all subsequent pushes
   $ git push
   ```

7. **Open a Pull Request** against the `main` branch
   - Include a clear description of the changes
   - Linking the issue number in the PR's description (e.g., `Resolves #123`)
     - [More about linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue) 
   - Wait for CI checks to pass
   - Request review from team members

## Getting Help

If you need help at any point, comment on the issue you're working on or ask in the #stocks-in-the-future channel on the Ruby for Good Slack.

## Troubleshooting

### ASDF

If you find yourself in a cycle of encountering errors such as:

```
in stocks-in-the-future/ on main
› asdf install ruby 3.4.4

in stocks-in-the-future/ on main
› asdf set local ruby 3.4.4

in stocks-in-the-future/ on main
› ruby --version
No version is set for command ruby
Consider adding one of the following versions in your config file at /Users/america/dev/stocks-in-the-future/.tool-versions
ruby 3.3.6
ruby 3.1.6
```

Try upgrading asdf and trying again.
