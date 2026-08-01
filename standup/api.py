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

import frappe
from frappe import _
from frappe.utils.password import check_password


# ─── Private helpers ─────────────────────────────────────────────────────────

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
    return {
        "name":       user_doc.name,
        "full_name":  user_doc.full_name,
        "email":      user_doc.email,
        "user_image": user_doc.user_image,
        "roles":      [r.role for r in user_doc.roles],
    }


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
