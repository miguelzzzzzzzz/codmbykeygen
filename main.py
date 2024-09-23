import hashlib
import base64
import hmac
import time
import subprocess
import psutil
import socket
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
import os

# Set up your bot token and secret key
TOKEN = '7719430347:AAGhAwP5PQP0LvQjJvz0dIqQly-3iWy5V_4'
SECRET_KEY = b'sandokenkanen'  # Replace this with your actual secret key

# Function to get the system's unique HWID
def get_hwid():
    try:
        motherboard_serial = subprocess.check_output(["wmic", "baseboard", "get", "serialnumber"]).decode().split('\n')[1].strip()
    except Exception:
        motherboard_serial = "UNKNOWN"

    try:
        cpu_id = subprocess.check_output(["wmic", "cpu", "get", "ProcessorId"]).decode().split('\n')[1].strip()
    except Exception:
        cpu_id = "UNKNOWN"

    try:
        disk_serial = subprocess.check_output(["wmic", "diskdrive", "get", "serialnumber"]).decode().split('\n')[1].strip()
    except Exception:
        disk_serial = "UNKNOWN"

    try:
        mac_address = hex(psutil.net_if_addrs()[socket.if_nameindex()[0]].address)
    except Exception:
        mac_address = "UNKNOWN"

    hwid_source = f"{motherboard_serial}-{cpu_id}-{disk_serial}-{mac_address}"
    hwid_hash = hashlib.sha256(hwid_source.encode()).hexdigest()
    return hwid_hash

# Function to generate the key
def generate_key(expiration_time, hwid):
    message = f"{expiration_time},{hwid}".encode('utf-8')
    signature = hmac.new(SECRET_KEY, message, hashlib.sha256).digest()
    key = base64.urlsafe_b64encode(message + signature).decode('utf-8')
    return key

# Command to start the bot and display HWID
async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    hwid = get_hwid()
    await update.message.reply_text(f"Your HWID is: {hwid}")

# Command to generate a key
async def generate_key_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    hwid = get_hwid()
    await update.message.reply_text(f"Your HWID is: {hwid}")
    
    duration = context.args[0] if context.args else None
    if not duration:
        await update.message.reply_text("Please specify the key duration in hours (e.g., '5h') or days (e.g., '2d').")
        return

    # Calculate expiration time
    current_time = int(time.time())
    if duration.endswith('h'):
        hours = int(duration[:-1])
        expiration_time = current_time + (hours * 3600)
    elif duration.endswith('d'):
        days = int(duration[:-1])
        expiration_time = current_time + (days * 86400)
    else:
        await update.message.reply_text("Invalid duration format. Use '5h' for hours or '2d' for days.")
        return

    hwid_target = context.args[1] if len(context.args) > 1 else hwid
    key = generate_key(expiration_time, hwid_target)
    await update.message.reply_text(f"Generated key: {key}")

# Set up the application and handlers
async def error(update: Update, context: ContextTypes.DEFAULT_TYPE):
    print(f"Error: {context.error}")

if __name__ == '__main__':
    print("Starting bot...")

    # Create the application instance
    app = Application.builder().token(TOKEN).build()

    # Add command handlers
    app.add_handler(CommandHandler('start', start_command))
    app.add_handler(CommandHandler('generate_key', generate_key_command))

    # Add error handler
    app.add_error_handler(error)

    # Start polling
    print("Bot is polling...")
    app.run_polling()
