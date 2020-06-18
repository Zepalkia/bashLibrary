source ../bashLibrary0.0.1.sh
file=/tmp/testing$RANDOM
curr="$PWD"
mkdir "$file"
testing_testCase "Utilities" << TEST
assertSuccess utilities_safeCD $file
assertSuccess utilities_safeCD -
assertExit utilities_safeCD 1
assertExit utilities_safeCD 1 too many arguments
assertSuccess utilities_validateIP 192.168.1.1
assertFailure utilities_validateIP a.b.c.d
assertFailure utilities_validateIP 192.168.1.260
assertFailure utilities_validateIP 1.1.1.1.1
assertExit utilities_validateIP 1
assertExit utilities_validateIP 1 too many arguments
assertSuccess utilities_bytesToReadable 1024 res
assertEqual "\$res" "1024 o"
assertSuccess utilities_bytesToReadable 13049 res
assertEqual "\$res" "12.74 Kio"
assertExit utilities_bytesToReadable 1
assertExit utilities_bytesToReadable 1 too many random arguments
TEST
cd - &>/dev/null
rmdir "$file"
