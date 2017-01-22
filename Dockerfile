FROM ruby

EXPOSE 3000

ADD . /app

WORKDIR /app

ENV DATABASE_URL postgres://postgres:postgres@postgres/wiki

ENV PORT 3000

RUN bundle install

CMD bundle exec puma -p $PORT --bind=tcp://0.0.0.0:$PORT