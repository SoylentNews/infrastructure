#!/bin/bash
mv ./config.php /opt/lg/
cp ~/.ssh/id_ed25519 /opt/lg/devops.key
sudo chown 33:33 /opt/lg/config.php
sudo chown 33:33 /opt/lg/devops.key


