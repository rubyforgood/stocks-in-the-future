# Requirements

* A ruby version manager such as [rvm](https://rvm.io/rvm/install) or [rbenv](https://formulae.brew.sh/formula/rbenv)
* Ruby 3.2.3 (Installed via ruby manager ^)
* [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.

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

* Run setup: `bin/setup`
* Run the Rails server locally: `bin/dev`

## Windows

It is **strongly** recommend to use Docker. See instructions above.

## URL

Access the app via `localhost:5000`

# Contributing

* Please create a new branch for each request
* Branch name should include issue number. For example: `branchname-23`

