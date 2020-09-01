source string.sh

# This function inits the option environment, should be called before any other options_* function and only ONCE per application
# arg0: The name of the application
# arg1: A short description of the application
# arg2: The complete description of the application
# Note:
#   The arguments given to the option environment will be used to generate an automated help page for the application (man-compatible)
function options_init() {
  if [[ $# -eq 3 ]]; then
    rm -f /tmp/.helppage
    exec {BL_OPT_FD}<>/tmp/.helppage
    rm -f /tmp/.helppage
    echo ".TH $1 1
.SH NAME
$1 - $2
.SH DESCRIPTION
$3
.SH OPTIONS" >&$BL_OPT_FD
    #/proc/$$/fd/$BL_OPT_FD
  else
    bashlib_abort "$(caller)" "[application name] [application short description] [application description]"
  fi
}

# generates an automated man page
# handle -ABCD, -A -B -C -D, multi args (-A arg0 arg1 arg2), alias (-O/--option)

# This function adds inside the option environment a new option compatible with the application with some help message and possible alias
# arg0: The main option (should start with -/--/+)
# arg1: The help message related to the option
# arg2: An optional alias (e.g. a main option -h can have --help as an alias)
# arg3: An optional parameter information
# Example:
#   options_insert "-d" "This option doubles the given number" "--double" "number"
function options_insert() {
  if [[ $# -ge 2 ]]; then
    local helpString="$2"
    local option="$1"
    local string="$option"
    local optionAlias=""
    local optionArgs=""
    shift 2
    if [[ $# -gt 0 ]]; then
      if [[ "$1" != "" ]]; then
        optionAlias="$1"
        string="\\fB$string, $optionAlias\\fR"
      else
        string="\\fB$string\\fR"
      fi
      shift
    else
      string="\\fB$string\\fR"
    fi
    if [[ $# -gt 0 ]]; then
      optionArgs="$1"
      string="$string \\fI${optionArgs}\\fR"
    fi
    string="$string
.RS
$helpString
.RE
.PP"
    echo "$string" >&${BL_OPT_FD}
    __BL_ARGUMENTS__["$option"]="$string"
    if [[ "$optionAlias" != "" ]]; then
      __BL_ALIASES__["$optionAlias"]="$option"
    fi
  else
    bashlib_abort "$(caller)" "[option string] [help string] {alias} {arguments}"
  fi
}

# This function displays the auto-generated help menu for the application based on the previously inserted available option using 'man'
function options_display() {
  cat /proc/$$/fd/$BL_OPT_FD > /tmp/.help
  man /tmp/.help
  rm /tmp/.help
}

# This function parses all the given arguments and return them in an associative array to allow easy handling of large list of available options (has to be
# called after options_insert)
# arg0: The name of an already-declared associative array
# args...: All the parameters that have to be parsed (typically $*)
# returns: 0 if successful, 1 in case of unknown option (stored inside ${arg0[0]})
# Example:
#   declare -A userOptions
#   options_parse userOptions $*
#   for option in "${!userOptions[@]}"; do
#     echo "User entered option $option with args: ${userOptions[$option]}"
#   done
# Note:
#  In case of success, the arg0 associative array will contain all the associations between the option given and the argument attached to it
# (key = option name, value = argument), see the example for more info
function options_parse() {
  local __PARSING_SUCCESS__=1
  if [[ $# -gt 1 ]] && declare -p 2>/dev/null | grep "$1" | grep -qo "\-A"; then
    local -n __OPTION_PARSING_RESULT__=$1
    local currentOption=""
    local char=""
    __PARSING_SUCCESS__=0
    shift
    while [[ $# -gt 0 ]] && [[ $__PARSING_SUCCESS__ == 0 ]]; do
      if [[ "$1" == -* ]] || [[ "$1" == +* ]]; then
        if [[ ${__BL_ARGUMENTS__["$1"]} ]] || [[ ${__BL_ALIASES__["$1"]} ]]; then
          if [[ ${__BL_ALIASES__["$1"]} ]]; then
            currentOption="${__BL_ALIASES__["$1"]}"
          else
            currentOption="$1"
          fi
          __OPTION_PARSING_RESULT__["$currentOption"]=""
        else
          for ((index = 1; index < ${#1}; ++index)); do
            string_charAt "$1" "$index" char
            if [[ "$char" == "-" ]]; then
              __PARSING_SUCCESS__=1
              # shellcheck disable=SC2178
              # The joy of languages that are not strongly typed.. yes I'm using this variable as an array or a string, it's ugly but handy
              __OPTION_PARSING_RESULT__="$1"
              break
            fi
            if [[ ${__BL_ARGUMENTS__["-$char"]} ]]; then
              currentOption="-$char"
              __OPTION_PARSING_RESULT__["$currentOption"]=""
            else
              __PARSING_SUCCESS__=1
              # shellcheck disable=SC2178
              # The joy of languages that are not strongly typed.. yes I'm using this variable as an array or a string, it's ugly but handy
              __OPTION_PARSING_RESULT__="$char"
              break
            fi
          done
        fi
      else
        if [[ "$currentOption" == "" ]]; then
          # shellcheck disable=SC2178
          # The joy of languages that are not strongly typed.. yes I'm using this variable as an array or a string, it's ugly but handy
          __OPTION_PARSING_RESULT__="$1"
          __PARSING_SUCCESS__=1
        else
          if [[ "${__OPTION_PARSING_RESULT__["$currentOption"]}" != "" ]]; then
            __OPTION_PARSING_RESULT__["$currentOption"]="${__OPTION_PARSING_RESULT__["$currentOption"]}:$1"
          else
            __OPTION_PARSING_RESULT__["$currentOption"]="$1"
          fi
        fi
      fi
      shift
    done
  else
    bashlib_abort "$(caller)" "[&result] {\$*}"
  fi
  return $__PARSING_SUCCESS__
}

# This function returns the help message of a specific option
# arg0: The option to look for
# arg1: The name of the variable that will contain the help message
# Example:
#   options_getHelp "-h" result
#   echo "Help message for option -h: $result"
function options_getHelp() {
  if [[ $# -eq 2 ]]; then
    local -n __BL_HELP_OPTION__=$1
    local option="$2"
    if [[ ${__BL_ALIASES__["$option"]} ]]; then
      option="${__BL_ALIASES__["$option"]}"
    fi
    if [[ ${__BL_ARGUMENTS__["$option"]} ]]; then
      __BL_HELP_OPTION__=$(echo "${__BL_ARGUMENTS__["$option"]}" | tr -d '\n' | grep -o "\.RS.*\.RE")
      __BL_HELP_OPTION__=${__BL_HELP_OPTION__:3:$((${#__BL_HELP_OPTION__} - 6))}
    fi
  else
    bashlib_abort "$(caller)" "[&result] [option]"
  fi
}

