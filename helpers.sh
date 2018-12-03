# Shared interactive kernel build helpers

# Root of the kernel repository for use in helpers
kroot="$(dirname "$0")"

_RELEASE=0

mkzip() {
    [ $_RELEASE -eq 0 ] && vprefix=test
    [ $_RELEASE -eq 1 ] && vprefix=v

    cp -f "$kroot/arch/arm64/boot/dtb.img" "$kroot/flasher/"
    cp -f "$kroot/arch/arm64/boot/dtb2.img" "$kroot/flasher/"
    cp -f "$kroot/arch/arm64/boot/Image" "$kroot/flasher/"

    [ $_RELEASE -eq 0 ] && echo "Installing test build $(cat .version)" >| "$kroot/flasher/version"
    [ $_RELEASE -eq 1 ] && echo "Installing version v$(cat .version)" >| "$kroot/flasher/version"
    echo "Built on $(date "+%a %b %d, %Y")" >> "$kroot/flasher/version"

    fn="${1:-velocity_kernel.zip}"
    rm -f "$fn"
    echo "  ZIP     $fn"
    oldpwd="$(pwd)"
    pushd -q "$kroot/flasher"
    zip -qr9 "$oldpwd/$fn" . -x .gitignore
    popd -q
}

build_dtb() {
    do_dtb flasher/dtb.img dream/{09,10}
    do_dtb flasher/dtb2.img dream2/{09,10}
}

rel() {
    _RELEASE=1

    # Swap out version files
    [ ! -f "$kroot/.relversion" ] && echo 0 > "$kroot/.relversion"
    mv "$kroot/.version" "$kroot/.devversion" && \
    mv "$kroot/.relversion" "$kroot/.version"

    # Compile kernel
    make "${MAKEFLAGS[@]}" -j$jobs $@

    # Pack zip
    mkdir -p "$kroot/builds"
    mkzip "builds/VelocityKernel-s8-v$(cat "$kroot/.version").zip"

    # Revert version
    mv "$kroot/.version" "$kroot/.relversion" && \
    mv "$kroot/.devversion" "$kroot/.version"

    _RELEASE=0
}

zerover() {
    echo 0 >| "$kroot/.version"
}

cleanbuild() {
    make "${MAKEFLAGS[@]}" clean && make -j$jobs $@ && mkzip
}

incbuild() {
    make "${MAKEFLAGS[@]}" -j$jobs $@ && mkzip
}

dbuild() {
    make "${MAKEFLAGS[@]}" -j$jobs $@ && dzip
}

dzip() {
    mkdir -p "$kroot/builds"
    mkzip "builds/VelocityKernel-s8-test$(cat "$kroot/.version").zip"
}

# Flash the latest kernel zip on the connected device via ADB
ktest() {
    adb wait-for-any
    adb shell ls '/init.recovery*' > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        adb reboot recovery
    fi

    fn="${1:-velocity_kernel.zip}"
    adb wait-for-usb-recovery
    while [ ! -f "$fn" ]; do
        sleep 0.05
    done
    adb push "$fn" /tmp/kernel.zip && \
    adb shell "twrp install /tmp/kernel.zip && reboot"
    [ "$fn" = ".vtest.zip" ] && rm -f "$fn"
}

# Incremementally build the kernel, then flash it on the connected device via ADB
inc() {
    make "${MAKEFLAGS[@]}" -j$jobs $@ && \
    {
        rm -f .vtest.zip
        ktest .vtest.zip &
        mkzip .vtest.zip
        rm -f velocity_kernel.zip
    }
}

dc() {
    diff arch/arm64/configs/velocity_defconfig "$kroot/.config"
}

cpc() {
    # Don't use savedefconfig for readability and diffability
    cp "$kroot/.config" arch/arm64/configs/velocity_defconfig
}

mc() {
    make velocity_defconfig
}

cf() {
    make nconfig
}

# Because we don't have proper git commit history...
upstream() {
    curl https://cdn.kernel.org/pub/linux/kernel/v4.x/incr/patch-4.4.$(($1 - 1))-$1.xz | xz -d | git apply --reject
    git add "$kroot"
    find "$kroot" -type f -name '*.rej' -exec git reset HEAD {} \;

    echo -n "$1" > "$kroot/.upstream_ver"
    echo 'Patch applied. When you are finished fixing conflicts (.rejs) and have verified'
    echo 'that the kernel boots, run upsfinish.'
}

upsfinish() {
    find "$kroot" -type f -name '*.rej' -exec rm -f {} \;
    git add "$kroot"
    git commit -sm "treewide: update to Linux 4.4.$(cat .upstream_ver)"
    rm -f "$kroot/.upstream_ver"
}

# Edit the raw text config
ec() {
    ${EDITOR:-vim} "$kroot/.config"
}

# Get a sorted list of the side of various objects in the kernel
osize() {
    find "$kroot/out" -type f -name '*.o' ! -name 'built-in.o' ! -name 'vmlinux.o' -exec du -h --apparent-size {} + | sort -r -h | head -n "${1:-75}"
}
