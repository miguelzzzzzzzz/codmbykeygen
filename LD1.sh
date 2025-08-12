#!/system/bin/sh

# ==============================================================================
#  Android System Modification Script
#  WARNING: This script performs major system changes.
#  Execute with root privileges only. Use at your own risk.
# ==============================================================================

# --- Function for printing messages ---
log_message() {
    echo "[INFO] $1"
}

# --- Check for Root Access ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run as root. Aborting."
    exit 1
fi

log_message "Root access confirmed."
log_message "Starting system modifications..."
sleep 1

log_message "Resetting Android ID..."
content insert --uri content://settings/secure --bind name:s:android_id --bind value:s:
sleep 1

# WARNING: Setting permissions to 000 makes files/directories inaccessible.
log_message "Applying restrictive file permissions..."
chmod -R 750 /fstab.vbox86
chmod -R 000 /default.prop
chmod -R 000 /init.superuser.rc
chmod -R 000 /system/priv-app/
chmod -R 000 /system/priv-app/Settings.apk
chmod -R 000 /system/priv-app/Superuser.apk
chmod 000 /proc/cpuinfo
chmod 000 /proc/meminfo
chmod 000 /system/build.prop
chmod 000 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq
chmod 000 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
chmod 000 /sys/class/power_supply/battery/capacity
chmod 500 /proc

log_message "Setting specific permissions for libhardware.so..."
chmod -R 644 /system/lib/libhardware.so


log_message "Setting new custom Android ID..."
settings put secure android_id a33c87a12fa2934c218792191202828748

log_message "Renaming critical system files to hide them..."
mv /system/lib/libhoudini.so /system/lib/libhoudini.txt
mv /system/lib/libldutils.so /system/lib/libldutils.txt
mv /system/lib/libdvm.so /system/lib/libdvm.txt
mv /system/lib/libhardware.so /system/lib/libhardware.txt
mv /system/lib/libhardware_legacy.so /system/lib/libhardware_legacy.txt
mv /system/lib/libreference-ril.so /system/lib/libreference-ril.txt
mv /system/lib/libhoudini_415c.so /system/lib/libhoudini_415c.txt
mv /system/lib/libhoudini_408p.so /system/lib/libhoudini_408p.txt
mv /system/lib/libz.so /system/lib/libz.txt
mv /system/lib/libdrm.so /system/lib/libdrm.txt
mv /system/build.prop /system/build.txt
mv /init.vbox86.rc /init.vbox86.txt
mv /init.titan.rc /init.titan.txt

log_message "Renaming other system components..."
mv /dev/virtpipe-sec /dev/virtpipe-fuk
mv /data/data/com.tencent.tinput /data/data/com.tencent.tinpux

log_message "Clearing logcat..."
logcat -c


log_message "Script finished. All operations complete."
echo "=============================================================================="

exit 0
