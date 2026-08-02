"""
standup/api.py
──────────────
All mobile API endpoints for the Flutter client.

Endpoint base path: /api/method/standup.api.<function>

Authentication flow
───────────────────
1. Flutter POSTs {usr, pwd} to `mobile_login`.
2. Frappe validates credentials and returns api_key + api_secret.
3. Flutter stores credentials via flutter_secure_storage.
4. All subsequent requests include:
       Authorization: token <api_key>:<api_secret>
5. Flutter calls `logout` when the user signs out; the server
   resets the token pair so the old credentials are invalidated.

Frappe's token auth skips CSRF checks entirely, making it
purpose-built for headless/mobile clients.
"""

from __future__ import annotations

import json

import frappe
from frappe import _
from frappe.utils import getdate, now_datetime, formatdate
from frappe.utils.password import check_password


# ─── Private helpers ─────────────────────────────────────────────────────────

def _get_employee(user: str) -> str:
    """Return the Employee docname linked to *user*, or raise DoesNotExistError."""
    employee = frappe.db.get_value("Employee", {"user_id": user}, "name")
    if not employee:
        frappe.throw(
            _("No employee record found for this user."),
            frappe.DoesNotExistError,
        )
    return employee


def _map_leave_status(erpnext_status: str) -> str:
    """Convert an ERPNext Leave Application status to the mobile API status string."""
    return {
        "Open":      "pending",
        "Approved":  "approved",
        "Rejected":  "rejected",
        "Cancelled": "rejected",
    }.get(erpnext_status, "pending")


def _require_auth() -> str:
    """Return the current user or raise AuthenticationError for guests."""
    user = frappe.session.user
    if user == "Guest":
        frappe.throw(_("Not authenticated."), frappe.AuthenticationError)
    return user


def _get_or_create_token(user: str) -> dict[str, str]:
    """Return the existing api_key/api_secret for *user*, generating
    a fresh pair if none exists yet."""
    user_doc = frappe.get_doc("User", user)

    if not user_doc.api_key:
        frappe.generate_hash()          # ensure secrets module is loaded
        user_doc.api_key    = frappe.generate_hash(length=15)
        user_doc.api_secret = frappe.generate_hash(length=15)
        user_doc.save(ignore_permissions=True)
        frappe.db.commit()

    return {
        "api_key":    user_doc.api_key,
        "api_secret": user_doc.get_password("api_secret"),
    }


def _build_user_profile(user: str) -> dict:
    """Minimal profile payload the Flutter app needs at login."""
    user_doc = frappe.get_doc("User", user)
    profile = {
        "name":       user_doc.name,
        "full_name":  user_doc.full_name,
        "email":      user_doc.email,
        "user_image": user_doc.user_image,
        "roles":      [r.role for r in user_doc.roles],
    }
    # Attach energy points from the linked Employee record (0 if not found).
    emp = frappe.db.get_value("Employee", {"user_id": user}, "energy_points")
    profile["energy_points"] = int(emp or 0)
    return profile


# ─── Auth endpoints ──────────────────────────────────────────────────────────

@frappe.whitelist(allow_guest=True, methods=["POST"])
def mobile_login() -> dict:
    """
    Authenticate a mobile user and return token credentials.

    Request body (JSON or form-encoded):
        usr  – email / username
        pwd  – plain-text password (TLS required in production)

    Response 200:
        {
          "status":     "success",
          "api_key":    "...",
          "api_secret": "...",
          "user":       { name, full_name, email, user_image, roles }
        }

    Raises frappe.AuthenticationError (HTTP 401) on bad credentials.
    Raises frappe.PermissionError    (HTTP 403) on inactive / blocked user.
    """
    data = frappe.local.form_dict
    usr  = (data.get("usr") or "").strip()
    pwd  = (data.get("pwd") or "").strip()

    if not usr or not pwd:
        frappe.throw(_("Username and password are required."), frappe.AuthenticationError)

    # Delegate to Frappe's built-in credential check (handles 2FA flags too).
    try:
        frappe.local.login_manager.authenticate(usr, pwd)
        frappe.local.login_manager.post_login()
    except frappe.exceptions.AuthenticationError:
        raise

    user = frappe.session.user

    if user in ("Guest", "Administrator"):
        frappe.throw(
            _("This account is not permitted to use the mobile app."),
            frappe.PermissionError,
        )

    tokens  = _get_or_create_token(user)
    profile = _build_user_profile(user)

    return {
        "status":     "success",
        "api_key":    tokens["api_key"],
        "api_secret": tokens["api_secret"],
        "user":       profile,
    }


@frappe.whitelist(methods=["POST"])
def logout() -> dict:
    """
    Invalidate the current user's API token pair.

    After this call the stored credentials are cleared; the Flutter app
    should delete them from secure storage.
    """
    user = _require_auth()

    user_doc = frappe.get_doc("User", user)
    user_doc.api_key    = ""
    user_doc.api_secret = ""
    user_doc.save(ignore_permissions=True)
    frappe.db.commit()

    frappe.local.login_manager.logout()

    return {"status": "success", "message": _("Logged out successfully.")}


@frappe.whitelist(methods=["GET"])
def me() -> dict:
    """
    Return the authenticated user's profile.
    Used as a token-validation ping from the Flutter startup screen.
    """
    user = _require_auth()
    return {"status": "success", "user": _build_user_profile(user)}


@frappe.whitelist(methods=["POST"])
def refresh_token() -> dict:
    """
    Rotate the API token pair.
    Call this periodically or after a suspected credential leak.
    """
    user = _require_auth()

    user_doc = frappe.get_doc("User", user)
    user_doc.api_key    = frappe.generate_hash(length=15)
    user_doc.api_secret = frappe.generate_hash(length=15)
    user_doc.save(ignore_permissions=True)
    frappe.db.commit()

    return {
        "status":     "success",
        "api_key":    user_doc.api_key,
        "api_secret": user_doc.get_password("api_secret"),
    }


# ─── Holiday endpoints ───────────────────────────────────────────────────────

@frappe.whitelist(methods=["GET"])
def get_holidays(list_name: str = "Public Holidays") -> dict:
    """
    Return all holidays from the given Holiday List, sorted by date.

    Query params:
        list_name  – name of the Holiday List doc (default: "Public Holidays")

    Response 200:
        {
          "status":    "success",
          "list_name": "Public Holidays",
          "holidays": [
            { "id": "...", "name": "Republic Day", "date": "2026-01-26" },
            ...
          ]
        }

    Raises frappe.AuthenticationError (HTTP 401) when not logged in.
    Raises frappe.DoesNotExistError   (HTTP 404) when the list is not found.
    """
    _require_auth()

    if not frappe.db.exists("Holiday List", list_name):
        frappe.throw(
            _("Holiday List '{0}' does not exist.").format(list_name),
            frappe.DoesNotExistError,
        )

    holiday_list = frappe.get_doc("Holiday List", list_name)

    holidays = [
        {
            "id":   row.name,
            "name": row.description or "",
            "date": str(row.holiday_date),
        }
        for row in holiday_list.holidays
        if not row.weekly_off   # exclude regular weekly-off entries
    ]

    holidays.sort(key=lambda h: h["date"])

    return {
        "status":    "success",
        "list_name": list_name,
        "holidays":  holidays,
    }


# ─── Leave endpoints ─────────────────────────────────────────────────────────

@frappe.whitelist(methods=["GET"])
def get_leave_types() -> dict:
    """
    Return all active Leave Type names, sorted alphabetically.

    Response 200:
        {
          "status":      "success",
          "leave_types": ["Casual Leave", "Privilege Leave", "Sick Leave"]
        }
    """
    _require_auth()

    leave_types = frappe.get_all(
        "Leave Type",
        fields=["name"],
        order_by="name asc",
    )

    return {
        "status":      "success",
        "leave_types": [lt["name"] for lt in leave_types],
    }


@frappe.whitelist(methods=["GET"])
def get_leave_balance() -> dict:
    """
    Return the current employee's leave balances for the current calendar year.

    Response 200:
        {
          "status": "success",
          "balances": [
            {
              "leave_type": "Casual Leave",
              "allocated":  3.0,
              "used":       1.0,
              "remaining":  2.0
            },
            ...
          ]
        }
    """
    user     = _require_auth()
    employee = _get_employee(user)

    today      = getdate()
    year_start = today.replace(month=1, day=1)
    year_end   = today.replace(month=12, day=31)

    # Submitted allocations covering some portion of the current year.
    allocations = frappe.get_all(
        "Leave Allocation",
        filters={
            "employee":  employee,
            "docstatus": 1,
            "from_date": ["<=", year_end],
            "to_date":   [">=", year_start],
        },
        fields=["leave_type", "total_leaves_allocated"],
    )

    # Approved applications within the current year.
    approved_apps = frappe.get_all(
        "Leave Application",
        filters={
            "employee":  employee,
            "docstatus": 1,
            "status":    "Approved",
            "from_date": [">=", year_start],
            "to_date":   ["<=", year_end],
        },
        fields=["leave_type", "total_leave_days"],
    )

    used_by_type: dict[str, float] = {}
    for app in approved_apps:
        lt = app["leave_type"]
        used_by_type[lt] = used_by_type.get(lt, 0.0) + float(app["total_leave_days"] or 0)

    balances = []
    for alloc in allocations:
        lt        = alloc["leave_type"]
        allocated = float(alloc["total_leaves_allocated"] or 0)
        used      = used_by_type.get(lt, 0.0)
        balances.append({
            "leave_type": lt,
            "allocated":  allocated,
            "used":       used,
            "remaining":  allocated - used,
        })

    return {"status": "success", "balances": balances}


@frappe.whitelist(methods=["GET"])
def get_leave_history() -> dict:
    """
    Return the most recent 50 leave applications for the current employee,
    newest first.

    Response 200:
        {
          "status": "success",
          "records": [
            {
              "id":         "HR-LAP-2026-00001",
              "leave_type": "Casual Leave",
              "from_date":  "2026-07-10",
              "to_date":    "2026-07-10",
              "total_days": 1.0,
              "status":     "approved",
              "reason":     "Personal errand"
            },
            ...
          ]
        }
    """
    user     = _require_auth()
    employee = _get_employee(user)

    applications = frappe.get_all(
        "Leave Application",
        filters={"employee": employee},
        fields=[
            "name", "leave_type", "from_date", "to_date",
            "total_leave_days", "status", "description",
        ],
        order_by="from_date desc",
        limit=50,
    )

    records = [
        {
            "id":         app["name"],
            "leave_type": app["leave_type"],
            "from_date":  str(app["from_date"]),
            "to_date":    str(app["to_date"]),
            "total_days": float(app["total_leave_days"] or 1),
            "status":     _map_leave_status(app["status"]),
            "reason":     app["description"] or None,
        }
        for app in applications
    ]

    return {"status": "success", "records": records}


@frappe.whitelist(methods=["POST"])
def apply_leave() -> dict:
    """
    Submit a new leave application for the current employee.

    Request body (JSON or form-encoded):
        leave_type  – name of the Leave Type (e.g. "Casual Leave")
        from_date   – ISO date string, e.g. "2026-08-05"
        to_date     – ISO date string, e.g. "2026-08-06"
        reason      – optional free-text reason

    Response 200:
        {
          "status":  "success",
          "id":      "HR-LAP-2026-00002",
          "message": "Leave application submitted successfully."
        }

    Raises frappe.ValidationError (HTTP 417) for missing fields or
    ERPNext business-rule violations (insufficient balance, overlapping
    dates, etc.).
    """
    user     = _require_auth()
    employee = _get_employee(user)

    data       = frappe.local.form_dict
    leave_type = (data.get("leave_type") or "").strip()
    from_date  = (data.get("from_date")  or "").strip()
    to_date    = (data.get("to_date")    or "").strip()
    reason     = (data.get("reason")     or "").strip() or None

    if not leave_type or not from_date or not to_date:
        frappe.throw(
            _("leave_type, from_date, and to_date are required."),
            frappe.ValidationError,
        )

    employee_name = frappe.db.get_value("Employee", employee, "employee_name")

    leave_app = frappe.get_doc({
        "doctype":       "Leave Application",
        "employee":      employee,
        "employee_name": employee_name,
        "leave_type":    leave_type,
        "from_date":     from_date,
        "to_date":       to_date,
        "description":   reason,
        "status":        "Open",
    })
    leave_app.insert(ignore_permissions=True)
    frappe.db.commit()

    return {
        "status":  "success",
        "id":      leave_app.name,
        "message": _("Leave application submitted successfully."),
    }


# ─── Board endpoints ─────────────────────────────────────────────────────────

@frappe.whitelist(methods=["GET"])
def get_leaderboard(limit: int = 10) -> dict:
    """
    Return the top employees ranked by energy points (descending).

    Query params:
        limit  – max entries to return (default: 10)

    Response 200:
        {
          "status": "success",
          "leaderboard": [
            {
              "rank":          1,
              "employee_id":   "EMP-00001",
              "name":          "Alice Johnson",
              "designation":   "Software Engineer",
              "department":    "Engineering",
              "energy_points": 1723
            },
            ...
          ]
        }
    """
    _require_auth()

    employees = frappe.get_all(
        "Employee",
        filters={"status": "Active"},
        fields=["name as employee_id", "employee_name as name", "designation", "department", "energy_points"],
        order_by="energy_points desc",
        limit=int(limit),
    )

    leaderboard = [
        {
            "rank":          rank,
            "employee_id":   emp["employee_id"],
            "name":          emp["name"] or "",
            "designation":   emp["designation"] or "",
            "department":    emp["department"] or "",
            "energy_points": int(emp["energy_points"] or 0),
        }
        for rank, emp in enumerate(employees, start=1)
    ]

    return {"status": "success", "leaderboard": leaderboard}


@frappe.whitelist(methods=["GET"])
def get_employee_of_month() -> dict:
    """
    Return the most recent active Employee of the Month record.

    Response 200 (record found):
        {
          "status": "success",
          "employee_of_month": {
            "employee_id":   "EMP-00001",
            "name":          "Alice Johnson",
            "designation":   "Software Engineer",
            "description":   "...",
            "award_month":   "2026-08-01",
            "display_month": "August 2026"
          }
        }

    Response 200 (no record):
        { "status": "success", "employee_of_month": null }
    """
    _require_auth()

    records = frappe.get_all(
        "Employee of the Month",
        filters={"is_active": 1},
        fields=["employee", "employee_name", "designation", "description", "award_month"],
        order_by="award_month desc",
        limit=1,
    )

    if not records:
        return {"status": "success", "employee_of_month": None}

    rec = records[0]
    award_date = rec["award_month"]
    display_month = formatdate(str(award_date), "MMMM yyyy") if award_date else ""

    return {
        "status": "success",
        "employee_of_month": {
            "employee_id":   rec["employee"],
            "name":          rec["employee_name"] or "",
            "designation":   rec["designation"] or "",
            "description":   rec["description"] or "",
            "award_month":   str(award_date) if award_date else None,
            "display_month": display_month,
        },
    }


# ─── Pantry helpers ──────────────────────────────────────────────────────────

def _require_pantry_role() -> str:
    """Return the current user or raise PermissionError if they lack the Pantry role."""
    user = _require_auth()
    roles = frappe.get_roles(user)
    if not any(r.lower() == "pantry" for r in roles):
        frappe.throw(_("Only Pantry staff can perform this action."), frappe.PermissionError)
    return user


def _serialize_request(doc) -> dict:
    """Convert a Snack Request document to the mobile API payload format."""
    return {
        "id":               doc.name,
        "employee":         doc.employee,
        "employee_name":    doc.employee_name or "",
        "status":           (doc.status or "Pending").lower(),
        "location":         doc.location or None,
        "notes":            doc.notes or None,
        "requested_at":     str(doc.requested_at) if doc.requested_at else None,
        "handled_at":       str(doc.handled_at) if doc.handled_at else None,
        "completed_at":     str(doc.completed_at) if doc.completed_at else None,
        "rejection_reason": doc.rejection_reason or None,
        "items": [
            {
                "item_name": row.item_name,
                "item_type": row.item_type,
                "quantity":  row.quantity,
            }
            for row in (doc.items or [])
        ],
    }


# ─── Pantry endpoints ────────────────────────────────────────────────────────

@frappe.whitelist(methods=["GET"])
def get_pantry_catalog() -> dict:
    """
    Return all active pantry catalog items, ordered by type then name.

    Response:
        { status, items: [{name, item_type, emoji}, ...] }
    """
    _require_auth()

    rows = frappe.get_all(
        "Pantry Catalog Item",
        filters={"is_active": 1},
        fields=["item_name as name", "item_type", "emoji"],
        order_by="item_type asc, item_name asc",
    )
    return {"status": "success", "items": rows}


@frappe.whitelist(methods=["POST"])
def create_snack_request() -> dict:
    """
    Employee places a new pantry order.

    Request body:
        items   – JSON string: [{item_name, item_type, quantity}, ...]
        location – optional delivery location
        notes   – optional free-text note

    Response:
        { status, id, message }
    """
    user     = _require_auth()
    employee = _get_employee(user)

    data = frappe.local.form_dict

    raw_items = data.get("items")
    if not raw_items:
        frappe.throw(_("items is required."), frappe.ValidationError)

    try:
        items = json.loads(raw_items) if isinstance(raw_items, str) else raw_items
    except (json.JSONDecodeError, TypeError):
        frappe.throw(_("items must be valid JSON."), frappe.ValidationError)

    if not items:
        frappe.throw(_("At least one item is required."), frappe.ValidationError)

    employee_name = frappe.db.get_value("Employee", employee, "employee_name")

    doc = frappe.get_doc({
        "doctype":       "Snack Request",
        "employee":      employee,
        "employee_name": employee_name,
        "status":        "Pending",
        "location":      (data.get("location") or "").strip() or None,
        "notes":         (data.get("notes") or "").strip() or None,
        "requested_at":  now_datetime(),
        "items": [
            {
                "item_name": row.get("item_name", ""),
                "item_type": row.get("item_type", "snack"),
                "quantity":  int(row.get("quantity", 1)),
            }
            for row in items
        ],
    })
    doc.insert(ignore_permissions=True)
    frappe.db.commit()

    return {
        "status":  "success",
        "id":      doc.name,
        "message": _("Your pantry request has been submitted."),
    }


@frappe.whitelist(methods=["GET"])
def get_my_snack_requests() -> dict:
    """
    Return the current employee's own snack requests, newest first (limit 50).

    Response:
        { status, requests: [...] }
    """
    user     = _require_auth()
    employee = _get_employee(user)

    names = frappe.get_all(
        "Snack Request",
        filters={"employee": employee},
        fields=["name"],
        order_by="requested_at desc",
        limit=50,
    )
    requests = [_serialize_request(frappe.get_doc("Snack Request", r.name)) for r in names]
    return {"status": "success", "requests": requests}


@frappe.whitelist(methods=["GET"])
def get_all_snack_requests() -> dict:
    """
    Pantry staff fetches all requests, optionally filtered by status.

    Query params:
        status – optional: Pending | Accepted | Rejected | Completed

    Response:
        { status, requests: [...] }
    """
    _require_pantry_role()

    status_filter = (frappe.local.form_dict.get("status") or "").strip() or None
    filters = {"status": status_filter} if status_filter else {}

    names = frappe.get_all(
        "Snack Request",
        filters=filters,
        fields=["name"],
        order_by="requested_at desc",
        limit=200,
    )
    requests = [_serialize_request(frappe.get_doc("Snack Request", r.name)) for r in names]
    return {"status": "success", "requests": requests}


@frappe.whitelist(methods=["POST"])
def accept_snack_request() -> dict:
    """
    Pantry staff accepts a Pending request.

    Request body:
        request_id – name of the Snack Request doc

    Response:
        { status, message }
    """
    user = _require_pantry_role()

    request_id = (frappe.local.form_dict.get("request_id") or "").strip()
    if not request_id:
        frappe.throw(_("request_id is required."), frappe.ValidationError)

    doc = frappe.get_doc("Snack Request", request_id)
    if doc.status != "Pending":
        frappe.throw(
            _("Only Pending requests can be accepted. Current status: {0}").format(doc.status),
            frappe.ValidationError,
        )

    doc.status     = "Accepted"
    doc.handled_by = user
    doc.handled_at = now_datetime()
    doc.save(ignore_permissions=True)
    frappe.db.commit()

    return {"status": "success", "message": _("Request accepted.")}


@frappe.whitelist(methods=["POST"])
def reject_snack_request() -> dict:
    """
    Pantry staff rejects a Pending request with a reason.

    Request body:
        request_id       – name of the Snack Request doc
        rejection_reason – required explanation

    Response:
        { status, message }
    """
    user = _require_pantry_role()

    data      = frappe.local.form_dict
    request_id       = (data.get("request_id") or "").strip()
    rejection_reason = (data.get("rejection_reason") or "").strip()

    if not request_id:
        frappe.throw(_("request_id is required."), frappe.ValidationError)
    if not rejection_reason:
        frappe.throw(_("rejection_reason is required."), frappe.ValidationError)

    doc = frappe.get_doc("Snack Request", request_id)
    if doc.status != "Pending":
        frappe.throw(
            _("Only Pending requests can be rejected. Current status: {0}").format(doc.status),
            frappe.ValidationError,
        )

    doc.status           = "Rejected"
    doc.handled_by       = user
    doc.handled_at       = now_datetime()
    doc.rejection_reason = rejection_reason
    doc.save(ignore_permissions=True)
    frappe.db.commit()

    return {"status": "success", "message": _("Request rejected.")}


@frappe.whitelist(methods=["GET"])
def get_weekly_meetings() -> dict:
    """
    Return all active Weekly Meeting records, ordered by team_name.

    Response:
        { status, meetings: [ { id, team_name, recurrence, meeting_time,
                                location, meeting_link, description } ] }
    """
    _require_auth()

    rows = frappe.get_all(
        "Weekly Meeting",
        filters={"is_active": 1},
        fields=["name", "team_name", "recurrence", "meeting_time",
                "location", "meeting_link", "description"],
        order_by="team_name asc",
    )

    meetings = [
        {
            "id":           r.name,
            "team_name":    r.team_name,
            "recurrence":   r.recurrence,
            "meeting_time": str(r.meeting_time) if r.meeting_time else None,
            "location":     r.location,
            "meeting_link": r.meeting_link,
            "description":  r.description,
        }
        for r in rows
    ]

    return {"status": "success", "meetings": meetings}


@frappe.whitelist(methods=["GET"])
def get_upcoming_events() -> dict:
    """
    Return active Upcoming Event records on or after today, ordered by event_date.

    Response:
        { status, events: [ { id, title, event_date, location, description } ] }
    """
    _require_auth()

    today = getdate()

    rows = frappe.get_all(
        "Upcoming Event",
        filters={"is_active": 1, "event_date": [">=", today]},
        fields=["name", "title", "event_date", "location", "description"],
        order_by="event_date asc",
    )

    events = [
        {
            "id":          r.name,
            "title":       r.title,
            "event_date":  formatdate(r.event_date, "MMM dd, yyyy"),
            "location":    r.location,
            "description": r.description,
        }
        for r in rows
    ]

    return {"status": "success", "events": events}


@frappe.whitelist(methods=["GET"])
def get_birthdays() -> dict:
    """
    Return active employees whose birthday falls in the current calendar month,
    ordered by day of month.

    Response:
        { status, birthdays: [ { id, name, designation, day, month, day_month } ] }
    """
    _require_auth()

    today = getdate()
    current_month = today.month

    rows = frappe.db.sql(
        """
        SELECT name, employee_name, designation, date_of_birth
        FROM `tabEmployee`
        WHERE status = 'Active'
          AND date_of_birth IS NOT NULL
          AND MONTH(date_of_birth) = %(month)s
        ORDER BY DAY(date_of_birth) ASC
        """,
        {"month": current_month},
        as_dict=True,
    )

    birthdays = [
        {
            "id":          r.name,
            "name":        r.employee_name,
            "designation": r.designation,
            "day":         r.date_of_birth.day,
            "month":       r.date_of_birth.strftime("%b"),
            "day_month":   r.date_of_birth.strftime("%b %-d"),
        }
        for r in rows
    ]

    return {"status": "success", "birthdays": birthdays}


@frappe.whitelist(methods=["GET"])
def get_work_anniversaries() -> dict:
    """
    Return active employees whose work anniversary (date_of_joining) falls in
    the current calendar month, ordered by day of month.

    Response:
        { status, anniversaries: [ { id, name, designation, day, month,
                                      day_month, years } ] }
    """
    _require_auth()

    today = getdate()
    current_month = today.month
    current_year  = today.year

    rows = frappe.db.sql(
        """
        SELECT name, employee_name, designation, date_of_joining
        FROM `tabEmployee`
        WHERE status = 'Active'
          AND date_of_joining IS NOT NULL
          AND MONTH(date_of_joining) = %(month)s
        ORDER BY DAY(date_of_joining) ASC
        """,
        {"month": current_month},
        as_dict=True,
    )

    anniversaries = [
        {
            "id":          r.name,
            "name":        r.employee_name,
            "designation": r.designation,
            "day":         r.date_of_joining.day,
            "month":       r.date_of_joining.strftime("%b"),
            "day_month":   r.date_of_joining.strftime("%b %-d"),
            "years":       current_year - r.date_of_joining.year,
        }
        for r in rows
    ]

    return {"status": "success", "anniversaries": anniversaries}


@frappe.whitelist(methods=["POST"])
def complete_snack_request() -> dict:
    """
    Pantry staff marks an Accepted request as Completed (delivered).

    Request body:
        request_id – name of the Snack Request doc

    Response:
        { status, message }
    """
    _require_pantry_role()

    request_id = (frappe.local.form_dict.get("request_id") or "").strip()
    if not request_id:
        frappe.throw(_("request_id is required."), frappe.ValidationError)

    doc = frappe.get_doc("Snack Request", request_id)
    if doc.status != "Accepted":
        frappe.throw(
            _("Only Accepted requests can be completed. Current status: {0}").format(doc.status),
            frappe.ValidationError,
        )

    doc.status       = "Completed"
    doc.completed_at = now_datetime()
    doc.save(ignore_permissions=True)
    frappe.db.commit()

    return {"status": "success", "message": _("Request marked as completed.")}
