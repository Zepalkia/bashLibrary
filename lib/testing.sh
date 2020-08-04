source system.sh
source string.sh
source terminal.sh

# ************************************************************************************************************************************************************
# The following functions are NOT suppose to be called manually, check 'testing_testCase' (very last defined function here) to see how to automate your tests
function testing_assertSuccess() {
  local result=1
  local funcName="$1"
  local cmd="$*"
  shift
  # shellcheck disable=SC2086
  if eval $cmd; then
    result=0
  else
    __BL_FAILURE_REASON__="The function [$funcName] called with parameters [$*] returned a result different from 0"
  fi
  return $result
}

function testing_assertFailure() {
  local result=1
  local funcName="$1"
  local cmd="$*"
  shift
  # shellcheck disable=SC2086
  if ! eval $cmd; then
    result=0
  else
    __BL_FAILURE_REASON__="The function [$funcName] called with parameters [$*] returned 0"
  fi
  return $result
}

function testing_assertExit() {
  local result=1
  local funcName="$1"
  local expectedCode="$2"
  shift 2
  local cmd="$funcName $*"
  # shellcheck disable=SC2086
  (eval $cmd &>/dev/null)&
  wait $!
  errno=$?
  if [[ $errno -eq $expectedCode ]]; then
    result=0
  else
    __BL_FAILURE_REASON__="The function [$funcName] called with parameters [$*] exited with exit code [$errno] instead of the expected [$expectedCode]"
  fi
  return $result
}

function testing_assertEqual() {
  local result=1
  local v1="$1"
  local v2="$2"
  [[ "$v1" =~ \$ ]] && eval "v1=$v1"
  [[ "$v2" =~ \$ ]] && eval "v2=$v2"
  if [[ "$v1" == "$v2" ]]; then
    result=0
  else
    __BL_FAILURE_REASON__="$v1 != $v2"
  fi
  return $result
}

function testing_assertGT() {
  local result=1
  local v1="$1"
  local v2="$2"
  [[ "$v1" =~ \$ ]] && eval "v1=$v1"
  [[ "$v2" =~ \$ ]] && eval "v2=$v2"
  if [[ $v1 -gt $v2 ]]; then
    result=0
  else
    __BL_FAILURE_REASON__="$v1 <= $v2"
  fi
  return $result
}
# ************************************************************************************************************************************************************

# This function will perform a list of tests on a given user-defined function and will output any error during the process
# arg0: The name of the testing case
# heredoc: A list of tests to perform on the function, each line should be a test function (e.g. assertSuccess) that will be performed while launching the
#   function using any parameter given to the test function (e.g. assertSuccess myfunc X Y Z will call the function 'myfunc' with parameters 'X Y Z')
#   Please note that any variable scoped inside the heredoc (e.g. a value passed by address that will contian a result value) has to be escaped and not directly
#   evaluated (like the variable 'res' in the following example)
# Example:
# # The following test case will test the implementation of a function named 'factorial'
# testing_testCase "Factorial test" << TEST
#assertSuccess factorial 10 res
#assertEqual \$res 3628800
#assertSuccess factorial 0 res
#assertEqual \$res 1
#assertFailure -1 res
#TEST
# Note:
#  The following available test function (defined previously on this file) are the following:
#   assertSuccess [func.name] {func. arguments} -> expects the function to return 0
#   assertFailure [func.name] {func. arguments} -> expects the function to return 1
#   assertExit [func.name] [exit code] {func. arguments} -> expects the function to exit with err.code 'exit code'
#   assertEqual [value 1] [value 2] -> expects value 1 == value2
function testing_testCase() {
  if [[ $# -eq 1 ]]; then
    local nTests=0
    local success=0
    local failure=0
    local cmd=""
    local functionCode=""
    local firstChar=""
    local coverage=true
    local tokens=()
    local pos=0
    local str="Testing case [$1]... "
    __BL_FAILURE_REASON__=""
    echo "$str"
    while read -r inputLine; do
      nTests=$((++nTests))
      cmd="testing_$inputLine"
      # shellcheck disable=SC2086
      if eval $cmd; then
        success=$((++success))
      else
        string_tokenize "$inputLine" " " tokens
        echo " - Test #$nTests [${tokens[0]}] failed: $__BL_FAILURE_REASON__"
        failure=$((++failure))
      fi
    done
  else
    bashlib_abort "$(caller)" "[test case name]"
  fi
}
