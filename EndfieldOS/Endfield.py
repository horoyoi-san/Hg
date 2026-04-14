import requests
import json
import os
import hashlib
from datetime import datetime, timezone

# ================= Webhook =================
webhook_urls = [
    os.environ.get("WEBHOOK"),
    os.environ.get("WEBHOOK1"),
    os.environ.get("WEBHOOK2"),
]

# ================= API =================
IMAGE_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield-api/refs/heads/main/output/akEndfield/launcher/web/6/main_bg_image/th-th/all.json"
LAUNCHER_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield-api/refs/heads/main/output/akEndfield/launcher/launcher/Official/6/all.json"
GAME_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield-api/refs/heads/main/output/akEndfield/launcher/game/6/all.json"

# ================= Utils =================
def fetch_json(url):
    try:
        return requests.get(url, timeout=10).json()
    except Exception as e:
        print(f"❌ fetch error: {url} -> {e}")
        return []

def get_latest(items):
    if not items:
        return None
    return sorted(items, key=lambda x: x.get("rsp", {}).get("version", ""), reverse=True)[0]

def get_latest_image():
    data = fetch_json(IMAGE_API)
    if not data:
        return None

    # เรียงตาม updatedAt แทน
    latest = sorted(
        data,
        key=lambda x: x.get("updatedAt", ""),
        reverse=True
    )[0]

    return latest.get("rsp", {}).get("main_bg_image", {}).get("url")


# ================= Logging =================
def log_and_check(api_url, name):
    try:
        resp = requests.get(api_url, timeout=10)
        text = resp.text
        data = json.loads(text)
    except Exception as e:
        print(f"❌ Error fetching {name}: {e}")
        return False, None

    current_hash = hashlib.md5(text.encode()).hexdigest()

    log_dir = os.path.join(os.getcwd(), "Hg", "log", name)
    os.makedirs(log_dir, exist_ok=True)

    hash_file = os.path.join(log_dir, "last_hash.txt")
    raw_file = os.path.join(log_dir, "raw_log.jsonl")

    # write log
    with open(raw_file, "a", encoding="utf-8") as f:
        f.write(json.dumps({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data": data
        }, ensure_ascii=False) + "\n")

    last_hash = ""
    if os.path.exists(hash_file):
        last_hash = open(hash_file).read().strip()

    if current_hash != last_hash:
        with open(hash_file, "w") as f:
            f.write(current_hash)
        return True, data

    return False, data

# ================= Embed =================
def split_text_to_embeds(title, text, color=16776960, max_len=1024, image_url=None):
    if not text:
        return []

    embeds = []
    lines = text.split("\n")
    current = ""
    part = 1

    for line in lines:
        if len(current) + len(line) + 1 > max_len:
            embeds.append({
                "title": f"{title} {part}",
                "description": current,
                "color": color,
                "image": {"url": image_url} if image_url else {}
            })
            current = line
            part += 1
        else:
            current += ("\n" if current else "") + line

    if current:
        embeds.append({
            "title": f"{title} {part}",
            "description": current,
            "color": color,
            "image": {"url": image_url} if image_url else {}
        })

    return embeds

# ================= Convert (Endfield → Format เดิม) =================
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
            },
            "cdnList": [{"url": ""}]
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
                "indexFileMd5": pkg.get("game_files_md5", ""),
                "patchConfig": patch_list
            },
            "cdnList": [{"url": ""}],
            "resources": ""
        }
    }


# ================= Discord =================
def send_webhook(data, title, webhook_url, image_url=None):
    if not webhook_url:
        return

    blocks = []

    default = data.get("default")
    if default:
        resource = default.get("resource")

        if resource:  # Launcher
            version = resource.get("version", "No version")
            path = resource.get("path", "")

            desc = (
                f"**Version:** {version}\n"
                f"**Download:** {path}"
            )

            blocks += split_text_to_embeds(title + " — Launcher", desc, image_url=image_url)

        else:  # Game
            config = default.get("config", {})
            version = config.get("version", "No version")

            patch_lines = []
            for patch in config.get("patchConfig", []):
                ver = patch.get("version")
                url = patch.get("indexFile")
                patch_lines.append(f"{ver}: {url}")

            desc = f"**Version:** {version}\n**Download:**\n" + "\n".join(patch_lines)

            blocks += split_text_to_embeds(title + " — Game", desc, image_url=image_url)

    # send
    for i, embed in enumerate(blocks, 1):
        try:
            r = requests.post(webhook_url, json={"embeds": [embed]}, timeout=10)
            if r.status_code == 204:
                print(f"✅ ส่ง {title} embed {i}")
            else:
                print(f"❌ {r.status_code} {r.text}")
        except Exception as e:
            print("❌ webhook error:", e)

# ================= Main =================
def check_for_updates():
    image_url = get_latest_image()

    changed_l, _ = log_and_check(LAUNCHER_API, "Endfield Launcher")
    changed_g, _ = log_and_check(GAME_API, "Endfield Game")

    if changed_l:
        data = convert_launcher()
        if data:
            for url in webhook_urls:
                send_webhook(data, "Endfield", url, image_url)


    else:
        print("Launcher: no change")

    if changed_g:
        data = convert_game()
        if data:
            for url in webhook_urls:
                send_webhook(data, "Endfield", url, image_url)


    else:
        print("Game: no change")

if __name__ == "__main__":
    check_for_updates()
