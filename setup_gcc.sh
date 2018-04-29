#export CROSS_COMPILE=$HOME/code/android/google49/bin/aarch64-linux-android-
#export CROSS_COMPILE=$HOME/code/android/gclang/clang-4691093/bin/
#export CROSS_COMPILE=$HOME/code/android/linaro731/bin/aarch64-linux-gnu-
export CROSS_COMPILE=$HOME/code/android/cortex53/bin/aarch64-cortex_a53-linux-gnueabi-
export ARCH=arm64
export SUBARCH=arm64
export CFLAGS="-Ofast"
export CXXFLAGS="-Ofast"
jobs=10
#export C="clang"
#export CXX="clang++"
#export USE_CCACHE=0
#export CCACHE_DISABLE=1
#export HOSTCC="clang"
#export HOSTCXX="clang++"
#export CFLAGS="-target aarch64-linux-gnu -Ofast"
#export CXXFLAGS="-target aarch64-linux-gnu -Ofast"
#export CC="${CROSS_COMPILE}${C}"

source helpers.sh
