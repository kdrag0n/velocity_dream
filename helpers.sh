_RELEASE=0

mkzip() {
    build_dtb
    cp arch/arm64/boot/Image flasher/
    [ $_RELEASE -eq 0 ] && rm -f flasher/.rel
    [ $_RELEASE -eq 1 ] && touch flasher/.rel
    cd flasher

    if [ ! -f magisk.zip ]; then
        echo "  WGET    magisk.zip"
        wget -O magisk.zip https://github.com/topjohnwu/Magisk/releases/download/v16.3/Magisk-v16.3.zip > /dev/null 2>&1
    fi

    fn="velocity_kernel.zip"
    [ "x$1" != "x" ] && fn="$1"
    rm -f "../$fn"
    echo "  ZIP     $fn"
    zip -r9 "../$fn" . > /dev/null
    cd ..
}

build_dtb() {
    do_dtb flasher/dtb.img dream/{09,10}
    do_dtb flasher/dtb2.img dream2/{09,10}
}

do_dtb() {
    rm -fr /tmp/kdt{s,b}
    mkdir /tmp/kdt{s,b}

    echo "  DTB     $(dirname $2)"
    for dt in ${@:2}; do
        filename="$(dirname $dt)_$(basename $dt .dts)"
        ${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I include arch/arm64/boot/dts/exynos/${dt}.dts > /tmp/kdts/${filename}.dts
        scripts/dtc/dtc -p 0 -i arch/arm64/boot/dts/exynos -O dtb -o /tmp/kdtb/${filename}.dtb /tmp/kdts/${filename}.dts
    done

    scripts/dtbTool/dtbTool -o $1 -d /tmp/kdtb -s 2048 > /dev/null
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

test() {
    adb wait-for-any && \
    adb shell ls '/init.recovery*' > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        adb reboot recovery
    fi

    fn="velocity_kernel.zip"
    [ "x$1" != "x" ] && fn="$1"
    adb wait-for-usb-recovery && \
    adb push velocity_kernel.zip /tmp && \
    adb shell "twrp install /tmp/velocity_kernel.zip && reboot"
}

inc() {
    incbuild $@ && test
}

dc() {
    diff arch/arm64/configs/velocity_defconfig .config
}

cpc() {
    cp .config arch/arm64/configs/velocity_defconfig
}
