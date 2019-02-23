#!/usr/bin/env sh

docker run -it \
	--rm \
	--mount type=bind,source="$(pwd)",target=/opt/app \
	-w /opt/app \
	ruby:2.4 \
	/bin/bash -c "gem install rails && rails new helloworld"

sed -i '' "s|gem 'sqlite3'|&, '~> 1.3.6'|" helloworld/Gemfile
