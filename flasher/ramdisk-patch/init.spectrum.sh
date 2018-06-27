#!/system/bin/sh
# SPECTRUM KERNEL MANAGER
# Profile initialization script by nathanchance

# If there is not a persist value, we need to set one
if [ ! -f /data/property/persist.spectrum.profile ]; then
	setprop persist.spectrum.profile 0
fi

# VELOCITY KERNEL

# fix battery drain
stop secure_storage

# activate zswap
mkswap /dev/block/zram0
swapon /dev/block/zram0 # activate zswap

# fix deep sleep (thanks to Chainfire)
for i in $(ls /sys/class/scsi_disk/); do
	cat /sys/class/scsi_disk/$i/write_protect 2>/dev/null | grep 1 >/dev/null
	if [ $? -eq 0 ]; then
		echo 'temporary none' > /sys/class/scsi_disk/$i/cache_type
	fi
done

chmod 440 /sys/fs/selinux/policy
echo 0 > /sys/fs/selinux/enforce
chmod 640 /sys/fs/selinux/enforce
