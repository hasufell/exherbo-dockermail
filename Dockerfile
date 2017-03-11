FROM        hasufell/exherbo
MAINTAINER  Julian Ospald "hasufell@posteo.de"


# copy paludis config
COPY ./config/paludis /etc/paludis


##### PACKAGE INSTALLATION #####

# update world with our options
RUN chgrp paludisbuild /dev/tty && \
	eclectic env update && \
	source /etc/profile && \
	cave sync && \
	cave resolve -z -1 repository/net -x && \
	cave resolve -z -1 repository/hasufell -x && \
	cave resolve -z -1 repository/python -x && \
	cave resolve -z -1 repository/perl -x && \
	cave resolve -z -1 repository/nicoo -x && \
	cave update-world -s mail && \
	cave resolve -ks -Sa -sa -B world -x -f --permit-old-version '*/*' && \
	cave resolve -ks -Sa -sa -B world -x --permit-old-version '*/*' && \
	cave purge -x && \
	cave fix-linkage -x && \
	rm -rf /usr/portage/distfiles/*

RUN eclectic config accept-all

################################


##### APPLICATION CONFIG #####

# copy "mailbase" stuff
COPY ./config/mailcap /etc/mailcap
COPY ./config/mail /etc/mail
COPY ./config/pam.d /etc/pam.d

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
RUN openssl req -new -x509 -nodes -out /etc/ssl/certs/postfix.pem -keyout \
	/etc/ssl/private/postfix.key -days 3650 -subj '/CN=www.example.com'

# Postfix configuration
ADD ./config/postfix/postfix.main.cf /etc/postfix/main.cf
ADD ./config/postfix/postfix.master.cf.append /etc/postfix/master-additional.cf
RUN cat /etc/postfix/master-additional.cf >> /etc/postfix/master.cf
RUN sed -r -i -e \
	'/^smtp[[:space:]]+inet[[:space:]]+/a\ -o content_filter=spamassassin' \
	/etc/postfix/master.cf
RUN newaliases -oA/etc/mail/aliases

# Dovecot configuration
COPY ./config/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
COPY ./config/dovecot/dovecot.mail /etc/dovecot/conf.d/10-mail.conf
COPY ./config/dovecot/dovecot.ssl /etc/dovecot/conf.d/10-ssl.conf
COPY ./config/dovecot/dovecot.auth /etc/dovecot/conf.d/10-auth.conf
COPY ./config/dovecot/dovecot.master /etc/dovecot/conf.d/10-master.conf

COPY ./config/dovecot/dovecot.lda /etc/dovecot/conf.d/15-lda.conf
COPY ./config/dovecot/dovecot.imap /etc/dovecot/conf.d/20-imap.conf
COPY ./config/dovecot/dovecot.sieve /etc/dovecot/conf.d/90-sieve.conf
COPY ./config/dovecot/dovecot.managesieve \
	/etc/dovecot/conf.d/20-managesieve.conf
# Uncomment to add verbose logging
COPY ./config/dovecot/dovecot.logging /etc/dovecot/conf.d/10-logging.conf

# spamassasin configuration
COPY ./config/spamassasin/spamassasin.local.append \
	/etc/mail/spamassassin/local.cf.append
RUN mkdir /etc/mail/spamassassin/.pyzor /etc/mail/spamassassin/.razor
COPY ./config/spamassasin/pyzor.servers /etc/mail/spamassassin/.pyzor/servers
RUN cat /etc/mail/spamassassin/local.cf.append >> /etc/mail/spamassassin/local.cf
COPY ./update-spamlists /usr/bin/update-spamlists
RUN chmod +x /usr/bin/update-spamlists

# supervisord configuration
COPY ./config/supervisord.conf /etc/supervisord.conf

##############################


# Nice place for your settings
VOLUME ["/mail_settings"]

# Copy boot scripts
COPY boot /
RUN chmod 755 /boot
COPY boot.d /boot.d
RUN chmod -R 755 /boot.d

# Add user vmail that owns mail
RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /vmail -m

# Volume to store email
VOLUME ["/vmail"]

EXPOSE 25 465 993 4190

CMD /boot && exec /usr/bin/supervisord -n -c /etc/supervisord.conf
