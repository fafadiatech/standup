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
from frappe.utils import date_diff
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
        "Female", "1992-07-15", "2023-03-01",
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

    print("=== Done ===", flush=True)
