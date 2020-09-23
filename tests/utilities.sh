source ../bashLibrary.sh
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

testing_testCase "Version comparison" << TEST
assertSuccess utilities_upgradeRequired 1.0.0 1.0.1
assertFailure utilities_upgradeRequired 1.0.1 1.0.0
assertSuccess utilities_upgradeRequired v1.0.0-a 2.0.0
assertFailure utilities_upgradeRequired 1.10.13 1.9.13
assertSuccess utilities_upgradeRequired 1.10.13 1.10.14
assertFailure utilities_upgradeRequired 1.10.14 1.9.15
assertFailure utilities_upgradeRequired 1.001.1 1.000.2
assertSuccess utilities_upgradeRequired 1.002.1 1.100.0
TEST
