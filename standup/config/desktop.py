from frappe import _


def get_data():
    return [
        {
            "module_name": "Standup",
            "color": "#3498db",
            "icon": "octicon octicon-check",
            "type": "module",
            "label": _("Standup"),
            "description": _("Daily standup tracker"),
        }
    ]
