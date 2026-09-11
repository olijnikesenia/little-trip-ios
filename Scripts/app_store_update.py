#!/usr/bin/env python3
"""Apply Little Walk metadata to its existing App Store Connect record."""

import json
import os
from pathlib import Path
import urllib.error
import urllib.request

BASE = "https://api.appstoreconnect.apple.com"
TOKEN = os.environ["ASC_JWT"]
APP_ID = "6811079070"
BUNDLE_RESOURCE_ID = "5823Q3S5QB"
INFO_ID = "451bbe71-a805-4c3e-bf0d-8e6a85d62a5a"
INFO_LOCALIZATION_ID = "564b2c3c-2b77-4c48-a24f-8dd1c08f8cf3"
VERSION_ID = "51e34329-a6fc-4ba1-be40-6c3e94c26355"
VERSION_LOCALIZATION_ID = "47c7b06b-fcff-4f22-a45c-4e73ef01ed12"

ROOT = Path(__file__).resolve().parents[1]
METADATA = json.loads((ROOT / "AppStore/Metadata-en-US.json").read_text())
REVIEW_NOTES = (ROOT / "AppStore/ReviewNotes-en-US.txt").read_text().strip()


def request(method: str, path: str, payload=None, allow_not_found=False):
    body = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        BASE + path,
        data=body,
        method=method,
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        if allow_not_found and error.code == 404:
            return None
        detail = error.read().decode()
        raise RuntimeError(f"{method} {path} failed ({error.code}): {detail}") from error


def patch(resource_type: str, resource_id: str, path: str, attributes=None, relationships=None):
    data = {"type": resource_type, "id": resource_id}
    if attributes is not None:
        data["attributes"] = attributes
    if relationships is not None:
        data["relationships"] = relationships
    return request("PATCH", path, {"data": data})


patch("bundleIds", BUNDLE_RESOURCE_ID, f"/v1/bundleIds/{BUNDLE_RESOURCE_ID}", {"name": METADATA["productName"]})
print("Bundle name updated")

patch(
    "appInfoLocalizations",
    INFO_LOCALIZATION_ID,
    f"/v1/appInfoLocalizations/{INFO_LOCALIZATION_ID}",
    {
        "name": METADATA["name"],
        "subtitle": METADATA["subtitle"],
        "privacyPolicyUrl": METADATA["privacyPolicyUrl"],
    },
)
print("App name, subtitle and privacy URL updated")

patch(
    "appStoreVersionLocalizations",
    VERSION_LOCALIZATION_ID,
    f"/v1/appStoreVersionLocalizations/{VERSION_LOCALIZATION_ID}",
    {
        "description": METADATA["description"],
        "keywords": METADATA["keywords"],
        "marketingUrl": METADATA["marketingUrl"],
        "promotionalText": METADATA["promotionalText"],
        "supportUrl": METADATA["supportUrl"],
    },
)
print("English version metadata updated")

patch(
    "appInfos",
    INFO_ID,
    f"/v1/appInfos/{INFO_ID}",
    relationships={
        "primaryCategory": {"data": {"type": "appCategories", "id": METADATA["category"]}},
        "secondaryCategory": {"data": {"type": "appCategories", "id": METADATA["secondaryCategory"]}},
    },
)
print("Categories updated")

patch(
    "apps",
    APP_ID,
    f"/v1/apps/{APP_ID}",
    {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
)
patch(
    "appStoreVersions",
    VERSION_ID,
    f"/v1/appStoreVersions/{VERSION_ID}",
    {"copyright": METADATA["copyright"], "releaseType": "AFTER_APPROVAL", "usesIdfa": False},
)
print("Rights and release settings updated")

frequencies = [
    "alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated",
    "gunsOrOtherWeapons", "medicalOrTreatmentInformation", "profanityOrCrudeHumor",
    "sexualContentGraphicAndNudity", "sexualContentOrNudity", "horrorOrFearThemes",
    "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
    "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic",
]
booleans = [
    "advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat",
    "parentalControls", "ageAssurance", "socialMedia", "socialMediaAgeRestricted",
    "unrestrictedWebAccess", "userGeneratedContent",
]
rating = {name: "NONE" for name in frequencies}
rating.update({name: False for name in booleans})
rating.update({"kidsAgeBand": None, "ageRatingOverrideV2": "NONE", "koreaAgeRatingOverride": "NONE"})
patch("ageRatingDeclarations", INFO_ID, f"/v1/ageRatingDeclarations/{INFO_ID}", rating)
print("Age rating updated")

existing_review = request("GET", f"/v1/appStoreVersions/{VERSION_ID}/appStoreReviewDetail")
review_attributes = {
    "contactFirstName": "Pedro",
    "contactLastName": "Lord",
    "contactPhone": "+17124857409",
    "contactEmail": "info@pedrolord8578w.site",
    "demoAccountRequired": False,
    "notes": REVIEW_NOTES,
}
if existing_review.get("data"):
    review_id = existing_review["data"]["id"]
    patch("appStoreReviewDetails", review_id, f"/v1/appStoreReviewDetails/{review_id}", review_attributes)
else:
    request(
        "POST",
        "/v1/appStoreReviewDetails",
        {"data": {"type": "appStoreReviewDetails", "attributes": review_attributes,
                  "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}}}}},
    )
print("App Review contact and notes updated")

availability = request("GET", f"/v1/apps/{APP_ID}/appAvailabilityV2", allow_not_found=True)
if availability is None:
    territories = request("GET", "/v1/territories?limit=200")["data"]
    relationship_data, included = [], []
    for index, territory in enumerate(territories):
        placeholder = f"${{territory-{index}}}"
        relationship_data.append({"type": "territoryAvailabilities", "id": placeholder})
        included.append({
            "type": "territoryAvailabilities", "id": placeholder,
            "attributes": {"available": True, "preOrderEnabled": False},
            "relationships": {"territory": {"data": {"type": "territories", "id": territory["id"]}}},
        })
    request("POST", "/v2/appAvailabilities", {
        "data": {"type": "appAvailabilities", "attributes": {"availableInNewTerritories": True},
                 "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}},
                                   "territoryAvailabilities": {"data": relationship_data}}},
        "included": included,
    })
    print(f"Availability enabled in {len(territories)} territories")
else:
    print("Availability already configured")
