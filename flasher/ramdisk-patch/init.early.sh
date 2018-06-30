#!/system/bin/sh
enforce=0

chmod 440 /sys/fs/selinux/policy
echo $enforce > /sys/fs/selinux/enforce
chmod 640 /sys/fs/selinux/enforce
