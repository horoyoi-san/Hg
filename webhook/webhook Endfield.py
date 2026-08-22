import requests
import time
import re
import os
from collections import defaultdict


def load_env_file():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env_path = os.path.join(repo_root, ".env")

    if not os.path.exists(env_path):
        return

    with open(env_path, "r", encoding="utf-8") as env_file:
        for line in env_file:
            line = line.strip()

            if not line or line.startswith("#") or "=" not in line:
                continue

            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip("'\""))


load_env_file()

WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "YOUR_DISCORD")
BOT_TOKEN = os.getenv("DISCORD_BOT_TOKEN", "")
CHANNEL_ID = os.getenv("DISCORD_HKRPG_CHANNEL_ID", os.getenv("DISCORD_CHANNEL_ID", ""))
DISCORD_API_URL = "https://discord.com/api/v10"


def send_discord_message(payload):
    if (
        BOT_TOKEN
        and BOT_TOKEN != "YOUR_BOT_TOKEN"
        and CHANNEL_ID
        and CHANNEL_ID != "YOUR_CHANNEL_ID"
    ):
        url = f"{DISCORD_API_URL}/channels/{CHANNEL_ID}/messages"
        headers = {
            "Authorization": f"Bot {BOT_TOKEN}",
            "Content-Type": "application/json",
        }
        response = requests.post(url, headers=headers, json=payload, timeout=15)
        response.raise_for_status()
        return "bot"

    if WEBHOOK_URL and WEBHOOK_URL != "YOUR_DISCORD":
        response = requests.post(WEBHOOK_URL, json=payload, timeout=15)
        response.raise_for_status()
        return "webhook"

    raise RuntimeError(
        "Please set DISCORD_WEBHOOK_URL or set DISCORD_BOT_TOKEN and DISCORD_HKRPG_CHANNEL_ID."
    )

# =========================
# แหล่งข้อมูล
# =========================

# ถ้ามี URL จะดึงจาก URL ก่อน
DATA_URL = ""

# ถ้า URL ใช้ไม่ได้ จะ fallback มาอ่านไฟล์ txt
DATA_FILE = "data/Endfield.txt"

PURPLE = 0xf2ff00

GIF_URL = "https://raw.githubusercontent.com/horoyoi-san/Endfield/refs/heads/main/output/raw/gl-utils-public.hg-cdn.com/hg-utils/prod/eppcsuwqpaueijqk/YDUTE5gscDZ229CW/75/9c/759ce3971deae80470cda81cec43ba24.webp"

EMBED_LIMIT = 4096

# =========================
# โหลดข้อมูล
# =========================

text = ""

# 1) พยายามดึงจาก URL ก่อน
if DATA_URL:
    try:
        print("Loading data from URL...")

        resp = requests.get(DATA_URL, timeout=15)
        resp.raise_for_status()

        text = resp.text.strip()

        print("Loaded data from URL")

    except Exception as e:
        print(f"Failed to load URL: {e}")

# 2) ถ้า URL ใช้ไม่ได้ -> อ่านจากไฟล์ txt
if not text:
    try:
        print("Loading data from local file...")

        with open(DATA_FILE, "r", encoding="utf-8") as f:
            text = f.read().strip()

        print("Loaded data from local file")

    except Exception as e:
        print(f"Failed to load local file: {e}")
        raise SystemExit("No data source available.")

# =========================
# แยก block ต่อเวอร์ชัน
# =========================

blocks = re.split(r"\n(?=Arknights: Endfield \d+\.\d)", text)
blocks = [b.strip() for b in blocks if b.strip()]

# =========================
# Group ตาม major version
# =========================

groups = defaultdict(list)

for block in blocks:
    m = re.search(r"Arknights: Endfield (\d+)\.(\d+)", block)

    if not m:
        continue

    major = int(m.group(1))
    minor = int(m.group(2))

    groups[major].append((minor, block))

# =========================
# สร้าง Embed
# =========================

for major in sorted(groups.keys()):
    versions = sorted(groups[major], key=lambda x: x[0])

    current_desc = ""
    embeds_to_send = []

    for _, block in versions:
        candidate = block + "\n\n"

        if len(current_desc) + len(candidate) > EMBED_LIMIT:
            embeds_to_send.append(current_desc.rstrip())
            current_desc = candidate
        else:
            current_desc += candidate

    if current_desc.strip():
        embeds_to_send.append(current_desc.rstrip())

    # =========================
    # ส่ง Embed
    # =========================

    for desc in embeds_to_send:
        payload = {
            "embeds": [
                {
                    "title": f"Arknights: Endfield Timeline (STC) ({major}.0)",
                    "description": desc,
                    "color": PURPLE,
                    "image": {
                        "url": GIF_URL
                    }
                }
            ]
        }

        try:
            send_mode = send_discord_message(payload)

            print(f"Sent embed for {major}.0 via {send_mode}")

        except Exception as e:
            print(f"Failed to send Discord message: {e}")

        time.sleep(1)  # กัน rate limit
