# syntax=docker/dockerfile:1.4
#
# Custom ERPNext v15 image with the Standup application pre-installed.
#
# Build manually:
#   docker build --tag custom-erpnext:v15 .
#
# Or let docker compose handle it automatically:
#   docker compose up --build -d

FROM frappe/erpnext:v15

USER frappe
WORKDIR /home/frappe/frappe-bench

# ── Fetch HRMS (version-15 branch) ───────────────────────────────────────────
# Shallow clone keeps the layer small; pip install -e wires up the package.
RUN git clone --branch version-15 --depth 1 \
        https://github.com/frappe/hrms \
        apps/hrms && \
    /home/frappe/frappe-bench/env/bin/pip install \
        --quiet --no-deps -e apps/hrms

# ── Copy the local Standup app ────────────────────────────────────────────────
# The Flutter app/ directory and build artefacts are excluded via .dockerignore.
COPY --chown=frappe:frappe . /home/frappe/frappe-bench/apps/standup

# Make the standup Python package importable by writing a .pth file into the
# bench virtualenv's site-packages. This is equivalent to `pip install -e` but
# avoids the build-backend resolution step that fails on older pip/setuptools.
RUN SITE_PACKAGES=$( \
        /home/frappe/frappe-bench/env/bin/python \
        -c "import site; print(site.getsitepackages()[0])") && \
    echo "/home/frappe/frappe-bench/apps/standup" > "${SITE_PACKAGES}/standup.pth"

# ── Register both apps with the bench ────────────────────────────────────────
# Fresh named volumes copy these files from the image on first creation.
# Write via Python so a missing trailing newline cannot glue app names together.
RUN python3 <<'EOF'
from pathlib import Path
import json

# ── apps.txt ──
apps_txt = Path("sites/apps.txt")
raw = apps_txt.read_text().split() if apps_txt.exists() else []
apps = []
for a in raw:
    if a == "erpnextstandup":
        apps.extend(["erpnext", "standup"])
    else:
        apps.append(a)
for name in ("hrms", "standup"):
    if name not in apps:
        apps.append(name)
seen, out = set(), []
for a in apps:
    if a not in seen:
        seen.add(a)
        out.append(a)
apps_txt.write_text("\n".join(out) + "\n")

# ── apps.json ──
apps_json = Path("sites/apps.json")
data = json.loads(apps_json.read_text()) if apps_json.exists() else {}
data.pop("erpnextstandup", None)
next_idx = max((a.get("idx", 0) for a in data.values()), default=0) + 1
data.setdefault(
    "hrms",
    {
        "is_repo": True,
        "resolution": {"commit_hash": None, "branch": "version-15"},
        "required": [],
        "idx": next_idx,
        "version": "0.0.1",
    },
)
next_idx = max(a.get("idx", 0) for a in data.values()) + 1
data.setdefault(
    "standup",
    {
        "is_repo": False,
        "resolution": {"commit_hash": None, "branch": None},
        "required": [],
        "idx": next_idx,
        "version": "0.1.0",
    },
)
apps_json.write_text(json.dumps(data, indent=4))
EOF

# ── Compile frontend assets ───────────────────────────────────────────────────
RUN /home/frappe/frappe-bench/env/bin/bench build --app hrms || true
RUN /home/frappe/frappe-bench/env/bin/bench build --app standup || true
