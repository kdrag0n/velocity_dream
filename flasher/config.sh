#!/sbin/sh

tmp=/tmp/vflash
device_names="dreamlte dream2lte"
boot_block=/dev/block/platform/11120000.ufs/by-name/BOOT
ramdisk_compression=
# if you enable this, you will need to add /data mounting to the update-binary script
# boot_backup=/data/local/boot-backup.img

bin=$tmp/tools
ramdisk=$tmp/ramdisk
ramdisk_patch=$ramdisk-patch
split_img=$tmp/split-img

arch=arm64
bin=$bin/$arch
