#!/usr/bin/env python3
# Pulls today's events via gcalcli (https://github.com/insanum/gcalcli) and
# renders them into the same JSON shape CalendarPopup.qml already expects
# (originally fed by a Selenium scrape of a Danish school timetable site,
# tied to the original author's own Firefox profile and requiring
# `nix-shell`, which isn't even installed on this system - that path never
# worked here at all).
#
# gcalcli authenticates once via OAuth against your whole Google account, so
# it sees every calendar you have without per-calendar setup - see
# docs/api-auth.md in the gcalcli repo for the one-time Google Cloud project
# + `gcalcli --client-id=... init` setup. After that initial `init`, this
# script needs no further auth handling; gcalcli reuses its cached token.
import json
import os
import shutil
import subprocess
from datetime import datetime, timedelta

CACHE_DIR = os.environ.get("QS_CACHE_SCHEDULE", os.path.expanduser("~/.cache/quickshell/schedule"))
CACHE_FILE = os.path.join(CACHE_DIR, "schedule.json")

# The UI is a fixed horizontal timeline shaped for a school day originally -
# reused as a waking-hours window for a general daily agenda.
DAY_START_STR = "07:00"
DAY_END_STR = "22:00"
TOTAL_AVAILABLE_WIDTH_PX = 750


def get_layout_props(duration_seconds, ppm):
    duration_seconds = max(0, duration_seconds)
    minutes = duration_seconds / 60
    width = minutes * ppm
    return int(width), int(width / 5)


def format_header(date_obj, now):
    delta = (date_obj.date() - now.date()).days
    date_str = date_obj.strftime("%A, %d %b")
    suffix = "(Today)" if delta == 0 else "(Tomorrow)" if delta == 1 else ""
    return f"{date_str} {suffix}".strip()


def fetch_gcalcli_events():
    result = subprocess.run(
        ["gcalcli", "agenda", "today", "tomorrow", "--details", "location", "--json"],
        capture_output=True, text=True, timeout=20,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "gcalcli exited non-zero")
    return json.loads(result.stdout)


def build_output(raw_events, now):
    start_h, start_m = map(int, DAY_START_STR.split(":"))
    end_h, end_m = map(int, DAY_END_STR.split(":"))
    total_minutes = (end_h * 60 + end_m) - (start_h * 60 + start_m)
    ppm = TOTAL_AVAILABLE_WIDTH_PX / total_minutes

    today = now.date()
    todays = []
    for ev in raw_events:
        # All-day events have no start_time/end_time (gcalcli's Time handler
        # leaves them blank) - skip, they don't fit this timeline's shape.
        if not ev.get("start_time") or not ev.get("end_time"):
            continue
        try:
            start_dt = datetime.strptime(f"{ev['start_date']} {ev['start_time']}", "%Y-%m-%d %H:%M")
            end_dt = datetime.strptime(f"{ev['end_date']} {ev['end_time']}", "%Y-%m-%d %H:%M")
        except (KeyError, ValueError):
            continue
        if start_dt.date() != today:
            continue
        todays.append({
            "type": "class",
            "time": f"{start_dt.strftime('%H:%M')}-{end_dt.strftime('%H:%M')}",
            "subject": ev.get("title") or "(No title)",
            "room": ev.get("location", ""),
            "teacher": "",
            "start": int(start_dt.timestamp()),
            "end": int(end_dt.timestamp()),
        })

    todays.sort(key=lambda x: x["start"])

    timeline_start = now.replace(hour=start_h, minute=start_m, second=0, microsecond=0)
    timeline_end = now.replace(hour=end_h, minute=end_m, second=0, microsecond=0)
    current_cursor = int(timeline_start.timestamp())
    standard_end_cursor = int(timeline_end.timestamp())

    processed = []
    for ev in todays:
        if ev["start"] > current_cursor:
            gap = ev["start"] - current_cursor
            if gap > 60:
                width, _ = get_layout_props(gap, ppm)
                processed.append({"type": "gap", "width": width, "desc": f"{int(gap / 60)}m",
                                   "start": current_cursor, "end": ev["start"]})
            current_cursor = ev["start"]

        if ev["end"] <= int(timeline_start.timestamp()):
            continue

        if ev["start"] >= current_cursor:
            duration = ev["end"] - current_cursor
            width, char_limit = get_layout_props(duration, ppm)
            ev["width"] = width
            ev["char_limit"] = char_limit
            ev["is_compact"] = width < 70
            processed.append(ev)
            current_cursor = ev["end"]

    if current_cursor < standard_end_cursor:
        gap = standard_end_cursor - current_cursor
        if gap > 60:
            width, _ = get_layout_props(gap, ppm)
            processed.append({"type": "gap", "width": width, "desc": "Free",
                               "start": current_cursor, "end": standard_end_cursor})

    header = format_header(now, now) if todays else "No events today"
    return {"header": header, "lessons": processed, "link": "https://calendar.google.com/"}


def update_schedule():
    now = datetime.now()

    if not shutil.which("gcalcli"):
        output = {"header": "gcalcli not installed", "lessons": [], "link": "https://calendar.google.com/"}
    else:
        try:
            raw_events = fetch_gcalcli_events()
            output = build_output(raw_events, now)
        except Exception as e:
            output = {"header": "Error", "link": "", "lessons": [{
                "type": "class", "time": "Error", "subject": "Run: gcalcli agenda",
                "room": "", "teacher": str(e), "start": 0, "end": 0,
                "width": 220, "char_limit": 30, "is_compact": False,
            }]}

    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(output, f)


if __name__ == "__main__":
    update_schedule()
