pushd ~/data/storage
echo "Mounting crypto storage"
echo "Enter sudo password when prompted, then crypto passphrase"
sudo ~/data/storage/mountstorage email
sudo ~/data/storage/mountstorage docs

echo "Starting g13 stuff"
sudo modprobe uinput
sudo chgrp uucp /dev/uinput
sudo chmod g+rw /dev/uinput
stfu ~/outside_tools/linux-g13-driver-read-only/source/Linux-G13-Driver

echo "Starting autossh"
~/autossh.sh

echo "Starting vmware, chromium"
stfu vmware
stfu chromium
