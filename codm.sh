#!/system/bin/sh

# ###############################################################################
# #                                                                             #
# #             >> ADVANCED CODM DATA & LOG PURGE UTILITY V2.1 <<                #
# #                                                                             #
# # ---DISCLAIMER------------------------------------------------------------- #
# # This script PERMANENTLY DELETES application files and directories. This is  #
# # a destructive action that can lead to loss of game settings and data.       #
# # Use this utility at your own risk. The author is not responsible for any    #
# # data loss or account-related consequences.                                  #
# ###############################################################################


# --- Setup & Functions ---
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); RESET=$(tput sgr0); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4); RED=$(tput setaf 1); CYAN=$(tput setaf 6)
else
  BOLD=""; RESET=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; CYAN=""
fi
spinner() {
  pid=$1; spinstr='|/-\'
  while [ "$(ps -p $pid)" ]; do
    temp=${spinstr#?}; printf " [%c] " "$spinstr"; spinstr=$temp${spinstr%"$temp"}
    sleep 0.1; printf "\b\b\b\b\b"
  done
}
# This function simulates work and then executes a real command
purge_path() {
  local message=$1
  local path=$2
  echo -n "${CYAN}[*] Purging ${message}...${RESET}"
  # Simulate work before deletion
  (sleep 2) &
  spinner $!
  # Execute the actual deletion
  rm -rf "${path}"
  echo "${GREEN}[DONE]${RESET}"
}


# --- Main Execution ---
clear
echo "${BLUE}${BOLD}"; cat << "BANNER"
    ____   ____  __  ____  __  __
   / __ \ / __ \/ / / / / / / /  \
  / / / // / / / / / / / / / / /\ \
 / /_/ // /_/ / /_/ / /_/ / / /  \ \
/_____/ \____/\____/\____/_/_/    \_\
CODM ADVANCED DATA PURGE
BANNER
echo "${RESET}"
sleep 2

echo "\n${RED}${BOLD}!!!--- WARNING: DESTRUCTIVE OPERATION ---!!!${RESET}"
echo "${YELLOW}This script will permanently delete CODM cache, logs, and data."
echo "This can result in the loss of settings and game progress."
echo "The operation will begin automatically in 5 seconds."
echo "Press CTRL+C NOW to abort.${RESET}"
sleep 5
echo "\n${GREEN}Starting operation...${RESET}"
sleep 1

echo "\n${YELLOW}--- STAGE 1: Purging Internal App Data ---${RESET}"
purge_path "Bugly Logs" "/data/data/com.garena.game.codm/app_bugly"
purge_path "Crash Records" "/data/data/com.garena.game.codm/app_crashrecord"
purge_path "CrashSight Data" "/data/data/com.garena.game.codm/app_crashSight"
purge_path "Texture Cache" "/data/data/com.garena.game.codm/app_textures"
purge_path "WebView Cache" "/data/data/com.garena.game.codm/app_webview"
purge_path "Main Cache" "/data/data/com.garena.game.codm/cache"
purge_path "Code Cache" "/data/data/com.garena.game.codm/code_cache"
purge_path "Databases" "/data/data/com.garena.game.codm/databases"
purge_path "Non-Backup Data" "/data/data/com.garena.game.codm/no_backup"
purge_path "Internal Files" "/data/data/com.garena.game.codm/files"
sleep 1

echo "\n${YELLOW}--- STAGE 2: Purging Shared Storage Data ---${RESET}"
purge_path "Android Data Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/cache"
purge_path "Chat Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/ChatCache"
purge_path "Apollo SDK Files" "/storage/emulated/0/Android/data/com.garena.game.codm/files/Apollo/*"
purge_path "TGPA Logs" "/storage/emulated/0/Android/data/com.garena.game.codm/files/TGPA"
purge_path "Voice Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/VoiceCache"
purge_path "Tencent Midas Logs" "/storage/emulated/0/tencent/Midas/Log/com.garena.game.codm"
sleep 1

echo "\n${YELLOW}--- STAGE 3: Finalizing User Data Purge ---${RESET}"
purge_path "User 0 Files" "/data/user/0/com.garena.game.codm/files"
purge_path "Shared Preferences" "/data/user/0/com.garena.game.codm/shared_prefs"
sleep 2

echo "\n${GREEN}${BOLD}====================================="
echo "    CODM DATA PURGE COMPLETE"
echo "=====================================${RESET}"
echo "${YELLOW}All specified cache and log files have been deleted.${RESET}"
exit 0
