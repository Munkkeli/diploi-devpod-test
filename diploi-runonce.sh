#!/bin/sh

progress() {
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local action="$1"
  echo "🟩 $current_date $action"
}

# Perform tasks at controller pod startup
progress "Runonce started";

# Set accepted ssh key(s)
mkdir -p /root/.ssh;
chmod 0700 /root/.ssh;
cat /etc/ssh/internal_ssh_host_rsa.pub > /root/.ssh/authorized_keys;

cd /app;

# Seems that this is first run in devel instance

# Configure VSCode
if [ ! -e /home/node/.local/share/code-server/User/settings.json ]; then
  mkdir -p /home/node/.local/share/code-server/User
  cp /usr/local/etc/diploi-vscode-settings.json /home/node/.local/share/code-server/User/settings.json
  chown -R node:node /home/node/.local/share/code-server
fi
# Update internal ca certificate
update-ca-certificates

# Make all special env variables available in ssh also (ssh will wipe out env by default)
env >> /etc/environment

progress "Runonce done";

exit 0;
