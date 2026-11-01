#!/usr/bin/env python3
"""Make sure each App ID has the capabilities its target's entitlements need,
then recreate its App Store provisioning profile and install it.

Run this after changing an App ID's capabilities (for example enabling
HealthKit on the iPhone app, or assigning the group.com.flip54.app App Group
to the watch app in the developer portal), since a profile only carries the
entitlements its App ID had when the profile was made. Pass bundle IDs to
regenerate only those; with none, all three are regenerated.

App Group assignment can't be done through the API; do that in the portal.

Needs pyjwt and requests (run with plain `python3`, not `python3 -I`).
"""
import sys
import base64
import os
import time

import jwt
import requests

KEY_ID = "959324PGJ9"
ISSUER = "cbf18e37-9b89-49a1-9ce2-70fbca6c1bf9"
KEY_PATH = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
API = "https://api.appstoreconnect.apple.com/v1"
INSTALL_DIR = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")
DISTRIBUTION_CERT_NAME = "Apple Distribution: Zachary Campbell"

PROFILES = {
    "com.flip54.app": "Flip 54 App Store",
    "com.flip54.app.watchkitapp": "Flip 54 Watch App Store",
    "com.flip54.app.watchkitapp.widgets": "Flip 54 Watch Widgets App Store",
}


# Capabilities the API can switch on, per App ID. HealthKit on the iPhone app
# lets it launch the watch app into a workout and receive its mirrored session.
CAPABILITIES = {
    "com.flip54.app": ["HEALTHKIT"],
    "com.flip54.app.watchkitapp": ["HEALTHKIT"],
}


def headers():
    with open(KEY_PATH) as f:
        token = jwt.encode(
            {"iss": ISSUER, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
            f.read(), algorithm="ES256", headers={"kid": KEY_ID},
        )
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def find(path, attribute, value):
    """The API's filters match loosely (com.flip54.app matches every Flip 54 ID),
    so pick the exact match out of the results."""
    r = requests.get(API + path, headers=headers())
    r.raise_for_status()
    return next((d for d in r.json()["data"] if d["attributes"][attribute] == value), None)


def main():
    certs = requests.get(API + "/certificates?filter[certificateType]=DISTRIBUTION", headers=headers()).json()["data"]
    cert_id = next(c["id"] for c in certs if c["attributes"]["name"] == DISTRIBUTION_CERT_NAME)

    wanted = sys.argv[1:] or list(PROFILES)
    for identifier in wanted:
        name = PROFILES[identifier]
        bundle = find(f"/bundleIds?filter[identifier]={identifier}&limit=200", "identifier", identifier)
        if bundle is None:
            raise SystemExit(f"App ID {identifier} is not registered")
        enable_capabilities(bundle["id"], CAPABILITIES.get(identifier, []))

        old = find(f"/profiles?filter[name]={name}&limit=200", "name", name)
        if old is not None:
            requests.delete(f"{API}/profiles/{old['id']}", headers=headers()).raise_for_status()
            stale = os.path.join(INSTALL_DIR, f"{old['attributes']['uuid']}.mobileprovision")
            if os.path.exists(stale):
                os.remove(stale)

        r = requests.post(API + "/profiles", headers=headers(), json={"data": {
            "type": "profiles",
            "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                "certificates": {"data": [{"type": "certificates", "id": cert_id}]},
            },
        }})
        r.raise_for_status()
        attrs = r.json()["data"]["attributes"]
        path = os.path.join(INSTALL_DIR, f"{attrs['uuid']}.mobileprovision")
        with open(path, "wb") as f:
            f.write(base64.b64decode(attrs["profileContent"]))
        print(f"{name}: {attrs['profileState']}, installed {attrs['uuid']}")


def enable_capabilities(bundle_id, capabilities):
    r = requests.get(f"{API}/bundleIds/{bundle_id}/bundleIdCapabilities", headers=headers())
    r.raise_for_status()
    have = {c["attributes"]["capabilityType"] for c in r.json()["data"]}
    for capability in capabilities:
        if capability in have:
            continue
        requests.post(API + "/bundleIdCapabilities", headers=headers(), json={"data": {
            "type": "bundleIdCapabilities",
            "attributes": {"capabilityType": capability},
            "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}},
        }}).raise_for_status()
        print(f"Enabled {capability}")


if __name__ == "__main__":
    main()
