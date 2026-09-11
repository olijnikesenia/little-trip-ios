#!/usr/bin/env python3
"""Replace the largest-iPhone screenshot set with Little Trip screenshots."""

import hashlib
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.request

BASE = "https://api.appstoreconnect.apple.com/v1"
TOKEN = os.environ["ASC_JWT"]
LOCALIZATION_ID = "47c7b06b-fcff-4f22-a45c-4e73ef01ed12"
SCREENSHOT_DIRECTORY = Path(__file__).resolve().parents[1] / "AppStore/Upload/en-US"
DISPLAY_TYPE = "APP_IPHONE_67"


def request(method: str, path: str, payload=None):
    body = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(BASE + path, data=body, method=method,
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 204:
                return {}
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"{method} {path} failed ({error.code}): {error.read().decode()}") from error


sets = request("GET", f"/appStoreVersionLocalizations/{LOCALIZATION_ID}/appScreenshotSets?limit=50")["data"]
screenshot_set = next((item for item in sets if item["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE), None)
if screenshot_set is None:
    screenshot_set = request("POST", "/appScreenshotSets", {
        "data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                 "relationships": {"appStoreVersionLocalization": {"data": {
                     "type": "appStoreVersionLocalizations", "id": LOCALIZATION_ID}}}}
    })["data"]
set_id = screenshot_set["id"]

for item in request("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=50")["data"]:
    request("DELETE", f"/appScreenshots/{item['id']}")

uploaded = []
for path in sorted(SCREENSHOT_DIRECTORY.glob("*.jpg")):
    data = path.read_bytes()
    reservation = request("POST", "/appScreenshots", {
        "data": {"type": "appScreenshots", "attributes": {"fileSize": len(data), "fileName": path.name},
                 "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}
    })["data"]
    for operation in reservation["attributes"]["uploadOperations"]:
        start, length = operation["offset"], operation["length"]
        headers = {header["name"]: header["value"] for header in operation["requestHeaders"]}
        with urllib.request.urlopen(urllib.request.Request(
            operation["url"], data=data[start:start + length], method=operation["method"], headers=headers
        )) as response:
            if not 200 <= response.status < 300:
                raise RuntimeError(f"Asset upload failed with status {response.status}")
    screenshot_id = reservation["id"]
    request("PATCH", f"/appScreenshots/{screenshot_id}", {
        "data": {"type": "appScreenshots", "id": screenshot_id,
                 "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}
    })
    uploaded.append(screenshot_id)
    print(f"Uploaded {path.name}")

for screenshot_id in uploaded:
    state = "UPLOAD_COMPLETE"
    for _ in range(30):
        item = request("GET", f"/appScreenshots/{screenshot_id}")["data"]
        state = item["attributes"]["assetDeliveryState"]["state"]
        if state in {"COMPLETE", "FAILED"}:
            break
        time.sleep(2)
    print(f"Processed {item['attributes']['fileName']}: {state}")
    if state == "FAILED":
        raise RuntimeError(json.dumps(item["attributes"]["assetDeliveryState"]))
