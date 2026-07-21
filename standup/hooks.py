from . import __version__ as app_version

app_name        = "standup"
app_title       = "Standup"
app_publisher   = "Fafadia Tech"
app_description = "Standup gives your workforce real-time access to ERPNext from the palm of their hand. Built on Flutter for maximum speed and smooth usability across iOS and Android, Standup eliminates operational lag, speeds up approvals, and drives organization-wide efficiency."
app_email       = "sidharth@fafadiatech.com"
app_license     = "MIT"
app_version     = app_version

# ─── Document Hooks ──────────────────────────────────────────────────────────
# doc_events = {
#     "StandupEntry": {
#         "on_submit": "standup.standup.doctype.standup_entry.standup_entry.on_submit",
#     }
# }

# ─── Scheduled Tasks ─────────────────────────────────────────────────────────
# scheduler_events = {
#     "daily": [
#         "standup.tasks.send_standup_reminder"
#     ],
# }

# ─── Website ─────────────────────────────────────────────────────────────────
# website_route_rules = [
#     {"from_route": "/standup/<path:app_path>", "to_route": "standup"},
# ]

# ─── Permissions ─────────────────────────────────────────────────────────────
# has_permission = {
#     "StandupEntry": "standup.permissions.has_permission",
# }

# ─── REST / CORS ─────────────────────────────────────────────────────────────
# Allow the Flutter app to call whitelisted endpoints from any origin
# in development. Tighten `allow_cors` in production to your actual domain.
allow_cors = "*"

# ─── On Login ────────────────────────────────────────────────────────────────
# on_login = "standup.api.auth.on_login"

# ─── Boot Session ────────────────────────────────────────────────────────────
# extend_bootinfo = "standup.boot.boot_session"
