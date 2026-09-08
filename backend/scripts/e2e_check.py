#!/usr/bin/env python3
"""End-to-end endpoint check for the Nway Love Vet Clinic API.

Read-only for existing data; it creates one temp record and deletes it again.
Run with the API server up:  python3 scripts/e2e_check.py
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

BASE = os.environ.get("BASE", "http://127.0.0.1:5050")
PASS = 0
FAIL = 0
FAILURES = []


def req(method, path, token=None, body=None):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Content-Type", "application/json")
    if token:
        r.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(r, timeout=15) as resp:
            return resp.status, json.loads(resp.read() or "{}")
    except urllib.error.HTTPError as e:
        try:
            payload = json.loads(e.read() or "{}")
        except Exception:
            payload = {}
        return e.code, payload
    except Exception as e:  # noqa: BLE001
        return 0, {"error": str(e)}


def check(desc, expected, actual):
    global PASS, FAIL
    if expected == actual:
        PASS += 1
        print(f"  ok   {desc} ({actual})")
    else:
        FAIL += 1
        FAILURES.append(f"{desc}: expected {expected} got {actual}")
        print(f"  FAIL {desc} (expected {expected} got {actual})")


def login(username, password):
    st, body = req("POST", "/auth/login", body={"username": username, "password": password})
    return body.get("token", ""), st


def get_status(token, table):
    return req("GET", f"/data/{table}", token=token)[0]


print("== 1. Infra ==")
check("GET / root", 200, req("GET", "/")[0])
st, health = req("GET", "/health")
check("GET /health", 200, st)
check("health db connected", "connected", health.get("database"))

print("== 2. Auth ==")
check("login bad password 401", 401, req("POST", "/auth/login", body={"username": "admin", "password": "wrong"})[0])
check("login missing fields 400", 400, req("POST", "/auth/login", body={})[0])
check("data without token 401", 401, req("GET", "/data/pets")[0])

admin_t, _ = login("admin", "Admin@123")
owner_t, _ = login("petowner", "Owner@123")
doctor_t, _ = login("doctor", "Doctor@123")
staff_t, _ = login("staff", "Staff@123")
check("admin login token", True, bool(admin_t))
check("owner login token", True, bool(owner_t))
check("doctor login token", True, bool(doctor_t))
check("staff login token", True, bool(staff_t))
check("pet-owner alias login", 200, req("POST", "/auth/pet-owner/login", body={"username": "petowner", "password": "Owner@123"})[0])

print("== 3. Unknown table 404 ==")
check("unknown table", 404, get_status(admin_t, "no_such_table"))

print("== 4. Read access matrix ==")
for t in ["clinic_directory", "pets", "appointments", "reminders", "health_posts", "inventory"]:
    check(f"owner reads {t}", 200, get_status(owner_t, t))
for t in ["doctor_profiles", "user_directory", "payments", "medical_records"]:
    check(f"owner denied {t}", 403, get_status(owner_t, t))
check("doctor reads doctor_profiles", 200, get_status(doctor_t, "doctor_profiles"))
check("doctor reads medical_records", 200, get_status(doctor_t, "medical_records"))
check("doctor denied user_directory", 403, get_status(doctor_t, "user_directory"))
check("doctor denied payments", 403, get_status(doctor_t, "payments"))
check("staff reads walk_in_appointments", 200, get_status(staff_t, "walk_in_appointments"))
check("staff reads payments", 200, get_status(staff_t, "payments"))
check("staff reads staff_profiles", 200, get_status(staff_t, "staff_profiles"))
check("staff denied user_directory", 403, get_status(staff_t, "user_directory"))
check("admin reads user_directory", 200, get_status(admin_t, "user_directory"))
check("admin reads audit_logs", 200, get_status(admin_t, "audit_logs"))
check("admin reads admin_profiles", 200, get_status(admin_t, "admin_profiles"))

print("== 5. Sync round-trip (owner pets create/update/delete) ==")
rid = f"e2e-{int(time.time())}"


def sync(changes=None, deletions=None):
    return req("POST", "/data/pets/sync", token=owner_t,
               body={"changes": changes or [], "deletions": deletions or []})


st, body = sync(changes=[{"id": rid, "version": 0, "data": {"key": rid, "value": {"name": "E2E Pet"}}}])
recs = body.get("records", [])
check("create returns version 1", 1, recs[0]["version"] if recs else None)
# stale update: client still at version 0 while server is at 1 -> 409
check("stale update 409", 409, sync(changes=[{"id": rid, "version": 0, "data": {"key": rid, "value": {"name": "Stale"}}}])[0])
# correct update at version 1 -> 2
st, body = sync(changes=[{"id": rid, "version": 1, "data": {"key": rid, "value": {"name": "E2E Pet v2"}}}])
recs = body.get("records", [])
check("update returns version 2", 2, recs[0]["version"] if recs else None)
# readable
_, listing = req("GET", "/data/pets", token=owner_t)
check("record readable after update", True, any(x["id"] == rid for x in listing.get("records", [])))
# invalid batch
check("invalid record 400", 400, sync(changes=[{"id": "x", "version": "nope", "data": {}}])[0])
# delete at version 2
check("delete 200", 200, sync(deletions=[{"id": rid, "version": 2}])[0])
_, listing = req("GET", "/data/pets", token=owner_t)
check("record removed after delete", False, any(x["id"] == rid for x in listing.get("records", [])))

print("== 6. Read-only enforcement ==")
check("owner write health_posts 403", 403, req("POST", "/data/health_posts/sync", token=owner_t,
      body={"changes": [{"id": "hp1", "version": 0, "data": {"key": "hp1", "value": {"t": "x"}}}]})[0])

print("== 7. Logout ==")
check("logout 200", 200, req("POST", "/auth/logout", token=staff_t)[0])
check("reuse after logout 401", 401, get_status(staff_t, "walk_in_appointments"))

print("\n===================================")
print(f"PASS={PASS}  FAIL={FAIL}")
if FAIL:
    for f in FAILURES:
        print(" -", f)
    sys.exit(1)
print("ALL ENDPOINTS OK")
