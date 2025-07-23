#!/system/bin/sh

# ###############################################################################
# #                                                                             #
# #            >> ANIMATED CODM DATA & LOG PURGE UTILITY V4.0 <<                 #
# #                                                                             #
# # ---DISCLAIMER------------------------------------------------------------- #
# # This script PERMANENTLY DELETES application files and directories. This is  #
# # a destructive action. USE AT YOUR OWN RISK.                                 #
# ###############################################################################


# --- Setup & Functions ---
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); RESET=$(tput sgr0); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4); RED=$(tput setaf 1); CYAN=$(tput setaf 6)
else
  BOLD=""; RESET=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; CYAN=""
fi

# Spinner animation to show a "working" state
spinner() {
  local pid=$1
  local spinstr='|/-\\'
  while ps -p $pid > /dev/null; do
    local temp=${spinstr#?}
    printf " [%c] " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
    printf "\b\b\b\b\b"
  done
}

# Function that shows the spinner for 1 second while deleting the path
purge_with_animation() {
  local message=$1
  local path=$2
  echo -n "${CYAN}[*] Purging ${message}... ${RESET}"
  # Run the deletion and a 1-second sleep in the background
  # The sleep ensures the process lasts long enough for the animation
  (rm -rf "${path}"; sleep 1) &
  local pid=$!
  # Show the spinner while the background process is running
  spinner $pid
  echo "${GREEN}[DONE]${RESET}"
}


# --- Main Execution ---
clear
echo "${BLUE}${BOLD}"; cat << "BANNER"
    ____   ____  __  ____  __  __
   / __ \ / __ \/ / / / / / / /  \
  / / / // / / / / / / / / / /\ \
 / /_/ // /_/ / /_/ / /_/ / / /  \ \
/_____/ \____/\____/\____/_/_/    \_\
CODM ANIMATED DATA PURGE
BANNER
echo "${RESET}"

echo "\n${RED}${BOLD}!!!--- WARNING: DESTRUCTIVE OPERATION INITIATED ---!!!${RESET}"
echo "${YELLOW}The following actions are permanent and cannot be undone.${RESET}"
echo "${GREEN}Executing purge sequence now...${RESET}"

echo "\n${YELLOW}--- STAGE 1: Purging Internal App Data ---${RESET}"
purge_with_animation "Bugly Logs" "/data/data/com.garena.game.codm/app_bugly"
purge_with_animation "Crash Records" "/data/data/com.garena.game.codm/app_crashrecord"
purge_with_animation "CrashSight Data" "/data/data/com.garena.game.codm/app_crashSight"
purge_with_animation "Texture Cache" "/data/data/com.garena.game.codm/app_textures"
purge_with_animation "WebView Cache" "/data/data/com.garena.game.codm/app_webview"
purge_with_animation "Main Cache" "/data/data/com.garena.game.codm/cache"
purge_with_animation "Code Cache" "/data/data/com.garena.game.codm/code_cache"
purge_with_animation "Databases" "/data/data/com.garena.game.codm/databases"
purge_with_animation "Non-Backup Data" "/data/data/com.garena.game.codm/no_backup"
purge_with_animation "Internal Files" "/data/data/com.garena.game.codm/files"

echo "\n${YELLOW}--- STAGE 2: Purging Shared Storage Data ---${RESET}"
purge_with_animation "Android Data Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/cache"
purge_with_animation "Chat Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/ChatCache"
purge_with_animation "Apollo SDK Files" "/storage/emulated/0/Android/data/com.garena.game.codm/files/Apollo/*"
purge_with_animation "TGPA Logs" "/storage/emulated/0/Android/data/com.garena.game.codm/files/TGPA"
purge_with_animation "Voice Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/VoiceCache"
purge_with_animation "Tencent Midas Logs" "/storage/emulated/0/tencent/Midas/Log/com.garena.game.codm"

echo "\n${YELLOW}--- STAGE 3: Finalizing User Data Purge ---${RESET}"
purge_with_animation "User 0 Files" "/data/user/0/com.garena.game.codm/files"
purge_with_animation "Shared Preferences" "/data/user/0/com.garena.game.codm/shared_prefs"

echo "\n${GREEN}${BOLD}====================================="
echo "    CODM DATA PURGE COMPLETE"
echo "=====================================${RESET}"
echo "${YELLOW}All specified cache and log files have been deleted.${RESET}"
exit 0
