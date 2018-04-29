# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

cat <<EOF
ui_print
ui_print __     __   _            _ _
ui_print \ \   / /__| | ___   ___(_) |_ _   _
ui_print  \ \ / / _ \ |/ _ \ / __| | __| | | |
ui_print   \ V /  __/ | (_) | (__| | |_| |_| |
ui_print    \_/ \___|_|\___/ \___|_|\__|\__, |
ui_print                                |___/
ui_print
ui_print Galaxy S8/S8+ Exynos (SM-G95xF/FD/N)
ui_print            Unified Kernel
ui_print -------------------------------------
ui_print
EOF

## AnyKernel setup
# begin properties
properties() {
kernel.string=Velocity Kernel by kdragon
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=dreamlte
device.name2=dream2lte
device.name3=
device.name4=
device.name5=
} # end properties

# shell variables
block=/dev/block/platform/11120000.ufs/by-name/BOOT;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

if [ -d $ramdisk/.subackup -o -d $ramdisk/.backup ]; then
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;

# begin ramdisk changes


# end ramdisk changes

write_boot;

## end install

