#export CROSS_COMPILE=$HOME/code/android/google49/bin/aarch64-linux-android-
#export CROSS_COMPILE=$HOME/code/android/gclang/clang-4691093/bin/
export CROSS_COMPILE=$HOME/code/android/linaro731/bin/aarch64-linux-gnu-
export ARCH=arm64
export SUBARCH=arm64
export CFLAGS="-Ofast"
export CXXFLAGS="-Ofast"
#export C="clang"
#export CXX="clang++"
#export USE_CCACHE=0
#export CCACHE_DISABLE=1
#export HOSTCC="clang"
#export HOSTCXX="clang++"
#export CFLAGS="-target aarch64-linux-gnu -Ofast"
#export CXXFLAGS="-target aarch64-linux-gnu -Ofast"
#export CC="${CROSS_COMPILE}${C}"

# helpers
mkzip() {
    rm anykernel/Image.gz-dtb
    rm velocity_kernel.zip
    cp arch/arm64/boot/Image.gz-dtb anykernel/
    cd anykernel
    zip -r ../velocity_kernel.zip *
    cd ..
    echo 'Done. Output is velocity_kernel.zip'
}
