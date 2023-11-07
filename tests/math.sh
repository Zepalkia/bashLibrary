source ../bashLibrary.sh

testing_testCase "Max function" << TEST
assertSuccess math_max 0 2 max
assertEqual \$max 2
assertSuccess math_max 2 0 max
assertEqual \$max 2
assertSuccess math_max -20 -20 max
assertEqual \$max -20
assertExit math_max 1
assertExit math_max 1 too many random arguments
TEST

testing_testCase "Min function" << TEST
assertSuccess math_min 0 2 min
assertEqual \$min 0
assertSuccess math_min 2 0 min
assertEqual \$min 0
assertSuccess math_min -20 -20 min
assertEqual \$min -20
assertExit math_min 1
assertExit math_min 1 too many random arguments
TEST

testing_testCase "Decimal to Hexadecimal" << TEST
assertSuccess math_decToHex 129 0 hex0
assertSuccess math_decToHex 129 1 hex1
assertSuccess math_decToHex 129 2 hex2
assertEqual \$hex0 \$hex1
assertEqual \$hex0 "\x81"
assertEqual \$hex2 "\x00\x81"
TEST

testing_testCase "Byte to Int" << TEST
assertSuccess math_byteToInt "A" intValue
assertEqual \$intValue 65
TEST
