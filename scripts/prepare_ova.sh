#!/bin/bash
# Usage: ./prepare_ova.sh [web|app|db]
ROLE=$1
if [ -z "$ROLE" ]; then echo "Usage: ./prepare_ova.sh [web|app|db]"; exit 1; fi
echo "Preparing VM for OVA Export ($ROLE Tier)..."

# Services
if [ "$ROLE" == "web" ]; then systemctl enable nginx; chmod -R 755 /var/www/html; fi
if [ "$ROLE" == "app" ]; then systemctl enable community-app; fi
if [ "$ROLE" == "db" ]; then systemctl enable community-db; fi

# Cleanup
echo -n > /etc/machine-id
history -c
cat /dev/null > ~/.bash_history
poweroff
