 #@DEPENDENCIES: xmllint
source string.sh
source logging.sh

# Note: This function is parsing and loading the full info of an xml file, therefore in large file this can be pretty slow and should be run asynchronously
#   as much as possible (see threads.sh & lockable.sh), in case you just want to retrieve a specific value and not modify the file or load lots of various
#   things it's also recommended to do it directly using xmllint --xpath ... instead to speed up your implementation
#@DEPENDS: xmllint
function xml_load() {
  logging_startTrace
  if [[ $# -eq 2 ]]; then
    local -n __XML_LOADED_FILE__="$1"
    local oldIFS=$IFS
    local comment=false
    local parents=()
    local node=""
    local args=""
    local argsV=""
    local value=""
    local values=""
    local xpath=""
    local i=0
    local tokens=()
    declare -gA "$1"
    while IFS= read -r line; do
      line=$(echo -e "$line" | sed -e 's/^[[:space:]]*//')
      # string_trim "$line" "leading" line
      if [[ $comment == true ]] && [[ "$line" =~ --\>$ ]]; then
        comment=false
      elif [[ $comment == false ]]; then
        if [[ "$line" =~ ^\<\? ]]; then
          true
        elif [[ "$line" =~ ^\<!-- ]]; then
          if [[ ! "$line" =~ --\> ]]; then
            comment=true
          fi
        elif [[ "$line" =~ ^\</ ]]; then
          unset "parents[$((${#parents[@]} - 1))]"
        else
          #echo "$line"
          values=""
          if [[ "$line" =~ = ]]; then
            args=$(echo "$line" | grep -oE "[^ ]*=\".*\"")
            values="@${args//\" /@}"
          fi
          node=$(echo "$line" | grep -oE "<[^ />]*\>")
          node="${node//</}"
          value=$(echo "$line" | grep -oE ">.*<")
          value=${value:1:$((${#value} - 2))}
          xpath="${parents[*]} $node"
          if [[ "$value" == "" ]] && [[ ! "$line" =~ /\>$ ]]; then
            parents+=("$node")
          fi
          xpath="${xpath// /.}"
          oPath="$xpath"
          if [[ ! ${__XML_LOADED_FILE__["$oPath"]} ]]; then
            i=0
          else
            while [[ ${__XML_LOADED_FILE__["$oPath"]} ]]; do
              oPath="$xpath$i"
              i=$((++i))
            done
          fi
          __XML_LOADED_FILE__["$oPath"]="$value$values"
          #echo "-- Node [$node] with value [$value] and args [$values]"
          #echo "-- XPATH: $oPath -> ${__XML_LOADED_FILE__["$xpath"]}"
        fi
      fi
    done < <(xmllint --format "$2")
    IFS=$oldIFS
  else
    bashlib_abort "$(caller)" "[&xml] [path to xml]"
  fi
  logging_stopTrace
}

