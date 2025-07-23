#!/system/bin/sh

# ###############################################################################
# #                                                                             #
# #          >> CONTROLLED-PACE CODM DATA & LOG PURGE UTILITY V3.1 <<           #
# #                                                                             #
# # ---DISCLAIMER------------------------------------------------------------- #
# # This script PERMANENTLY DELETES application files and directories. This is  #
# # a destructive action that can lead to loss of game settings and data.       #
# # USE AT YOUR OWN RISK.                                                       #
# ###############################################################################


# --- Setup & Functions ---
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); RESET=$(tput sgr0); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4); RED=$(tput setaf 1); CYAN=$(tput setaf 6)
else
  BOLD=""; RESET=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; CYAN=""
fi

# Function with a 1-second delay per path
purge_path_with_delay() {
  local message=$1
  local path=$2
  echo -n "${CYAN}[*] Purging ${message}... ${RESET}"
  # Execute the actual deletion immediately
  rm -rf "${path}"
  echo "${GREEN}[DONE]${RESET}"
  # Wait for 1 second before proceeding
  sleep 1
}


# --- Main Execution ---
clear
echo "${BLUE}${BOLD}"; cat << "BANNER"
    ____   ____  __  ____  __  __
   / __ \ / __ \/ / / / / / / /  \
  / / / // / / / / / / / / / /\ \
 / /_/ // /_/ / /_/ / /_/ / / /  \ \
/_____/ \____/\____/\____/_/_/    \_\
CODM CONTROLLED-PACE DATA PURGE
BANNER
echo "${RESET}"

echo "\n${RED}${BOLD}!!!--- WARNING: DESTRUCTIVE OPERATION INITIATED ---!!!${RESET}"
echo "${YELLOW}The following actions are permanent and cannot be undone.${RESET}"
echo "${GREEN}Executing purge sequence now...${RESET}"

echo "\n${YELLOW}--- STAGE 1: Purging Internal App Data ---${RESET}"
purge_path_with_delay "Bugly Logs" "/data/data/com.garena.game.codm/app_bugly"
purge_path_with_delay "Crash Records" "/data/data/com.garena.game.codm/app_crashrecord"
purge_path_with_delay "CrashSight Data" "/data/data/com.garena.game.codm/app_crashSight"
purge_path_with_delay "Texture Cache" "/data/data/com.garena.game.codm/app_textures"
purge_path_with_delay "WebView Cache" "/data/data/com.garena.game.codm/app_webview"
purge_path_with_delay "Main Cache" "/data/data/com.garena.game.codm/cache"
purge_path_with_delay "Code Cache" "/data/data/com.garena.game.codm/code_cache"
purge_path_with_delay "Databases" "/data/data/com.garena.game.codm/databases"
purge_path_with_delay "Non-Backup Data" "/data/data/com.garena.game.codm/no_backup"
purge_path_with_delay "Internal Files" "/data/data/com.garena.game.codm/files"

echo "\n${YELLOW}--- STAGE 2: Purging Shared Storage Data ---${RESET}"
purge_path_with_delay "Android Data Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/cache"
purge_path_with_delay "Chat Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/ChatCache"
purge_path_with_delay "Apollo SDK Files" "/storage/emulated/0/Android/data/com.garena.game.codm/files/Apollo/*"
purge_path_with_delay "TGPA Logs" "/storage/emulated/0/Android/data/com.garena.game.codm/files/TGPA"
purge_path_with_delay "Voice Cache" "/storage/emulated/0/Android/data/com.garena.game.codm/files/VoiceCache"
purge_path_with_delay "Tencent Midas Logs" "/storage/emulated/0/tencent/Midas/Log/com.garena.game.codm"

echo "\n${YELLOW}--- STAGE 3: Finalizing User Data Purge ---${RESET}"
purge_path_with_delay "User 0 Files" "/data/user/0/com.garena.game.codm/files"
purge_path_with_delay "Shared Preferences" "/data/user/0/com.garena.game.codm/shared_prefs"

echo "\n${GREEN}${BOLD}====================================="
echo "    CODM DATA PURGE COMPLETE"
echo "=====================================${RESET}"
echo "${YELLOW}All specified cache and log files have been deleted.${RESET}"
exit 0
