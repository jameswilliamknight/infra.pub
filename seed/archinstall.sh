#!/usr/bin/env bash

github_account="${ARCHINSTALL_SSH_KEY_GITHUB_ACCOUNT:-jameswilliamknight}"
echo "Installing all public ssh keys for github user '$github_account'"

pyscript=$(cat <<'END_HEREDOC'

import json
import sys

for entry in json.load(sys.stdin):
    print(entry["key"] + '\n')

END_HEREDOC
)

install -m 700 -d /root/.ssh

curl -s "https://api.github.com/users/${github_account}/keys" | \
    python -c "$pyscript" \
    >/root/.ssh/authorized_keys

chmod 600 /root/.ssh/authorized_keys

echo "Starting ssh..."
systemctl enable --now sshd

echo "Detecting primary block device name..."
if [ -b /dev/mmcblk1 ]; then
  mmcdoc=$(echo "$ export ARCHLINSTALL_MMC=yes")
  device=mmcblk1
else
  mmcdoc=""
  device=sda
fi

my_ip=`ip route get 1 | awk '{print $(NF-2);exit}'`

cat << EOF
Now you can connect with ssh root@$my_ip

To install this machine, on your development machine do the following:
${mmcdoc}$ export ARCHINSTALL_SSH_KEY_GITHUB_ACCOUNT=$github_account
$ export ARCHINSTALL_IP_ADDRESS=$my_ip
$ export ARCHINSTALL_HOSTNAME=...        # (Optional. arch by default)
$ export ARCHINSTALL_USERNAME=...        # (Optional. arch by default)
$ export ARCHINSTALL_PASSWORD=...        # (Optional. No password by default)
$ ansible-playbook install_archlinux.yaml

If you want to restart from scratch, run the following command here before:
$ wipefs --all /dev/$device
$ sfdisk --delete all /dev/sda
EOF