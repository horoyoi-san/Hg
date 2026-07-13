# Hoyo Discord Timeline Webhooks

โปรเจกต์นี้ใช้ส่ง timeline จากไฟล์ใน `data/` ไปยัง Discord ด้วย Discord Bot Token
หรือ webhook fallback

## วิธีตั้งค่า

1. สร้างไฟล์ `.env` ที่ root ของโปรเจกต์
2. ใส่ Discord bot token และ channel ID ของแต่ละไฟล์
3. รันไฟล์ webhook ที่ต้องการส่ง

ตัวอย่าง `.env`:

```env
DISCORD_BOT_TOKEN=YOUR_BOT_TOKEN

DISCORD_HK4E_CHANNEL_ID=YOUR_HK4E_CHANNEL_ID
DISCORD_HKRPG_CHANNEL_ID=YOUR_HKRPG_CHANNEL_ID
DISCORD_BH3_CHANNEL_ID=YOUR_BH3_CHANNEL_ID
DISCORD_NAP_CHANNEL_ID=YOUR_NAP_CHANNEL_ID
DISCORD_HYG_CHANNEL_ID=YOUR_HYG_CHANNEL_ID
DISCORD_ABC_CHANNEL_ID=YOUR_ABC_CHANNEL_ID

# Optional fallback: used only when bot token/channel is not set.
DISCORD_WEBHOOK_URL=YOUR_DISCORD
```

## ไฟล์กับ Channel ID

| ไฟล์ | Env ที่ใช้ |
| --- | --- |
| `webhook/webhook hk4e.py` | `DISCORD_HK4E_CHANNEL_ID` |
| `webhook/webhook hkrpg.py` | `DISCORD_HKRPG_CHANNEL_ID` |
| `webhook/webhook bh3.py` | `DISCORD_BH3_CHANNEL_ID` |
| `webhook/webhook nap.py` | `DISCORD_NAP_CHANNEL_ID` |
| `webhook/webhook hyg.py` | `DISCORD_HYG_CHANNEL_ID` |
| `webhook/webhook abc.py` | `DISCORD_ABC_CHANNEL_ID` |

## วิธีรัน

ติดตั้ง dependency:

```bash
pip install requests
```

สร้างหรืออัปเดตไฟล์ timeline ใน `data/`:

```bash
python "Timeline/Timeline Genshin Impact.py"
python "Timeline/Timeline Honkai Star Rail.py"
python "Timeline/Timeline Honkai Impact 3rd.py"
```

ตัวอย่างรันไฟล์:

```bash
python "webhook/webhook hk4e.py"
python "webhook/webhook hkrpg.py"
python "webhook/webhook bh3.py"
```

## หมายเหตุ

- ห้ามอัปโหลดไฟล์ `.env` ขึ้น repo เพราะมี bot token จริง
- ไฟล์ `.gitignore` ignore `.env` ไว้แล้ว
- ให้ใช้ `.env.example` เป็นตัวอย่างสำหรับคนอื่นใน repo
- Bot ต้องอยู่ใน Discord server และต้องมี permission `Send Messages` กับ `Embed Links`
