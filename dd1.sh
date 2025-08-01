#!/system/bin/sh

# ==============================================================================
# ==        ANDROID EMULATOR IDENTIFIER RANDOMIZATION SCRIPT (v2)           ==
# ==============================================================================
# ==                                                                        ==
# ==   WARNING: THIS SCRIPT MODIFIES CORE SYSTEM FILES. EXECUTE AT YOUR     ==
# ==   OWN RISK. CREATE A SNAPSHOT/BACKUP OF YOUR EMULATOR BEFORE RUNNING.  ==
# ==                                                                        ==
# ==============================================================================

echo "--- Starting Device Identifier Randomization (v2) ---"

# --- Step 1: Generate New Random Values (No Dependencies) ---
echo "[*] Generating new random identifiers using /dev/urandom..."

# Function to generate random hex characters using hexdump (should be on all systems)
gen_hex() {
    hexdump -v -n $1 -e '1/1 "%02x"' /dev/urandom
}

# For device model/brand, we'll pick from a list to look more realistic
BRANDS=("samsung" "google" "oneplus" "xiaomi" "LGE" "motorola")
MODELS=("SM-G998U" "Pixel 6 Pro" "KB2005" "M2101K6G" "LM-V600" "moto g power")
RAND_IDX=$(($(gen_hex 1) % ${#BRANDS[@]})) # Use random byte for index
NEW_BRAND=${BRANDS[$RAND_IDX]}
NEW_MODEL=${MODELS[$RAND_IDX]}
NEW_MANUFACTURER=$NEW_BRAND
NEW_DEVICE="generic_$(gen_hex 4)"
NEW_PRODUCT=$NEW_MODEL

NEW_SERIALNO=$(gen_hex 8)
NEW_ANDROID_ID=$(gen_hex 8)
NEW_MAC_ADDR="00:$(gen_hex 1):$(gen_hex 1):$(gen_hex 1):$(gen_hex 1):$(gen_hex 1)"
NEW_BUILD_ID="RQ3A.$(date +%y%m%d).$(gen_hex 3)"
NEW_BUILD_INCREMENTAL=$(gen_hex 12)
NEW_FINGERPRINT="$NEW_BRAND/$NEW_PRODUCT/$NEW_DEVICE:11/$NEW_BUILD_ID/$NEW_BUILD_INCREMENTAL:user/release-keys"

echo "  > New Brand: $NEW_BRAND"
echo "  > New Model: $NEW_MODEL"
echo "  > New Serial: $NEW_SERIALNO"
echo "  > New Android ID: $NEW_ANDROID_ID"
echo "  > New MAC Address: $NEW_MAC_ADDR"
echo "  > New Fingerprint: $NEW_FINGERPRINT"

# --- Step 2: Gain Root and Modify Files (Modern Android Method) ---

su -c "
    echo '[*] Attempting to gain root and remount partitions...'
    
    # On modern Android, the system partition is mounted at /.
    # First, try to remount the root filesystem.
    mount -o rw,remount /
    
    # Determine the location of build.prop
    if [ -f /system/build.prop ]; then
        BUILD_PROP_PATH='/system/build.prop'
    elif [ -f /build.prop ]; then
        BUILD_PROP_PATH='/build.prop'
    else
        echo '[ERROR] Could not find build.prop file. Aborting.'
        exit 1
    fi

    # Check if remount was successful by trying to write to the file's directory
    if ! touch \${BUILD_PROP_PATH}.tmp 2>/dev/null; then
        echo '[ERROR] Failed to remount system as writeable. Partitions are likely locked.'
        echo '          You might need to disable verified boot (AVB) first by running:'
        echo '          adb disable-verity'
        echo '          adb reboot'
        echo '          Then try this script again.'
        exit 1
    fi
    rm \${BUILD_PROP_PATH}.tmp
    
    echo '[SUCCESS] System partition is writeable.'

    # --- Section A: Modify build.prop ---
    echo '[*] Modifying \${BUILD_PROP_PATH}...'
    
    sed -i \"s/^ro.product.brand=.*/ro.product.brand=$NEW_BRAND/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.product.manufacturer=.*/ro.product.manufacturer=$NEW_MANUFACTURER/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.product.model=.*/ro.product.model=$NEW_MODEL/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.product.name=.*/ro.product.name=$NEW_PRODUCT/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.product.device=.*/ro.product.device=$NEW_DEVICE/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.serialno=.*/ro.serialno=$NEW_SERIALNO/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.boot.serialno=.*/ro.boot.serialno=$NEW_SERIALNO/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.build.id=.*/ro.build.id=$NEW_BUILD_ID/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.build.display.id=.*/ro.build.display.id=$NEW_BUILD_ID release-keys/g\" \$BUILD_PROP_PATH
    sed -i \"s/^ro.build.version.incremental=.*/ro.build.version.incremental=$NEW_BUILD_INCREMENTAL/g\" \$BUILD_PROP_PATH
    sed -i \"s|^ro.build.fingerprint=.*|ro.build.fingerprint=$NEW_FINGERPRINT|g\" \$BUILD_PROP_PATH
    sed -i \"s|^ro.bootimage.build.fingerprint=.*|ro.bootimage.build.fingerprint=$NEW_FINGERPRINT|g\" \$BUILD_PROP_PATH
    sed -i \"s|^ro.build.description=.*|ro.build.description=$NEW_PRODUCT-user 11 $NEW_BUILD_ID $NEW_BUILD_INCREMENTAL release-keys|g\" \$BUILD_PROP_PATH

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
    mount -o ro,remount /
"

echo ""
echo "--- Randomization Complete ---"
echo "A REBOOT IS REQUIRED for build.prop changes to take effect."
echo "You can reboot now by typing: su -c 'reboot'"
