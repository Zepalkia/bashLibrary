source ../bashLibrary.sh

testing_testCase "Options initialization" << TEST
assertExit options_init 1 "NAME"
assertExit options_init 1 "too" "many" "arguments" "given"
assertSuccess options_init "NAME" "SHORT" "DESCRIPTION"
assertSuccess options_insert "-1" "Option1"
assertSuccess options_insert "-2" "Option2" "--option2"
assertSuccess options_insert "-3" "Option3" "--option3" "int"
assertExit options_insert 1
TEST

declare -A userOptions
testing_testCase "Options parsing" << TEST
assertExit options_parse 1 userOptions
assertFailure options_parse userOptions -4 -5
assertEqual "\${userOptions[0]}" "4"
assertSuccess options_parse userOptions -12
assertSuccess options_parse userOptions -1 -2
assertSuccess options_parse userOptions --option2
assertSuccess options_parse userOptions --option2 --option3 8
TEST

unset userOptions
declare -A userOptions
testing_testCase "Options with arguments and help" << TEST
assertSuccess options_parse userOptions --option2 -1 --option3 8
assertEqual "\${userOptions["-3"]}" 8
assertEqual "\${#userOptions[@]}" 3
assertSuccess options_getHelp res0 -3
assertSuccess options_getHelp res1 --option3
assertEqual "\$res0" "\$res1"
TEST
