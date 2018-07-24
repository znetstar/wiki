FROM ruby:2.4.0

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

RUN apt-get install -y nodejs

RUN npm install -g bower

EXPOSE 3000

ADD . /app

WORKDIR /app

RUN bower install --allow-root

ENV PORT 3000

RUN bundle install

CMD bundle exec puma -p $PORT --bind=tcp://0.0.0.0:$PORT