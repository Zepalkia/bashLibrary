function xml_Entries() {
  if [[ $# -eq 3 ]]; then
    local -n __XML_ENTRIES__=$3
    # __XML_ENTRIES__=($(echo "$(xmllint --xpath "$1" "$2" 2>/dev/null)" | sed 's/<[^>*>/ /g'))
  else
    false
  fi
}
