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
