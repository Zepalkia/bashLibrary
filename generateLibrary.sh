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
source lib/options.sh &>/dev/null
source lib/ui.sh &>/dev/null

function __EXIT__() {
  if [[ $1 -ne 0 ]]; then
    echo "Error while generating the library file in function ${FUNCNAME[2]}, the script exited with following result: $2 (errno $1)"
  fi
  lockable_namedUnlock "ABlock"
  exit $1
}

bashlib_declareErrno EXIT_SUCCESS 0 "Success"
bashlib_declareErrno EXIT_FAILURE 1 "Failure"
bashlib_declareErrno EXIT_LOCKED 2 "Process already ongoing"
if lockable_namedTryLock "ABlock" 2; then
  version=0.0.12
  comment=true
  stopOnFailure=false
  testing=false
  functions=$(grep -oE "function [a-z]+_[a-zA-Z]+" lib/* | awk '{print $2}')
  declare -A userOptions
  options_init "Bash library generator" "A small tool to generate a single .sh script containing the full bash library" ""
  options_insert "-h" "Displays this help page" "--help"
  options_insert "--no-comment" "The bashLibrary.sh file will not contain any comment or documentation"
  options_insert "--stop" "The generation of the library file will stop in case of failure during shellcheck validation"
  options_insert "--test" "Unit tests will be run at the end of the generation process"
  options_insert "--release" "Resets the checksum to force the generation of all the components from scratch + implies --stop and --test"
  if [[ $# -gt 0 ]]; then
    if ! options_parse userOptions $*; then
      ui_showMessage err "Unexpected option ${userOptions[0]} found"
      EXIT_FAILURE
    fi
    for option in "${!userOptions[@]}"; do
      case "$option" in
        -h|--help)
          options_display
          EXIT_SUCCESS;;
        --stop) stopOnFailure=true;;
        --test) testing=true;;
        --no-comment) comment=false;;
        --release)
          stopOnFailure=true
          testing=true
          rm -r ".checksums"
          rm -r ".temp"
          ;;
      esac
    done
  fi
  library="bashLibrary.sh"
  compressedLibrary="bashLibrary.small.sh"
  mkdir ".temp" &>/dev/null
  mkdir ".checksums" &>/dev/null
  for file in lib/*; do
    checksum=$(md5sum "$file" | awk '{print $1}')
    checkfile=".checksums/${file//*\//}"
    str="[$file]:"
    string_fixSize str 20
    if [[ -f "$checkfile" ]] && [[ "$(< $checkfile)" == "$checksum" ]]; then
      echo "$str Nothing to do"
      continue
    fi
    rm -f .temp/*${file//*\/}
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
    echo "$str Parsing..."
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
            [[ $scope == false ]] && [[ ${#line} -gt 0 ]] && echo -e "$line" >> ".temp/$temporaryName"
          fi
        fi
      fi
      nLine=$((++nLine))
    done < $file
    sed -i '1i#!/bin/bash' ".temp/$temporaryName"
    echo "$checksum" > ".checksums/${file//*\//}"
    shellcheck ".temp/$temporaryName" &>/dev/null || true
    if [[ $? -ne 0 ]]; then
      if [[ $stopOnFailure == true ]]; then
        string_echoRich "-- Shellcheck *~rfailed~*"
        ls ".temp/"
        shellcheck ".temp/$temporaryName"
        lockable_namedUnlock "ABlock"
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
  done
  cat "$library" | grep -vE "^#.*" | gzip | base64 -w0 > "$compressedLibrary"
  shellcheck "$library" &>/dev/null
  if [[ $? -ne 0 ]]; then
    if [[ $stopOnFailure == true ]]; then
      string_echoRich "-- Shellcheck *~rfailed~*"
      shellcheck "$library"
      lockable_namedLock "ABlock"
      exit 0
    else
      string_echoRich "-- Shellcheck *~yfailed~*"
    fi
  else
    string_echoRich "-- Shellcheck *~gsuccess~*"
  fi
  if [[ $testing == true ]]; then
    cd "tests"
    for file in *; do
      bash "$file"
    done
    cd - &>/dev/null
  fi
  EXIT_SUCCESS
else
  EXIT_LOCKED
fi
