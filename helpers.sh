_RELEASE=0

mkzip() {
    cp -f arch/arm64/boot/dtb{,2}.img flasher/
    cp -f arch/arm64/boot/Image flasher/
    [ $_RELEASE -eq 0 ] && rm -f flasher/.rel
    [ $_RELEASE -eq 1 ] && touch flasher/.rel

    fn="velocity_kernel.zip"
    [ "x$1" != "x" ] && fn="$1"
    rm -f "$fn"
    rm -fr /tmp/velozip
    mkdir /tmp/velozip
    cp -fr flasher/META-INF /tmp/velozip
    echo "  XZ      arc.xz"
    pushd flasher
    tar c --owner=0 --group=0 * | xz -zcT $(($(cat /proc/cpuinfo|grep processor|wc -l)-2)) > /tmp/velozip/arc.xz
    popd
    echo "  ZIP     $fn"
    prpath="$(pwd)"
    pushd /tmp/velozip
    zip -0qr "$prpath/$fn" .
    popd
    unset prpath
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
    mkdir -p releases
    mkzip "releases/velocity_kernel-dream-r$(cat .relversion)-$(date +%Y%m%d).zip"

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
    mkzip "betas/velocity_kernel-dream-b$(cat .version)-$(date +%Y%m%d).zip"
}

ktest() {
    adb wait-for-any
    adb shell ls '/init.recovery*' > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        adb reboot recovery
    fi

    fn="velocity_kernel.zip"
    [ "x$1" != "x" ] && fn="$1"
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
