
function xml_getNode() {
  if [[ $# -eq 2 ]]; then
    local -n __XML_NODE__=$2
    __XML_NODE__=$(xmllint --xpath "$1")
  else
    bashlib_abort "$(caller)" "[xpath] [&result]"
  fi
}
