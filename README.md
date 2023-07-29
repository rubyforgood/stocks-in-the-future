# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration


## Running in docker

We have a docker-compose file set up to allow smoother local development.
The compose structure includes services needed for running the stocks app
locally, with preconfigured connections.

At present, these services are: postgres, redis, and the rails application.

To start the application, run `docker compose up`.  Adding `-d` will free your
terminal after the service boots.  After the application starts, the site can
be accessed at `http://localhost:3000`.

The docker entrypoint takes care of installing updated gems, and running any
pending database migrations before starting the rails application.  Any
gem or configuration changes can be applied by restarting the application server:
`docker compose restart stocks`

### Running rails commands

To run rails commands, such as `rails generate ...`, it is easiest to step
into a console:

```shell
$ docker compose run --rm stocks bin/rails generate ....
```

If a console is needed for multiple commands, you can launch a shell in a running the container:

```shell
$ docker compose run --rm stocks bash
[+] Running 2/0
 ⠿ Container stocks-in-the-future-db-1     Running                                                  0.0s
 ⠿ Container stocks-in-the-future-redis-1  Running                                                  0.0s
The Gemfile's dependencies are satisfied
root@cea35fe15a85:/rails# 
```

### Running tests

To run RSpec tests in the container:
```shell
docker compose run --rm stocks rspec
```

Or a specific file/directory may be specified to narrow the scope:

```shell
docker compose run --rm stocks rspec spec/features
```
