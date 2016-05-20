#!/bin/sh
/etc/init.d/postgresql start
/etc/init.d/rabbitmq-server start
/etc/init.d/mongodb start
if (sudo -u  postgres psql -c "SELECT usename from pg_user WHERE usename = 'StackStorm';" --quiet | grep "1 row" --quiet)
then
  echo "Role mistral already exists"
else
  sudo -u postgres psql -c "CREATE ROLE mistral WITH CREATEDB LOGIN ENCRYPTED PASSWORD 'StackStorm';"
fi

if (sudo -u  postgres psql -c "SELECT datname FROM pg_database WHERE datname = 'mistral';" --quiet | grep "1 row" --quiet)
then
  echo "database mistral already exists"
else
  sudo -u postgres psql -c "CREATE DATABASE mistral OWNER mistral;"
  /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf upgrade head
  /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf populate
fi
cp -a -r -n /tmp/st2docker/packs/* /opt/stackstorm/packs

/usr/bin/st2ctl start
/usr/bin/st2ctl reload
echo $1
echo $2
user_list= "$1"
username= "$2"

if [ -n "$user_list" ]
then
  python /tmp/st2docker/add_user.py ${user_list}
  password=`python /tmp/st2docker/get_user_password.py ${username} ${user_list}`
  TOKEN=`st2 auth devops -p ${password} | grep token | awk -F'|' '{print $3}'`
  for pack in "/tmp/st2contrib/packs/"*
  do
    if [ ! -d /opt/stackstorm/packs/$(basename $pack) ]
    then
      st2 run packs.install packs=$(basename $pack) -t ${TOKEN}
    fi
  done
fi
rm -rf /tmp/st2docker
rm -rf /tmp/st2contrib

echo "Sleep for 10 seconds while services start..."
sleep 10

echo "Starting nginx..."
exec $(which nginx) -g "daemon off;"