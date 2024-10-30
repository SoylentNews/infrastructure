#!/bin/sh
sleep 30s # wait for database to start

cp /sphinx.conf.in /sphinx.conf
sed -i "s/MYSQL_HOST/${MYSQL_HOST}/g" /sphinx.conf
sed -i "s/MYSQL_USER/${MYSQL_USER}/g" /sphinx.conf
sed -i "s/MYSQL_PASSWORD/${MYSQL_PASSWORD}/g" /sphinx.conf
sed -i "s/MYSQL_DATABASE/${MYSQL_DATABASE}/g" /sphinx.conf

indexer --all --rotate  -c /sphinx.conf
searchd -c /sphinx.conf

while true
do
    sleep 15m
    indexer --all --rotate  -c /sphinx.conf
done