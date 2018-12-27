_RELEASE=0

mkzip() {
    [ $_RELEASE -eq 0 ] && vprefix=test
    [ $_RELEASE -eq 1 ] && vprefix=v

    cp -f arch/arm64/boot/dtb{,2}.img flasher/
    cp -f arch/arm64/boot/Image flasher/

    [ $_RELEASE -eq 0 ] && echo "Installing test build $(cat .version)" >| flasher/version
    [ $_RELEASE -eq 1 ] && echo "Installing version v$(cat .version)" >| flasher/version
    echo "Built on $(date "+%a %b '%y at %H:%M")" >> flasher/version

    fn="${1:-velocity_kernel.zip}"
    pushd flasher
    rm -f "../$fn"
    echo "  ZIP     $fn"
    zip -r9 "../$fn" . > /dev/null
    popd
}

build_dtb() {
    do_dtb flasher/dtb.img dream/{09,10}
    do_dtb flasher/dtb2.img dream2/{09,10}
}

rel() {
    _RELEASE=1

    # Swap version files
    [ ! -f .relversion ] && echo 0 > .relversion
    mv .version .devversion && \
    mv .relversion .version

    # Compile kernel
    make "${MAKEFLAGS[@]}" -j$jobs $@

    # Revert version files
    mv .version .relversion && \
    mv .devversion .version

    # Pack release zip
    mkdir -p builds
    mkzip "releases/VelocityKernel-s8-r$(cat .relversion).zip"

    _RELEASE=0
}

zerover() {
    echo 0 >| .version
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
    mkdir -p builds
    mkzip "builds/VelocityKernel-s8-test$(cat .version).zip"
}

ktest() {
    adb wait-for-any
    adb shell ls '/init.recovery*' > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        adb reboot recovery
    fi

    fn="${1:-velocity_kernel.zip}"
    adb wait-for-usb-recovery
    while [ ! -f $fn ]; do
        sleep 0.05
    done
    adb push $fn /tmp/kernel.zip && \
    adb shell "twrp install /tmp/kernel.zip && reboot"
    [ "$fn" = ".vtest.zip" ] && rm -f $fn
}

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
    diff arch/arm64/configs/velocity_defconfig .config
}

cpc() {
    cp .config arch/arm64/configs/velocity_defconfig
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
    git add .
    find . -type f -name '*.rej' -exec git reset HEAD {} \;

    echo -n "$1" > .upstream_ver
    echo 'Patch applied. When you are finished fixing conflicts (.rejs) and have verified'
    echo 'that the kernel boots, run upsfinish.'
}
upsfinish() {
    find . -type f -name '*.rej' -exec rm -f {} \;
    git add .
    git commit -sm "treewide: update to Linux 4.4.$(cat .upstream_ver)"
    rm -f .upstream_ver
}

# Get a sorted list of the side of various objects in the kernel
osize() {
    find out -type f -name '*.o' ! -name 'built-in.o' ! -name 'vmlinux.o' -exec du -h --apparent-size {} + | sort -r -h | head -n "${1:-75}"
}
