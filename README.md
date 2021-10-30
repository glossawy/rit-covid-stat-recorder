RIT Covid Stat Recorder
---

[![Latest Version 2.5.0][docker-version-badge-url]][docker-hub-url] [![Licensed under the GNU Public License version 3.0][license-badge-url]](./LICENSE.md) [![Maintenace Status: YES][maintenance-badge-url]](./README.md)

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

Google Credentials setup for exporting to google sheets:

1. Create your Google Sheets API credentials at the Google Cloud Platform and download the json file
2. Create a directory somewhere to capture token: `mkdir ./credstore`
3. Place the downloaded json file in the above directory as `credentials.json`, e.h. `./credstore/credentials.json`
4. Run `docker run --rm -it -e DEBUG=1 -v $PWD/credstore:/app/credstore glossawy/rit-covid-recorder:current bin/recorder authorize --home=./credstore`
5. Follow prompts to acquire token
6. Token will now be found at `./credstore/token.yaml`
7. When running the image as daemon or with export, make sure to mount the credentials directory, e.g. `-e CREDENTIALS_HOME=/app/credstore -v $PWD/credstore:/app/credstore`, it cannot be read-only

Note: Currently the scraper will assume your spreadsheet's columns matches ours.

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
[docker-hub-url]: https://hub.docker.com/layers/174827952/glossawy/rit-covid-recorder/2.5.0/images/sha256-b46c6f8c725d4c64a1da026777b5a532297f5dc06bc2733e71eb2b3ddf8addea

[license-badge-url]: https://img.shields.io/github/license/Glossawy/rit-covid-stat-recorder?style=for-the-badge
[maintenance-badge-url]: https://img.shields.io/maintenance/yes/2021?style=for-the-badge
