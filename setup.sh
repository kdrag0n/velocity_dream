# Toolchain paths

# Path to the GCC toolchain, including the target prefix.
tc=$HOME/code/android/linaro641/bin/aarch64-linux-gnu-

# Number of parallel jobs to run
# This should be set to the number of CPU cores on your system.
# Do not remove, set to 1 for no parallelism.
jobs=10

# Do not edit below this point
# -----------------------------

export CROSS_COMPILE=$tc
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=velocity
export KBUILD_BUILD_HOST=kernel

export CFLAGS=""
export CXXFLAGS=""
export LDFLAGS=""

cc_ver="$(${tc}gcc --version|head -n1|cut -d'(' -f2|tr -d ')'|awk '{$5=""; print $0}'|sed -e 's/[[:space:]]*$//')"

MAKEFLAGS="KBUILD_COMPILER_STRING=\"${cc_ver}\""

source helpers.sh
