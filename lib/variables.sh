#@PRIORITY: 0

# This will force the use of xterm-256 color if present in the system, e.g. when using linux terminal you'll be able to use 256-color instead of 8
if [[ "$TERM" != "xterm-256color" ]]; then
  if [[ -f /lib/terminfo/x/xterm-256color ]] || [[ -f /usr/lib/terminfo/x/xterm-256color ]]; then
    TERM="xterm-256color"
  fi
fi
# This part will setup the available color-variable, either 8 if no more are available or the base 8 (with nicer colors) + few more. You can add or change those
# value based on your preferences/setup, to display how the 256 colors are looking on your computer you can simply run the following command:
# for ((i=0; i < 256; ++i)); do echo -e "$(tput setab $i)$(printf "%03d" $i)$(tput sgr0)"; done
if [[ $(tput colors) == 8 ]]; then
  COLOR_RESET="$(tput setaf 9)$(tput setab 9)"
  COLOR_FG_RED="$(tput setaf 1)"
  COLOR_BG_RED="$(tput setab 1)"
  COLOR_FG_BLINKING_RED="$(tput blink)$COLOR_FG_RED"
  COLOR_FG_GREEN="$(tput setaf 2)"
  COLOR_BG_GREEN="$(tput setab 2)"
  COLOR_FG_YELLOW="$(tput setaf 3)"
  COLOR_BG_YELLOW="$(tput setab 3)"
  COLOR_FG_BLUE="$(tput setaf 4)"
  COLOR_BG_BLUE="$(tput setab 4)"
  COLOR_FG_MAGENTA="$(tput setaf 5)"
  COLOR_BG_MAGENTA="$(tput setab 6)"
  COLOR_FG_CYAN="$(tput setaf 6)"
  COLOR_BG_CYAN="$(tput setab 6)"
  COLOR_FG_WHITE="$(tput setaf 7)"
  COLOR_BG_WHITE="$(tput setab 7)"
elif [[ $(tput colors) == 256 ]]; then
  COLOR_RESET="$(tput sgr0)"
  COLOR_FG_RED="$(tput setaf 9)"
  COLOR_BG_RED="$(tput setab 9)"
  COLOR_FG_BLINKING_RED="$(tput blink)$COLOR_FG_RED"
  COLOR_FG_GREEN="$(tput setaf 10)"
  COLOR_BG_GREEN="$(tput setab 10)"
  COLOR_FG_YELLOW="$(tput setaf 11)"
  COLOR_BG_YELLOW="$(tput setab 11)"
  COLOR_FG_BLUE="$(tput setaf 12)"
  COLOR_BG_BLUE="$(tput setab 12)"
  COLOR_FG_MAGENTA="$(tput setaf 13)"
  COLOR_BG_MAGENTA="$(tput setab 13)"
  COLOR_FG_CYAN="$(tput setaf 14)"
  COLOR_BG_CYAN="$(tput setab 14)"
  COLOR_FG_WHITE="$(tput setaf 15)"
  COLOR_BG_WHITE="$(tput setab 15)"
  COLOR_FG_ORANGE="$(tput setaf 130)"
  COLOR_BG_ORANGE="$(tput setab 130)"
  COLOR_FG_PINK="$(tput setaf 177)"
  COLOR_BG_PINK="$(tput setab 177)"
  COLOR_FG_GRAY="$(tput setaf 240)"
  COLOR_BG_GRAY="$(tput setab 240)"
fi
FONT_RESET=$(tput sgr0)
FONT_BOLD=$(tput bold)
FONT_UNDERLINE=$(tput smul)
FONT_COLOR_REVERSE=$(tput rev)
FONT_BLINK=$(tput blink)
FONT_INVISIBLE=$(tput invis)

function bashlib_abort() {
  local line=$(echo "$1" | awk '{print $1}')
  local component=$(echo "$1" | awk '{print $2}')
  if [[ "$component" != "NULL" ]]; then
    echo -e "[${COLOR_FG_RED}Error${COLOR_RESET}] Bad usage of $2: $3 (called from $component at line $line)"
    exit 1
  else
    echo -e "[${COLOR_FG_RED}Error${COLOR_RESET}] Bad usage of $2: $3 (called by an interactive terminal)"
  fi
}
