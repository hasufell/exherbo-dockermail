FROM        gentoo-amd64-paludis:latest
MAINTAINER  Julian Ospald "hasufell@posteo.de"

# check these with "cave show <package-name>"
RUN echo -e "*/* acl bash-completion ipv6 kmod openrc pcre readline unicode\
	zlib pam ssl sasl bzip2 urandom crypt tcpd\
	-acpi -cairo -consolekit -cups -dbus -dri -gnome -gnutls -gtk -ogg -opengl\
	-pdf -policykit -qt3support -qt5 -qt4 -sdl -sound -systemd -truetype -vim\
	-vim-syntax -wayland -X\
	\n\
	\nnet-mail/dovecot cydir imapc maildir mbox mdbox pam pop3c sieve sqlite\
	\n\
	\nmail-mta/postfix dovecot-sasl mbox sasl" \
	>> /etc/paludis/use.conf

# update world with our USE flags
RUN chgrp paludisbuild /dev/tty && cave resolve -c world -x

# install dovecot
RUN chgrp paludisbuild /dev/tty && cave resolve -z net-mail/dovecot mail-mta/postfix -x

# install tools
RUN chgrp paludisbuild /dev/tty && cave resolve -z app-admin/supervisor sys-process/htop -x

# update etc files... hope this doesn't screw up
RUN etc-update --automode -5

# create dovecot certificates
RUN mkdir -p /var/tmp/dovecot-cert
RUN cp /usr/share/doc/dovecot-*/mkcert.sh /var/tmp/dovecot-cert/ ; \
	cp /usr/share/doc/dovecot-*/dovecot-openssl.cnf /var/tmp/dovecot-cert/
RUN chmod +x /var/tmp/dovecot-cert/mkcert.sh
WORKDIR /var/tmp/dovecot-cert
RUN ./mkcert.sh
RUN chown root:dovecot /etc/ssl/certs/dovecot.pem ; \
	chmod 0644 /etc/ssl/certs/dovecot.pem ; \
	chown root:dovecot /etc/ssl/private/dovecot.pem ; \
	chmod 0600 /etc/ssl/private/dovecot.pem
WORKDIR /
RUN rm -r /var/tmp/dovecot-cert

# create postfix certificates
RUN openssl req -new -x509 -nodes -out /etc/ssl/certs/postfix.pem -keyout /etc/ssl/private/postfix.key -days 3650 -subj '/CN=www.example.com'

# Postfix configuration
ADD ./config/postfix.main.cf /etc/postfix/main.cf
ADD ./config/postfix.master.cf.append /etc/postfix/master-additional.cf
RUN cat /etc/postfix/master-additional.cf >> /etc/postfix/master.cf

# Dovecot configuration
COPY ./config/dovecot.mail /etc/dovecot/conf.d/10-mail.conf
COPY ./config/dovecot.ssl /etc/dovecot/conf.d/10-ssl.conf
COPY ./config/dovecot.auth /etc/dovecot/conf.d/10-auth.conf
COPY ./config/dovecot.master /etc/dovecot/conf.d/10-master.conf
COPY ./config/dovecot.lda /etc/dovecot/conf.d/15-lda.conf
COPY ./config/dovecot.imap /etc/dovecot/conf.d/20-imap.conf
# Uncomment to add verbose logging
COPY ./config/dovecot.logging /etc/dovecot/conf.d/10-logging.conf
COPY ./config/supervisord.conf /etc/supervisord.conf

# Nice place for your settings
VOLUME ["/mail_settings"]

# Copy boot scripts
COPY boot /
RUN chmod 755 /boot
COPY boot.d /boot.d
RUN chmod -R 755 /boot.d

# Volume to store email
VOLUME ["/vmail"]

# Add user vmail that owns mail
RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /vmail -m

EXPOSE 25 143 587

ENTRYPOINT /boot; /usr/bin/supervisord -n
