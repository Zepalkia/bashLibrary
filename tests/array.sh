source ../bashLibrary.sh

array=(10 9 8 7 1 2 3 4 5 6)
array2=(2 2 2 2 2 2 0 2 2 2 2)
testing_testCase "Argmax function" << TEST
assertSuccess array_argmax array max argmax
assertEqual \$max 10
assertEqual \$argmax 0
assertSuccess array_argmax array2 max argmax
assertEqual \$max 2
assertEqual \$argmax 0
assertExit array_argmax 1
assertExit array_argmax 1 too many random arguments
TEST

testing_testCase "Argmin function" << TEST
assertSuccess array_argmin array min argmin
assertEqual \$min 1
assertEqual \$argmin 4
assertSuccess array_argmin array2 min argmin
assertEqual \$min 0
assertEqual \$argmin 6
assertExit array_argmin 1
assertExit array_argmin 1 too many random arguments
TEST
