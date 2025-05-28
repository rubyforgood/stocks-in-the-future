# Requirements

- A ruby version manager such as [rvm](https://rvm.io/rvm/install), [rbenv](https://formulae.brew.sh/formula/rbenv) or [asdf](https://asdf-vm.com/guide/getting-started.html)
- Ruby 3.4.4 (Installed via ruby manager ^)
- [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) and yarn (`npm install -g yarn`)

# Installation

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

### Seed Data

The application includes seed data to create default users for testing. After setting up the database, you can seed it with: `bin/rails db:seed`

This creates three users:
Teacher: Username: Teacher, Password: password (Email: teacher@example.com)

Student: Username: Student, Password: password (Email: student@example.com)

Admin: Username: Admin, Password: password (Email: admin@example.com)

Use the username and password to log in and test the application locally or on a deployed environment. 

Note: Do not run db:seed in production unless explicitly required.

## URL

Access the app via `localhost:5000`

## Contributing

- Add tests with your PR
- Run `bundle exec rails test` and make sure all tests are passing
- Run `bin/lint` and fix any errors
- Create a PR with context in the description and in the comment use the key word `Resolves` and the issue number to link the issue to the desciption (For example Resolves #32)

# About Stocks in the Future

## Mission

[Stocks in the Future](https://sifonline.org/) is a program with the mission of developing highly motivated middle school students who are eager to learn and dedicated to attending class through the use of incentives coupled with a financial literacy curriculum focused on investing that reinforces Math, Language Arts and Social Studies. Stocks in the Future pushes to educate, encourage, and empower the next generation of financially-literate individuals.

## Ruby for Good

If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack] (https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). Stocks-in-the-future has a #stocks-in-the-future channel in the Slack. Feel free to join the community!

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
   $ bundle exec standardrb --fix
   ```

5. **Run tests** to verify your changes don't break existing functionality

   ```console
   $ bin/rails test
   ```

6. **Push your branch** to GitHub

   ```console
   # For the first push to a new branch
   $ git push --set-upstream origin feature-description-123

   # For all subsequent pushes
   $ git push
   ```

7. **Open a Pull Request** against the `main` branch
   - Include a clear description of the changes
   - Reference the issue number in the PR description (e.g., "Fixes #123")
   - Wait for CI checks to pass
   - Request review from team members

## Getting Help

If you need help at any point, comment on the issue you're working on or ask in the #stocks-in-the-future channel on the Ruby for Good Slack.
