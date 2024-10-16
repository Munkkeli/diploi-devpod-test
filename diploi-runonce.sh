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
# Intialize persistant storage
if [ ! "$(ls -A /app)" ]; then

  echo "Empty /app, assuming development instance setup was intended";

  # Make /app default folder  
  echo "cd /app;" >> /root/.bashrc

  # Generate root ssh key
  ssh-keygen -A;

  if [ "$REPOSITORY_URL" = "https://github.com/diploi/nextjs-postgresql-template-demo.git" ]; then
    # Using quick launch cached initial files
    progress "Using quick launch /app";
    find /app-quick-launch/ -mindepth 1 -maxdepth 1 -exec mv -t /app -- {} +
    rmdir /app-quick-launch
  else
    progress "Pulling code";
    git init --initial-branch=main
    git config credential.helper '!diploi-credential-helper';
    git remote add --fetch origin $REPOSITORY_URL;
    if [ -z "$REPOSITORY_TAG" ]; then
      git checkout -f $REPOSITORY_BRANCH;
    else
      git checkout -f -q $REPOSITORY_TAG;
      git checkout -b main
      git branch --set-upstream-to=origin/main main
    fi
    git remote set-url origin "$REPOSITORY_URL";
    git config --unset credential.helper;

    progress "Installing";
    npm install;
  fi

  # Configure VSCode
  mkdir -p /root/.local/share/code-server/User
  cp /usr/local/etc/diploi-vscode-settings.json /root/.local/share/code-server/User/settings.json
fi

# Update internal ca certificate
update-ca-certificates

# Make all special env variables available in ssh also (ssh will wipe out env by default)
env >> /etc/environment

progress "Runonce done";

exit 0;
