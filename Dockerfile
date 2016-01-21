FROM ruby

EXPOSE 80

COPY . /app

WORKDIR /app

ENV DATABASE_URL postgres://postgres:@postgres/wiki

ENV PORT 80

RUN bundle install

CMD bundle exec rackup