source string.sh
source logging.sh
# Still in validation, the xml_* functions are offering easy to use pure-bash ways of loading, grabbing and modifying info as well as writing to the disk
# Not a single xml library is required in order to use these functions
# regular XML files.
# Examples based on the following xml:
#   <xml>
#     <values>
#       <value1>10</value1>
#       <value2 priority="1">20</value2>
#     </values>
#   </xml>
#
# The path to values is starting from the root and jump with '.' character, e.g.:
#   xml_getSingleValue xmlFile "xml.values.value1" value
#
# To retrieve an attribute value it's using the '@' character, e.g.:
#   xml_getSingleValue xmlFile "xml.values.value2@priority" value
#

function xml_create() {
  if [[ $# -eq 3 ]]; then
    local -n __XML_LOADED_FILE__=$1
    unset "$1"
    declare -gA "$1"
    rm -f "$2"
    __XML_LOADED_FILE__["FROOT"]="$2"
    __XML_LOADED_FILE__["XROOT"]="$3"
    __XML_LOADED_FILE__["$3"]=""
  else
    bashlib_abort "$(caller)" "[&XML object] [file path] [xml root]"
  fi
}

function xml_load() {
  if [[ $# -eq 2 ]] && [[ -f "$2" ]]; then
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
          __XML_LOADED_FILE__["XROOT"]="$path"
          initialized=true
        else
          # If the path is now empty, we probably have a bad xml file or we failed to parse it properly
          bashlib_abort "$(caller)" "Critical failure in parsing the xml file $2"
        fi
        if [[ "${path: -1}" == "/" ]]; then
          path=${path::-1}
        fi
        if [[ "${content: -1}" == "/" ]]; then
          content=${content::-1}
        fi
        tmpPath="$path"
        count=0
        until [[ ! ${__XML_LOADED_FILE__["$tmpPath"]} ]]; do
          tmpPath="$path<$count>"
          count=$((++count))
        done
        __XML_LOADED_FILE__["$tmpPath"]="$content"
        for ((i = 1; i < ${#tokens[@]}; ++i)); do
          token="${tokens[$i]}"
          string_tokenize "$token" "=" attribute
          tmpPath2="$tmpPath@${attribute[0]}"
          count=0
          until [[ ! ${__XML_LOADED_FILE__["$tmpPath2"]} ]]; do
            tmpPath2="$tmpPath@${attribute[0]}<$count>"
            count=$((++count))
            if [[ "${tmpPath2: -1}" == "/" ]]; then
              tmpPath2=${tmpPath2::-1}
            fi
          done
          if [[ "${attribute[1]}" != "" ]] && [[ "${attribute[1]}" != "/" ]]; then
            if [[ "${attribute[1]: -1}" == "/" ]]; then
              __XML_LOADED_FILE__["$tmpPath2"]="${attribute[1]::-1}"
            else
              __XML_LOADED_FILE__["$tmpPath2"]="${attribute[1]}"
            fi
          fi
        done
        path="$tmpPath"
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
    bashlib_abort "$(caller)" "[&XML object] [path to existing xml file]"
  fi
}

function xml_getSingleValue() {
  local __VALUE_FOUND__=1
  if [[ $# -eq 3 ]]; then
    local -n __XML_OBJECT__="$1"
    local -n __SINGLE_VALUE__="$3"
    if [[ "$2" =~ "@" ]]; then
      __SINGLE_VALUE__=$(echo "${__XML_OBJECT__["$2"]}" | grep -o \"".*\"" | tr -d \")
    else
      __SINGLE_VALUE__="${__XML_OBJECT__["$2"]}"
    fi
    if [[ "$__SINGLE_VALUE__" != "" ]] && [[ $(echo "$__SINGLE_VALUE__" | wc -l) -eq 1 ]]; then
      __VALUE_FOUND__=0
    fi
  else
    bashlib_abort "$(caller)" "[&XML object] [path to element/attribute] [&result]"
  fi
  return $__VALUE_FOUND__
}

function xml_setSingleValue() {
  local __VALUE_SET_SUCCESS__=1
  if [[ $# -eq 3 ]]; then
    local -n __XML_OBJECT__="$1"
    if [[ ${__XML_OBJECT__["$2"]} ]]; then
      if [[ "$2" =~ "@" ]]; then
        __XML_OBJECT__["$2"]="\"$3\""
      else
        __XML_OBJECT__["$2"]="$3"
      fi
      __VALUE_SET_SUCCESS__=0
    fi
  else
    bashlib_abort "$(caller)" "[&XML object] [path to element/attribute] [new value]"
  fi
  return $__VALUE_SET_SUCCESS__
}

function xml_addNode() {
  local __NODE_ADD_SUCCESS__=0
  if [[ $# -ge 3 ]]; then
    local -n __XML_OBJECT__="$1"
    local attribute=""
    local tokens=()
    if [[ $# -eq 4 ]]; then
      local -n __ATTRIBUTES__="$4"
    else
      local __ATTRIBUTES__=()
    fi
    __XML_OBJECT__["$2"]="$3"
    for attribute in "${__ATTRIBUTES__[@]}"; do
      string_tokenize "$attribute" "=" tokens
      if [[ ${#tokens[@]} -eq 2 ]]; then
        local count=-1
        # If the path already exists, we append an incrementing value to the value name until we fouond a unique new one
        if [[ ${__XML_OBJECT__["$2@${tokens[0]}"]} ]]; then
          count=0
          while [[ ${__XML_OBJECT__["$2@${tokens[0]}<$count>"]} ]]; do
            count=$((++count))
          done
        fi
        if [[ $count -eq -1 ]]; then
        __XML_OBJECT__["$2@${tokens[0]}"]="\"${tokens[1]}\""
        else
        __XML_OBJECT__["$2@${tokens[0]}<$count>"]="\"${tokens[1]}\""
        fi
      else
        __NODE_ADD_SUCCESS__=1
      fi
    done
  else
    bashlib_abort "$(caller)" "[&XML object] [path to new node] [value (can be empty)] {&attributes}"
  fi
  return $__NODE_ADD_SUCCESS__
}

function xml_dump() {
  if [[ $# -ge 1 ]]; then
    local -n __XML_FILE_CONTENT__="$1"
    local filePath="${__XML_FILE_CONTENT__["FROOT"]}"
    local root="${__XML_FILE_CONTENT__["XROOT"]}"
    local path="$root" printedPath="" lastPath=""
    local tag="" value="" attribute="" attributeValue="" tmp=""
    local attributes=()
    if [[ $# -eq 2 ]]; then
      filePath="$2"
    fi
    rm -f "$filePath"
    unset "$1[FROOT]" "$1[XROOT]"
    while [[ ${#__XML_FILE_CONTENT__[@]} -gt 0 ]]; do
      if [[ "$lastPath" == "$root" ]] && [[ "${path##*.}" == "$root" ]]; then
        bashlib_abort "$(caller)" "Critical issue when dumping the xml, we have leftovers value we didn't manage to dump: ${!__XML_FILE_CONTENT__[@]} -- ${__XML_FILE_CONTENT__[@]} -- $path"
      fi
      tag=${path##*.}
      cleanTag=tag=${tag//<*>/}
      lastPath="$tag"
      if xml_getSingleValue "$1" "$path" value; then
        attributes=($(echo "${!__XML_FILE_CONTENT__[@]}" | grep -oE "$path@[a-zA-Z0-9]*"))
        for attribute in "${attributes[@]}"; do
          attribute=$(echo "$attribute" | tr -d " ")
          xml_getSingleValue "$1" "$attribute" attributeValue
          tag="$tag ${attribute#*@}=\"$attributeValue\""
          unset "$1["$attribute"]"
        done
        echo "<${tag//<*>/}>$value</${lastPath//<*>/}>" >> "$filePath"
        unset "$1["$path"]"
        path="${path%.*}"
      else
        tag="<${tag//<*>}"
        attributes=($(echo "${!__XML_FILE_CONTENT__[@]}" | grep -oE "$path@[a-zA-Z0-9]*"))
        for attribute in "${attributes[@]}"; do
          attribute=$(echo "$attribute" | tr -d " ")
          xml_getSingleValue "$1" "$attribute" attributeValue
          tag="$tag ${attribute#*@}=\"$attributeValue\""
          unset "$1["$attribute"]"
        done
        tmp="$(echo "${!__XML_FILE_CONTENT__[@]} " | grep -oE "$path\.[a-zA-Z0-9<>]*\s" | head -1)"
        if [[ ${#tmp} -gt 0 ]]; then
          tmp="${tmp::-1}"
        fi
        if [[ "$tmp" == "" ]]; then
          # In case no attribute is present
          if [[ ${#attributes[@]} -eq 0 ]]; then
            cleanTag="${tag:1}"
            cleanTag="${cleanTag//<*>/}"
            # If only unique node
            if [[ "$(echo "$printedPath" | grep -o "$path")" == "" ]]; then
              printedPath="$printedPath#$path"
              echo "<$cleanTag />" >> "$filePath"
            else
            # If it's a closing node
              echo "</${tag:1}>" >> "$filePath"
            fi
          else
            echo "$tag />" >> "$filePath"
          fi
          unset "$1["$path"]"
          path="${path%.*}"
        else
          if [[ "$(echo "$printedPath" | grep -o "$path")" == "" ]]; then
            echo "$tag>" >> $filePath
            printedPath="$printedPath#$path"
          fi
          path="$tmp"
        fi
      fi
    done
  else

    bashlib_abort "$(caller)" "[&XML object] {new path for file}"
  fi
}
