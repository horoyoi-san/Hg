import requests
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime

URL = "https://endfield.gryphline.com/en-us/news"

headers = {
    "User-Agent": "Mozilla/5.0"
}

response = requests.get(
    URL,
    headers=headers,
    timeout=20
)

print("STATUS:", response.status_code)

html = response.text

soup = BeautifulSoup(html, "html.parser")

text = soup.get_text("\n", strip=True)

# DEBUG
print(text[:2000])

# หา Version Update Notes
matches = re.findall(
    r"(\d{4}-\d{2}-\d{2}).{0,80}?Version Update Notes",
    text,
    re.IGNORECASE | re.DOTALL
)

data = {}

for i, date_str in enumerate(matches, start=1):

    dt = datetime.strptime(
        date_str,
        "%Y-%m-%d"
    )

    version = f"1.{i}"

    data[version] = dt.isoformat()

with open(
    "versions.json",
    "w",
    encoding="utf-8"
) as f:

    json.dump(
        data,
        f,
        indent=4,
        ensure_ascii=False
    )

print("\nFOUND:")
print(json.dumps(data, indent=4))