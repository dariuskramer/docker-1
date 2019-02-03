FROM debian:sid

RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake

# Ruby
RUN apt-get install -y ruby ruby-dev && gem install bundler --no-document

# Go
RUN apt-get install -y golang

# NodeJS
RUN apt-get install -y nodejs yarnpkg
# RUN apt-get install -y nodejs

# Git
RUN apt-get install -y git && adduser --disabled-login --gecos 'GitLab (by djean)' git

# PostgreSQL
RUN apt-get install -y postgresql postgresql-client postgresql-contrib libpq-dev && \
	service postgresql start && \
	runuser -u postgres -- psql -d template1 -c "CREATE USER git CREATEDB;" && \
	runuser -u postgres -- psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" && \
	runuser -u postgres -- psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;" && \
	runuser -u git -- psql -d gitlabhq_production -c "SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pg_trgm' AND installed_version IS NOT NULL;" | grep --quiet enabled

# Redis
RUN apt-get install -y redis-server && \
	sed -i 's/^port .*/port 0/' /etc/redis/redis.conf && \
	echo 'unixsocket /var/run/redis/redis.sock' >> /etc/redis/redis.conf && \
	echo 'unixsocketperm 770' >> /etc/redis/redis.conf && \
	mkdir /var/run/redis && \
	chown redis:redis /var/run/redis && \
	chmod 755 /var/run/redis && \
	if test -d /etc/tmpfiles.d; then echo 'd  /var/run/redis  0755  redis  redis  10d  -' >> /etc/tmpfiles.d/redis.conf; fi && \
	service redis-server restart && \
	usermod -aG redis git

# GitLab
RUN runuser -u git -- git clone --depth=1 https://gitlab.com/gitlab-org/gitlab-ce.git -b 11-7-stable /home/git/gitlab && \
	cd /home/git/gitlab && \
	runuser -u git -- cp config/gitlab.yml.example config/gitlab.yml && \
	runuser -u git -- sed -i -e '/port: 80/s/80/443/g' \
							 -e '/https: false/s/false/true/g' \
							 -e '/email_from:/s/example@.*$/gitlab@localhost/g' config/gitlab.yml && \
	runuser git -c "cp config/secrets.yml.example config/secrets.yml && \
					chmod 0600 config/secrets.yml && \
					chown -R git log/ tmp/ && \
					chmod -R u+rwX,go-w log/ && \
					chmod -R u+rwX tmp/ && \
					mkdir --mode=0700 public/uploads/ && \
					chmod -R u+rwX builds/ shared/artifacts/ && \
					chmod -R ug+rwX shared/pages/ && \
					cp config/unicorn.rb.example config/unicorn.rb && \
					cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb && \
					git config --global core.autocrlf input && \
					git config --global gc.auto 0 && \
					git config --global repack.writeBitmaps true && \
					git config --global receive.advertisePushOptions true && \
					cp config/resque.yml.example config/resque.yml"

WORKDIR /home/git/gitlab

# Configure GitLab DB Settings
RUN runuser -u git -- cp config/database.yml.postgresql config/database.yml && \
	runuser -u git -- sed -i '/^production:$/,/^#$/s/secure //' config/database.yml && \
	runuser -u git -- chmod o-rwx config/database.yml

# Install Gems
RUN gem install bundler -v 1.17.3 && \
	runuser -u git -- bundle install -j$(nproc) --deployment --without development test mysql aws kerberos

# GitLab Shell
RUN runuser -u git -- bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true

# GitLab workhorse
RUN runuser -u git -- bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production

# Gitaly
RUN runuser -u git -- bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production && \
	chmod 0700 /home/git/gitlab/tmp/sockets/private && \
	chown git /home/git/gitlab/tmp/sockets/private

# Initialize Database and Activate Advanced Features
RUN service postgresql start && \
	sed -i '/^bin_dir/s,/bin,,' ../gitaly/config.toml && \
	sed -i '/^client_path/s,/bin,,' config/gitlab.yml && \
	sed -i '4d' lib/tasks/gitlab/setup.rake && \
	runuser -u postgres -- psql -d template1 -c "ALTER USER git WITH PASSWORD 'password';" && \
	runuser -u git -- bundle exec rake gitlab:setup force=yes RAILS_ENV=production GITLAB_ROOT_PASSWORD='password' GITLAB_ROOT_EMAIL=admin@localhost

# Install Init Script / Logrotate
RUN cp lib/support/init.d/gitlab /etc/init.d/gitlab && \
	update-rc.d gitlab defaults 21 && \
	cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

# Compile things
RUN service postgresql start && \
	apt-get install -y npm && \
	npm install --global yarn && \
	runuser -u git -- bundle exec rake gettext:compile RAILS_ENV=production && \
	runuser -u git -- yarn install --production --pure-lockfile && \
	runuser -u git -- bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production && \
	runuser -u git -- bundle exec rake gitlab:env:info RAILS_ENV=production # useless

# Nginx
RUN apt-get install -y nginx && \
	cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab && \
	sed -i 's/YOUR_SERVER_FQDN/localhost/' /etc/nginx/sites-available/gitlab && \
	ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab && \
	rm /etc/nginx/sites-enabled/default && \
	nginx -t

RUN service postgresql start && \
	service redis-server start && \
	service nginx start && \
	service gitlab start && \
	runuser -u git bundle exec rake gitlab:check RAILS_ENV=production

# https://docs.gitlab.com/11.7/ee/install/installation.html#done
# Entrypoint
# service gitlab start
