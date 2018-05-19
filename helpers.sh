# helpers
mkzip() {
    rm anykernel/Image > /dev/null 2>&1
    rm velocity_kernel.zip > /dev/null 2>&1
    build_dtb
    cp arch/arm64/boot/Image anykernel/
    cd anykernel
    zip -r ../velocity_kernel.zip * > /dev/null
    cd ..
    echo '  ZIP     velocity_kernel.zip'
}

build_dtb() {
    do_dtb anykernel/dtb dream/{00,01,02,03,04,05,07,08,09,10}
    do_dtb anykernel/dtb2 dream2/{03,04,05,06,07,08,09,10}
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

cleanbuild() {
    make clean && make -j$jobs && mkzip
}

incbuild() {
    make -j$jobs && mkzip
}

test() {
    adb reboot recovery && \
    sleep 20 && \
    adb push velocity_kernel.zip /tmp && \
    adb shell twrp install /tmp/velocity_kernel.zip && \
    adb shell reboot
}

inc() {
    incbuild && test
}
