"""
standup/scripts/setup_sample_data.py
─────────────────────────────────────
Loads baseline sample data required by the Standup mobile app.

Run via bench (idempotent — safe to call on every `docker compose up`):
    bench --site <site> execute standup.scripts.setup_sample_data.run

What is created
───────────────
• Holiday List "Public Holidays" with Indian public holidays for 2026.

Idempotency
───────────
Each fixture is guarded by a frappe.db.exists() check before insertion.
Re-running this script on an already-configured site is a no-op.
"""

from __future__ import annotations

import frappe
from frappe import _


# ─── Fixtures ────────────────────────────────────────────────────────────────

_PUBLIC_HOLIDAYS = [
    ("2026-01-01", "New Year's Day"),
    ("2026-01-14", "Makar Sankranti / Pongal"),
    ("2026-01-26", "Republic Day"),
    ("2026-03-03", "Holi"),
    ("2026-03-20", "Eid al-Fitr"),
    ("2026-04-03", "Good Friday"),
    ("2026-04-14", "Dr. Ambedkar Jayanti"),
    ("2026-05-01", "Maharashtra Day / Labour Day"),
    ("2026-08-15", "Independence Day"),
    ("2026-10-02", "Gandhi Jayanti"),
    ("2026-10-20", "Dussehra"),
    ("2026-10-27", "Eid al-Adha"),
    ("2026-11-08", "Diwali"),
    ("2026-11-09", "Diwali (Laxmi Puja)"),
    ("2026-12-25", "Christmas Day"),
]


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _setup_public_holidays() -> None:
    list_name = "Public Holidays"

    if frappe.db.exists("Holiday List", list_name):
        print(f"  [skip] Holiday List '{list_name}' already exists.", flush=True)
        return

    doc = frappe.get_doc({
        "doctype":      "Holiday List",
        "holiday_list_name": list_name,
        "from_date":    "2026-01-01",
        "to_date":      "2026-12-31",
        "holidays": [
            {
                "holiday_date": date,
                "description":  name,
                "weekly_off":   0,
            }
            for date, name in _PUBLIC_HOLIDAYS
        ],
    })
    doc.insert(ignore_permissions=True)
    frappe.db.commit()
    print(f"  [created] Holiday List '{list_name}' with {len(_PUBLIC_HOLIDAYS)} entries.", flush=True)


# ─── Entry point ─────────────────────────────────────────────────────────────

def run() -> None:
    """
    Main entry point called by `bench execute`.
    Each fixture function is responsible for its own idempotency check.
    """
    print("=== Standup: loading sample data ===", flush=True)
    _setup_public_holidays()
    print("=== Done ===", flush=True)
