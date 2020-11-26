FROM ruby:2.6-alpine
MAINTAINER Glossawy (glossawy@protonmail.com)

ARG period=P1H

RUN apk add build-base sqlite-dev tzdata

# throw errors if Gemfile has been modified since Gemfile.lock
RUN gem install bundler
RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY ./bin /app/bin
COPY ./lib /app/lib
COPY ./script /app/script

COPY ./credentials.json /app/credentials.json
COPY ./token.yaml /app/token.yaml

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone && date

ENV DAEMON_PERIOD="${period}"

VOLUME /app/db
VOLUME /app/log

WORKDIR /app

CMD bin/recorder daemon run ${DAEMON_PERIOD}
