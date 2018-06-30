#!/system/bin/sh
enforce=0

[ $enforce = 0 ] && chmod 440 /sys/fs/selinux/policy
echo $enforce > /sys/fs/selinux/enforce
[ $enforce = 0 ] && chmod 640 /sys/fs/selinux/enforce

# activate zram
if [ "$(cat /proc/swaps|wc -l)" = 1 ]; then
    mkswap /dev/block/zram0
    swapon /dev/block/zram0
fi
