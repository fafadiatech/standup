"""
standup/scripts/setup_sample_data.py
─────────────────────────────────────
Loads baseline sample data required by the Standup mobile app.

Run via bench (idempotent — safe to call on every `docker compose up`):
    bench --site <site> execute standup.scripts.setup_sample_data.run

What is created
───────────────
• Holiday List  "Public Holidays"         — 15 Indian public holidays (2026)
• Leave Types   Casual / Sick / Privilege — standard HR leave buckets
• Departments   Engineering, Human Resources, Product
• Designations  Software Engineer, HR Manager, Product Manager
• Users         4 test employees with passwords  (Test@1234)
• Employees     Linked to the above users
• Leave Allocs  Each employee gets a full-year allocation per leave type
• Leave Apps    6 sample applications in Open / Approved / Rejected states

Idempotency
───────────
Every fixture is guarded by frappe.db.exists() before insertion.
Re-running this script on an already-configured site is a no-op.
"""

from __future__ import annotations

import frappe
from frappe.utils import date_diff, now_datetime
from frappe.utils.password import update_password


# ─── Fixture data ────────────────────────────────────────────────────────────

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

# (name, max_days_allowed, allow_negative, is_lwp)
_LEAVE_TYPES = [
    ("Casual Leave",   3,  0, 0),
    ("Sick Leave",     0,  1, 0),  # allow_negative so balance never blocks sick leave
    ("Privilege Leave", 0, 0, 0),
]

_DEPARTMENTS = ["Engineering", "Human Resources", "Product"]

_DESIGNATIONS = ["Software Engineer", "HR Manager", "Product Manager"]

# email, first_name, last_name, gender, dob, doj, department, designation, roles
_EMPLOYEES = [
    (
        "alice.johnson@example.com", "Alice", "Johnson",
        "Female", "1992-08-12", "2023-03-01",
        "Engineering", "Software Engineer",
        ["Employee", "Leave Approver"],
    ),
    (
        "bob.smith@example.com", "Bob", "Smith",
        "Male", "1990-04-22", "2022-08-15",
        "Engineering", "Software Engineer",
        ["Employee"],
    ),
    (
        "carol.davis@example.com", "Carol", "Davis",
        "Female", "1988-11-30", "2021-01-10",
        "Human Resources", "HR Manager",
        ["Employee", "HR Manager", "Leave Approver"],
    ),
    (
        "david.lee@example.com", "David", "Lee",
        "Male", "1993-02-14", "2023-06-01",
        "Product", "Product Manager",
        ["Employee"],
    ),
]

_TEST_PASSWORD = "Test@1234"

# (leave_type, new_leaves_allocated)
_LEAVE_ALLOCATIONS = [
    ("Casual Leave",    12),
    ("Sick Leave",      12),
    ("Privilege Leave", 15),
]

# email, leave_type, from_date, to_date, status, description
_LEAVE_APPLICATIONS = [
    (
        "alice.johnson@example.com", "Casual Leave",
        "2026-01-15", "2026-01-17",
        "Approved", "Family event",
    ),
    (
        "bob.smith@example.com", "Sick Leave",
        "2026-02-03", "2026-02-04",
        "Approved", "Medical appointment",
    ),
    (
        "carol.davis@example.com", "Privilege Leave",
        "2026-03-10", "2026-03-14",
        "Approved", "Annual vacation",
    ),
    (
        "david.lee@example.com", "Casual Leave",
        "2026-08-05", "2026-08-07",
        "Open", "Personal work",
    ),
    (
        "alice.johnson@example.com", "Sick Leave",
        "2026-09-01", "2026-09-02",
        "Open", "Not feeling well",
    ),
    (
        "bob.smith@example.com", "Privilege Leave",
        "2026-10-12", "2026-10-16",
        "Rejected", "Insufficient notice period",
    ),
]

# (team_name, recurrence, meeting_time, location, description)
_WEEKLY_MEETINGS = [
    (
        "Engineering Standup",
        "Every Tuesday",
        "09:00:00",
        "Conference Room A",
        "Daily sync for the engineering team to share progress and blockers.",
    ),
    (
        "Product Review",
        "Mon & Thu",
        "14:00:00",
        "Conference Room B",
        "Product roadmap review and sprint planning with the product team.",
    ),
    (
        "All Hands",
        "Every Friday",
        "17:00:00",
        "Main Hall",
        "Company-wide meeting for updates, shoutouts, and announcements.",
    ),
]

# (title, event_date, location, description)
_UPCOMING_EVENTS = [
    (
        "Company Outing",
        "2026-09-15",
        "Lonavala",
        "Annual company outing — team-building activities and dinner.",
    ),
    (
        "Diwali Celebration",
        "2026-11-08",
        "Office Cafeteria",
        "Celebrate Diwali with sweets, lamps, and festivities.",
    ),
    (
        "Annual Day",
        "2026-12-31",
        "Bandra Kurla Complex",
        "Year-end celebrations, awards ceremony, and cultural performances.",
    ),
]

_EMPLOYEE_ENERGY_POINTS = {
    "alice.johnson@example.com": 1723,
    "bob.smith@example.com":     1500,
    "carol.davis@example.com":   1300,
    "david.lee@example.com":     1000,
}

# (employee_email, award_month, description)
_EMPLOYEE_OF_MONTH = (
    "alice.johnson@example.com",
    "2026-08-01",
    (
        "Alice has been outstanding this month, delivering the mobile "
        "integration project ahead of schedule and mentoring two junior "
        "engineers along the way."
    ),
)

_PANTRY_ROLE = "Pantry"

_PANTRY_USER = (
    "pantry.staff@example.com", "Pantry", "Staff", [_PANTRY_ROLE],
)

# (item_name, item_type, emoji)
_PANTRY_CATALOG = [
    ("Sandwich",    "snack", "🥪"),
    ("Cookies",     "snack", "🍪"),
    ("Samosa",      "snack", "🥟"),
    ("Muffin",      "snack", "🧁"),
    ("Tea",         "drink", "🍵"),
    ("Coffee",      "drink", "☕"),
    ("Lemon Juice", "drink", "🍋"),
    ("Buttermilk",  "drink", "🥛"),
]

# (employee_email, status, location, notes, items[(item_name, qty)], handled_by_email)
_SNACK_REQUESTS = [
    (
        "alice.johnson@example.com", "Completed", "Desk", None,
        [("Coffee", 1), ("Muffin", 1)],
        "pantry.staff@example.com",
    ),
    (
        "bob.smith@example.com", "Accepted", "Conference Room", "No sugar please",
        [("Tea", 2)],
        "pantry.staff@example.com",
    ),
    (
        "carol.davis@example.com", "Pending", "Cabin 1", None,
        [("Samosa", 2), ("Lemon Juice", 1)],
        None,
    ),
    (
        "david.lee@example.com", "Rejected", "Desk", None,
        [("Sandwich", 1)],
        "pantry.staff@example.com",
    ),
    (
        "alice.johnson@example.com", "Pending", None, "Extra napkins please",
        [("Cookies", 3)],
        None,
    ),
]


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _ensure_core_fixtures() -> None:
    """Install Gender/Salutation records normally created by the desk setup wizard."""
    from frappe.desk.page.setup_wizard.install_fixtures import install as install_frappe_fixtures

    install_frappe_fixtures()


def _get_company() -> str:
    """Return the first company, bootstrapping ERPNext if the site is brand-new."""
    companies = frappe.get_all("Company", limit=1)
    if companies:
        return companies[0].name

    # Fresh docker sites skip the desk setup wizard. Use ERPNext's programmatic
    # setup_complete so fixtures (Warehouse Type: Transit, etc.) exist before
    # Company.on_update creates default warehouses / accounts.
    from erpnext.setup.setup_wizard.setup_wizard import setup_complete

    setup_complete(
        frappe._dict(
            {
                "language": "English",
                "country": "India",
                "timezone": "Asia/Kolkata",
                "currency": "INR",
                "company_name": "Fafadia Tech",
                "company_abbr": "FT",
                "chart_of_accounts": "India - Chart of Accounts",
                "domain": "Services",
                "fy_start_date": "2026-04-01",
                "fy_end_date": "2027-03-31",
            }
        )
    )
    frappe.db.commit()
    _tag("Company 'Fafadia Tech' (via setup_complete)", "created")

    companies = frappe.get_all("Company", limit=1)
    if not companies:
        frappe.throw("ERPNext setup_complete ran but no Company was created.")
    return companies[0].name


def _tag(label: str, action: str) -> None:
    print(f"  [{action}] {label}", flush=True)


# ─── Fixtures ────────────────────────────────────────────────────────────────

def _setup_public_holidays(company: str) -> None:
    list_name = "Public Holidays"
    if frappe.db.exists("Holiday List", list_name):
        _tag(f"Holiday List '{list_name}'", "skip")
    else:
        doc = frappe.get_doc({
            "doctype":           "Holiday List",
            "holiday_list_name": list_name,
            "from_date":         "2026-01-01",
            "to_date":           "2026-12-31",
            "holidays": [
                {"holiday_date": d, "description": n, "weekly_off": 0}
                for d, n in _PUBLIC_HOLIDAYS
            ],
        })
        doc.insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Holiday List '{list_name}' ({len(_PUBLIC_HOLIDAYS)} entries)", "created")

    # Ensure the company has a default holiday list so HRMS can calculate
    # leave days without throwing ValidationError.
    current = frappe.db.get_value("Company", company, "default_holiday_list")
    if not current:
        frappe.db.set_value("Company", company, "default_holiday_list", list_name)
        frappe.db.commit()
        _tag(f"Company '{company}' default_holiday_list → '{list_name}'", "fixed")


def _setup_leave_types() -> None:
    for lt_name, max_days, allow_neg, is_lwp in _LEAVE_TYPES:
        if frappe.db.exists("Leave Type", lt_name):
            _tag(f"Leave Type '{lt_name}'", "skip")
            continue

        frappe.get_doc({
            "doctype":          "Leave Type",
            "leave_type_name":  lt_name,
            "max_days_allowed": max_days,
            "allow_negative":   allow_neg,
            "is_lwp":           is_lwp,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Leave Type '{lt_name}'", "created")


def _setup_departments(company: str) -> None:
    for dept in _DEPARTMENTS:
        if frappe.db.exists("Department", {"department_name": dept, "company": company}):
            _tag(f"Department '{dept}'", "skip")
            continue

        frappe.get_doc({
            "doctype":         "Department",
            "department_name": dept,
            "company":         company,
            "is_group":        0,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Department '{dept}'", "created")


def _setup_designations() -> None:
    for desig in _DESIGNATIONS:
        if frappe.db.exists("Designation", desig):
            _tag(f"Designation '{desig}'", "skip")
            continue

        frappe.get_doc({
            "doctype":          "Designation",
            "designation_name": desig,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Designation '{desig}'", "created")


def _setup_users_and_employees(company: str) -> None:
    for email, first, last, gender, dob, doj, dept, desig, roles in _EMPLOYEES:
        full_name = f"{first} {last}"

        # ── User ──────────────────────────────────────────────────────────────
        if frappe.db.exists("User", email):
            _tag(f"User '{email}'", "skip")
        else:
            user = frappe.get_doc({
                "doctype":           "User",
                "email":             email,
                "first_name":        first,
                "last_name":         last,
                "full_name":         full_name,
                "enabled":           1,
                "send_welcome_email": 0,
                "roles": [{"role": r} for r in roles],
            })
            user.insert(ignore_permissions=True)
            update_password(email, _TEST_PASSWORD)
            frappe.db.commit()
            _tag(f"User '{email}'", "created")

        # ── Employee ──────────────────────────────────────────────────────────
        if frappe.db.exists("Employee", {"user_id": email}):
            _tag(f"Employee for '{email}'", "skip")
            continue

        # Resolve department name to its doc name (Tree doctype uses compound key)
        dept_doc = frappe.db.get_value(
            "Department", {"department_name": dept, "company": company}, "name"
        )

        emp = frappe.get_doc({
            "doctype":         "Employee",
            "first_name":      first,
            "last_name":       last,
            "employee_name":   full_name,
            "status":          "Active",
            "company":         company,
            "gender":          gender,
            "date_of_birth":   dob,
            "date_of_joining": doj,
            "department":      dept_doc or dept,
            "designation":     desig,
            "user_id":         email,
        })
        emp.flags.ignore_validate = True
        emp.flags.ignore_mandatory = True
        emp.insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Employee '{full_name}' ({emp.name})", "created")


def _get_employee_id(email: str) -> str | None:
    """Return the Employee doc name (e.g. EMP-00001) for a given user email."""
    return frappe.db.get_value("Employee", {"user_id": email}, "name")


def _setup_leave_allocations(company: str) -> None:
    for email, *_ in _EMPLOYEES:
        emp_id = _get_employee_id(email)
        if not emp_id:
            print(f"  [warn] Employee not found for '{email}', skipping allocations.", flush=True)
            continue

        for lt_name, num_days in _LEAVE_ALLOCATIONS:
            existing = frappe.db.get_value(
                "Leave Allocation",
                {"employee": emp_id, "leave_type": lt_name, "from_date": "2026-01-01"},
                ["name", "docstatus"],
                as_dict=True,
            )
            if existing:
                # Backfill: if the allocation was saved with raw docstatus=1 (bypassing
                # on_submit), no Leave Ledger Entry was created. Create it now.
                has_ledger = frappe.db.exists(
                    "Leave Ledger Entry",
                    {"transaction_name": existing.name, "docstatus": 1},
                )
                if not has_ledger and existing.docstatus == 1:
                    alloc_doc = frappe.get_doc("Leave Allocation", existing.name)
                    alloc_doc.create_leave_ledger_entry()
                    frappe.db.commit()
                    _tag(f"Leave Allocation {emp_id} / {lt_name} (ledger backfill)", "fixed")
                else:
                    _tag(f"Leave Allocation {emp_id} / {lt_name}", "skip")
                continue

            alloc = frappe.get_doc({
                "doctype":              "Leave Allocation",
                "employee":             emp_id,
                "leave_type":           lt_name,
                "from_date":            "2026-01-01",
                "to_date":              "2026-12-31",
                "new_leaves_allocated": num_days,
                "company":              company,
            })
            alloc.insert(ignore_permissions=True)
            # Use the document's submit() so on_submit fires and creates
            # Leave Ledger Entries — critical for HRMS balance tracking.
            alloc.submit()
            frappe.db.commit()
            _tag(f"Leave Allocation {emp_id} / {lt_name} ({num_days} days)", "created")


def _setup_leave_applications() -> None:
    for email, lt_name, from_date, to_date, status, description in _LEAVE_APPLICATIONS:
        emp_id = _get_employee_id(email)
        if not emp_id:
            print(f"  [warn] Employee not found for '{email}', skipping leave application.", flush=True)
            continue

        existing = frappe.db.get_value(
            "Leave Application",
            {"employee": emp_id, "leave_type": lt_name, "from_date": from_date},
            ["name", "status", "docstatus"],
            as_dict=True,
        )
        if existing:
            # Repair drafts left by a prior failed seed (insert succeeded, submit did not).
            if status in ("Approved", "Rejected") and existing.docstatus == 0:
                app_doc = frappe.get_doc("Leave Application", existing.name)
                app_doc.status = status
                app_doc.submit()
                frappe.db.commit()
                _tag(f"Leave Application {emp_id} / {lt_name} from {from_date} (submit repair)", "fixed")
                continue

            # Backfill: approved applications saved with raw docstatus=1 bypass
            # on_submit, so no Leave Ledger Entry (deduction) was created.
            if status == "Approved" and existing.docstatus == 1:
                has_ledger = frappe.db.exists(
                    "Leave Ledger Entry",
                    {"transaction_name": existing.name, "docstatus": 1},
                )
                if not has_ledger:
                    app_doc = frappe.get_doc("Leave Application", existing.name)
                    app_doc.create_leave_ledger_entry()
                    frappe.db.commit()
                    _tag(f"Leave Application {emp_id} / {lt_name} from {from_date} (ledger backfill)", "fixed")
                    continue
            _tag(f"Leave Application {emp_id} / {lt_name} from {from_date}", "skip")
            continue

        emp_name = frappe.db.get_value("Employee", emp_id, "employee_name")

        app = frappe.get_doc({
            "doctype":       "Leave Application",
            "employee":      emp_id,
            "employee_name": emp_name,
            "leave_type":    lt_name,
            "from_date":     from_date,
            "to_date":       to_date,
            "description":   description,
            "posting_date":  from_date,
        })
        app.insert(ignore_permissions=True)

        # HRMS on_submit rejects Open/Cancelled — set status before submit so
        # Leave Ledger deductions are created for Approved/Rejected apps.
        if status in ("Approved", "Rejected"):
            app.status = status
            app.submit()

        frappe.db.commit()
        _tag(f"Leave Application {emp_id} / {lt_name} {from_date}→{to_date} [{status}]", "created")


def _setup_pantry_role() -> None:
    if frappe.db.exists("Role", _PANTRY_ROLE):
        _tag(f"Role '{_PANTRY_ROLE}'", "skip")
        return
    frappe.get_doc({"doctype": "Role", "role_name": _PANTRY_ROLE}).insert(ignore_permissions=True)
    frappe.db.commit()
    _tag(f"Role '{_PANTRY_ROLE}'", "created")


def _setup_pantry_user() -> None:
    email, first, last, roles = _PANTRY_USER
    if frappe.db.exists("User", email):
        _tag(f"User '{email}'", "skip")
        return
    user = frappe.get_doc({
        "doctype":            "User",
        "email":              email,
        "first_name":         first,
        "last_name":          last,
        "full_name":          f"{first} {last}",
        "enabled":            1,
        "send_welcome_email": 0,
        "roles":              [{"role": r} for r in roles],
    })
    user.insert(ignore_permissions=True)
    update_password(email, _TEST_PASSWORD)
    frappe.db.commit()
    _tag(f"User '{email}' (pantry staff)", "created")


def _setup_pantry_catalog() -> None:
    for item_name, item_type, emoji in _PANTRY_CATALOG:
        if frappe.db.exists("Pantry Catalog Item", item_name):
            _tag(f"Pantry Catalog Item '{item_name}'", "skip")
            continue
        frappe.get_doc({
            "doctype":   "Pantry Catalog Item",
            "item_name": item_name,
            "item_type": item_type,
            "emoji":     emoji,
            "is_active": 1,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Pantry Catalog Item '{item_name}' ({item_type} {emoji})", "created")


def _setup_snack_requests() -> None:
    pantry_user_email = _PANTRY_USER[0]

    for email, status, location, notes, items, handled_by_email in _SNACK_REQUESTS:
        emp_id = _get_employee_id(email)
        if not emp_id:
            print(f"  [warn] Employee not found for '{email}', skipping snack request.", flush=True)
            continue

        # Use a fixed requested_at per email+status to make the guard deterministic
        guard_key = f"{emp_id}-{status}-{','.join(i[0] for i in items)}"
        existing = frappe.db.get_value(
            "Snack Request",
            {"employee": emp_id, "status": status, "notes": notes or ""},
            "name",
        )
        if existing:
            _tag(f"Snack Request {emp_id} [{status}]", "skip")
            continue

        now = now_datetime()
        doc = frappe.get_doc({
            "doctype":       "Snack Request",
            "employee":      emp_id,
            "employee_name": frappe.db.get_value("Employee", emp_id, "employee_name"),
            "status":        status,
            "location":      location,
            "notes":         notes,
            "requested_at":  now,
            "items": [
                {"item_name": name, "item_type": _item_type(name), "quantity": qty}
                for name, qty in items
            ],
        })

        if handled_by_email:
            doc.handled_by = handled_by_email
            doc.handled_at = now

        if status == "Completed":
            doc.completed_at = now

        if status == "Rejected":
            doc.rejection_reason = "Unavailable at this time"

        doc.insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Snack Request {emp_id} [{status}] — {', '.join(n for n, _ in items)}", "created")


def _setup_energy_points_field() -> None:
    """Create the energy_points custom field on Employee if it doesn't exist."""
    if frappe.db.exists("Custom Field", {"dt": "Employee", "fieldname": "energy_points"}):
        _tag("Custom Field Employee.energy_points", "skip")
        return

    frappe.get_doc({
        "doctype":    "Custom Field",
        "dt":         "Employee",
        "fieldname":  "energy_points",
        "label":      "Energy Points",
        "fieldtype":  "Int",
        "default":    "0",
        "insert_after": "date_of_joining",
    }).insert(ignore_permissions=True)
    frappe.db.commit()
    _tag("Custom Field Employee.energy_points", "created")


def _setup_energy_points() -> None:
    """Seed energy_points values on each test employee."""
    for email, points in _EMPLOYEE_ENERGY_POINTS.items():
        emp_id = _get_employee_id(email)
        if not emp_id:
            print(f"  [warn] Employee not found for '{email}', skipping energy points.", flush=True)
            continue

        current = frappe.db.get_value("Employee", emp_id, "energy_points") or 0
        if int(current) == points:
            _tag(f"Employee {emp_id} energy_points ({points})", "skip")
            continue

        frappe.db.set_value("Employee", emp_id, "energy_points", points)
        frappe.db.commit()
        _tag(f"Employee {emp_id} energy_points → {points}", "set")


def _setup_employee_of_month() -> None:
    """Insert the Employee of the Month fixture record if not already present."""
    email, award_month, description = _EMPLOYEE_OF_MONTH

    emp_id = _get_employee_id(email)
    if not emp_id:
        print(f"  [warn] Employee not found for '{email}', skipping Employee of the Month.", flush=True)
        return

    if frappe.db.exists("Employee of the Month", {"employee": emp_id, "award_month": award_month}):
        _tag(f"Employee of the Month {emp_id} / {award_month}", "skip")
        return

    frappe.get_doc({
        "doctype":     "Employee of the Month",
        "employee":    emp_id,
        "award_month": award_month,
        "description": description,
        "is_active":   1,
    }).insert(ignore_permissions=True)
    frappe.db.commit()
    _tag(f"Employee of the Month {emp_id} / {award_month}", "created")


def _setup_weekly_meetings() -> None:
    for team_name, recurrence, meeting_time, location, description in _WEEKLY_MEETINGS:
        if frappe.db.exists("Weekly Meeting", {"team_name": team_name, "recurrence": recurrence}):
            _tag(f"Weekly Meeting '{team_name}' ({recurrence})", "skip")
            continue

        frappe.get_doc({
            "doctype":      "Weekly Meeting",
            "team_name":    team_name,
            "recurrence":   recurrence,
            "meeting_time": meeting_time,
            "location":     location,
            "description":  description,
            "is_active":    1,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Weekly Meeting '{team_name}' ({recurrence} at {meeting_time})", "created")


def _setup_upcoming_events() -> None:
    for title, event_date, location, description in _UPCOMING_EVENTS:
        if frappe.db.exists("Upcoming Event", {"title": title, "event_date": event_date}):
            _tag(f"Upcoming Event '{title}' ({event_date})", "skip")
            continue

        frappe.get_doc({
            "doctype":     "Upcoming Event",
            "title":       title,
            "event_date":  event_date,
            "location":    location,
            "description": description,
            "is_active":   1,
        }).insert(ignore_permissions=True)
        frappe.db.commit()
        _tag(f"Upcoming Event '{title}' ({event_date})", "created")


def _item_type(item_name: str) -> str:
    """Look up item_type from the catalog fixture data."""
    for name, itype, _ in _PANTRY_CATALOG:
        if name == item_name:
            return itype
    return "snack"


# ─── Entry point ─────────────────────────────────────────────────────────────

def run() -> None:
    """
    Main entry point called by `bench execute`.
    Each fixture function handles its own idempotency.
    """
    print("=== Standup: loading sample data ===", flush=True)

    _ensure_core_fixtures()
    company = _get_company()
    print(f"  company: {company}", flush=True)

    _setup_public_holidays(company)
    _setup_leave_types()
    _setup_departments(company)
    _setup_designations()
    _setup_users_and_employees(company)
    _setup_leave_allocations(company)
    _setup_leave_applications()

    _setup_pantry_role()
    _setup_pantry_user()
    _setup_pantry_catalog()
    _setup_snack_requests()

    _setup_energy_points_field()
    _setup_energy_points()
    _setup_employee_of_month()

    _setup_weekly_meetings()
    _setup_upcoming_events()

    print("=== Done ===", flush=True)
