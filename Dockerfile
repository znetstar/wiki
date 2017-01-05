FROM ruby

EXPOSE 3000

COPY . /app

WORKDIR /app

ENV DATABASE_URL postgres://postgres:@postgres/wiki

ENV PORT 3000

RUN bundle install

CMD bundle exec rackup