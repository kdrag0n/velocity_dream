# Toolchain paths

# Path to the root of the clang toolchain
# Do not add /bin/... or anything.
tc_clang=$HOME/code/android/dtc/out/7.0

# Whether the given clang toolchain is DragonTC.
# Controls use of optimizations.
# Value: true or false
dragontc=true

# Path to the root of the gcc toolchain.
# Must be recent, or you may encounter problems.
# Do not add /bin/... or anything.
tc_gcc=$HOME/code/android/linaro731

# Number of parallel jobs to run
# This should be set to the number of CPU cores on your system.
# Do not remove, set to 1 for no parallelism.
jobs=10

# Do not edit below this point
# -----------------------------

export CLANG_PREBUILT_BIN=$tc_clang/bin/
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export GCC_TOOLCHAIN=$tc_gcc
export ARCH=arm64
export LD_LIBRARY_PATH=$tc_clang/lib64:$LD_LIBRARY_PATH
export PATH=$CLANG_PREBUILT_BIN:$GCC_TOOLCHAIN/bin:$PATH
export REAL_COMPILER=clang
export SUBARCH=arm64
export KBUILD_BUILD_USER=velocity
export KBUILD_BUILD_HOST=kernel
export TOOL_CHAIN_PATH=$tc_gcc/bin/aarch64-linux-gnu-
export CLANG_TCHAIN=$CLANG_PREBUILT_BIN/clang
export CLANG_VERSION="$(${CLANG_TCHAIN} --version|head -n1|cut -d'(' -f1,4|sed -e 's/^\s*//' -e 's/\s*$//')"
export REAL_COMPILER=clang
export DRAGONTC=$dragontc

export CFLAGS=""
export CXXFLAGS=""
export LDFLAGS=""

alias make="make CC=$CLANG_TCHAIN CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$TOOL_CHAIN_PATH KBUILD_COMPILER_STRING=\"${CLANG_VERSION}\" KBUILD_BUILD_VERSION=1 HOSTCC=$CLANG_TCHAIN"

source helpers.sh
