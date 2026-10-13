from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


OUT_DIR = Path("output/erd")
OUT_DIR.mkdir(parents=True, exist_ok=True)

FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def f(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size)


BG = "#F8FAFC"
CARD = "#FFFFFF"
HEADER = "#326F9F"
TEXT = "#27323A"
MUTED = "#69757D"
EDGE = "#A8B1B7"
BORDER = "#D8DEE3"
BADGE = "#E7EAED"
PK = "#9A6C19"
FK = "#3E7B72"


class ErdCanvas:
    def __init__(self, title, subtitle, width=4000, height=2600):
        self.width = width
        self.height = height
        self.image = Image.new("RGB", (width, height), BG)
        self.draw = ImageDraw.Draw(self.image)
        self.nodes = {}
        self.draw.text((100, 68), title, font=f(64, True), fill=TEXT)
        self.draw.text((102, 145), subtitle, font=f(30), fill=MUTED)
        self.draw.text((3020, 86), "PK  Primary key", font=f(24, True), fill=PK)
        self.draw.text((3020, 126), "FK  Foreign key", font=f(24, True), fill=FK)
        self.draw.text((3020, 166), "NN  Not null", font=f(24, True), fill=MUTED)

    def add_node(self, name, x, y, fields, width=650):
        header_h = 72
        row_h = 50
        h = header_h + row_h * len(fields) + 18
        self.nodes[name] = {"x": x, "y": y, "w": width, "h": h, "fields": fields}

    def point(self, name, side):
        n = self.nodes[name]
        if side == "top":
            return (n["x"] + n["w"] // 2, n["y"])
        if side == "bottom":
            return (n["x"] + n["w"] // 2, n["y"] + n["h"])
        if side == "left":
            return (n["x"], n["y"] + n["h"] // 2)
        return (n["x"] + n["w"], n["y"] + n["h"] // 2)

    def edge(self, a, b, a_card="1", b_card="0..*", a_side="bottom", b_side="top"):
        p1 = self.point(a, a_side)
        p2 = self.point(b, b_side)
        if a_side in ("top", "bottom") and b_side in ("top", "bottom"):
            my = (p1[1] + p2[1]) // 2
            pts = [p1, (p1[0], my), (p2[0], my), p2]
        else:
            mx = (p1[0] + p2[0]) // 2
            pts = [p1, (mx, p1[1]), (mx, p2[1]), p2]
        self.draw.line(pts, fill=EDGE, width=5, joint="curve")
        # Reference-style endpoint marks.
        for px, py in (p1, p2):
            self.draw.line((px - 9, py, px + 9, py), fill=EDGE, width=4)
        self.draw.text((p1[0] + 12, p1[1] + 6), a_card, font=f(21, True), fill=MUTED)
        self.draw.text((p2[0] + 12, p2[1] - 32), b_card, font=f(21, True), fill=MUTED)

    def draw_node(self, name):
        n = self.nodes[name]
        x, y, w, h = n["x"], n["y"], n["w"], n["h"]
        shadow = Image.new("RGBA", (w + 50, h + 50), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle((14, 14, w + 14, h + 14), radius=14, fill=(20, 37, 48, 42))
        shadow = shadow.filter(ImageFilter.GaussianBlur(12))
        self.image.paste(shadow, (x - 14, y - 10), shadow)

        self.draw.rounded_rectangle((x, y, x + w, y + h), radius=12, fill=CARD, outline=BORDER, width=3)
        self.draw.rounded_rectangle((x, y, x + w, y + 72), radius=12, fill=HEADER)
        self.draw.rectangle((x, y + 50, x + w, y + 72), fill=HEADER)
        self.draw.text((x + 24, y + 17), name.lower(), font=f(31, True), fill="white")

        row_y = y + 88
        for field in n["fields"]:
            key, field_name, dtype, nn = field
            if key:
                color = PK if key == "PK" else FK
                self.draw.text((x + 22, row_y + 5), key, font=f(20, True), fill=color)
                field_x = x + 78
            else:
                field_x = x + 24
            self.draw.text((field_x, row_y), field_name, font=f(25), fill=TEXT)
            type_box = self.draw.textbbox((0, 0), dtype, font=f(23))
            type_w = type_box[2] - type_box[0]
            right_pad = 67 if nn else 25
            self.draw.text((x + w - right_pad - type_w, row_y + 2), dtype, font=f(23), fill=MUTED)
            if nn:
                bx = x + w - 55
                self.draw.rounded_rectangle((bx, row_y - 1, bx + 40, row_y + 31), radius=5, fill=BADGE)
                self.draw.text((bx + 6, row_y + 3), "NN", font=f(18, True), fill=MUTED)
            row_y += 50

    def finish(self, path):
        for name in self.nodes:
            self.draw_node(name)
        self.image.save(path, quality=96)


def field(key, name, dtype, nn=True):
    return (key, name, dtype, nn)


def accounts_diagram():
    c = ErdCanvas(
        "Accounts and Access Control ERD",
        "Authentication, role profiles, device registration, verification, and auditing",
        4000,
        2500,
    )
    c.add_node("APP_ACCOUNT", 1675, 280, [
        field("PK", "id", "text"), field("", "username", "text"), field("", "email", "text", False),
        field("", "phone", "text", False), field("", "password_hash", "text"), field("", "full_name", "text"),
        field("", "role", "enum"), field("", "active", "boolean"), field("", "created_at", "timestamp"),
    ])

    cards = [
        ("APP_SESSION", 80, 950, [field("PK", "token_hash", "text"), field("FK", "account_id", "text"), field("", "role", "text"), field("", "expires_at", "timestamp")]),
        ("PASSWORD_RESET_CODE", 850, 950, [field("PK", "account_id", "text"), field("", "code_hash", "text"), field("", "expires_at", "timestamp"), field("", "attempts", "integer")]),
        ("DEVICE_TOKEN", 1620, 950, [field("PK", "token", "text"), field("FK", "account_id", "text"), field("", "platform", "text"), field("", "updated_at", "timestamp")]),
        ("OWNER_PROFILE", 2390, 950, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "data", "jsonb"), field("", "version", "integer")]),
        ("DOCTOR_PROFILE", 3160, 950, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "license", "text"), field("", "availability", "jsonb")]),
        ("STAFF_PROFILE", 80, 1650, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "data", "jsonb")]),
        ("ADMIN_PROFILE", 850, 1650, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "data", "jsonb")]),
        ("USER_DIRECTORY", 1620, 1650, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "role", "text"), field("", "status", "text")]),
        ("DOCTOR_VERIFICATION", 2390, 1650, [field("PK", "id", "text"), field("FK", "applicant_id", "text"), field("", "license_number", "text"), field("", "status", "text")]),
        ("AUDIT_LOG", 3160, 1650, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "module", "text"), field("", "action", "text"), field("", "created_at", "timestamp")]),
    ]
    for name, x, y, fields in cards:
        c.add_node(name, x, y, fields)
        c.edge("APP_ACCOUNT", name, "1", "0..*" if name in {"APP_SESSION", "DEVICE_TOKEN", "AUDIT_LOG"} else "0..1")
    c.finish(OUT_DIR / "erd-1-accounts-access.png")


def clinic_diagram():
    c = ErdCanvas(
        "Clinic Operations ERD",
        "Pet ownership, appointments, queue, services, medical records, payments, and inventory",
        4300,
        3300,
    )
    c.add_node("APP_ACCOUNT", 150, 280, [field("PK", "id", "text"), field("", "role", "enum"), field("", "full_name", "text")], 590)
    c.add_node("DOCTOR_PROFILE", 980, 280, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "availability", "jsonb")], 590)
    c.add_node("PET", 1810, 280, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "name", "text"), field("", "species", "text"), field("", "medical_info", "jsonb")], 620)

    second = [
        ("APPOINTMENT", 80, 980, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("FK", "pet_id", "text"), field("FK", "doctor_id", "text"), field("", "service", "text"), field("", "status", "text")]),
        ("WALK_IN_APPOINTMENT", 790, 980, [field("PK", "id", "text"), field("FK", "pet_id", "text"), field("FK", "doctor_id", "text"), field("", "arrival_time", "timestamp"), field("", "status", "text")]),
        ("HOME_VISIT", 1500, 980, [field("PK", "id", "text"), field("FK", "pet_id", "text"), field("FK", "doctor_id", "text"), field("", "address", "text"), field("", "status", "text")]),
        ("EMERGENCY_REQUEST", 2210, 980, [field("PK", "id", "text"), field("FK", "pet_id", "text"), field("FK", "doctor_id", "text"), field("", "symptoms", "text"), field("", "status", "text")]),
        ("PET_CARE_BOOKING", 2920, 980, [field("PK", "id", "text"), field("FK", "pet_id", "text"), field("", "service", "text"), field("", "provider", "text"), field("", "status", "text")]),
        ("INVENTORY", 3630, 980, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "item_name", "text"), field("", "stock", "integer"), field("", "expiry_date", "date", False)], 590),
    ]
    for name, x, y, fields, *custom in second:
        c.add_node(name, x, y, fields, custom[0] if custom else 650)

    third = [
        ("QUEUE_ENTRY", 120, 1900, [field("PK", "id", "text"), field("FK", "appointment_id", "text", False), field("FK", "walk_in_id", "text", False), field("", "queue_number", "integer"), field("", "status", "text")]),
        ("MEDICAL_RECORD", 850, 1900, [field("PK", "id", "text"), field("FK", "pet_id", "text"), field("FK", "doctor_id", "text"), field("", "diagnosis", "text"), field("", "treatment", "text")]),
        ("PAYMENT", 1580, 1900, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("FK", "service_record_id", "text"), field("", "amount", "numeric"), field("", "status", "text")]),
        ("REMINDER", 2290, 1900, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("FK", "pet_id", "text"), field("", "scheduled_for", "timestamp"), field("", "completed", "boolean")], 600),
        ("APPOINTMENT_REMINDER", 2960, 1900, [field("PK", "appointment_id", "text"), field("PK", "scheduled_for", "timestamp"), field("FK", "owner_id", "text"), field("", "sent_at", "timestamp")], 600),
        ("OWNER_NOTIFICATION", 3650, 1900, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "title", "text"), field("", "message", "text"), field("", "read", "boolean")], 570),
    ]
    for name, x, y, fields, *custom in third:
        c.add_node(name, x, y, fields, custom[0] if custom else 650)

    c.add_node("QUEUE_DAILY_COUNTER", 520, 2760, [field("PK", "clinic_date", "date"), field("", "last_number", "integer")], 650)
    c.add_node("DOCTOR_APPOINTMENT_STATE", 1550, 2760, [field("PK", "id", "text"), field("FK", "appointment_id", "text"), field("FK", "doctor_id", "text"), field("", "state", "text")], 720)

    c.edge("APP_ACCOUNT", "PET", "1", "0..*", "right", "left")
    for target in ["APPOINTMENT", "WALK_IN_APPOINTMENT", "HOME_VISIT", "EMERGENCY_REQUEST", "PET_CARE_BOOKING", "REMINDER"]:
        c.edge("PET", target, "1", "0..*", "bottom", "top")
    for target in ["APPOINTMENT", "WALK_IN_APPOINTMENT", "HOME_VISIT", "EMERGENCY_REQUEST", "MEDICAL_RECORD"]:
        c.edge("DOCTOR_PROFILE", target, "1", "0..*", "bottom", "top")
    c.edge("APPOINTMENT", "QUEUE_ENTRY", "1", "0..1")
    c.edge("WALK_IN_APPOINTMENT", "QUEUE_ENTRY", "1", "0..1")
    c.edge("PET_CARE_BOOKING", "QUEUE_ENTRY", "1", "0..1")
    for source in ["APPOINTMENT", "HOME_VISIT", "EMERGENCY_REQUEST"]:
        c.edge(source, "MEDICAL_RECORD", "1", "0..*")
    for source in ["APPOINTMENT", "WALK_IN_APPOINTMENT", "HOME_VISIT", "EMERGENCY_REQUEST", "PET_CARE_BOOKING"]:
        c.edge(source, "PAYMENT", "1", "0..*")
    c.edge("APPOINTMENT", "APPOINTMENT_REMINDER", "1", "0..*")
    c.edge("APPOINTMENT_REMINDER", "OWNER_NOTIFICATION", "1", "1", "right", "left")
    c.edge("QUEUE_DAILY_COUNTER", "QUEUE_ENTRY", "1", "0..*", "top", "bottom")
    c.edge("APPOINTMENT", "DOCTOR_APPOINTMENT_STATE", "1", "0..1", "bottom", "top")
    c.finish(OUT_DIR / "erd-2-clinic-operations.png")


def communication_diagram():
    c = ErdCanvas(
        "Communication, Content, and Support ERD",
        "Health posts, messages, notifications, preferences, saved information, and support",
        4000,
        2550,
    )
    c.add_node("APP_ACCOUNT", 1680, 280, [field("PK", "id", "text"), field("", "role", "enum"), field("", "full_name", "text")], 640)
    cards = [
        ("HEALTH_POST", 80, 900, [field("PK", "id", "text"), field("FK", "author_id", "text"), field("", "title", "text"), field("", "content", "text"), field("", "status", "text")]),
        ("HEALTH_POST_DRAFT", 850, 900, [field("PK", "id", "text"), field("FK", "doctor_id", "text"), field("", "content", "text"), field("", "scheduled_for", "timestamp", False)]),
        ("CLINIC_MESSAGE", 1620, 900, [field("PK", "id", "text"), field("FK", "sender_id", "text"), field("FK", "recipient_id", "text"), field("", "message_text", "text"), field("", "sent_at", "timestamp")]),
        ("OWNER_NOTIFICATION", 2390, 900, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "title", "text"), field("", "message", "text"), field("", "read", "boolean")]),
        ("NOTIFICATION_SETTINGS", 3160, 900, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "appointments", "boolean"), field("", "emergencies", "boolean"), field("", "queue_alerts", "boolean")]),
        ("SAVED_ADDRESS", 80, 1720, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "label", "text"), field("", "address", "text")]),
        ("SUPPORT_TICKET", 850, 1720, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "subject", "text"), field("", "status", "text")]),
        ("HISTORY_REVIEW", 1620, 1720, [field("PK", "id", "text"), field("FK", "history_record_id", "text"), field("", "rating", "integer"), field("", "comment", "text")]),
        ("SAVED_FIRST_AID_GUIDE", 2390, 1720, [field("PK", "id", "text"), field("FK", "owner_id", "text"), field("", "guide_id", "text"), field("", "saved_at", "timestamp")]),
        ("CLINIC_DIRECTORY", 3160, 1720, [field("PK", "account_id", "text"), field("", "name", "text"), field("", "specialty", "text"), field("", "public_profile", "jsonb")]),
    ]
    for name, x, y, fields in cards:
        c.add_node(name, x, y, fields)
        c.edge("APP_ACCOUNT", name, "1", "0..1" if name in {"NOTIFICATION_SETTINGS", "CLINIC_DIRECTORY"} else "0..*")
    c.edge("HEALTH_POST_DRAFT", "HEALTH_POST", "0..1", "0..1", "left", "right")
    c.finish(OUT_DIR / "erd-3-communication-support.png")


accounts_diagram()
clinic_diagram()
communication_diagram()
print("Created clear ERD images in", OUT_DIR.resolve())
