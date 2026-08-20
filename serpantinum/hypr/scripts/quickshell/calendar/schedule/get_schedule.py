#!/usr/bin/env python3
# Pulls today's events from a Google Calendar's private iCal feed and renders
# them into the same JSON shape CalendarPopup.qml already expects (it was
# originally fed by a Selenium scrape of a Danish school timetable site, tied
# to the original author's own Firefox profile and requiring `nix-shell` -
# which isn't even installed on this system, so that path never worked here
# at all). No new Python dependencies: only stdlib + `requests` (already
# installed), parsing the ICS format directly rather than pulling in the
# `icalendar` package.
#
# Setup: open Google Calendar -> Settings -> pick a calendar in the sidebar
# (repeat per calendar you want included) -> "Integrate calendar" -> "Secret
# address in iCal format" -> copy each URL into schedule/.env as
# GOOGLE_CALENDAR_ICS_URLS=url1,url2,... (comma-separated, gitignored, never
# committed). Events from all listed calendars are merged into one timeline,
# with identical events appearing in more than one calendar deduped.
import json
import os
from datetime import datetime, timedelta, timezone

import requests

CACHE_DIR = os.environ.get("QS_CACHE_SCHEDULE", os.path.expanduser("~/.cache/quickshell/schedule"))
CACHE_FILE = os.path.join(CACHE_DIR, "schedule.json")
ENV_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")

# The original UI is a fixed horizontal timeline shaped for a school day.
# Reused as-is for a general daily agenda - a waking-hours window rather than
# a full 24h span, so the timeline stays usefully proportioned.
DAY_START_STR = "07:00"
DAY_END_STR = "22:00"
TOTAL_AVAILABLE_WIDTH_PX = 750


def load_env():
    env = {}
    if os.path.isfile(ENV_FILE):
        with open(ENV_FILE) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip()
    return env


def unfold_ics(text):
    # RFC 5545 line folding: a line starting with a space/tab is a
    # continuation of the previous line.
    lines = text.replace("\r\n", "\n").split("\n")
    out = []
    for line in lines:
        if line.startswith(" ") or line.startswith("\t"):
            if out:
                out[-1] += line[1:]
        else:
            out.append(line)
    return out


def parse_events(ics_text):
    events = []
    cur = None
    for line in unfold_ics(ics_text):
        if line == "BEGIN:VEVENT":
            cur = {}
        elif line == "END:VEVENT":
            if cur is not None:
                events.append(cur)
            cur = None
        elif cur is not None:
            if ":" not in line:
                continue
            key, _, value = line.partition(":")
            key_base = key.split(";")[0]
            if key_base == "DTSTART":
                cur["start_raw"] = value.strip()
                cur["start_allday"] = "VALUE=DATE" in key and "VALUE=DATE-TIME" not in key
            elif key_base == "DTEND":
                cur["end_raw"] = value.strip()
            elif key_base == "SUMMARY":
                cur["summary"] = value.replace("\\,", ",").replace("\\;", ";").replace("\\n", " ")
            elif key_base == "LOCATION":
                cur["location"] = value.replace("\\,", ",").replace("\\;", ";")
    return events


def parse_ics_datetime(value):
    value = value.strip()
    if value.endswith("Z"):
        dt = datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
        return dt.astimezone().replace(tzinfo=None)
    if "T" in value:
        return datetime.strptime(value, "%Y%m%dT%H%M%S")
    return datetime.strptime(value, "%Y%m%d")  # all-day, date only


def to_epoch(dt):
    return int(dt.timestamp())


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


def build_output(events, now):
    start_h, start_m = map(int, DAY_START_STR.split(":"))
    end_h, end_m = map(int, DAY_END_STR.split(":"))
    total_minutes = (end_h * 60 + end_m) - (start_h * 60 + start_m)
    ppm = TOTAL_AVAILABLE_WIDTH_PX / total_minutes

    today = now.date()
    todays = []
    for ev in events:
        try:
            if ev.get("start_allday") or "start_raw" not in ev:
                continue  # all-day events don't fit this timeline's shape
            start_dt = parse_ics_datetime(ev["start_raw"])
            end_dt = parse_ics_datetime(ev["end_raw"]) if ev.get("end_raw") else start_dt + timedelta(hours=1)
        except Exception:
            continue
        if start_dt.date() != today:
            continue
        todays.append({
            "type": "class",
            "time": f"{start_dt.strftime('%H:%M')}-{end_dt.strftime('%H:%M')}",
            "subject": ev.get("summary", "(No title)"),
            "room": ev.get("location", ""),
            "teacher": "",
            "start": to_epoch(start_dt),
            "end": to_epoch(end_dt),
        })

    todays.sort(key=lambda x: x["start"])

    timeline_start = now.replace(hour=start_h, minute=start_m, second=0, microsecond=0)
    timeline_end = now.replace(hour=end_h, minute=end_m, second=0, microsecond=0)
    current_cursor = to_epoch(timeline_start)
    standard_end_cursor = to_epoch(timeline_end)

    processed = []
    for ev in todays:
        if ev["start"] > current_cursor:
            gap = ev["start"] - current_cursor
            if gap > 60:
                width, _ = get_layout_props(gap, ppm)
                processed.append({"type": "gap", "width": width, "desc": f"{int(gap / 60)}m",
                                   "start": current_cursor, "end": ev["start"]})
            current_cursor = ev["start"]

        if ev["end"] <= to_epoch(timeline_start):
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
    env = load_env()
    ics_urls = [u.strip() for u in env.get("GOOGLE_CALENDAR_ICS_URLS", "").split(",") if u.strip()]
    now = datetime.now()

    if not ics_urls:
        output = {"header": "No Google Calendar configured",
                   "lessons": [], "link": "https://calendar.google.com/"}
    else:
        all_events = []
        errors = []
        for url in ics_urls:
            try:
                resp = requests.get(url, timeout=10)
                resp.raise_for_status()
                all_events.extend(parse_events(resp.text))
            except Exception as e:
                # One broken calendar shouldn't take down the others.
                errors.append(str(e))

        if not all_events and errors:
            output = {"header": "Error", "link": "", "lessons": [{
                "type": "class", "time": "Error", "subject": "Check schedule/.env / connection",
                "room": "", "teacher": "; ".join(errors), "start": 0, "end": 0,
                "width": 220, "char_limit": 30, "is_compact": False,
            }]}
        else:
            # Dedupe identical events that appear in more than one calendar
            # (e.g. a shared event visible on both a primary and a shared
            # calendar) before laying out the timeline.
            seen = set()
            deduped = []
            for ev in all_events:
                key = (ev.get("start_raw"), ev.get("end_raw"), ev.get("summary"))
                if key in seen:
                    continue
                seen.add(key)
                deduped.append(ev)
            output = build_output(deduped, now)

    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(output, f)


if __name__ == "__main__":
    update_schedule()
