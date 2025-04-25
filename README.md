# Requirements

* A ruby version manager such as [rvm](https://rvm.io/rvm/install), [rbenv](https://formulae.brew.sh/formula/rbenv) or [asdf](https://asdf-vm.com/guide/getting-started.html)
* Ruby 3.2.3 (Installed via ruby manager ^)
* [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.
* [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) and yarn (`npm install -g yarn`)

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

# About Stocks in the Future 

## Mission
[Stocks in the Future](https://sifonline.org/) is a program with the mission of developing highly motivated middle school students who are eager to learn and dedicated to attending class through the use of incentives coupled with a financial literacy curriculum focused on investing that reinforces Math, Language Arts and Social Studies. Stocks in the Future pushes to educate, encourage, and empower the next generation of financially-literate individuals.

## Ruby for Good
If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack] (https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). Stocks-in-the-future has a #stocks-in-the-future channel in the Slack. Feel free to join the community! 

# Contributing

* Please create a new branch for each request
* Branch name should include issue number. For example: `branchname-23`

