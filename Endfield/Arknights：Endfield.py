import discord
from discord.ext import commands
import asyncio

import requests
import json
import os
import hashlib
from datetime import datetime, timezone

# =========================================================
# Discord Bot
# =========================================================

TOKEN = os.environ.get("DISCORD_TOKEN")

intents = discord.Intents.default()

bot = discord.Client(
    intents=intents
)

# =========================================================
# Branding
# =========================================================

BOT_NAME = "Arknights：Endfield"

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
        1292097230924283965, # Test
        1291728736739131402, # 1
        1267379122338791435, # 2
    ],
}

# =========================================================
# API
# =========================================================

IMAGE_API = (
    "https://raw.githubusercontent.com/"
    "horoyoi-san/Endfield/refs/heads/main/"
    "output/akEndfield/launcher/web/6/main_bg_image/th-th/all.json"
)

LAUNCHER_API = (
    "https://raw.githubusercontent.com/"
    "horoyoi-san/Endfield/refs/heads/main/"
    "output/akEndfield/launcher/launcher/Official/6/all.json"
)

GAME_API = (
    "https://raw.githubusercontent.com/"
    "horoyoi-san/Endfield/refs/heads/main/"
    "output/akEndfield/launcher/game/6/all.json"
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

def get_latest(items):
    if not items:
        return None

    return sorted(
        items,
        key=lambda x: x.get("rsp", {}).get("version", ""),
        reverse=True
    )[0]

def get_latest_image():
    data = fetch_json(IMAGE_API)

    if not data:
        return None

    latest = sorted(
        data,
        key=lambda x: x.get("updatedAt", ""),
        reverse=True
    )[0]

    return (
        latest
        .get("rsp", {})
        .get("main_bg_image", {})
        .get("url")
    )

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

    current_hash = hashlib.md5(
        text.encode()
    ).hexdigest()

    log_dir = os.path.join(
        os.getcwd(),
        "Hg",
        "log",
        name
    )

    os.makedirs(log_dir, exist_ok=True)

    hash_file = os.path.join(
        log_dir,
        "last_hash.txt"
    )

    raw_file = os.path.join(
        log_dir,
        "raw_log.jsonl"
    )

    # write raw log
    with open(raw_file, "a", encoding="utf-8") as f:
        f.write(json.dumps({
            "timestamp": datetime.now(
                timezone.utc
            ).isoformat(),

            "data": data

        }, ensure_ascii=False) + "\n")

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

def split_text_to_embeds(
    title,
    text,
    color=0xFFD700,
    max_len=4000,
    image_url=None
):
    if not text:
        return []

    embeds = []

    lines = text.split("\n")

    current = ""

    part = 1

    for line in lines:

        if len(current) + len(line) + 1 > max_len:

            embed = discord.Embed(
                title=f"{title} {part}",
                description=current,
                color=color
            )

            embed.set_thumbnail(
                url=BOT_ICON
            )

            if image_url:
                embed.set_image(
                    url=image_url
                )

            embed.set_footer(
                text="Arknights：Endfield Update"
            )

            embeds.append(embed)

            current = line

            part += 1

        else:
            current += (
                "\n" if current else ""
            ) + line

    if current:

        embed = discord.Embed(
            title=f"{title} {part}",
            description=current,
            color=color
        )

        embed.set_thumbnail(
            url=BOT_ICON
        )

        if image_url:
            embed.set_image(
                url=image_url
            )

        embed.set_footer(
            text="Horoyoi-san | Mortenax Blade ඞ"
        )

        embeds.append(embed)

    return embeds

# =========================================================
# Convert
# =========================================================

def convert_launcher():
    data = fetch_json(LAUNCHER_API)

    latest = get_latest(data)

    if not latest:
        return None

    rsp = latest.get("rsp", {})

    return {
        "default": {
            "resource": {
                "version": rsp.get("version"),
                "size": rsp.get("package_size", 0),
                "md5": rsp.get("md5", ""),
                "path": rsp.get("zip_package_url")
            }
        }
    }

def convert_game():
    data = fetch_json(GAME_API)

    latest = get_latest(data)

    if not latest:
        return None

    rsp = latest.get("rsp", {})

    pkg = rsp.get("pkg", {})

    packs = pkg.get("packs", [])

    patch_list = []

    for p in packs:

        if p.get("url"):

            patch_list.append({
                "version": rsp.get("version"),
                "indexFile": p.get("url")
            })

    return {
        "default": {
            "config": {
                "version": rsp.get("version"),
                "size": pkg.get("total_size", 0),
                "indexFileMd5": pkg.get(
                    "game_files_md5",
                    ""
                ),

                "patchConfig": patch_list
            }
        }
    }

# =========================================================
# Discord Send
# =========================================================

async def send_discord(
    channel_id,
    embeds
):
    try:
        channel = await bot.fetch_channel(channel_id)

    except Exception as e:
        print(f"❌ Channel fetch error: {channel_id}")
        print(e)
        return

    for i, embed in enumerate(embeds, 1):

        try:
            await channel.send(embed=embed)

            print(
                f"✅ sent embed {i} -> {channel_id}"
            )

        except Exception as e:
            print(
                f"❌ send error -> {channel_id}"
            )

            print(e)

# =========================================================
# Build Embeds
# =========================================================

def build_launcher_embeds(
    data,
    title,
    image_url=None
):
    blocks = []

    default = data.get("default")

    if not default:
        return []

    resource = default.get("resource")

    if not resource:
        return []

    version = resource.get(
        "version",
        "No version"
    )

    path = resource.get(
        "path",
        ""
    )

    size = resource.get(
        "size",
        0
    )

    md5 = resource.get(
        "md5",
        ""
    )

    desc = (
        f"## Version {version}\n"
        f"## Download\n"
        f"{path}\n"
    )

    blocks += split_text_to_embeds(
        title + " — Launcher",
        desc,
        image_url=image_url
    )

    return blocks

def build_game_embeds(
    data,
    title,
    image_url=None
):
    blocks = []

    default = data.get("default")

    if not default:
        return []

    config = default.get(
        "config",
        {}
    )

    version = config.get(
        "version",
        "No version"
    )

    patch_lines = []

    for patch in config.get(
        "patchConfig",
        []
    ):

        ver = patch.get("version")

        url = patch.get("indexFile")

        patch_lines.append(
            f"{ver}\n{url}"
        )

    desc = (
        f"## Version\n"
        f"`{version}`\n\n"

        f"## Download\n"
        + "\n\n".join(patch_lines)
    )

    blocks += split_text_to_embeds(
        title + " — Game",
        desc,
        image_url=image_url
    )

    return blocks

async def main():

    await bot.login(TOKEN)

    print(f"✅ Logged in as {bot.user}")

    image_url = get_latest_image()

    # =====================================================
    # Launcher
    # =====================================================

    changed_l, _ = log_and_check(
        LAUNCHER_API,
        "Arknights：Endfield Launcher"
    )

    if changed_l:

        print("✅ launcher changed")

        data = convert_launcher()

        if data:

            embeds = build_launcher_embeds(
                data,
                "Arknights：Endfield",
                image_url
            )

            for channel_id in CHANNELS["endfield"]:

                await send_discord(
                    channel_id,
                    embeds
                )

    else:
        print("Launcher: no change")

    # =====================================================
    # Game
    # =====================================================

    changed_g, _ = log_and_check(
        GAME_API,
        "Arknights：Endfield Game"
    )

    if changed_g:

        print("✅ game changed")

        data = convert_game()

        if data:

            embeds = build_game_embeds(
                data,
                "Arknights：Endfield",
                image_url
            )

            for channel_id in CHANNELS["endfield"]:

                await send_discord(
                    channel_id,
                    embeds
                )

    else:
        print("Game: no change")

    await bot.close()

# =========================================================
# Run Once
# =========================================================

asyncio.run(main())