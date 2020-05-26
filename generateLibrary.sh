#!/bin/bash
# This script is generating a full 'bashLibrary{version number}.sh script containing all the components that are compatible with the system in which
# it's generated (e.g. if this script is run on a computer without 'inotify-tools' package the final library will not contain the functions that marked
# this package as a dependency)
source lib/variables.sh
source lib/math.sh
source lib/string.sh &>/dev/null
source lib/utilities.sh
source lib/system.sh
source lib/lockable.sh
source lib/ui.sh &>/dev/null
if lockable_globalTryLock 2; then
  comment=true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo -e "This script will generates the full 'bashLibrary.sh' script, ready to be sourced with all the required and compatible components in a single file.
The following options can be used:
  ${COLOR_FG_WHITE}${FONT_BOLD}--no-comment${FONT_RESET}
    The bashLibrary.sh file will not contain any comment or documentation"
        lockable_globalUnlock
        exit 0;;
      --no-comment)
        comment=false;;
    esac
    shift
  done
  version=0.0.1
  library="bashLibrary${version}.sh"
  mkdir ".temp"
  for file in lib/*; do
    tokens=()
    header=true
    scope=false
    dependencyCheck=false
    priority=9
    nLine=0
    oldIFS=$IFS
    IFS=''
    temporaryName="$priority$(basename $file)"
    echo "Parsing component [$file]..."
    while read -r line; do
      if [[ $line != \#* ]]; then
        header=false
      fi
      if [[ $header == true ]] && [[ $line == \#@* ]]; then
        macro=$(echo $line | grep -oE "#@[A-Z]+")
        line=${line//$macro:/}
        line=$(echo $line | tr -d ' ')
        macro=${macro//\#@}
        string_tokenize $line "," tokens
        case "$macro" in
          PRIORITY)
            echo "-- Component priority: [${tokens[0]}]"
            priority="${tokens[0]}"
            temporaryName="$priority$(basename $file)"
            ;;
          DEPENDENCIES)
            for token in ${tokens[@]}; do
              system_packageInstalled "$token" result
              if [[ $result == false ]]; then
                dependencyCheck=true
                echo "-- Package [$token] missing"
              fi
            done;;
        esac
      elif [[ $header == false ]]; then
        if [[ $line == \#@* ]]; then
          macro=$(echo $line | grep -oE "#@[A-Z]+")
          line=${line//$macro:/}
          line=$(echo $line | tr -d ' ')
          macro=${macro//\#@}
          string_tokenize $line "," tokens
          case "$macro" in
            DEPENDS)
              if [[ $dependencyCheck == true ]]; then
                for token in ${tokens[@]}; do
                  system_packageInstalled $token result
                  if [[ $result == false ]]; then
                    scope=true
                    break
                  fi
                done
              fi
              ;;
          esac
        elif [[ $scope == true ]] && [[ $line == function* ]]; then
          funcName=$(echo $line | grep -oE "[a-z]+_[a-zA-Z]+\(\)")
          echo "---- Function [$funcName] depends on missing library --> not included !"
        elif [[ $scope == true ]] && [[ "$line" == "}" ]]; then
          scope=false
        elif [[ $scope == false ]]; then
          # No need to source anything anymore, everything will be put into a single file
          if [[ ! $line =~ source ]]; then
            if [[ $comment == false ]] && [[ $line == \#* ]]; then
              continue;
            fi
            echo -e "$line" >> ".temp/$temporaryName"
          fi
        fi
      fi
      nLine=$((++nLine))
    done < $file
  done
  IFS=$oldIFS
  echo "Generating the library file..."
  cat > "$library" << EOF
#!/bin/bash
BASHLIB_VERSION="$version"
EOF
  for component in .temp/*; do
    cat "$component" >> "$library"
    rm "$component"
  done
  lockable_globalUnlock
  rmdir ".temp"
else
  echo "Process already running !"
fi
