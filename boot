#!/bin/bash


# Update hostname if given
if [ -f /mail_settings/myhostname ]; then
	sed -i -e "s/myhostname = localhost/myhostname = $(sed 's:/:\\/:g' /mail_settings/myhostname)/" /etc/postfix/main.cf
	echo $(sed 's:/:\\/:g' /mail_settings/myhostname) > /etc/mailname
fi

# Configure mail delivery to dovecot
cp /mail_settings/aliases /etc/postfix/virtual
cp /mail_settings/domains /etc/postfix/virtual-mailbox-domains

# Parse mailbox settings
mkdir -p /etc/postfix/tmp
awk < /etc/postfix/virtual '{ print $2 }' > /etc/postfix/tmp/virtual-receivers
sed -r 's,(.+)@(.+),\2/\1/,' /etc/postfix/tmp/virtual-receivers > /etc/postfix/tmp/virtual-receiver-folders
paste /etc/postfix/tmp/virtual-receivers /etc/postfix/tmp/virtual-receiver-folders > /etc/postfix/virtual-mailbox-maps

# Give postfix ownership of its files
chown -R postfix:postfix /etc/postfix

# Map virtual aliases and user/filesystem mappings
postmap /etc/postfix/virtual
postmap /etc/postfix/virtual-mailbox-maps
chown -R postfix:postfix /etc/postfix

# add global sieve script
mkdir -p /vmail/sieve && cp /mail_settings/spam-global.sieve /vmail/sieve/

# Make user vmail own all mail folders
chown -R vmail:vmail /vmail
chmod u+w /vmail

# Add password file
cp /mail_settings/passwords /etc/dovecot/passwd

# set mynetworks
sed -i \
	-e "s#^mynetworks = .*#mynetworks = $(cat /mail_settings/postfix-networks | tr -d '\n')#" \
	/etc/postfix/main.cf

# Run boot scripts
for SCRIPT in /boot.d/*
do
  if [ -f "$SCRIPT" -a -x "$SCRIPT" ]; then
    "$SCRIPT"
  fi
done
