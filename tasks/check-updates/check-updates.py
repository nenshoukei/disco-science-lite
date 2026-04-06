"""Check for updates to supported mods by comparing file checksums."""

import argparse
import hashlib
import json
import os
import platform
import sys
import zipfile
import zlib
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.request import urlopen, Request, HTTPError

SCRIPT_DIR = Path(__file__).parent
MODS_DIR = SCRIPT_DIR.parent.parent / "scripts" / "prototype" / "mods"
DOWNLOAD_DIR = SCRIPT_DIR / ".downloaded"
API_BASE = "https://mods.factorio.com"


def get_factorio_user_dir() -> Path:
    system = platform.system()
    if system == "Darwin":
        return Path.home() / "Library/Application Support/factorio"
    elif system == "Windows":
        return Path(os.environ["APPDATA"]) / "Factorio"
    else:
        return Path.home() / ".factorio"


def load_credentials() -> tuple[str, str]:
    username = os.environ.get("FACTORIO_SERVICE_USERNAME")
    token = os.environ.get("FACTORIO_SERVICE_TOKEN")
    if username and token:
        return username, token

    user_dir = get_factorio_user_dir()
    player_data_path = user_dir / "player-data.json"
    if not player_data_path.exists():
        print(f"Error: player-data.json not found at {player_data_path}", file=sys.stderr)
        sys.exit(1)

    with open(player_data_path) as f:
        player_data = json.load(f)

    username = player_data.get("service-username")
    token = player_data.get("service-token")
    if not username or not token:
        print("Error: service-username or service-token not found in player-data.json", file=sys.stderr)
        sys.exit(1)

    return username, token


def api_get(url: str) -> dict:
    with urlopen(url) as resp:
        return json.loads(resp.read())


def get_zip_top_dir(zf: zipfile.ZipFile) -> str:
    top_dirs = {name.split("/")[0] for name in zf.namelist() if "/" in name}
    top_dirs.discard("__MACOSX")
    if len(top_dirs) != 1:
        raise ValueError(f"Expected one top-level directory in zip, found: {top_dirs}")
    return top_dirs.pop()


def find_line_index(
    lines: list[bytes],
    spec: "int | str",
    name: str,
    file_path: str,
    label: str,
    search_from: int = 0,
) -> int:
    """Return 0-based line index for a line_from/line_to spec (int=1-based line number, str=content pattern)."""
    if isinstance(spec, int):
        if spec < 1 or spec > len(lines):
            raise ValueError(f"{name}: {file_path}: {label}={spec} out of range (file has {len(lines)} lines)")
        return spec - 1
    for i in range(search_from, len(lines)):
        if lines[i].rstrip(b"\r\n").decode(errors="replace") == spec:
            return i
    raise ValueError(f"{name}: {file_path}: {label} pattern not found: {spec!r}")


def sha1_file(path: Path) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def load_mod_files() -> list[tuple[Path, dict]]:
    """Load all *.json files from MODS_DIR. Returns list of (path, parsed_json)."""
    result = []
    for path in sorted(MODS_DIR.glob("*.json")):
        if path.name == "_schema.json":
            continue
        try:
            with open(path) as f:
                result.append((path, json.load(f)))
        except Exception as e:
            print(f"Error while loading {path.name}: {e}", file=sys.stderr)
            raise e
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Check for updates to supported Factorio mods")
    parser.add_argument("--full", action="store_true", help="Re-check all mods, not just ones missing file checksums")
    args = parser.parse_args()

    username, token = load_credentials()
    user_dir = get_factorio_user_dir()

    has_error = False

    mod_files = load_mod_files()
    mods: list[dict] = []
    for path, mod_file in mod_files:
        try:
            mods.extend(mod_file["mods"])
        except Exception as e:
            print(f"Error while loading {path}: {e}", file=sys.stderr)
            raise e
    mod_by_name = {m["name"]: m for m in mods}

    # Download targets: list of {name, download_url, version, sha1}
    download_targets: list[dict] = []
    already_queued: set[str] = set()

    def add_target(name: str, download_url: str, version: str, sha1: str) -> None:
        if name not in already_queued:
            already_queued.add(name)
            download_targets.append({"name": name, "download_url": download_url, "version": version, "sha1": sha1})

    def has_missing_checksums(mod: dict) -> bool:
        for f in mod.get("files", []):
            ranges = f.get("ranges")
            if ranges is not None:
                if any(r.get("size") is None or r.get("crc") is None for r in ranges):
                    return True
            else:
                if f.get("size") is None or f.get("crc") is None:
                    return True
        return False

    # --- Full lookup: mods with any file missing size/crc, or all mods when --full ---
    full_lookup_mods = [m for m in mods if args.full or has_missing_checksums(m)]
    if full_lookup_mods:
        names = [m["name"] for m in full_lookup_mods]
        found_names: set[str] = set()
        for i in range(0, len(names), 20):
            batch = names[i : i + 20]
            url = f"{API_BASE}/api/mods?namelist={','.join(batch)}"
            print(f"GET {url}")
            data = api_get(url)
            for result in data.get("results", []):
                found_names.add(result["name"])
                releases = result.get("releases", [])
                if releases:
                    latest = releases[-1]
                    add_target(result["name"], latest["download_url"], latest["version"], latest["sha1"])
        missing_names = [n for n in names if n not in found_names]
        if missing_names:
            for n in missing_names:
                print(f"Error: mod '{n}' not found on mod portal (name may be wrong or mod was removed)", file=sys.stderr)
            sys.exit(1)

    # --- Incremental lookup: mods not covered by full lookup ---
    full_lookup_names = {m["name"] for m in full_lookup_mods}
    recent_check_mods = [m for m in mods if m["name"] not in full_lookup_names]
    if recent_check_mods:
        recent_check_by_name = {m["name"]: m for m in recent_check_mods}
        page = 1
        while True:
            url = f"{API_BASE}/api/mods?sort=updated_at&sort_order=desc&version=2.0&page={page}&page_size=100"
            print(f"GET {url}")
            data = api_get(url)
            results = data.get("results", [])
            if not results:
                break

            for result in results:
                name = result["name"]
                if name not in recent_check_by_name:
                    continue
                latest_release = result.get("latest_release")
                if not latest_release:
                    continue
                add_target(name, latest_release["download_url"], latest_release["version"], latest_release["sha1"])

            # Continue to next page only if the last result was updated within 25 hours
            last = results[-1]
            last_released_at = (last.get("latest_release") or {}).get("released_at")
            if not last_released_at:
                break
            try:
                released_dt = datetime.fromisoformat(last_released_at.replace("Z", "+00:00"))
                if datetime.now(timezone.utc) - released_dt > timedelta(hours=25):
                    break
            except ValueError:
                break

            page += 1

    if not download_targets:
        print("No updates detected.")
        return

    # --- Download and check each target ---
    DOWNLOAD_DIR.mkdir(exist_ok=True)

    for target in download_targets:
        name = target["name"]
        version = target["version"]
        expected_sha1 = target["sha1"]
        zip_filename = f"{name}_{version}.zip"
        print(f"Checking {name} {version}")

        user_zip = user_dir / "mods" / zip_filename
        cached_zip = DOWNLOAD_DIR / zip_filename

        if user_zip.exists():
            zip_path = user_zip
        elif cached_zip.exists():
            zip_path = cached_zip
        else:
            url = f"{API_BASE}{target['download_url']}?username={username}&token={token}"
            req = Request(url, headers={"User-Agent": "Mozilla/5.0 mokkosu55/check-updates"})
            print(f"Downloading {zip_filename}...")
            try:
                with urlopen(req) as resp:
                    cached_zip.write_bytes(resp.read())
            except HTTPError as e:
                print(f"Error downloading {zip_filename}: {e}", file=sys.stderr)
                print(f"Response body: {e.read().decode()}", file=sys.stderr)
                has_error = True
                continue
            except Exception as e:
                print(f"Error downloading {zip_filename}: {e}", file=sys.stderr)
                has_error = True
                continue
            zip_path = cached_zip

        # Verify SHA1
        actual_sha1 = sha1_file(zip_path)
        if actual_sha1 != expected_sha1:
            print(f"Error: SHA1 mismatch for {zip_filename}: expected {expected_sha1}, got {actual_sha1}", file=sys.stderr)
            has_error = True
            continue

        mod = mod_by_name.get(name)
        if not mod:
            continue

        # Check each monitored file
        with zipfile.ZipFile(zip_path) as zf:
            try:
                top_dir = get_zip_top_dir(zf)
            except ValueError as e:
                print(f"Error: {name}: {e}", file=sys.stderr)
                has_error = True
                continue

            for file_entry in mod.get("files", []):
                file_path = file_entry["file"]
                ranges = file_entry.get("ranges")

                if ranges is not None:
                    # Multi-range check: read file once, check each range
                    try:
                        raw = zf.read(f"{top_dir}/{file_path}")
                    except KeyError:
                        print(f"Error: {name}: {file_path} not found in zip", file=sys.stderr)
                        has_error = True
                        continue

                    lines = raw.splitlines(keepends=True)
                    search_from = 0
                    for i, range_entry in enumerate(ranges):
                        line_from = range_entry.get("line_from")
                        line_to = range_entry.get("line_to")
                        try:
                            start = find_line_index(lines, line_from, name, file_path, "line_from", search_from) if line_from is not None else 0
                            end = find_line_index(lines, line_to, name, file_path, "line_to", search_from=start) + 1 if line_to is not None else len(lines)
                        except ValueError as e:
                            print(f"Error: {name}: Failed to find ranges[{i}] in {file_path}: {e}", file=sys.stderr)
                            has_error = True
                            continue

                        search_from = end
                        extracted = b"".join(lines[start:end])
                        new_size = len(extracted)
                        new_crc = zlib.crc32(extracted) & 0xFFFFFFFF

                        prev_size = range_entry.get("size")
                        prev_crc = range_entry.get("crc")
                        if prev_size is not None and prev_crc is not None:
                            if new_size != prev_size or new_crc != prev_crc:
                                print(f"CHANGED: {name}: {file_path} ranges[{i}]")

                        range_entry["size"] = new_size
                        range_entry["crc"] = new_crc

                else:
                    # Full-file check using zip metadata
                    try:
                        info = zf.getinfo(f"{top_dir}/{file_path}")
                    except KeyError:
                        print(f"Warning: {name}: {file_path} not found in zip", file=sys.stderr)
                        continue
                    new_size = info.file_size
                    new_crc = info.CRC

                    prev_size = file_entry.get("size")
                    prev_crc = file_entry.get("crc")
                    if prev_size is not None and prev_crc is not None:
                        if new_size != prev_size or new_crc != prev_crc:
                            print(f"CHANGED: {name}: {file_path}")

                    file_entry["size"] = new_size
                    file_entry["crc"] = new_crc

    # Write updated mod JSON files
    for path, mod_file in mod_files:
        with open(path, "w") as f:
            json.dump(mod_file, f, indent=2)
            f.write("\n")

    if has_error:
        print("Some errors occurred.")
        sys.exit(1)
    else:
        print("Done successfully.")


if __name__ == "__main__":
    main()
