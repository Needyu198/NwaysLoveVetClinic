from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("output/erd/nways-love-vet-clinic-erd.png")
W, H = 4200, 5600
BG = "#F4F8F6"
INK = "#17211E"
MUTED = "#536762"
LINE = "#78928A"
CARD = "#FFFFFF"
MINT = "#9FE8CD"
BLUE = "#A9C9F2"
ORANGE = "#F7C477"
PURPLE = "#D6C2F0"
RED = "#F2B8B5"


def font(size, bold=False):
    name = (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
        if bold
        else "/System/Library/Fonts/Supplemental/Arial.ttf"
    )
    return ImageFont.truetype(name, size)


TITLE = font(58, True)
SUBTITLE = font(28)
SECTION = font(38, True)
ENTITY = font(25, True)
FIELD = font(20)
KEY = font(19, True)
SMALL = font(18)


img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img)


def rounded_box(box, fill, outline=LINE, radius=24, width=3):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def entity(name, fields, x, y, w=590, header=MINT):
    header_h = 62
    row_h = 31
    pad = 18
    h = header_h + pad + row_h * len(fields) + pad
    rounded_box((x, y, x + w, y + h), CARD, radius=20, width=3)
    draw.rounded_rectangle(
        (x, y, x + w, y + header_h),
        radius=20,
        fill=header,
        outline=LINE,
        width=3,
    )
    draw.rectangle((x, y + 36, x + w, y + header_h), fill=header)
    draw.text((x + 18, y + 15), name, font=ENTITY, fill=INK)
    fy = y + header_h + pad
    for marker, label in fields:
        marker_color = "#246B55" if marker == "PK" else "#8B5A18" if marker == "FK" else MUTED
        if marker:
            draw.text((x + 18, fy), marker, font=KEY, fill=marker_color)
            label_x = x + 72
        else:
            label_x = x + 18
        draw.text((label_x, fy), label, font=FIELD, fill=INK)
        fy += row_h
    return {"name": name, "x": x, "y": y, "w": w, "h": h}


def anchor(node, side):
    if side == "top":
        return (node["x"] + node["w"] // 2, node["y"])
    if side == "bottom":
        return (node["x"] + node["w"] // 2, node["y"] + node["h"])
    if side == "left":
        return (node["x"], node["y"] + node["h"] // 2)
    return (node["x"] + node["w"], node["y"] + node["h"] // 2)


def relation(a, b, label="owns", a_card="1", b_card="0..*", a_side="bottom", b_side="top", color=LINE):
    p1 = anchor(a, a_side)
    p2 = anchor(b, b_side)
    if a_side in ("top", "bottom") and b_side in ("top", "bottom"):
        mid = (p1[1] + p2[1]) // 2
        points = [p1, (p1[0], mid), (p2[0], mid), p2]
    else:
        mid = (p1[0] + p2[0]) // 2
        points = [p1, (mid, p1[1]), (mid, p2[1]), p2]
    draw.line(points, fill=color, width=4, joint="curve")
    draw.ellipse((p1[0] - 6, p1[1] - 6, p1[0] + 6, p1[1] + 6), fill=color)
    draw.ellipse((p2[0] - 6, p2[1] - 6, p2[0] + 6, p2[1] + 6), fill=color)
    draw.text((p1[0] + 8, p1[1] + 4), a_card, font=SMALL, fill=MUTED)
    draw.text((p2[0] + 8, p2[1] - 28), b_card, font=SMALL, fill=MUTED)
    if label:
        mx, my = points[len(points) // 2]
        bbox = draw.textbbox((0, 0), label, font=SMALL)
        tw = bbox[2] - bbox[0]
        rounded_box((mx - tw // 2 - 12, my - 18, mx + tw // 2 + 12, my + 16), BG, outline=BG, radius=10, width=1)
        draw.text((mx - tw // 2, my - 14), label, font=SMALL, fill=MUTED)


def section_box(y1, y2, title, subtitle, accent):
    rounded_box((55, y1, W - 55, y2), "#FAFCFB", outline="#C7D5D0", radius=34, width=4)
    draw.rectangle((55, y1, 73, y2), fill=accent)
    draw.text((105, y1 + 28), title, font=SECTION, fill=INK)
    draw.text((105, y1 + 78), subtitle, font=SUBTITLE, fill=MUTED)


draw.text((90, 55), "Nway's Love Veterinary Clinic", font=TITLE, fill=INK)
draw.text((90, 128), "Entity Relationship Diagram (ERD)", font=SECTION, fill="#2E725D")
draw.text(
    (90, 185),
    "Logical relationships derived from the implemented PostgreSQL and JSONB persistence model",
    font=SUBTITLE,
    fill=MUTED,
)
draw.text((3210, 80), "PK  Primary key", font=SMALL, fill="#246B55")
draw.text((3210, 115), "FK  Foreign key", font=SMALL, fill="#8B5A18")
draw.text((3210, 150), "1 / 0..1 / 0..*  Cardinality", font=SMALL, fill=MUTED)


# Section 1: accounts and access
section_box(255, 1640, "1. Accounts and Access Control", "Authentication, profiles, roles, devices, verification, and auditing", MINT)

account = entity("APP_ACCOUNT", [
    ("PK", "id : string"), ("", "username : string (unique)"), ("", "email : string"),
    ("", "phone : string"), ("", "password_hash : string"), ("", "full_name : string"),
    ("", "role : enum"), ("", "active : boolean"),
], 1800, 375, 600, MINT)

row1_y = 825
nodes1 = [
    entity("APP_SESSION", [("PK", "token_hash"), ("FK", "account_id"), ("", "role"), ("", "expires_at")], 130, row1_y, 590, BLUE),
    entity("PASSWORD_RESET_CODE", [("PK", "account_id"), ("", "code_hash"), ("", "expires_at"), ("", "attempts")], 790, row1_y, 590, BLUE),
    entity("DEVICE_TOKEN", [("PK", "token"), ("FK", "account_id"), ("", "platform"), ("", "updated_at")], 1450, row1_y, 590, BLUE),
    entity("OWNER_PROFILE", [("PK", "id"), ("FK", "owner_id"), ("", "data : JSONB"), ("", "version")], 2110, row1_y, 590, BLUE),
    entity("DOCTOR_PROFILE", [("PK", "id"), ("FK", "owner_id"), ("", "license / specialty"), ("", "availability : JSONB")], 2770, row1_y, 590, BLUE),
    entity("STAFF_PROFILE", [("PK", "id"), ("FK", "owner_id"), ("", "data : JSONB"), ("", "version")], 3430, row1_y, 590, BLUE),
]
row2_y = 1240
nodes2 = [
    entity("ADMIN_PROFILE", [("PK", "id"), ("FK", "owner_id"), ("", "data : JSONB")], 300, row2_y, 590, PURPLE),
    entity("USER_DIRECTORY", [("PK", "id"), ("FK", "owner_id"), ("", "role / status")], 1030, row2_y, 590, PURPLE),
    entity("DOCTOR_VERIFICATION", [("PK", "id"), ("FK", "applicant_account_id"), ("", "license / status")], 1760, row2_y, 590, PURPLE),
    entity("AUDIT_LOG", [("PK", "id"), ("FK", "owner_id"), ("", "module / action"), ("", "created_at")], 2490, row2_y, 590, PURPLE),
    entity("PASSWORD_RESET_AUDIT", [("PK", "id"), ("FK", "account_id"), ("", "event / ip_hash")], 3220, row2_y, 590, PURPLE),
]
for n in nodes1 + nodes2:
    relation(account, n, "has", "1", "0..*" if n["name"] in {"APP_SESSION", "DEVICE_TOKEN", "AUDIT_LOG", "PASSWORD_RESET_AUDIT"} else "0..1")


# Section 2: clinic operations
section_box(1695, 3950, "2. Clinic Operations", "Pets, bookings, queue, clinical records, services, payments, and inventory", ORANGE)

owner_ref = entity("APP_ACCOUNT", [("PK", "id"), ("", "role = petOwner / clinic")], 140, 1870, 520, MINT)
doctor_ref = entity("DOCTOR_PROFILE", [("PK", "id"), ("FK", "owner_id"), ("", "availability")], 720, 1870, 520, BLUE)
pet = entity("PET", [("PK", "id"), ("FK", "owner_id"), ("", "name / species / breed"), ("", "medical_info : JSONB")], 1300, 1870, 560, ORANGE)

appointment = entity("APPOINTMENT", [("PK", "id"), ("FK", "owner_id / pet_id / doctor_id"), ("", "service / date / time"), ("", "status")], 140, 2380, 610, ORANGE)
walkin = entity("WALK_IN_APPOINTMENT", [("PK", "id"), ("FK", "pet_id / doctor_id"), ("", "service / arrival_time"), ("", "status")], 810, 2380, 610, ORANGE)
homevisit = entity("HOME_VISIT", [("PK", "id"), ("FK", "owner_id / pet_id / doctor_id"), ("", "address / slot / reason"), ("", "status")], 1480, 2380, 610, ORANGE)
emergency = entity("EMERGENCY_REQUEST", [("PK", "id"), ("FK", "owner_id / pet_id / doctor_id"), ("", "symptoms / description"), ("", "status")], 2150, 2380, 610, ORANGE)
petcare = entity("PET_CARE_BOOKING", [("PK", "id"), ("FK", "owner_id / pet_id"), ("", "service / provider / slot"), ("", "status")], 2820, 2380, 610, ORANGE)
inventory = entity("INVENTORY", [("PK", "id"), ("FK", "owner_id"), ("", "item / category / brand"), ("", "price / stock / expiry")], 3490, 2380, 570, ORANGE)

queue = entity("QUEUE_ENTRY", [("PK", "id"), ("FK", "appointment / walk-in / booking"), ("", "queue_number / clinic_date"), ("", "status / service_group")], 160, 3000, 610, RED)
medical = entity("MEDICAL_RECORD", [("PK", "id"), ("FK", "pet / doctor / service record"), ("", "diagnosis / treatment"), ("", "prescription / vaccination")], 850, 3000, 610, RED)
payment = entity("PAYMENT", [("PK", "id"), ("FK", "owner_id / service_record_id"), ("", "amount / method"), ("", "status / paid_at")], 1540, 3000, 610, RED)
reminder = entity("REMINDER", [("PK", "id"), ("FK", "owner_id / pet_id"), ("", "type / title / note"), ("", "scheduled_for / completed")], 2230, 3000, 610, RED)
appt_reminder = entity("APPOINTMENT_REMINDER", [("PK", "appointment_id + scheduled_for"), ("FK", "owner_id"), ("", "sent_at")], 2920, 3000, 610, RED)
owner_notification = entity("OWNER_NOTIFICATION", [("PK", "id"), ("FK", "owner_id / appointment_id"), ("", "title / message / read")], 3510, 3000, 550, RED)

counter = entity("QUEUE_DAILY_COUNTER", [("PK", "clinic_date"), ("", "last_number")], 280, 3580, 590, PURPLE)
doctor_state = entity("DOCTOR_APPOINTMENT_STATE", [("PK", "id"), ("FK", "appointment_id / doctor_id"), ("", "state / updated_at")], 1000, 3580, 640, PURPLE)

relation(owner_ref, pet, "owns", "1", "0..*", "right", "left")
for n in [appointment, homevisit, emergency, petcare, reminder]:
    relation(pet, n, "for pet", "1", "0..*", "bottom", "top")
for n in [appointment, walkin, homevisit, emergency, medical]:
    relation(doctor_ref, n, "assigned", "1", "0..*", "bottom", "top", "#567FA3")
relation(appointment, queue, "creates", "1", "0..1")
relation(walkin, queue, "creates", "1", "0..1")
relation(petcare, queue, "creates", "1", "0..1")
for n in [appointment, homevisit, emergency]:
    relation(n, medical, "produces", "1", "0..*", "bottom", "top", "#A35D57")
for n in [appointment, walkin, homevisit, emergency, petcare]:
    relation(n, payment, "billed by", "1", "0..*", "bottom", "top", "#A35D57")
relation(appointment, appt_reminder, "schedules", "1", "0..*", "bottom", "top")
relation(appt_reminder, owner_notification, "creates", "1", "1", "right", "left")
relation(counter, queue, "numbers", "1", "0..*", "top", "bottom")
relation(appointment, doctor_state, "tracks", "1", "0..1", "bottom", "top")


# Section 3: communications and administration
section_box(4005, 5500, "3. Communication, Content, and Support", "Posts, messages, alerts, settings, saved information, and help workflows", BLUE)

acct3 = entity("APP_ACCOUNT", [("PK", "id"), ("", "role / full_name")], 1810, 4180, 580, MINT)
top3_y = 4500
health = entity("HEALTH_POST", [("PK", "id"), ("FK", "author_id"), ("", "title / category / content"), ("", "status / published_at")], 100, top3_y, 610, BLUE)
draft = entity("HEALTH_POST_DRAFT", [("PK", "id"), ("FK", "doctor_id"), ("", "content / scheduled_for")], 780, top3_y, 610, BLUE)
message = entity("CLINIC_MESSAGE", [("PK", "id"), ("FK", "sender_id / recipient_id"), ("", "conversation / message / sent_at")], 1460, top3_y, 610, BLUE)
owner_notice = entity("OWNER_NOTIFICATION", [("PK", "id"), ("FK", "owner_id"), ("", "title / message / read")], 2140, top3_y, 610, BLUE)
doctor_notice = entity("DOCTOR_NOTIFICATION", [("PK", "id"), ("FK", "owner_id"), ("", "title / message / read")], 2820, top3_y, 610, BLUE)
settings = entity("NOTIFICATION_SETTINGS", [("PK", "id"), ("FK", "owner_id"), ("", "appointment / emergency / queue")], 3500, top3_y, 560, BLUE)

bottom3_y = 5050
address = entity("SAVED_ADDRESS", [("PK", "id"), ("FK", "owner_id"), ("", "label / contact / address")], 100, bottom3_y, 590, PURPLE)
support = entity("SUPPORT_TICKET", [("PK", "id"), ("FK", "owner_id"), ("", "subject / message / status")], 760, bottom3_y, 590, PURPLE)
review = entity("HISTORY_REVIEW", [("PK", "id"), ("FK", "owner_id / history_record_id"), ("", "rating / comment")], 1420, bottom3_y, 590, PURPLE)
firstaid = entity("SAVED_FIRST_AID_GUIDE", [("PK", "id"), ("FK", "owner_id"), ("", "guide_id / title / saved_at")], 2080, bottom3_y, 590, PURPLE)
directory = entity("CLINIC_DIRECTORY", [("PK", "account_id"), ("", "name / role / specialty"), ("", "public profile")], 2740, bottom3_y, 590, PURPLE)
verification = entity("DOCTOR_VERIFICATION", [("PK", "id"), ("FK", "applicant_account_id"), ("", "license / documents / status")], 3400, bottom3_y, 610, PURPLE)

for n in [health, draft, message, owner_notice, doctor_notice, settings, address, support, review, firstaid, directory, verification]:
    relation(acct3, n, "owns / participates", "1", "0..*" if n["name"] not in {"NOTIFICATION_SETTINGS", "CLINIC_DIRECTORY", "DOCTOR_VERIFICATION"} else "0..1")
relation(draft, health, "publishes as", "0..1", "0..1", "left", "right", "#567FA3")


draw.text(
    (90, 5545),
    "Physical note: most feature tables store domain fields inside data JSONB and use owner_id for ownership. API rules enforce many logical relationships shown above.",
    font=SMALL,
    fill=MUTED,
)

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT, quality=95)
print(OUT.resolve())
