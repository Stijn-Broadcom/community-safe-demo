#!/bin/bash
# Configure IPs here
WEB_IP="192.168.1.10"
APP_IP="192.168.1.11"
DB_IP="192.168.1.12"
DOMAIN="communitysafe.local"

cp /etc/hosts /etc/hosts.bak
sed -i "/$DOMAIN/d" /etc/hosts
echo "" >> /etc/hosts
echo "# CommunitySafe Demo Map" >> /etc/hosts
echo "$WEB_IP web.$DOMAIN" >> /etc/hosts
echo "$APP_IP app.$DOMAIN" >> /etc/hosts
echo "$DB_IP  db.$DOMAIN"  >> /etc/hosts
