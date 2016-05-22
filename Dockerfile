FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive


RUN \
  apt-get update && \
    apt-get install -y curl python python-dev python-pip python-virtualenv openssh-server && \
      bash -c 'rm -f /usr/sbin/policy-rc.d 2> /dev/null' && \
        apt-get install -y python-prettytable python-yaml git git-core mongodb-server && \
          apt-get install -y rabbitmq-server postgresql postgresql-contrib && \
            rm -rf /var/lib/apt/lists/*

# Set environment variable to Docker
ENV CONTAINER DOCKER

# Install Python Package
RUN pip install requests -q
RUN pip install requests_ntlm -q
RUN pip install six -q
RUN pip install python_hosts -q


RUN curl -s https://packagecloud.io/install/repositories/StackStorm/stable/script.deb.sh | sudo bash

RUN apt-get install -y st2 st2mistral



RUN bash -c 'mkdir  /home/stanley/.ssh'

RUN bash -c 'chmod 0700 /home/stanley/.ssh'

RUN bash -c 'ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P "Welcome123"'

RUN bash -c 'cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys'

RUN bash -c 'chown -R stanley:stanley /home/stanley/.ssh'

RUN bash -c 'echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2'

RUN bash -c 'chmod 0440 /etc/sudoers.d/st2'

RUN bash -c 'sudo sed -i -r "s/^Defaults\s+\+requiretty/# Defaults +requiretty/g" /etc/sudoers'


RUN mkdir -p /data/main && \
  chown postgres /data/* && \
   chgrp postgres /data/* && \
    chmod 700 /data/main && \
     cp -a /etc/postgresql/9.3/main/postgresql.conf /data/postgresql.conf && \
      cp -a /etc/postgresql/9.3/main/pg_hba.conf /data/pg_hba.conf && \
       sed -i '/^data_directory*/ s|/var/lib/postgresql/9.3/main|/data/main|' /data/postgresql.conf && \
        sed -i '/^hba_file*/ s|/etc/postgresql/9.3/main/pg_hba.conf|/data/pg_hba.conf|' /data/postgresql.conf && \
         su postgres --command "/usr/lib/postgresql/9.3/bin/initdb -D /data/main" && \
          su postgres --command "/usr/lib/postgresql/9.3/bin/postgres -D /data/main -c config_file=/data/postgresql.conf &" && \
           su postgres --command 'createuser -P -d -r -s docker' && \
            su postgres --command 'createdb -O docker docker'


RUN sudo apt-key adv --fetch-keys http://nginx.org/keys/nginx_signing.key && \
     bash -c 'echo deb http://nginx.org/packages/ubuntu/ trusty nginx > /etc/apt/sources.list.d/nginx.list' && \
      bash -c 'echo deb-src http://nginx.org/packages/ubuntu/ trusty nginx >> /etc/apt/sources.list.d/nginx.list' && \
       sudo apt-get update && \
        sudo apt-get install -y st2web nginx && \
         mkdir -p /etc/ssl/st2 && \
          sudo openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/st2/st2.key -out /etc/ssl/st2/st2.crt \
            -days XXX -nodes -subj "/C=AU/ST=NSW/L=Sydney/O=DimensionData/OU=itaas/CN=st2" && \
           sudo mkdir /etc/nginx/sites-available/ && \
            sudo cp -r /usr/share/doc/st2/conf/nginx/st2.conf /etc/nginx/sites-available/ && \
             sudo mkdir /etc/nginx/sites-enabled/ && \
              sudo ln -s /etc/nginx/sites-available/st2.conf /etc/nginx/sites-enabled/st2.conf && \
               sudo service nginx restart

RUN bash -c 'cd /tmp && git clone https://github.com/StackStorm/st2contrib.git'

RUN bash -c 'cd /tmp'

RUN bash -c 'cd /tmp && git clone https://github.com/kumarappanc/st2docker.git'


RUN sudo mkdir /opt/stackstorm/rbac && \
     sudo mkdir /opt/stackstorm/rbac/assignments

RUN cp -f /tmp/st2docker/nginx/nginx.conf /etc/nginx/nginx.conf

RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py" && \
  cd /tmp && python get-pip.py && \
   pip install git+https://github.com/StackStorm/st2-auth-backend-pam.git@master#egg=st2_auth_backend_pam

RUN cp -f /tmp/st2docker/st2/st2auth /etc/init.d/st2auth

RUN cp -f /tmp/st2docker/st2/st2.conf /etc/st2/st2.conf

#WEBUI
EXPOSE 443

#auth service
EXPOSE 9100

# api server
EXPOSE 9101
# webui
EXPOSE 8080


RUN mkdir /root/st2 && cp -f /tmp/st2docker/start.sh /root/st2/start.sh


RUN bash -c 'chmod +x /root/st2/start.sh'

RUN cd /root/st2 && wget https://packages.chef.io/stable/ubuntu/12.04/chefdk_0.14.25-1_amd64.deb && \
  dpkg -i chefdk_0.14.25-1_amd64.deb && \
   bash -c '/opt/chefdk/bin/chef gem install winrm' && \
    bash -c '/opt/chefdk/bin/chef gem install knife-windows'

RUN apt-get update && \
    apt-get install -y build-essential