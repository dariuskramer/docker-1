FROM ruby

# Disallow changes to the Gemfile. When the Gemfile is changed and the lockfile has not been updated, running Bundler commands will be blocked.
RUN bundle config --global frozen true

RUN apt update &&\
    apt install -y nodejs &&\
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app

ONBUILD COPY Gemfile /opt/app/
ONBUILD COPY Gemfile.lock /opt/app/
ONBUILD RUN bundle install
ONBUILD COPY . /opt/app
ONBUILD RUN rake db:migrate && rake db:setup && rake db:seed

# Build
# docker build -t ft-rails:on-build .
#
# Create rails app
# sh create_rails_project.sh
#
# Build on-build Dockerfile
# cd helloworld; and docker build -t ex02 -f ../ex02-Dockerfile .
#
# Run
# docker run -dit --rm -p 3000:3000 ex02
#
# Test
# curl (docker-machine ip):3000
