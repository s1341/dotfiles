function is_mounted () {
	mount | grep -q $1;
	return $?
}

function is_running () {
	pidof $1 >/dev/null 2>&1
	return $?
}

is_mounted /media/storage/email || is_mounted /media/storage/docs || {
	pushd ~/data/storage
	echo "Mounting crypto storage"
	echo "Enter sudo password when prompted, then crypto passphrase"
	is_mounted /media/storage/email || sudo ~/data/storage/mountstorage email
	is_mounted /media/storage/docs || sudo ~/data/storage/mountstorage docs
	popd
}

is_running Linux-G13-Driver || {
	echo "Starting g13 stuff"
	sudo modprobe uinput
	sudo chgrp uucp /dev/uinput
	sudo chmod g+rw /dev/uinput
	~/outside_tools/linux-g13-driver-read-only/source/Linux-G13-Driver >/dev/null 2>&1 &
}


# is_running autossh || {
# 	echo "Starting autossh"
# 	~/autossh.sh
# }

is_running vmware || is_running chromium || {
	echo "Starting vmware, chromium"
	is_running vmware || vmware >/dev/null 2>&1 &
	is_running chromium || chromium >/dev/null 2>&1 &
}

#znc
