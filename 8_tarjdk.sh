#!/bin/bash
set -e
. setdevkitpath.sh

if [[ "$BUILD_IOS" != "1" ]]; then

unset AR AS CC CXX LD OBJCOPY RANLIB STRIP CPPFLAGS LDFLAGS
git clone https://github.com/termux/termux-elf-cleaner || true
cd termux-elf-cleaner
# This is the last commit that uses autoconf, newer builds are using cmake
git checkout eab198c72a020e883b79f99b70a5aa0243dbf0a8 
autoreconf --install
bash configure
make CFLAGS=-D__ANDROID_API__=${API}
cd ..

findexec() { find $1 -type f -name "*" -not -name "*.o" -exec sh -c '
    case "$(head -n 1 "$1")" in
      ?ELF*) exit 0;;
      MZ*) exit 0;;
      #!*/ocamlrun*)exit0;;
    esac
exit 1
' sh {} \; -print
}

findexec jreout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner
findexec jdkout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner

fi

cp -rv jre_override/lib/* jreout/lib/ || true

cd jreout

# Strip in place all .so files thanks to the ndk
find ./ -name '*.so' -execdir ${TOOLCHAIN}/bin/llvm-strip {} \;


tar cJf ../jre${TARGET_VERSION}-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

cd ../jdkout
tar cJf ../jdk${TARGET_VERSION}-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

# Remove jreout and jdkout
cd ..
rm -rf jreout jdkout

