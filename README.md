[![Continuous Integration](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/ci.yml/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/ci.yml)
[![Lint](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/lint.yml/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/lint.yml)
[![Dependabot Updates](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/rubyforgood/stocks-in-the-future/actions/workflows/dependabot/dependabot-updates)

[![Help wanted](https://badgen.net/github/label-issues/rubyforgood/stocks-in-the-future/help%20wanted/open??color=green&icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/labels/help%20wanted)
[![Open PRs](https://badgen.net/github/open-prs/rubyforgood/stocks-in-the-future??color=green&icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/pulls)
[![Last commit](https://badgen.net/github/last-commit/rubyforgood/stocks-in-the-future??icon=github&cache=3600)](https://github.com/rubyforgood/stocks-in-the-future/commits)

# About Stocks in the Future

## Mission

[Stocks in the Future](https://sifonline.org/) is a program with the mission of developing highly motivated middle school students who are eager to learn and dedicated to attending class through the use of incentives coupled with a financial literacy curriculum focused on investing that reinforces Math, Language Arts and Social Studies. Stocks in the Future pushes to educate, encourage, and empower the next generation of financially-literate individuals.
This application is used by the students to manage their portfolios by trading and selling their stocks. It is also used by the teachers and administrator to manage the classrooms, enter student's grades, attendance, and post announcements. 

## Ruby for Good

If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack](https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). Stocks-in-the-future has a #stocks-in-the-future channel in the Slack. Feel free to join the community!

## Contributing

To understand the project better, read the [project documentation](docs/README.md).

Then follow our [contributing guide](CONTRIBUTING.md) to get started.

# Local Development
## Requirements

- A ruby version manager such as [rvm](https://rvm.io/rvm/install), [rbenv](https://formulae.brew.sh/formula/rbenv) or [asdf](https://asdf-vm.com/guide/getting-started.html)
- Ruby 3.4.4 (Installed via ruby manager ^)
- [PostgreSQL](https://www.postgresql.org/), if you're not using Docker.
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) and yarn (`npm install -g yarn`)

## Easy Docker Scripts
Go to the [Easy Docker Scripts](docker/README.md) page for an easy way to set up this app, test this app, seed data, run RuboCop, and execute other routine tasks.

## Installation

Create `config/database.yml`. A copy of `config/database.yml.sample` should be adequate.

### With Docker

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

It is **strongly** recommended to use Docker. See instructions above.

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

# Operations

## Production And Staging Email

Password reset and account setup emails are sent through Devise using Rails Action Mailer. In staging and production, Action Mailer is configured to use Amazon SES SMTP in `us-east-1`.

The SES domain identity is `sifonline.org`. DKIM is verified with three CNAME records in GoDaddy DNS:

```text
xqnfudzzscsqz2vbneqh75ojqwduiphb._domainkey.sifonline.org -> xqnfudzzscsqz2vbneqh75ojqwduiphb.dkim.amazonses.com
4zk3q7oy5kz7xubi2gxqkn2kpqglwgms._domainkey.sifonline.org -> 4zk3q7oy5kz7xubi2gxqkn2kpqglwgms.dkim.amazonses.com
qsq7nni46gdkvr6vu7gn6cm4rexzo22u._domainkey.sifonline.org -> qsq7nni46gdkvr6vu7gn6cm4rexzo22u.dkim.amazonses.com
```

The SES SMTP credentials are stored in AWS Secrets Manager:

```text
stocks-in-the-future/ses-smtp
```

The app reads these runtime environment variables from `/etc/stocks/env` on each Lightsail instance:

```text
APP_HOST
MAILER_SENDER
SES_SMTP_ADDRESS
SES_SMTP_PORT
SES_SMTP_USERNAME
SES_SMTP_PASSWORD
```

Expected values by environment:

```text
production APP_HOST=app.sifonline.org
staging    APP_HOST=staging.sifonline.org
MAILER_SENDER=no-reply@sifonline.org
SES_SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SES_SMTP_PORT=587
```

SES may still be sandboxed in a new AWS account or region. If `ProductionAccessEnabled` is `false`, SES can only send to verified recipient email addresses even if the `sifonline.org` sending domain is verified.

Check SES status:

```console
AWS_PROFILE=713141626029_AdministratorAccess AWS_REGION=us-east-1 aws sesv2 get-email-identity --email-identity sifonline.org
AWS_PROFILE=713141626029_AdministratorAccess AWS_REGION=us-east-1 aws sesv2 get-account
```

## SSM Access To Lightsail

The Lightsail instances are registered with AWS Systems Manager as hybrid managed instances so routine ops do not require SSH keys.

Current managed instances:

```text
production_web -> mi-059a7bcb37754c44d
staging_web    -> mi-0c65ce3a1a596c81c
```

Check SSM connectivity:

```console
AWS_PROFILE=713141626029_AdministratorAccess AWS_REGION=us-east-1 aws ssm describe-instance-information
```

Run a safe health check through SSM:

```console
AWS_PROFILE=713141626029_AdministratorAccess AWS_REGION=us-east-1 aws ssm send-command \
  --instance-ids mi-059a7bcb37754c44d mi-0c65ce3a1a596c81c \
  --document-name AWS-RunShellScript \
  --parameters '{"commands":["systemctl is-active stocks && grep -E \"^(APP_HOST|MAILER_SENDER|SES_SMTP_ADDRESS|SES_SMTP_PORT|SES_SMTP_USERNAME|SES_SMTP_PASSWORD)=\" /etc/stocks/env | sed -E \"s/=.*/=present/\""]}'
```

Do not print `SES_SMTP_PASSWORD` or other secrets in terminal output. Check for key presence only.

## Email Troubleshooting

If reset password emails do not send:

1. Confirm the deployed code includes SES Action Mailer configuration in `config/environments/production.rb` or `config/environments/staging.rb`.
2. Confirm the app was restarted after updating `/etc/stocks/env`: `sudo systemctl restart stocks`.
3. Confirm required env keys exist on the server using SSM. Do not print secret values.
4. Confirm SES identity status is `SUCCESS` and DKIM status is `SUCCESS`.
5. Confirm SES production access is enabled, or verify the recipient email address while SES is still sandboxed.
6. Check recent app logs:

```console
AWS_PROFILE=713141626029_AdministratorAccess AWS_REGION=us-east-1 aws ssm send-command \
  --instance-ids mi-059a7bcb37754c44d \
  --document-name AWS-RunShellScript \
  --parameters '{"commands":["sudo journalctl -u stocks -n 200 --no-pager"]}'
```

If SSM stops working, first confirm the instance is listed as `Online` in `aws ssm describe-instance-information`. If it is missing or offline after a rebuild, install/register the SSM agent again with a new SSM hybrid activation, then enable the agent service so it persists across reboot.

## DNS And Load Balancers

The application hostname is `app.sifonline.org`. It should point to the Terraform-managed production Lightsail load balancer:

```text
stocks-production-lb
1c0d863aa670cdbc48e7167de9d300ef-1607315586.us-east-1.elb.amazonaws.com
```

Staging uses:

```text
staging-lb
d74e239060df7f70047c7878e32ed0c8-1040760270.us-east-1.elb.amazonaws.com
```

If the app returns an AWS ELB `503`, check whether DNS points to an old load balancer or whether the target instance is detached/unhealthy. If HTTPS fails after an HTTP redirect, check that the Lightsail load balancer has a valid attached TLS certificate and exposes port `443`.
