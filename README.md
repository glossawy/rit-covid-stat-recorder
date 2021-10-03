RIT Covid Stat Recorder
---

[![Latest Version 2.3.2][docker-version-badge-url]][docker-hub-url] [![Licensed under the GNU Public License version 3.0][license-badge-url]](./LICENSE.md) [![Maintenace Status: YES][maintenance-badge-url]](./README.md)

A simple page scraper that takes a number of stats off the [RIT Covid Stats](https://www.rit.edu/ready/dashboard) page and saves them to a database and google sheets.

For fun, this scraper uses [Hanami](https://github.com/hanami/model) libraries for database work and logging instead of ActiveRecord or ActiveSupport.

The database is implemented using `sqlite3`

The core data model is:

- `Recorder::Entities::CovidStat`
  - Snapshot of stats at a particular point in time
- `Recorder::Entities::CollectionAttempt`
  - Log of all attempts at collecting stats and the outcome
  - Links to collected stat if successful

The scraping is done by `Recorder::Spiders::RitCovidSpider` with a series of very dirty string and array manipulations. This never needed to be too complicated to require additional abstraction.

## Setup and CLI

This application has a rails-like cli. For any command you can provide the `-h|--help` option.

Modify any necessary variables in `lib/config.rb`.

Install gems:

```
bundle install
```

DB setup:

1. `bin/recorder db create`
2. `bin/recorder db migrate`

or just `bin/recorder db prepare`

To add a new model or migration u can use `bin/recorder <generate|g> <model|migration> [...]`. 

The general flow for collecting statistics is:

1. `bin/recorder scrape fetch`
  - This will not persist the data, allows verification
2. `bin/recorder scrape fetch --persist`
  - This will persist the data **if** it is sufficiently different from previous data
3. `bin/recorder export csv > data.csv` or `bin/recorder export google` depending on preference

## Cron and Daemon

This application uses [javan/whenever](https://github.com/javan/whenever) for local crontabs:

```
bundle exec whenever --update-crontab
```

You can modify `lib/schedule.rb` and then repeat the above command to update frequency of checks.

Alternatively, a daemon implementation is provided which can take a fetch frequency and a backup frequency:

```
bin/recorder daemon run --help
```

## Logging

Logging output while running is written to stdout as well as:

- `app.log`
  - Primary log of all application output
- `cron.log`
  - Output during cron execution
- `database.log`
  - Output for all database queries (can be disabled in `lib/config.rb`)

## Scripts

- `scripts/backup`
  - zsh script to use `sqlite3` to backup locally
- `scripts/notify.ps1`
  - powershell script to use [BurntToast](https://github.com/Windos/BurntToast) to display popup notifications for new stats on windows only
- `scripts/publish` and `scripts/publish.ps1`
  - zsh and powershell scripts to publish a docker image to a docker hub repository with basic versioning

[docker-version-badge-url]: https://img.shields.io/docker/v/glossawy/rit-covid-recorder?sort=semver&style=for-the-badge
[docker-hub-url]: https://hub.docker.com/layers/glossawy/rit-covid-recorder/2.3.2/images/sha256-425cd0dc56d677c96cc398bf17b618369bd6dab683522532319604b4f6b0f449

[license-badge-url]: https://img.shields.io/github/license/Glossawy/rit-covid-stat-recorder?style=for-the-badge
[maintenance-badge-url]: https://img.shields.io/maintenance/yes/2021?style=for-the-badge
