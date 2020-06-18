source ../bashLibrary.sh

testing_testCase "Display messages" << TEST
assertSuccess ui_showMessage emg \""Emergency message\""
assertSuccess ui_showMessage err \""Error message\""
assertSuccess ui_showMessage war \""Warning message\""
assertSuccess ui_showMessage inf \""Info message\""
assertExit ui_showMessage 1
assertExit ui_showMessage 1 too many random arguments
assertSuccess ui_horizontalRule
TEST

testing_testCase "Test windows" << TEST
assertSuccess ui_okWindow 0 0 20 \""This window should be in the top-left corner\"" true
TEST
#assertSuccess ui_centerTopLeft 20 4 X Y
# assertSuccess ui_confirmWindow \$X \$Y 20 \""Is this window well centered ?\"" true res
# assertEqual \$res true
