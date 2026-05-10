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

# ================= Branding =================
BOT_NAME = "Arknights: Endfield"
BOT_ICON = "https://raw.githubusercontent.com/horoyoi-san/Hg/refs/heads/webhook/assets/endfield.png"

# ================= API =================
IMAGE_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield/refs/heads/main/output/akEndfield/launcher/web/6/main_bg_image/th-th/all.json"
LAUNCHER_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield/refs/heads/main/output/akEndfield/launcher/launcher/Official/6/all.json"
GAME_API = "https://raw.githubusercontent.com/horoyoi-san/Endfield/refs/heads/main/output/akEndfield/launcher/game/6/all.json"


# ================= Utils =================
def fetch_json(url):
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        print(f"❌ fetch error: {url} -> {e}")
        return []


def version_key(v):
    try:
        return [int(x) for x in str(v).split(".")]
    except:
        return [0]


def get_latest(items):
    if not items:
        return None

    return sorted(
        items,
        key=lambda x: version_key(x.get("rsp", {}).get("version", "0")),
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

    return latest.get("rsp", {}).get("main_bg_image", {}).get("url")


# ================= Logging =================
def log_and_check(api_url, name):
    try:
        resp = requests.get(api_url, timeout=10)
        resp.raise_for_status()

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

    with open(raw_file, "a", encoding="utf-8") as f:
        f.write(json.dumps({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data": data
        }, ensure_ascii=False) + "\n")

    last_hash = ""

    if os.path.exists(hash_file):
        with open(hash_file, "r", encoding="utf-8") as f:
            last_hash = f.read().strip()

    if current_hash != last_hash:
        with open(hash_file, "w", encoding="utf-8") as f:
            f.write(current_hash)

        return True, data

    return False, data


# ================= Embed =================
def split_text_to_embeds(
    title,
    text,
    color=16776960,
    max_len=3500,
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

            embed = {
                "title": f"{title} {part}"[:256],
                "description": current[:4096],
                "color": color,
                "thumbnail": {
                    "url": BOT_ICON
                }
            }

            if image_url:
                embed["image"] = {
                    "url": image_url
                }

            embeds.append(embed)

            current = line
            part += 1

        else:
            current += ("\n" if current else "") + line

    if current:

        embed = {
            "title": f"{title} {part}"[:256],
            "description": current[:4096],
            "color": color,
            "thumbnail": {
                "url": BOT_ICON
            }
        }

        if image_url:
            embed["image"] = {
                "url": image_url
            }

        embeds.append(embed)

    return embeds


# ================= Convert =================
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

        url = p.get("url")

        if url:
            patch_list.append({
                "version": rsp.get("version"),
                "indexFile": url
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

        # ================= Launcher =================
        if resource:

            version = resource.get("version", "No version")
            path = resource.get("path", "")

            desc = (
                f"**Version:** {version}\n"
                f"**Download:**\n{path}"
            )

            blocks += split_text_to_embeds(
                title + " — Launcher",
                desc,
                image_url=image_url
            )

        # ================= Game =================
        else:

            config = default.get("config", {})

            version = config.get("version", "No version")

            patch_lines = []

            for patch in config.get("patchConfig", []):

                ver = patch.get("version")
                url = patch.get("indexFile")

                patch_lines.append(f"{ver}\n{url}")

            desc = (
                f"**Version:** {version}\n\n"
                f"**Download:**\n\n"
                + "\n\n".join(patch_lines)
            )

            blocks += split_text_to_embeds(
                title + " — Game",
                desc,
                image_url=image_url
            )

    # Discord max 10 embeds/request
    for chunk_start in range(0, len(blocks), 10):

        chunk = blocks[chunk_start:chunk_start + 10]

        try:

            r = requests.post(
                webhook_url,
                json={
                    "username": BOT_NAME,
                    "avatar_url": BOT_ICON,
                    "embeds": chunk
                },
                timeout=10
            )

            print(r.status_code)
            print(r.text)

            if r.status_code in [200, 204]:
                print(f"✅ ส่ง {title}")
            else:
                print(f"❌ {r.status_code} {r.text}")

        except Exception as e:
            print("❌ webhook error:", e)


# ================= Main =================
def check_for_updates():

    image_url = get_latest_image()

    changed_l, _ = log_and_check(
        LAUNCHER_API,
        "Arknights Endfield Launcher"
    )

    changed_g, _ = log_and_check(
        GAME_API,
        "Arknights Endfield Game"
    )

    if changed_l:

        data = convert_launcher()

        if data:
            for url in webhook_urls:
                send_webhook(
                    data,
                    "Arknights: Endfield",
                    url,
                    image_url
                )

    else:
        print("Launcher: no change")

    if changed_g:

        data = convert_game()

        if data:
            for url in webhook_urls:
                send_webhook(
                    data,
                    "Arknights: Endfield",
                    url,
                    image_url
                )

    else:
        print("Game: no change")


if __name__ == "__main__":
    check_for_updates()