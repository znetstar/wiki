FROM ruby:latest

WORKDIR /app

COPY . /app

ENV PORT 80

EXPOSE 80

RUN bundle install

CMD rackup