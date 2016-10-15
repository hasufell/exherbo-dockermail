Dockermail - Email Core
==========
This image provides a secure mail server based on:
* postfix
* dovecot (with sieve/managesieve support)
* spamassasin (with pyzor and razor)

All incoming mail to your domains is accepted.
For outgoing mail, only authenticated (logged in with username and password) clients can send messages via STARTTLS.

### Setup
You will need 2 folder on your host, one to store your configuration and another one to store your email.
In the instructions below we will use the following:
  * `/var/lib/dockermail/settings` to store configuration
  * `/var/lib/dockermail/vmail` to store the mail

Use the the example config files in `config/example` to get you started.

1. Add all domains you want to receive mail for to the file `/var/lib/dockermail/settings/domains`, like this:

		example.org
		example.net

2. Add user aliases to the file `/var/lib/dockermail/settings/aliases`:

		johndoe@example.org       john.doe@example.org
		john.doe@example.org      john.doe@example.org
		admin@forum.example.org   forum-admin@example.org
		@example.net              catch-all@example.net

	An IMAP mail account is created for each entry on the right hand side.
	Every mail sent to one of the addresses in the left column will be delivered to the corresponding account in the right column.

3. Add user passwords to the file `/var/lib/dockermail/settings/passwords` like this

		john.doe@example.org:{PLAIN}password123
		admin@example.org:{SHA256-CRYPT}$5$ojXGqoxOAygN91er$VQD/8dDyCYOaLl2yLJlRFXgl.NSrB3seZGXBRMdZAr6

	To get the hash values, you can either install dovecot locally or use `docker exec -it [email_core_container_name] bash` to attach to the running container (step 6) and run `doveadm pw -s <scheme-name>` inside, remember to restart your container if you update the settings!

4. Change the hostname in file `/var/lib/dockermail/settings/myhostname` to the correct fully qualified domain of your server.

5. Set the "mynetworks" variable for postfix in file `/var/lib/dockermail/settings/postfix-networks` to e.g. `127.0.0.0/8 [::1]/128` (one single line only).

5. Build container

		docker build -t hasufell/exherbo-dockermail .

6. Run container

		docker run -ti -d \
		  --name dockermail \
		  -p 25:25 \
		  -p 465:465 \
		  -p 993:993 \
		  -p 4190:4190 \
		  -v /var/lib/dockermail/settings:/mail_settings \
		  -v /var/lib/dockermail/vmail:/vmail \
		  -v <path-to-certs>:/etc/ssl/server
		  dockermail_email_core

	Note that the certificates must be named `email.crt` and `email.key`.
