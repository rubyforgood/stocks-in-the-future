# Requirements

* A ruby version manager such as [rvm](https://rvm.io/rvm/install) or [rbenv](https://formulae.brew.sh/formula/rbenv)
* Ruby 3.2.3 (Installed via ruby manager ^)
* [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.
* [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) and yarn (`npm install -g yarn`)

# Installation

How to run the application on your machine.

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

* Run setup: `bin/setup`
* Run the Rails server locally: `bin/dev`

## Windows

It is **strongly** recommend to use Docker. See instructions above.

## URL

Access the app via `localhost:5000`

# Contributing

If you are not already a project contributor, you'll need to create a fork of the project before taking any of the following steps.

* Please create a new branch for each pull request.
* Branch name should include issue number. For example: `branchname-23`.
* Write tests.
* Write code to make the tests pass.
* Run the test suite and linter to make sure it is good code.
* Commit your changes to a branch, push to GitHub, and open a Pull Request!

## Development Tools

We use Minitest for testing. You can run the test suite like this

```console
$ bin/rails db:create    # one time setup
$ bin/rails test

# in docker
$ docker compose run stocks bin/rails db:create
$ docker compose run stocks bin/rails test
```

We use a Ruby linting and formatting gem called [Standard Ruby](https://github.com/standardrb/standard). You can run it like this:

```console
$ bin/standardrb         # run the linter and emit errors or warnings
$ bin/standardrb --fix   # automatically fix errors

# in docker
$ docker compose run stocks bin/standardrb
$ docker compose run stocks bin/standardrb --fix
```

Every Pull Request is checked by a GitHub Action which runs `bin/rails test` and `bin/standardrb`. If either check fails, the Pull Request will get a ❌ instead of the more pleasant ✅.

