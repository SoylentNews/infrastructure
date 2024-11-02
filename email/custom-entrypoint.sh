#!/bin/bash

cat <<EOL | cat - /conf/dovecot.conf > temp && mv temp /conf/dovecot.conf
auth_master_user_separator = *
auth_debug=yes
passdb {
  driver = passwd-file
  master = yes
  args = /etc/dovecot/master-users

  # Unless you're using PAM, you probably still want the destination user to
  # be looked up from passdb that it really exists. pass=yes does that.
  pass = yes
}
EOL

# Echo the contents of the environment variable $MAIL_MASTER_USER into /etc/dovecot/master-users
echo "$MAIL_MASTER_USER" > /etc/dovecot/master-users

# Execute the original command
exec /start.py
