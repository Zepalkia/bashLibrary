 #@DEPENDENCIES: xmllint
source string.sh
source logging.sh

# Note: This function is parsing and loading the full info of an xml file, therefore in large file this can be pretty slow and should be run asynchronously
#   as much as possible (see threads.sh & lockable.sh), in case you just want to retrieve a specific value and not modify the file or load lots of various
#   things it's also recommended to do it directly using xmllint --xpath ... instead to speed up your implementation
#@DEPENDS: xmllint
function xml_load() {
  if [[ $# -eq 2 ]]; then
    local oldIFS=$IFS
    local -n __XML_LOADED_FILE__=$1
    local tokens=()
    local attribute=()
    local token=""
    local path=""
    local tmpPath=""
    local tmpPath2=""
    local count=0
    local initialized=false
    local inComment=false
    unset "$1"
    declare -gA "$1"
    __XML_LOADED_FILE__["FROOT"]="$2"
    nLine=0
    while IFS=\> read -rd \< tag content; do
      string_tokenize "$tag" " " tokens
      #nLine=$((nLine + $(echo "$tag $content" | wc -l) - 1))
      if [[ $inComment == true ]]; then
        string_trim "${tokens[*]} $content" "trailing" content
        # End of multi-line comment, let's start again to analyze the content of the lines
        if [[ "${tokens[0]}" == *-- ]] || [[ "$content" == *--\> ]]; then
          inComment=false
        fi
      elif [[ "${tokens[0]}" == /* ]]; then
        path="${path%.*}"
      elif [[ "${tokens[0]}" == \!* ]]; then
        # We just ignore comments and, in case of multi-line ones, we need to jump over the next lines as well
        if [[ "${tokens[0]}" != *-- ]]; then
          inComment=true
        fi
      elif [[ "${tokens[0]}" == \?* ]] || [[ "${tokens[0]}" == "" ]]; then
        true # That's a DTD / an empty line, we don't care about it
      else
        if [[ "$path" != "" ]]; then
          path="$path.${tokens[0]}"
        elif [[ $initialized == false ]]; then
          path="${tokens[0]}"
          initialized=true
        else
          # If the path is now empty, we probably have a bad xml file or we failed to parse it properly
          bashlib_abort "$(caller)" "Critical failure in parsing the xml file $2"
        fi
        tmpPath="$path"
        count=0
        until [[ ! ${__XML_LOADED_FILE__["$tmpPath"]} ]]; do
          tmpPath="$path$count"
          count=$((++count))
        done
        __XML_LOADED_FILE__["$tmpPath"]="$content"
        for ((i = 1; i < ${#tokens[@]}; ++i)); do
          token="${tokens[$i]}"
          string_tokenize "$token" "=" attribute
          tmpPath2="$tmpPath@${attribute[0]}"
          count=0
          until [[ ! ${__XML_LOADED_FILE__["$tmpPath2"]} ]]; do
            tmpPath2="$tmpPath@${attribute[0]}$count"
            count=$((++count))
          done
          __XML_LOADED_FILE__["$tmpPath2"]="${attribute[1]}"
        done
        # Single-line value (<tag/>) doesn't add a new path
        if [[ "$tag" == */ ]]; then
          path="${path%.*}"
        fi
      fi
    done < <(cat "$2")
    if [[ "${path//[!\.]/}" != "" ]]; then
      # If the path is not empty, we probably have a bad xml file or we failed to parse it properly
      bashlib_abort "$(caller)" "Critical failure in parsing the xml file $2"
    fi
    IFS=$oldIFS
  else
    bashlib_abort "$(caller)" "[&XML object] [path to xml file]"
  fi
}

function xml_getSingleValue() {
  if [[ $# -eq 3 ]]; then
    local -n __XML_OBJECT__="$1"
    local -n __SINGLE_VALUE__="$3"
    __SINGLE_VALUE__="${__XML_OBJECT__["$2"]}"
  else
    bashlib_abort "$(caller)" "[XML object] [path to element/attribute] [&result]"
  fi
}

function xml_setSingleValue() {
  local __VALUE_SET_SUCCESS__=1
  if [[ $# -eq 3 ]]; then
    local -n __XML_OBJECT__="$1"
    if [[ ${__XML_OBJECT__["$2"]} ]]; then
      __XML_OBJECT__["$2"]="$3"
      __VALUE_SET_SUCCESS__=0

    fi
  else
    bashlib_abort "$(caller)" "[XML object] [path to element/attribute] [new value]"
  fi
  return $__VALUE_SET_SUCCESS__
}
