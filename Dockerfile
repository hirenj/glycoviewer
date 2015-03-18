# DOCKER-VERSION 0.3.4

# FROM trusty
FROM	ubuntu

RUN		apt-get update --fix-missing
RUN		dpkg-divert --local --rename --add /sbin/initctl
RUN     DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common python-software-properties
RUN     DEBIAN_FRONTEND=noninteractive apt-add-repository ppa:brightbox/ruby-ng
RUN		apt-get update --fix-missing
RUN     ln -sf /bin/true /sbin/initctl
RUN		DEBIAN_FRONTEND=noninteractive apt-get install -y vim mysql-server ruby1.8 rubygems1.8
RUN     DEBIAN_FRONTEND=noninteractive apt-get install ruby-switch
RUN     ruby-switch --set ruby1.8
RUN     gem install rubygems-update -v='1.4.2'; update_rubygems
RUN     gem install rake -v 0.8.3
RUN     gem install rails -v 2.2.2
RUN     gem install rdoc; gem install rdoc-data; rdoc-data --install
RUN     gem install --no-rdoc --no-ri facets -v 2.8.1; true
RUN     gem install --no-rdoc --no-ri  color -v 1.4.0; true

RUN 	DEBIAN_FRONTEND=noninteractive apt-get install -y imagemagick libmagickwand-dev
RUN     gem install --no-rdoc --no-ri  rmagick -v 2.12.0; true

RUN     DEBIAN_FRONTEND=noninteractive apt-get install -y libmysqlclient-dev
RUN     gem install --no-rdoc --no-ri  mysql -v 2.8.1; true

ADD 	. /glycoviewer
RUN     cd /glycoviewer; rake gems:install

RUN     gem install --no-rdoc --no-ri builder -v 2.1.2
RUN     gem install --no-rdoc --no-ri xml-mapping -v 0.8.1

RUN     (/usr/bin/mysqld_safe &) && sleep 5 && /usr/bin/mysql --user=root mysql -e "CREATE USER 'enzymedb' IDENTIFIED BY 'enzymedb';"
RUN     (/usr/bin/mysqld_safe &) && sleep 5 && /usr/bin/mysql --user=root -e "CREATE database enzymedb;"
RUN     (/usr/bin/mysqld_safe &) && sleep 5 && /usr/bin/mysql --user=root mysql -e "GRANT ALL PRIVILEGES ON enzymedb.* to 'enzymedb' WITH GRANT OPTION; FLUSH PRIVILEGES;"

RUN     (/usr/bin/mysqld_safe &) && sleep 5 && cd /glycoviewer; rake db:schema:load
RUN     (/usr/bin/mysqld_safe &) && sleep 5 && /usr/bin/mysql --user=root enzymedb < /glycoviewer/glycodbs_dump
RUN     (/usr/bin/mysqld_safe &) && sleep 5 && cd /glycoviewer; rake enzymedb:loaddb[db-dump]

EXPOSE  3000

CMD		["/usr/bin/mysqld_safe & cd /glycoviewer; ruby script/server"]