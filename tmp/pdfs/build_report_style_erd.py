from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


OUT = Path("/Users/apple/NwaysLoveVetClinic/output/erd/report-style")
OUT.mkdir(parents=True, exist_ok=True)

REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else REGULAR, size)


BG = "#FBFBFB"
CARD = "#FFFFFF"
HEADER = "#326F9F"
TEXT = "#30383D"
MUTED = "#6F767B"
LINE = "#AAB0B4"
BORDER = "#E1E4E6"
BADGE = "#ECEEEF"


def col(key, name, dtype, required=True):
    return (key, name, dtype, required)


class Diagram:
    def __init__(self, width, height, scale=1.0):
        self.image = Image.new("RGB", (width, height), BG)
        self.draw = ImageDraw.Draw(self.image)
        self.nodes = {}
        self.scale = scale

    def add(self, name, x, y, columns, width=650):
        header_h = int(70 * self.scale)
        row_h = int(51 * self.scale)
        height = header_h + row_h * len(columns) + int(18 * self.scale)
        self.nodes[name] = {
            "x": x, "y": y, "w": width, "h": height,
            "header_h": header_h, "row_h": row_h, "columns": columns,
        }

    def anchor(self, name, side, fraction=0.5):
        n = self.nodes[name]
        if side == "left":
            return (n["x"], int(n["y"] + n["h"] * fraction))
        if side == "right":
            return (n["x"] + n["w"], int(n["y"] + n["h"] * fraction))
        if side == "top":
            return (int(n["x"] + n["w"] * fraction), n["y"])
        return (int(n["x"] + n["w"] * fraction), n["y"] + n["h"])

    def relation(
        self,
        source,
        target,
        source_side="right",
        target_side="left",
        source_fraction=0.5,
        target_fraction=0.5,
        source_card="one",
        target_card="many",
    ):
        p1 = self.anchor(source, source_side, source_fraction)
        p2 = self.anchor(target, target_side, target_fraction)
        width = max(2, int(3 * self.scale))
        if source_side in ("left", "right") and target_side in ("left", "right"):
            middle = (p1[0] + p2[0]) // 2
            points = [p1, (middle, p1[1]), (middle, p2[1]), p2]
        elif source_side in ("top", "bottom") and target_side in ("top", "bottom"):
            middle = (p1[1] + p2[1]) // 2
            points = [p1, (p1[0], middle), (p2[0], middle), p2]
        else:
            points = [p1, (p2[0], p1[1]), p2]
        self.draw.line(points, fill=LINE, width=width, joint="curve")
        self._cardinality_marker(p1, source_side, source_card)
        self._cardinality_marker(p2, target_side, target_card)

    def _cardinality_marker(self, point, side, cardinality):
        """Draw Crow's Foot symbols without arrowheads.

        one          = ||  exactly one
        one_optional = o|  zero or one
        many         = o + crow's foot  zero or many
        many_required= | + crow's foot  one or many
        """
        x, y = point
        w = max(2, int(3 * self.scale))
        half = max(7, int(13 * self.scale))
        step = max(9, int(15 * self.scale))

        vectors = {
            "left": (-1, 0), "right": (1, 0),
            "top": (0, -1), "bottom": (0, 1),
        }
        dx, dy = vectors[side]
        px, py = -dy, dx

        def at(distance):
            return (x + dx * distance, y + dy * distance)

        def bar(distance):
            cx, cy = at(distance)
            self.draw.line(
                (cx - px * half, cy - py * half, cx + px * half, cy + py * half),
                fill=LINE,
                width=w,
            )

        def circle(distance):
            cx, cy = at(distance)
            radius = max(6, int(10 * self.scale))
            self.draw.ellipse(
                (cx - radius, cy - radius, cx + radius, cy + radius),
                fill=BG,
                outline=LINE,
                width=w,
            )

        if cardinality == "one":
            bar(step)
            bar(step * 2)
        elif cardinality == "one_optional":
            bar(step)
            circle(step * 2 + max(2, int(3 * self.scale)))
        elif cardinality in {"many", "many_required"}:
            # The three-pronged foot opens toward the entity. Its junction is
            # separated from the table edge so it cannot look like an arrow.
            junction = at(step * 2)
            near_center = at(max(2, int(3 * self.scale)))
            self.draw.line((junction[0], junction[1], near_center[0], near_center[1]), fill=LINE, width=w)
            self.draw.line(
                (junction[0], junction[1], near_center[0] + px * half, near_center[1] + py * half),
                fill=LINE,
                width=w,
            )
            self.draw.line(
                (junction[0], junction[1], near_center[0] - px * half, near_center[1] - py * half),
                fill=LINE,
                width=w,
            )
            if cardinality == "many":
                circle(step * 3 + max(3, int(5 * self.scale)))
            else:
                bar(step * 3 + max(3, int(5 * self.scale)))

    def _key_icon(self, x, y, color):
        r = max(4, int(6 * self.scale))
        w = max(2, int(3 * self.scale))
        self.draw.ellipse((x, y, x + r * 2, y + r * 2), outline=color, width=w)
        self.draw.line((x + r * 2 - 1, y + r, x + r * 4, y + r), fill=color, width=w)
        self.draw.line((x + r * 3, y + r, x + r * 3, y + r * 2), fill=color, width=w)

    def draw_node(self, name):
        n = self.nodes[name]
        x, y, w, h = n["x"], n["y"], n["w"], n["h"]
        radius = max(7, int(10 * self.scale))
        shadow_pad = int(40 * self.scale)
        shadow = Image.new("RGBA", (w + shadow_pad, h + shadow_pad), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle((10, 10, w + 10, h + 10), radius=radius, fill=(30, 45, 55, 34))
        shadow = shadow.filter(ImageFilter.GaussianBlur(max(4, int(8 * self.scale))))
        self.image.paste(shadow, (x - 10, y - 7), shadow)
        self.draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=CARD, outline=BORDER, width=max(1, int(2 * self.scale)))
        self.draw.rounded_rectangle((x, y, x + w, y + n["header_h"]), radius=radius, fill=HEADER)
        self.draw.rectangle((x, y + n["header_h"] - radius, x + w, y + n["header_h"]), fill=HEADER)

        title_size = max(17, int(29 * self.scale))
        self.draw.text((x + int(22 * self.scale), y + int(16 * self.scale)), name.lower(), font=font(title_size, True), fill="white")

        row_y = y + n["header_h"] + int(16 * self.scale)
        name_size = max(15, int(23 * self.scale))
        type_size = max(14, int(21 * self.scale))
        badge_size = max(12, int(17 * self.scale))
        for key, field_name, dtype, required in n["columns"]:
            name_x = x + int(22 * self.scale)
            if key:
                self._key_icon(name_x, row_y + int(6 * self.scale), "#687178")
                name_x += int(43 * self.scale)
            self.draw.text((name_x, row_y), field_name, font=font(name_size), fill=TEXT)
            badge_w = int(42 * self.scale) if required else 0
            right = x + w - int(18 * self.scale) - badge_w
            box = self.draw.textbbox((0, 0), dtype, font=font(type_size))
            dtype_w = box[2] - box[0]
            self.draw.text((right - dtype_w - int(8 * self.scale), row_y + int(2 * self.scale)), dtype, font=font(type_size), fill=MUTED)
            if required:
                bx = x + w - int(54 * self.scale)
                by = row_y - int(1 * self.scale)
                self.draw.rounded_rectangle((bx, by, bx + int(39 * self.scale), by + int(31 * self.scale)), radius=max(3, int(4 * self.scale)), fill=BADGE)
                self.draw.text((bx + int(5 * self.scale), by + int(4 * self.scale)), "NN", font=font(badge_size, True), fill=MUTED)
            row_y += n["row_h"]

    def save(self, path):
        for name in self.nodes:
            self.draw_node(name)
        self.image.save(path, optimize=True)


ACCOUNT = [
    col("PK", "id", "text"), col("", "username", "varchar"), col("", "email", "varchar", False),
    col("", "phone", "varchar", False), col("", "password_hash", "text"),
    col("", "full_name", "varchar"), col("", "role", "enum"), col("", "active", "boolean"),
    col("", "created_at", "timestamp"),
]


def overview():
    d = Diagram(5000, 3550, 0.62)
    entities = [
        ("APP_ACCOUNTS", 2050, 100, [col("PK", "id", "text"), col("", "role", "enum"), col("", "full_name", "varchar")]),
        ("OWNER_PROFILES", 140, 620, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("DOCTOR_PROFILES", 1090, 620, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("STAFF_PROFILES", 2040, 620, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("ADMIN_PROFILES", 2990, 620, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("USER_DIRECTORY", 3940, 620, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("PETS", 140, 1240, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("APPOINTMENTS", 1090, 1240, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("QUEUE_ENTRIES", 2040, 1240, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("WALK_IN_APPOINTMENTS", 2990, 1240, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("MEDICAL_RECORDS", 3940, 1240, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("HOME_VISITS", 140, 1860, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("EMERGENCY_REQUESTS", 1090, 1860, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("PET_CARE_BOOKINGS", 2040, 1860, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("PAYMENTS", 2990, 1860, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("INVENTORY", 3940, 1860, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("REMINDERS", 140, 2480, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("OWNER_NOTIFICATIONS", 1090, 2480, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("CLINIC_MESSAGES", 2040, 2480, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("HEALTH_POSTS", 2990, 2480, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("SUPPORT_TICKETS", 3940, 2480, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("DOCTOR_VERIFICATIONS", 1090, 3090, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
        ("AUDIT_LOGS", 2990, 3090, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb")]),
    ]
    for name, x, y, fields in entities:
        d.add(name, x, y, fields, 800)
    for profile in ["OWNER_PROFILES", "DOCTOR_PROFILES", "STAFF_PROFILES", "ADMIN_PROFILES", "USER_DIRECTORY"]:
        d.relation("APP_ACCOUNTS", profile, "bottom", "top", target_card="one_optional")
    d.relation("OWNER_PROFILES", "PETS", "bottom", "top")
    d.relation("PETS", "APPOINTMENTS")
    d.relation("APPOINTMENTS", "QUEUE_ENTRIES")
    d.relation("QUEUE_ENTRIES", "WALK_IN_APPOINTMENTS")
    d.relation("APPOINTMENTS", "MEDICAL_RECORDS")
    d.relation("PETS", "HOME_VISITS", "bottom", "top")
    d.relation("HOME_VISITS", "EMERGENCY_REQUESTS")
    d.relation("EMERGENCY_REQUESTS", "PET_CARE_BOOKINGS")
    d.relation("PET_CARE_BOOKINGS", "PAYMENTS")
    d.relation("PAYMENTS", "INVENTORY")
    d.relation("PETS", "REMINDERS", "bottom", "top")
    d.relation("REMINDERS", "OWNER_NOTIFICATIONS")
    d.relation("OWNER_NOTIFICATIONS", "CLINIC_MESSAGES")
    d.relation("CLINIC_MESSAGES", "HEALTH_POSTS")
    d.relation("HEALTH_POSTS", "SUPPORT_TICKETS")
    d.relation("DOCTOR_PROFILES", "DOCTOR_VERIFICATIONS", "bottom", "top", target_card="one_optional")
    d.relation("ADMIN_PROFILES", "AUDIT_LOGS", "bottom", "top")
    d.save(OUT / "nways-erd-overview.png")


def detail_access():
    d = Diagram(4200, 2700, 1.0)
    d.add("APP_ACCOUNTS", 1575, 90, ACCOUNT, 1050)
    nodes = [
        ("APP_SESSIONS", 90, 850, [col("PK", "token_hash", "text"), col("FK", "account_id", "text"), col("", "role", "varchar"), col("", "expires_at", "timestamp"), col("", "created_at", "timestamp")]),
        ("PASSWORD_RESET_CODES", 890, 850, [col("PK", "account_id", "text"), col("", "code_hash", "text"), col("", "expires_at", "timestamp"), col("", "attempts", "integer"), col("", "created_at", "timestamp")]),
        ("DEVICE_TOKENS", 1690, 850, [col("PK", "token", "text"), col("FK", "account_id", "text"), col("", "platform", "varchar"), col("", "updated_at", "timestamp")]),
        ("OWNER_PROFILES", 2490, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer"), col("", "updated_at", "timestamp")]),
        ("DOCTOR_PROFILES", 3290, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer"), col("", "updated_at", "timestamp")]),
        ("STAFF_PROFILES", 90, 1780, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer")]),
        ("ADMIN_PROFILES", 890, 1780, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer")]),
        ("USER_DIRECTORY", 1690, 1780, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer")]),
        ("DOCTOR_VERIFICATIONS", 2490, 1780, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "version", "integer")]),
        ("AUDIT_LOGS", 3290, 1780, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "data", "jsonb"), col("", "created_at", "timestamp")]),
    ]
    for name, x, y, fields in nodes:
        d.add(name, x, y, fields, 720)
        target_card = "many" if name in {"APP_SESSIONS", "DEVICE_TOKENS", "DOCTOR_VERIFICATIONS", "AUDIT_LOGS"} else "one_optional"
        d.relation("APP_ACCOUNTS", name, "bottom", "top", target_card=target_card)
    d.save(OUT / "nways-erd-detail-1-access.png")


def detail_booking():
    d = Diagram(4200, 2800, 1.0)
    d.add("APP_ACCOUNTS", 90, 90, [col("PK", "id", "text"), col("", "full_name", "varchar"), col("", "role", "enum")], 720)
    d.add("PETS", 930, 90, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "name", "varchar"), col("", "species", "varchar"), col("", "data", "jsonb")], 720)
    d.add("APPOINTMENTS", 1770, 90, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("FK", "doctor_id", "text"), col("", "status", "varchar"), col("", "data", "jsonb")], 720)
    d.add("QUEUE_ENTRIES", 2610, 90, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "appointment_id", "text", False), col("", "queue_number", "integer"), col("", "status", "varchar"), col("", "data", "jsonb")], 720)
    d.add("WALK_IN_APPOINTMENTS", 3450, 90, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("", "status", "varchar"), col("", "data", "jsonb")], 680)
    lower = [
        ("HOME_VISITS", 90, 1170, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("", "address", "text"), col("", "status", "varchar")]),
        ("EMERGENCY_REQUESTS", 890, 1170, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("", "symptoms", "text"), col("", "status", "varchar")]),
        ("PET_CARE_BOOKINGS", 1690, 1170, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("", "service", "varchar"), col("", "status", "varchar")]),
        ("REMINDERS", 2490, 1170, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "pet_id", "text"), col("", "scheduled_for", "timestamp"), col("", "data", "jsonb")]),
        ("SAVED_ADDRESSES", 3290, 1170, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "label", "varchar"), col("", "address", "text"), col("", "data", "jsonb")]),
        ("NOTIFICATION_SETTINGS", 490, 2100, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "appointments", "boolean"), col("", "queue_alerts", "boolean")]),
        ("OWNER_NOTIFICATIONS", 1690, 2100, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "title", "varchar"), col("", "message", "text"), col("", "read", "boolean")]),
        ("APPOINTMENT_REMINDERS", 2890, 2100, [col("PK", "appointment_id", "text"), col("PK", "scheduled_for", "timestamp"), col("FK", "owner_id", "text"), col("", "sent_at", "timestamp", False)]),
    ]
    for name, x, y, fields in lower:
        d.add(name, x, y, fields, 720)
    d.relation("APP_ACCOUNTS", "PETS")
    d.relation("PETS", "APPOINTMENTS")
    d.relation("APPOINTMENTS", "QUEUE_ENTRIES")
    d.relation("QUEUE_ENTRIES", "WALK_IN_APPOINTMENTS")
    for target in ["HOME_VISITS", "EMERGENCY_REQUESTS", "PET_CARE_BOOKINGS", "REMINDERS"]:
        d.relation("PETS", target, "bottom", "top")
    d.relation("APP_ACCOUNTS", "SAVED_ADDRESSES", "bottom", "top")
    d.relation("APP_ACCOUNTS", "NOTIFICATION_SETTINGS", "bottom", "top")
    d.relation("REMINDERS", "OWNER_NOTIFICATIONS", "bottom", "top")
    d.relation("APPOINTMENTS", "APPOINTMENT_REMINDERS", "bottom", "top")
    d.save(OUT / "nways-erd-detail-2-booking.png")


def detail_clinical():
    d = Diagram(4200, 2700, 1.0)
    top = [
        ("DOCTOR_PROFILES", 90, 100, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "license_number", "varchar"), col("", "availability", "jsonb")]),
        ("APPOINTMENTS", 900, 100, [col("PK", "id", "text"), col("FK", "pet_id", "text"), col("FK", "doctor_id", "text"), col("", "status", "varchar"), col("", "data", "jsonb")]),
        ("MEDICAL_RECORDS", 1710, 100, [col("PK", "id", "text"), col("FK", "pet_id", "text"), col("FK", "doctor_id", "text"), col("", "diagnosis", "text"), col("", "treatment", "text")]),
        ("PAYMENTS", 2520, 100, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("FK", "service_record_id", "text"), col("", "amount", "numeric"), col("", "status", "varchar")]),
        ("INVENTORY", 3330, 100, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "item_name", "varchar"), col("", "stock", "integer"), col("", "expiry_date", "date", False)]),
    ]
    bottom = [
        ("WALK_IN_APPOINTMENTS", 90, 1300, [col("PK", "id", "text"), col("FK", "pet_id", "text"), col("FK", "doctor_id", "text"), col("", "arrival_time", "timestamp"), col("", "status", "varchar")]),
        ("QUEUE_ENTRIES", 900, 1300, [col("PK", "id", "text"), col("FK", "appointment_id", "text", False), col("FK", "walk_in_id", "text", False), col("", "queue_number", "integer"), col("", "status", "varchar")]),
        ("DOCTOR_APPOINTMENT_STATE", 1710, 1300, [col("PK", "id", "text"), col("FK", "appointment_id", "text"), col("FK", "doctor_id", "text"), col("", "state", "varchar"), col("", "data", "jsonb")]),
        ("QUEUE_DAILY_COUNTERS", 2520, 1300, [col("PK", "clinic_date", "date"), col("", "last_number", "integer"), col("", "updated_at", "timestamp")]),
        ("APPOINTMENT_REMINDERS", 3330, 1300, [col("PK", "appointment_id", "text"), col("PK", "scheduled_for", "timestamp"), col("FK", "owner_id", "text"), col("", "sent_at", "timestamp", False)]),
    ]
    for name, x, y, fields in top + bottom:
        d.add(name, x, y, fields, 720)
    d.relation("DOCTOR_PROFILES", "APPOINTMENTS")
    d.relation("APPOINTMENTS", "MEDICAL_RECORDS")
    d.relation("MEDICAL_RECORDS", "PAYMENTS")
    d.relation("PAYMENTS", "INVENTORY")
    d.relation("DOCTOR_PROFILES", "WALK_IN_APPOINTMENTS", "bottom", "top")
    d.relation("APPOINTMENTS", "QUEUE_ENTRIES", "bottom", "top")
    d.relation("APPOINTMENTS", "DOCTOR_APPOINTMENT_STATE", "bottom", "top")
    d.relation("QUEUE_DAILY_COUNTERS", "QUEUE_ENTRIES", "left", "right")
    d.relation("APPOINTMENTS", "APPOINTMENT_REMINDERS", "bottom", "top")
    d.save(OUT / "nways-erd-detail-3-clinical.png")


def detail_content():
    d = Diagram(4200, 2750, 1.0)
    d.add("APP_ACCOUNTS", 1575, 80, ACCOUNT, 1050)
    nodes = [
        ("HEALTH_POSTS", 90, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "title", "varchar"), col("", "content", "text"), col("", "status", "varchar")]),
        ("HEALTH_POST_DRAFTS", 890, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "title", "varchar"), col("", "content", "text"), col("", "scheduled_for", "timestamp", False)]),
        ("CLINIC_MESSAGES", 1690, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "sender_id", "text"), col("", "recipient_id", "text"), col("", "message", "text")]),
        ("DOCTOR_NOTIFICATIONS", 2490, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "title", "varchar"), col("", "message", "text"), col("", "read", "boolean")]),
        ("SUPPORT_TICKETS", 3290, 850, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "subject", "varchar"), col("", "status", "varchar"), col("", "data", "jsonb")]),
        ("HISTORY_REVIEWS", 90, 1800, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "record_id", "text"), col("", "rating", "integer"), col("", "comment", "text")]),
        ("SAVED_FIRST_AID_GUIDES", 890, 1800, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "guide_id", "text"), col("", "saved_at", "timestamp")]),
        ("CLINIC_DIRECTORY", 1690, 1800, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "name", "varchar"), col("", "specialty", "varchar"), col("", "data", "jsonb")]),
        ("PASSWORD_RESET_AUDIT", 2490, 1800, [col("PK", "id", "bigint"), col("FK", "account_id", "text", False), col("", "identifier", "text"), col("", "event", "varchar"), col("", "created_at", "timestamp")]),
        ("AUDIT_LOGS", 3290, 1800, [col("PK", "id", "text"), col("FK", "owner_id", "text"), col("", "module", "varchar"), col("", "action", "varchar"), col("", "created_at", "timestamp")]),
    ]
    for name, x, y, fields in nodes:
        d.add(name, x, y, fields, 720)
        target_card = "one_optional" if name == "CLINIC_DIRECTORY" else "many"
        d.relation("APP_ACCOUNTS", name, "bottom", "top", target_card=target_card)
    d.relation("HEALTH_POST_DRAFTS", "HEALTH_POSTS", "left", "right", target_card="one_optional")
    d.save(OUT / "nways-erd-detail-4-content-admin.png")


overview()
detail_access()
detail_booking()
detail_clinical()
detail_content()
print(f"Created ERD overview and four detail images in {OUT}")
