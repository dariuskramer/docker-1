#!/bin/sh

docker run -it --rm -v $PWD:/opt/app -p 8080:8080 -w /opt/app ruby sh -c "\
	       rm -rf helloworld &&\
	       apt update && apt install -y nodejs &&\
	       gem install rails &&\
	       rails new helloworld &&\
	       cd helloworld &&\
	       bundle install &&\
	       rails server -b 0.0.0.0 -p 8080"
