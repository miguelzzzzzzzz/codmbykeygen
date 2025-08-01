#!/system/bin/sh

# ==============================================================================
# ==            ANDROID EMULATOR IDENTIFIER RANDOMIZATION SCRIPT            ==
# ==============================================================================
# ==                                                                        ==
# ==   WARNING: THIS SCRIPT MODIFIES CORE SYSTEM FILES. EXECUTE AT YOUR     ==
# ==   OWN RISK. CREATE A SNAPSHOT/BACKUP OF YOUR EMULATOR BEFORE RUNNING.  ==
# ==                                                                        ==
# ==============================================================================

echo "--- Starting Device Identifier Randomization ---"

# --- Step 1: Generate New Random Values ---

echo "[*] Generating new random identifiers..."

# For device model/brand, we'll pick from a list to look more realistic
BRANDS=("samsung" "google" "oneplus" "xiaomi" "LGE" "motorola")
MODELS=("SM-G998U" "Pixel 6 Pro" "KB2005" "M2101K6G" "LM-V600" "moto g power")
RAND_IDX=$((RANDOM % ${#BRANDS[@]}))
NEW_BRAND=${BRANDS[$RAND_IDX]}
NEW_MODEL=${MODELS[$RAND_IDX]}
NEW_MANUFACTURER=$NEW_BRAND
NEW_DEVICE="generic_$(openssl rand -hex 4)"
NEW_PRODUCT=$NEW_MODEL

# Generate a random 8-character hex serial number
NEW_SERIALNO=$(openssl rand -hex 8)

# Generate a random 16-character hex Android ID
NEW_ANDROID_ID=$(openssl rand -hex 8)$(openssl rand -hex 8)

# Generate a new random MAC address (must start with 00 to be locally administered)
NEW_MAC_ADDR="00:$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//')"

# Generate new build numbers
NEW_BUILD_ID="RQ3A.$(date +%y%m%d).$(openssl rand -hex 3)"
NEW_BUILD_INCREMENTAL=$(openssl rand -hex 12)

# Construct a new fingerprint
NEW_FINGERPRINT="$NEW_BRAND/$NEW_PRODUCT/$NEW_DEVICE:11/$NEW_BUILD_ID/$NEW_BUILD_INCREMENTAL:user/release-keys"

echo "  > New Brand: $NEW_BRAND"
echo "  > New Model: $NEW_MODEL"
echo "  > New Serial: $NEW_SERIALNO"
echo "  > New Android ID: $NEW_ANDROID_ID"
echo "  > New MAC Address: $NEW_MAC_ADDR"
echo "  > New Fingerprint: $NEW_FINGERPRINT"

# --- Step 2: Gain Root and Modify Files ---

su -c "
    echo '[*] Attempting to gain root and remount partitions...'
    
    # Remount /system as read-write. This may vary on different Android versions.
    # Try common mount points.
    mount -o rw,remount /system || mount -o rw,remount / || mount -o rw,remount /system_root
    
    if [ ! -w /system/build.prop ]; then
        echo '[ERROR] Failed to remount /system as writeable. Aborting.'
        exit 1
    fi
    
    echo '[SUCCESS] System partition remounted as read-write.'

    # --- Section A: Modify /system/build.prop ---
    echo '[*] Modifying /system/build.prop...'
    
    # Use sed to replace the values. The -i flag edits the file in-place.
    sed -i \"s/^ro.product.brand=.*/ro.product.brand=$NEW_BRAND/g\" /system/build.prop
    sed -i \"s/^ro.product.manufacturer=.*/ro.product.manufacturer=$NEW_MANUFACTURER/g\" /system/build.prop
    sed -i \"s/^ro.product.model=.*/ro.product.model=$NEW_MODEL/g\" /system/build.prop
    sed -i \"s/^ro.product.name=.*/ro.product.name=$NEW_PRODUCT/g\" /system/build.prop
    sed -i \"s/^ro.product.device=.*/ro.product.device=$NEW_DEVICE/g\" /system/build.prop
    sed -i \"s/^ro.serialno=.*/ro.serialno=$NEW_SERIALNO/g\" /system/build.prop
    sed -i \"s/^ro.boot.serialno=.*/ro.boot.serialno=$NEW_SERIALNO/g\" /system/build.prop
    sed -i \"s/^ro.build.id=.*/ro.build.id=$NEW_BUILD_ID/g\" /system/build.prop
    sed -i \"s/^ro.build.display.id=.*/ro.build.display.id=$NEW_BUILD_ID release-keys/g\" /system/build.prop
    sed -i \"s/^ro.build.version.incremental=.*/ro.build.version.incremental=$NEW_BUILD_INCREMENTAL/g\" /system/build.prop
    sed -i \"s|^ro.build.fingerprint=.*|ro.build.fingerprint=$NEW_FINGERPRINT|g\" /system/build.prop
    sed -i \"s|^ro.bootimage.build.fingerprint=.*|ro.bootimage.build.fingerprint=$NEW_FINGERPRINT|g\" /system/build.prop
    sed -i \"s|^ro.build.description=.*|ro.build.description=$NEW_PRODUCT-user 11 $NEW_BUILD_ID $NEW_BUILD_INCREMENTAL release-keys|g\" /system/build.prop

    echo '[SUCCESS] build.prop has been modified.'

    # --- Section B: Change Android ID ---
    echo '[*] Changing Android ID...'
    settings put secure android_id $NEW_ANDROID_ID
    echo '[SUCCESS] Android ID has been set.'

    # --- Section C: Change MAC Address (Temporary) ---
    echo '[*] Changing MAC address for wlan0 (this will reset on reboot)...'
    ip link set wlan0 down
    ip link set wlan0 address $NEW_MAC_ADDR
    ip link set wlan0 up
    echo '[SUCCESS] MAC address has been temporarily changed.'

    # --- Section D: Remount back to Read-Only ---
    echo '[*] Remounting system partition as read-only...'
    mount -o ro,remount /system || mount -o ro,remount / || mount -o ro,remount /system_root
"

echo ""
echo "--- Randomization Complete ---"
echo "A REBOOT IS REQUIRED for build.prop changes to take effect."
echo "You can reboot now by typing: su -c 'reboot'"
