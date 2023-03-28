#!/bin/bash

echo -e "\033[0;32mMise à jour des paquets\033[0m"
sleep 2
apt update && apt upgrade -y
echo ""

echo -e "\033[0;32mInstallation des dépendances\033[0m"
sleep 2
apt install -y apt-transport-https openjdk-11-jre-headless uuid-runtime pwgen dirmngr gnupg wget sudo
echo ""

echo -e "\033[0;32mInstallation de MongoDB\033[0m"
sleep 2
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update
apt install -y mongodb-org
systemctl daemon-reload
systemctl enable mongod.service
systemctl restart mongod.service
echo ""

echo -e "\033[0;32mInstallation d'ElasticSearch\033[0m"
sleep 2
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update && apt install -y elasticsearch-oss
echo ""

echo -e "\033[0;32mConfiguration d'ElasticSearch\033[0m"
sleep 2
tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
cluster.name: graylog
action.auto_create_index: false
EOT
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
echo ""

echo -e "\033[0;32mInstallation de Graylog\033[0m"
sleep 2
wget https://packages.graylog2.org/repo/packages/graylog-5.0-repository_latest.deb
dpkg -i graylog-5.0-repository_latest.deb
apt-get update && apt install -y graylog-server
echo ""

echo -e "\033[0;32mConfiguration de Graylog\033[0m"
pass=$(pwgen -N 1 -s 96)
echo -ne "\033[1;33mEnter Password for Graylog:\033[0m " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1 > secret
secret=$(cat secret)
echo "Entrer votre Timezone, voir la liste sur https://www.joda.org/joda-time/timezones.html (ex. Europe/Paris)"
read -p $'\033[1;33mTimezone: \033[0m' time
cp /etc/graylog/server/server.conf /etc/graylog/server/server.bak
echo "root_timezone = $time" >> /etc/graylog/server/server.conf
echo "password_secret = $pass" >> /etc/graylog/server/server.conf
echo "root_password_sha2 = $secret" >> /etc/graylog/server/server.conf
echo "http_bind_address = 0.0.0.0:9000" >> /etc/graylog/server/server.conf
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
echo ""

echo -e "\033[0;32mNettoyage\033[0m"
sleep 2
rm graylog-5.0-repository_latest.deb
rm graylog_install.bash
rm secret

ip4=$(/sbin/ip -o -4 addr list | grep 2: | awk '{print $4}' | cut -d/ -f1)

echo -e "\033[0;32mInstallation terminée\033[0m"
echo -e "\033[0;32mVotre serveur Graylog est disponible à l'adresse : http://$ip4:9000\033[0m"
