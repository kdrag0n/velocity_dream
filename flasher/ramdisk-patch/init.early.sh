#!/system/bin/sh

chmod 440 /sys/fs/selinux/policy
echo 0 > /sys/fs/selinux/enforce
chmod 640 /sys/fs/selinux/enforce
