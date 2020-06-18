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
  smart=()
  stopOnFailure=false
  testing=false
  functions=$(grep -oE "function [a-z]+_[a-zA-Z]+" lib/* | awk '{print $2}')
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        string_echoRich "This script will generates the full 'bashLibrary.sh' script, ready to be sourced with all the required and compatible components in a single file.
The following options can be used:
  **--no-comment**
    The bashLibrary.sh file will not contain any comment or documentation
  **--stop**
  Will stop in case of any failure during shellcheck validation
  **--test**
  Will run the unit tests at the end of the process
  **--smart**
  Will generate a subset of the full library containing only required functions and without comments or additional content"
        lockable_globalUnlock
        exit 0;;
      --no-comment)
        comment=false;;
      --stop)
        stopOnFailure=true;;
      --test)
        testing=true;;
      --smart)
        shift
        while [[ $# -gt 0 ]] && [[ $1 != -* ]]; do
          smart+=($1)
          shift
        done
        if [[ ${#smart[@]} -eq 0 ]]; then
          string_echoRich "*~rError:~* --smart option expects files to scan that will use the library"
          exit 0
          lockable_globalUnlock
        fi
        comment=false
        ;;
    esac
    shift
  done
  version=0.0.1
  library="bashLibrary.sh"
  mkdir ".temp"
  for file in lib/*; do
    tokens=()
    header=true
    scope=false
    dependencyCheck=false
    reason=""
    priority=9
    nLine=0
    systemVersion=$(bash --version | grep -oE "version [0-9]+\.[0-9]+" | head -1 | awk '{print $2}')
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
              if ! system_packageInstalled "$token"; then
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
                  if ! system_packageInstalled $token; then
                    scope=true
                    reason="depends on missing library"
                    break
                  fi
                done
              fi
              ;;
            VERSION)
              if [[ "$(bc <<< "${tokens[0]} > $systemVersion")" == "1" ]]; then
                scope=true
                reason="requires bash v${tokens[0]} but system uses $systemVersion"
              fi
              ;;
          esac
        elif [[ $scope == true ]] && [[ $line == function* ]]; then
          funcName=$(echo $line | grep -oE "[a-z]+_[a-zA-Z]+\(\)")
          echo "---- Function [$funcName] $reason --> not included !"
        elif [[ $scope == true ]] && [[ "$line" == "}" ]]; then
          scope=false
        elif [[ $scope == false ]]; then
          # No need to source anything anymore, everything will be put into a single file
          if [[ ! $line =~ ^source ]] || [[ "$file" == "lib/variables.sh" ]]; then
            if [[ $comment == false ]] && [[ $line == \#* ]]; then
              continue;
            fi
            if [[ ${#smart[@]} -gt 0 ]] && [[ $line == function* ]]; then
              funcName=$(echo $line | grep -oE "[a-z]+_[a-zA-Z]+")
              if [[ $(grep "$funcName" ${smart[@]} | wc -l) -eq 0 ]]; then
                scope=true
              fi
            fi
            [[ $scope == false ]] && [[ ${#line} -gt 0 ]] && echo -e "$line" >> ".temp/$temporaryName"
          fi
        fi
      fi
      nLine=$((++nLine))
    done < $file
    sed -i '1i#!/bin/bash' ".temp/$temporaryName"
    shellcheck ".temp/$temporaryName" &>/dev/null || true
    if [[ $? -ne 0 ]]; then
      if [[ $stopOnFailure == true ]]; then
        string_echoRich "-- Shellcheck *~rfailed~*"
        ls ".temp/"
        shellcheck ".temp/$temporaryName"
        rm -r ".temp"
        lockable_globalUnlock
        exit 0
      else
        string_echoRich "-- Shellcheck *~yfailed~*"
      fi
    else
      string_echoRich "-- Shellcheck *~gsuccess~*"
    fi
    sed -i '1d' ".temp/$temporaryName"
  done
  IFS=$oldIFS
  echo "Generating the library file..."
  cat > "$library" << EOF
#!/bin/bash
BASHLIB_VERSION="$version"
EOF
  cat ".temp/9variables.sh" >> "$library"
  for component in .temp/*; do
    [[ ! $component =~ variables ]] && cat "$component" >> "$library"
    rm "$component"
  done
  shellcheck "$library" &>/dev/null
  if [[ $? -ne 0 ]]; then
    if [[ $stopOnFailure == true ]]; then
      string_echoRich "-- Shellcheck *~rfailed~*"
      shellcheck "$library"
      rm -r ".temp"
      lockable_globalUnlock
      exit 0
    else
      string_echoRich "-- Shellcheck *~yfailed~*"
    fi
  else
    string_echoRich "-- Shellcheck *~gsuccess~*"
  fi
  lockable_globalUnlock
  rmdir ".temp"
  if [[ $testing == true ]]; then
    cd "tests"
    for file in *; do
      bash "$file"
    done
    cd - &>/dev/null
  fi
else
  echo "Process already running !"
fi
