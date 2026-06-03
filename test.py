import discord
from discord.ext import commands
import asyncio
import time

import requests
import json
import os
import hashlib
from datetime import datetime, timezone

# =========================================================
# Discord Bot
# =========================================================

# TOKEN = os.environ.get("DISCORD_TOKEN")
TOKEN = "GAYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"
intents = discord.Intents.default()

bot = discord.Client(intents=intents)

# =========================================================
# Branding
# =========================================================

BOT_NAME = "明日方舟：终末地"

BOT_ICON = (
    "https://raw.githubusercontent.com/"
    "horoyoi-san/Hg/refs/heads/webhook/assets/endfield.png"
)

# =========================================================
# Channels
# =========================================================
# ใส่ channel id ที่ต้องการส่ง
# ใช้แทน webhook หลายตัวได้เลย

CHANNELS = {
    "endfield": [
        999999999999999,  # Test
        #888888888888888,  # 1
        #444444444444444444,  # 2
    ],
}

# =========================================================
# API
# =========================================================

LAUNCHER_WEB_API = (
    "https://launcher.hypergryph.com/api/proxy/web/batch_proxy"
)

LAUNCHER_API = (
    "https://launcher.hypergryph.com/api/launcher/get_latest_launcher"
    "?appcode=abYeZZ16BPluCFyT&channel=1&sub_channel=1"
)

GAME_API = (
    "https://launcher.hypergryph.com/api/game/get_latest"
    "?appcode=6LL0KJuqHBVz33WK&channel=1&sub_channel=1"
)

# =========================================================
# Utils
# =========================================================


def fetch_json(url):
    try:
        return requests.get(url, timeout=10).json()

    except Exception as e:
        print(f"❌ fetch error: {url}")
        print(e)

        return []


def get_main_bg_image():

    payload = {
        "proxy_reqs": [
            {
                "kind": "get_main_bg_image",
                "get_main_bg_image_req": {
                    "appcode": "6LL0KJuqHBVz33WK",
                    "channel": "1",
                    "sub_channel": "1",
                    "language": "zh-cn",
                    "platform": "Windows",
                    "source": "launcher",
                },
            }
        ]
    }

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/143.0.0.0 Safari/537.36"
        ),
        "Content-Type": "application/json;charset=UTF-8",
    }

    try:

        resp = requests.post(
            LAUNCHER_WEB_API,
            json=payload,
            headers=headers,
            timeout=15,
        )

        data = resp.json()

        print(json.dumps(data, indent=2, ensure_ascii=False))

        for item in data.get("proxy_rsps", []):

            if item.get("kind") == "get_main_bg_image":

                rsp = item.get("get_main_bg_image_rsp", {})

                main_bg = rsp.get("main_bg_image", {})

                return main_bg.get("url")

        return None

    except Exception as e:

        print("❌ get_main_bg_image error")
        print(e)

        return None
    
def get_latest_game_web():

    # =====================================================
    # ดึง current game version ก่อน
    # =====================================================

    game_rsp = fetch_json(GAME_API)

    current_version = game_rsp.get("version", "")

    print(f"Current Version: {current_version}")

    payload = {
        "proxy_reqs": [
            {
                "kind": "get_latest_game",
                "get_latest_game_req": {
                    "appcode": "6LL0KJuqHBVz33WK",
                    "channel": "1",
                    "sub_channel": "1",
                    "platform": "Windows",
                    "version": current_version
                },
            }
        ]
    }

    headers = {
        "User-Agent": "HGLauncher",
        "Content-Type": "application/json"
    }

    try:

        resp = requests.post(
            "https://launcher.hypergryph.com/api/proxy/batch_proxy",
            json=payload,
            headers=headers,
            timeout=15,
        )

        data = resp.json()

        print(json.dumps(data, indent=2, ensure_ascii=False))

        for item in data.get("proxy_rsps", []):

            if item.get("kind") == "get_latest_game":

                return item.get("get_latest_game_rsp", {})

        return {}

    except Exception as e:

        print("❌ get_latest_game_web error")
        print(e)

        return {}
    
    
def log_and_check_web_game():

    try:

        data = get_latest_game_web()

        text = json.dumps(
            data,
            ensure_ascii=False,
            sort_keys=True
        )

    except Exception as e:

        print("❌ Error fetching WEB GAME")
        print(e)

        return False, None

    current_hash = hashlib.md5(text.encode()).hexdigest()

    log_dir = os.path.join(
        os.getcwd(),
        "Hg",
        "log",
        "明日方舟：终末地 Web Game"
    )

    os.makedirs(log_dir, exist_ok=True)

    hash_file = os.path.join(log_dir, "last_hash.txt")

    raw_file = os.path.join(log_dir, "raw_log.jsonl")

    with open(raw_file, "a", encoding="utf-8") as f:

        f.write(
            json.dumps(
                {
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "data": data
                },
                ensure_ascii=False
            ) + "\n"
        )

    last_hash = ""

    if os.path.exists(hash_file):

        with open(hash_file, "r", encoding="utf-8") as f:
            last_hash = f.read().strip()

    if current_hash != last_hash:

        with open(hash_file, "w", encoding="utf-8") as f:
            f.write(current_hash)

        return True, data

    return False, data
  
# =========================================================
# Logging
# =========================================================


def log_and_check(api_url, name):
    try:
        resp = requests.get(api_url, timeout=10)

        text = resp.text

        data = json.loads(text)

    except Exception as e:
        print(f"❌ Error fetching {name}")
        print(e)

        return False, None

    current_hash = hashlib.md5(text.encode()).hexdigest()

    log_dir = os.path.join(os.getcwd(), "Hg", "log", name)

    os.makedirs(log_dir, exist_ok=True)

    hash_file = os.path.join(log_dir, "last_hash.txt")

    raw_file = os.path.join(log_dir, "raw_log.jsonl")

    # write raw log
    with open(raw_file, "a", encoding="utf-8") as f:
        f.write(
            json.dumps(
                {"timestamp": datetime.now(timezone.utc).isoformat(), "data": data},
                ensure_ascii=False,
            )
            + "\n"
        )

    last_hash = ""

    if os.path.exists(hash_file):
        with open(hash_file, "r", encoding="utf-8") as f:
            last_hash = f.read().strip()

    # changed
    if current_hash != last_hash:

        with open(hash_file, "w", encoding="utf-8") as f:
            f.write(current_hash)

        return True, data

    return False, data


# =========================================================
# Embed
# =========================================================


def split_text_to_embeds(title, text, color=0xFFD700, max_len=4000, image_url=None):
    embeds = []

    def push(part_text, part_num):
        embed = discord.Embed(
            title=f"{title} {part_num}",
            description=part_text,
            color=color
        )
        embed.set_thumbnail(url=BOT_ICON)
        if image_url:
            embed.set_image(url=image_url)
        embed.set_footer(text="https://endfield-game.vercel.app")
        embeds.append(embed)

    part = 1
    current = ""

    for line in text.split("\n"):
        # ถ้า line เดียวใหญ่เกิน → ต้อง "ตัดในตัวมันเอง"
        while len(line) > max_len:
            chunk = line[:max_len]
            line = line[max_len:]

            if len(current) + len(chunk) > max_len:
                push(current, part)
                part += 1
                current = chunk
            else:
                current += ("\n" if current else "") + chunk

        # ปกติ
        if len(current) + len(line) + 1 > max_len:
            push(current, part)
            part += 1
            current = line
        else:
            current += ("\n" if current else "") + line

    if current:
        push(current, part)

    return embeds


# =========================================================
# Convert
# =========================================================


def convert_launcher():
    rsp = fetch_json(LAUNCHER_API)

    if not rsp:
        return None

    return {
        "default": {
            "resource": {
                "version": rsp.get("version"),
                "size": rsp.get("exe_size", 0),
                "md5": "",
                "path": rsp.get("exe_url"),
            }
        }
    }

def convert_game():

    # =========================
    # GAME API
    # =========================

    game_rsp = fetch_json(GAME_API)

    if not game_rsp:
        return None

    # =========================
    # WEB API
    # =========================

    web_rsp = get_latest_game_web()

    version = game_rsp.get("version", "Unknown")

    pkg = game_rsp.get("pkg", {})

    pre_patch = web_rsp.get("pre_patch") or {}

    patch_list = []

    # =========================
    # FULL GAME
    # =========================

    for p in pkg.get("packs", []):

        url = p.get("url")

        if url:

            patch_list.append({
                "type": "FULL",
                "version": version,
                "url": url,
                "md5": p.get("md5", ""),
                "size": p.get("package_size", "0"),
            })

    # =========================
    # PRE PATCH
    # =========================

    pre_patch_version = pre_patch.get("version")

    for p in pre_patch.get("patches", []):

        url = p.get("url")

        if url:

            patch_list.append({
                "type": "PRE PATCH",
                "version": pre_patch_version,
                "url": url,
                "md5": p.get("md5", ""),
                "size": p.get("package_size", "0"),
            })

    return {
        "default": {
            "config": {
                "version": version,
                "file_path": pkg.get("file_path", ""),
                "md5": pkg.get("game_files_md5", ""),
                "patches": patch_list,
            }
        }
    }


# =========================================================
# Discord Send
# =========================================================


async def send_discord(channel_id, embeds):
    try:
        channel = await bot.fetch_channel(channel_id)

    except Exception as e:
        print(f"❌ Channel fetch error: {channel_id}")
        print(e)
        return

    for i, embed in enumerate(embeds, 1):

        try:
            await channel.send(embed=embed)

            print(f"✅ sent embed {i} -> {channel_id}")

        except Exception as e:
            print(f"❌ send error -> {channel_id}")

            print(e)


# =========================================================
# Build Embeds
# =========================================================


def build_launcher_embeds(data, title, image_url=None):
    blocks = []

    default = data.get("default")

    if not default:
        return []

    resource = default.get("resource")

    if not resource:
        return []

    version = resource.get("version", "No version")

    path = resource.get("path", "")

    size = resource.get("size", 0)

    md5 = resource.get("md5", "")

    desc = f"## Version {version}\n" f"## Download\n" f"{path}\n"

    blocks += split_text_to_embeds(title + " — Launcher", desc, image_url=image_url)

    return blocks


def build_game_embeds(data, title, image_url=None):

    default = data.get("default")
    if not default:
        return []

    config = default.get("config", {})

    version = config.get("version", "Unknown")
    file_path = config.get("file_path", "")

    embeds = []
    current_text = ""
    part = 1

    def push():
        nonlocal current_text, part
        if not current_text:
            return

        embed = discord.Embed(
            title=f"{title} — Game {part}",
            description=current_text,
            color=0xFFD700
        )
        embed.set_thumbnail(url=BOT_ICON)
        if image_url:
            embed.set_image(url=image_url)
        embed.set_footer(text="https://endfield-game.vercel.app")

        embeds.append(embed)

        current_text = ""
        part += 1

    def add_block(block):
        nonlocal current_text

        # ถ้า block เดียวใหญ่ → ต้อง force push
        if len(block) > 4000:
            push()
            embeds.append(discord.Embed(
                title=f"{title} — Game {part}",
                description=block[:4000],
                color=0xFFD700
            ))
            return

        if len(current_text) + len(block) > 4000:
            push()

        current_text += ("\n\n" if current_text else "") + block

    # ===== Version section =====
    add_block(f"## Current Version\n`{version}`")
    add_block(f"## File Path\n{file_path}")

    # ===== Patch section (IMPORTANT FIX) =====
    for patch in config.get("patches", []):
        block = (
            f"## {patch['type']}\n"
            f"Version: `{patch['version']}`\n"
            f"{patch['url']}"
        )
        add_block(block)

    push()

    return embeds


async def main():

    await bot.login(TOKEN)

    print(f"✅ Logged in as {bot.user}")

    image_url = get_main_bg_image()

    # =====================================================
    # Launcher
    # =====================================================

    changed_l, _ = log_and_check(
        LAUNCHER_API,
        "明日方舟：终末地 Launcher"
    )

    if changed_l:

        print("✅ launcher changed")

        data = convert_launcher()

        if data:

            embeds = build_launcher_embeds(
                data,
                "明日方舟：终末地",
                image_url
            )

            for channel_id in CHANNELS["endfield"]:

                await send_discord(channel_id, embeds)

    else:
        print("Launcher: no change")

    # =====================================================
    # Game
    # =====================================================

    changed_game, _ = log_and_check(
        GAME_API,
        "明日方舟：终末地 Game"
    )

    changed_pre, _ = log_and_check_web_game()

    if changed_game or changed_pre:

        print("✅ game/pre changed")

        data = convert_game()

        if data:

            embeds = build_game_embeds(
                data,
                "明日方舟：终末地",
                image_url
            )

            for channel_id in CHANNELS["endfield"]:

                await send_discord(channel_id, embeds)

    else:
        print("Game: no change")


# =========================================================
# Start
# =========================================================


async def runner():

    task = asyncio.create_task(bot.start(TOKEN))

    await asyncio.sleep(5)

    await main()

    await asyncio.sleep(60)

    await bot.close()

    await task


asyncio.run(runner())
