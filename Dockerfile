FROM ruby:2.6-alpine
MAINTAINER Glossawy (glossawy@protonmail.com)

ARG period=P1H

RUN apk add build-base sqlite sqlite-dev tzdata less

# throw errors if Gemfile has been modified since Gemfile.lock
RUN gem install bundler
RUN bundle config --global frozen 1
RUN mkdir -p /app/

WORKDIR /app

COPY Gemfile Gemfile.lock /app/
RUN bundle install

COPY ./credentials.json /app/credentials.json
COPY ./token.yaml /app/token.yaml

COPY ./bin /app/bin
COPY ./lib /app/lib
COPY ./script /app/script

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone && date

ENV DAEMON_PERIOD="${period}"

VOLUME /app/db
VOLUME /app/log

CMD script/start
