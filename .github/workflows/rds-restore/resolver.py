import subprocess
import json
import sys
from datetime import datetime, timedelta
import pytz

AWS_REGION = "il-central-1"

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode().strip()
    except subprocess.CalledProcessError as e:
        print(f"AWS command failed: {e}")
        sys.exit(1)

def get_instance(db):
    cmd = f"aws rds describe-db-instances --db-instance-identifier {db} --region {AWS_REGION}"
    data = json.loads(run(cmd))

    if not data.get("DBInstances"):
        print(f"DB not found: {db}")
        sys.exit(1)

    return data["DBInstances"][0]

def get_snapshots(db):
    cmd = f"aws rds describe-db-snapshots --db-instance-identifier {db} --region {AWS_REGION}"
    data = json.loads(run(cmd))
    return data.get("DBSnapshots", [])

def build_time(day_offset, hour, minute):
    tz = pytz.timezone("Asia/Jerusalem")
    now = datetime.now(tz)

    target = now - timedelta(days=int(day_offset))
    target = target.replace(
        hour=int(hour),
        minute=int(minute),
        second=0,
        microsecond=0
    )

    return target.astimezone(pytz.utc)

def main():
    if len(sys.argv) < 5:
        print("Usage: resolver.py <db> <day_offset> <hour> <minute>")
        sys.exit(1)

    db = sys.argv[1]
    day_offset = sys.argv[2]
    hour = sys.argv[3]
    minute = sys.argv[4]

    incident = build_time(day_offset, hour, minute)

    instance = get_instance(db)

    earliest = instance.get("EarliestRestorableTime")
    latest = instance.get("LatestRestorableTime")

    # ---------------- DEBUG BASE ----------------
    debug = {
        "incident_utc": incident.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "latest_utc": latest,
        "earliest_utc": earliest
    }

    # ---------------- NO PITR → SNAPSHOT ----------------
    if earliest is None or latest is None:
        snaps = get_snapshots(db)

        if not snaps:
            print("No snapshots found")
            sys.exit(1)

        snaps.sort(key=lambda x: x["SnapshotCreateTime"], reverse=True)

        result = {
            "mode": "SNAPSHOT",
            "snapshot_id": snaps[0]["DBSnapshotIdentifier"],
            "debug": {
                **debug,
                "reason": "PITR not available (earliest/latest null)"
            }
        }

        print(json.dumps(result))
        return

    # ---------------- CONVERT TIMES ----------------
    latest_dt = datetime.fromisoformat(latest.replace("Z","+00:00"))

    earliest_dt = None
    if earliest:
        earliest_dt = datetime.fromisoformat(earliest.replace("Z","+00:00"))

    debug["latest_utc"] = latest_dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    debug["earliest_utc"] = earliest_dt.strftime("%Y-%m-%dT%H:%M:%SZ") if earliest_dt else None

    # ---------------- PITR LOGIC ----------------

    # ✔ בתוך חלון PITR
    if earliest_dt and earliest_dt < incident <= latest_dt:
        result = {
            "mode": "PITR",
            "restore_time": incident.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "debug": debug
        }
        print(json.dumps(result))
        return

    # ✔ אם הזמן מאוחר מדי
    if incident > latest_dt:
        result = {
            "mode": "PITR",
            "restore_time": latest_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "debug": debug
        }
        print(json.dumps(result))
        return

    # ---------------- SNAPSHOT FALLBACK ----------------
    snaps = get_snapshots(db)

    if not snaps:
        print("No snapshots found")
        sys.exit(1)

    snaps.sort(key=lambda x: x["SnapshotCreateTime"], reverse=True)

    for s in snaps:
        snap_time = datetime.fromisoformat(s["SnapshotCreateTime"].replace("Z","+00:00"))

        if snap_time <= incident:
            result = {
                "mode": "SNAPSHOT",
                "snapshot_id": s["DBSnapshotIdentifier"],
                "debug": debug
            }
            print(json.dumps(result))
            return

    print("No valid snapshot found")
    sys.exit(1)

if __name__ == "__main__":
    main()