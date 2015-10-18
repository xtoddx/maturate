FROM ruby:2.2

MAINTAINER "Todd Willey <todd.willey@cirrusmio.com>"

VOLUME /usr/src/app

COPY Gemfile /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock
COPY maturate.gemspec /usr/src/app/maturate.gemspec

WORKDIR /usr/src/app
RUN bundle install
