import os
import re
import json
import shutil
import subprocess
import zipfile
import requests
from datetime import datetime
import sys

# =============== Config ===============
# Toggles
iShutdown = 0
doNuitka = 0
doVmp = 1
doDiscord = 1          # send announcement message (no file upload) for Matter/Void
doGit = 1              # commit & push for Matter/Void

# Paths
PROJECT_ROOT = r"C:\Users\A\Documents\BloodyLuciCODM"
CODM_REPO = os.path.join(PROJECT_ROOT, "codmbykeygen")
LOADERS_DIR = os.path.join(CODM_REPO, "Loaders")
MATTER_DIR = os.path.join(LOADERS_DIR, "Matter")
VOID_DIR = os.path.join(LOADERS_DIR, "Void")
FALLBACK_DIR = r"C:\Users\A\Documents\RELEASESS\loadersss"

LINKS_JSON = os.path.join(CODM_REPO, "LoaderLink", "links.json")

# VMProtect
VMP_FOLDER = r"C:\Users\A\Documents\VMProtect-Ultimate--main\VMProtect-Ultimate--main\VMProtect Ultimate\VMProtect Ultimate x64"
VMP_CON = "VMProtect_Con.exe"
VMP_PROJECT = os.path.join(PROJECT_ROOT, "BloodyLuci32bit.exe.vmp")  # re-use your existing .vmp config

# Discord
VOID_WEBHOOK = "https://discord.com/api/webhooks/1403280184311943178/grtear3CQ0E3bineZop_4fidvsYJDuvaGuIhAzcHXWxeOqnTAXvYMfdOcM-JT1-wXaZ_"
MATTER_WEBHOOK = "https://discord.com/api/webhooks/1403280316088582154/fN3kEViYzOapRpL8GuH0tfajXPvcJjVPNligSa0IiSHpUPR3Pp9V-tAGp9KjBtYR9Qc6"

# Raw link base (your GitHub repo)
RAW_BASE = "https://github.com/miguelzzzzzzzz/codmbykeygen/raw/refs/heads/main/Loaders"

# =====================================


def execute_command(command, cwd=None, check_rc=True):
    """Execute shell command, stream output."""
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    print(f"\n> {command}\n")
    proc = subprocess.Popen(
        command,
        shell=True,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=1,
        universal_newlines=True,
        env=env,
    )
    for line in iter(proc.stdout.readline, ""):
        sys.stdout.write(line)
        sys.stdout.flush()
    proc.stdout.close()
    proc.wait()
    if check_rc and proc.returncode != 0:
        raise RuntimeError(f"Command failed (rc={proc.returncode}): {command}")
    return proc.returncode


def list_bloodyluci_py_files(root_dir: str):
    """List .py files that contain 'bloodyluci' (case-insensitive)."""
    files = []
    for name in os.listdir(root_dir):
        if name.lower().endswith(".py") and "bloodyluci" in name.lower():
            files.append(name)
    files.sort()
    return files


def select_file(root_dir: str):
    files = list_bloodyluci_py_files(root_dir)
    if not files:
        print(f"No .py files with 'bloodyluci' in name found in {root_dir}")
        sys.exit(1)

    print("Select the file to release:")
    for i, f in enumerate(files,  start=1):
        print(f"{i}. {f}")

    while True:
        try:
            n = int(input("Enter number: ").strip())
            if 1 <= n <= len(files):
                return files[n - 1]
        except ValueError:
            pass
        print("Invalid choice. Try again.")


def classify_target_from_filename(selected_file: str):
    """Guess channel from filename."""
    name_lower = selected_file.lower()
    if "matter" in name_lower:
        return "Matter"
    if "void" in name_lower:
        return "Void"
    return None


def channel_to_dest_and_webhook(channel: str):
    if channel == "Matter":
        return MATTER_DIR, MATTER_WEBHOOK
    if channel == "Void":
        return VOID_DIR, VOID_WEBHOOK
    return FALLBACK_DIR, None


def nuitka_build(src_dir: str, filename: str):
    """Build with Nuitka; returns path to produced EXE inside src_dir or current dir."""
    base = os.path.splitext(filename)[0]
    exe_out = os.path.join(src_dir, f"{base}.exe")

    cmd = (
        f'nuitka --follow-imports --onefile --standalone '
        f'--enable-plugin=pyqt5 '
        f'--windows-console-mode=disable --windows-uac-admin '
        f'--windows-icon-from-ico="{os.path.join(src_dir, "icon.ico")}" '
        f'"{os.path.join(src_dir, filename)}"'
    )
    execute_command(cmd)
    if os.path.exists(exe_out):
        return exe_out
    # Nuitka sometimes drops the exe in the CWD
    fallback = os.path.abspath(f"{base}.exe")
    if os.path.exists(fallback):
        return fallback
    raise FileNotFoundError(f"Expected EXE not found: {exe_out}")


def vmprotect_pack(input_exe: str, output_exe: str):
    """Run VMProtect to pack input_exe into output_exe."""
    os.makedirs(os.path.dirname(output_exe), exist_ok=True)
    cmd = f'"{VMP_CON}" "{input_exe}" "{output_exe}" "{VMP_PROJECT}"'
    execute_command(cmd, cwd=VMP_FOLDER)
    if not os.path.exists(output_exe):
        raise FileNotFoundError(f"VMProtect output not found: {output_exe}")
    return output_exe


def move_to_destination(built_exe: str, version: str, target_dir: str, selected_file: str):
    """Rename to include version and move to destination directory, returning final path."""
    base = os.path.splitext(os.path.basename(selected_file))[0]  # e.g., BloodyLuciVoid
    final_name = f"{base}{version}.exe"
    os.makedirs(target_dir, exist_ok=True)
    final_path = os.path.join(target_dir, final_name)
    # Move if needed
    if os.path.abspath(built_exe) != os.path.abspath(final_path):
        shutil.move(built_exe, final_path)
    print(f"Moved to: {final_path}")
    return final_path, final_name


def update_links_json(links_json_path: str, channel: str, version: str, exe_filename: str):
    """Insert new entry at the start of the correct array (matter_versions or void_versions)."""
    with open(links_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    key = "matter_versions" if channel == "Matter" else "void_versions"
    array = data.get(key, [])

    # Build new link
    link = f"{RAW_BASE}/{channel}/{exe_filename}"

    # Avoid duplicates
    exists = any(item.get("version") == version for item in array)
    if not exists:
        array.insert(0, {"version": version, "link": link})
        data[key] = array
        with open(links_json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print(f"links.json updated: added {channel} {version}")
        return True
    else:
        print(f"{channel} {version} already present in links.json; no changes.")
        return False


def git_commit_and_push(repo_path: str, message: str):
    execute_command("git add -A", cwd=repo_path)
    rc = execute_command(f'git commit -m "{message}"', cwd=repo_path, check_rc=False)
    if rc != 0:
        print("No changes to commit or commit failed (continuing).")
    execute_command("git push origin HEAD", cwd=repo_path)


def send_discord_announcement(webhook_url: str, architecture: str, version: str):
    today_date = datetime.now().strftime("%b %d, %Y")
    content = (
        f"‼️ **New UPDATE {architecture} {version} | {today_date}** ‼️\n\n"
        "**⚙️ Changes:**\n\n"
        "**+ Fixed nonlib v1 (TEST BYPASS)**\n"
        "**+ Any bugs or features that doesnt work please report on my dms @portamentoX10**\n\n"
        "**❗️PLEASE USE DUMMY FIRST FOR THE NEW UPDATE❗️**"
    )
    resp = requests.post(webhook_url, json={"content": content})
    if resp.status_code in (200, 204):
        print("Discord announcement sent.")
    else:
        print(f"Discord failed: {resp.status_code} - {resp.text}")


# ---------------------- NEW: robust version + channel parser ----------------------
def get_version_and_channel(file_path: str):
    """
    Extracts (version_str, channel) from lines like:
      version = '1.7.5 VOID'
      version = "1.7.0 Matter"
      version = '1.7.3'           (no channel suffix)
    Returns: ('1.7.5', 'Void') or ('1.7.0', 'Matter') or ('1.7.3', None)
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # find all matches just in case; we’ll pick the first
    matches = re.findall(
        r"""version\s*=\s*['"](\d+\.\d+\.\d+)(?:\s+([A-Za-z]+))?['"]""",
        content,
        flags=re.IGNORECASE
    )
    if not matches:
        return None, None

    ver, lbl = matches[0]
    channel = None
    if lbl:
        lbl_l = lbl.strip().lower()
        if lbl_l == "void":
            channel = "Void"
        elif lbl_l == "matter":
            channel = "Matter"
    return ver, channel
# -------------------------------------------------------------------------------


def main():
    print("=== BloodyLuci Release Builder ===")
    selected = select_file(PROJECT_ROOT)
    base_no_ext = os.path.splitext(selected)[0]
    print(f"\nSelected: {selected}\n")

    # Guess channel from filename first (fallback)
    channel = classify_target_from_filename(selected)

    # Compile with Nuitka
    if doNuitka:
        print(">> Building with Nuitka...")
        built_path = nuitka_build(PROJECT_ROOT, selected)
    else:
        built_path = os.path.join(PROJECT_ROOT, f"{base_no_ext}.exe")
        if not os.path.exists(built_path):
            raise FileNotFoundError(f"Expected EXE not found: {built_path}")

    # --- Use the new parser ---
    version, channel_from_ver = get_version_and_channel(os.path.join(PROJECT_ROOT, selected))
    if not version:
        print("ERROR: Could not detect version (expected: version = 'x.y.z [VOID|Matter]')")
        sys.exit(1)

    # Channel priority: version suffix > filename guess
    if channel_from_ver:
        channel = channel_from_ver

    # Destination + webhook from final channel
    dest_dir, webhook = channel_to_dest_and_webhook(channel)

    # Pack with VMProtect to a temp output (same folder as selected .py)
    packed_temp = os.path.join(PROJECT_ROOT, f"{base_no_ext}_packed_tmp.exe")
    if doVmp:
        print(">> Packing with VMProtect...")
        vmprotect_pack(built_path, packed_temp)
    else:
        shutil.copy2(built_path, packed_temp)

    # Move/rename to final destination (include version in filename)
    final_path, final_name = move_to_destination(
        packed_temp, version, dest_dir, selected
    )

    # Matter/Void: update links, git push, announce
    if channel in ("Matter", "Void"):
        did_update_links = update_links_json(LINKS_JSON, channel, version, final_name)

        if doGit:
            print(">> Committing & pushing to origin...")
            msg = f"Release: {channel} {version}"
            git_commit_and_push(CODM_REPO, msg)

        if doDiscord and webhook:
            print(">> Sending Discord announcement...")
            # Architecture text in the message matches channel name
            send_discord_announcement(webhook, channel, version)
    else:
        print("Non-Matter/Void build: copied to fallback, skipped links.json, Git, and Discord.")

    print("\n=== Done ===")
    print(f"Final file: {final_path}")
    print(f"Channel: {channel or 'N/A'} | Version: {version}")
    if iShutdown:
        os.system("shutdown /s /t 1")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nFATAL: {e}")
        sys.exit(1)
