from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("/Users/apple/NwaysLoveVetClinic/output/class-diagram/report-style")
OUT.mkdir(parents=True, exist_ok=True)

REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else REGULAR, size)


BG = "#FFFFFF"
CLASS_FILL = "#FFF4DC"
CLASS_BORDER = "#E6D6B2"
TEXT = "#3F3C37"
LINE = "#343434"
RELATION_FILL = "#F0D8F2"
RELATION_TEXT = "#69466D"


class ClassDiagram:
    def __init__(self, width, height, scale=1.0):
        self.image = Image.new("RGB", (width, height), BG)
        self.draw = ImageDraw.Draw(self.image)
        self.nodes = {}
        self.edges = []
        self.scale = scale

    def add(self, name, x, y, attributes, width=620):
        header_h = int(64 * self.scale)
        row_h = int(43 * self.scale)
        padding = int(17 * self.scale)
        height = header_h + row_h * len(attributes) + padding * 2
        self.nodes[name] = {
            "x": x,
            "y": y,
            "w": width,
            "h": height,
            "header_h": header_h,
            "row_h": row_h,
            "attributes": attributes,
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
        label,
        source_mult="1",
        target_mult="*",
        source_side="right",
        target_side="left",
        source_fraction=0.5,
        target_fraction=0.5,
        label_offset=(0, 0),
    ):
        self.edges.append(
            {
                "source": source,
                "target": target,
                "label": label,
                "source_mult": source_mult,
                "target_mult": target_mult,
                "source_side": source_side,
                "target_side": target_side,
                "source_fraction": source_fraction,
                "target_fraction": target_fraction,
                "label_offset": label_offset,
            }
        )

    def _edge_points(self, edge):
        p1 = self.anchor(edge["source"], edge["source_side"], edge["source_fraction"])
        p2 = self.anchor(edge["target"], edge["target_side"], edge["target_fraction"])
        if edge["source_side"] in ("left", "right") and edge["target_side"] in ("left", "right"):
            middle = (p1[0] + p2[0]) // 2
            points = [p1, (middle, p1[1]), (middle, p2[1]), p2]
        elif edge["source_side"] in ("top", "bottom") and edge["target_side"] in ("top", "bottom"):
            middle = (p1[1] + p2[1]) // 2
            points = [p1, (p1[0], middle), (p2[0], middle), p2]
        else:
            points = [p1, (p2[0], p1[1]), p2]
        return p1, p2, points

    def _draw_edge_line(self, edge):
        _p1, _p2, points = self._edge_points(edge)
        self.draw.line(points, fill=LINE, width=max(2, int(3 * self.scale)), joint="curve")

    def _endpoint_text_position(self, point, side):
        x, y = point
        gap = max(12, int(20 * self.scale))
        if side == "left":
            return x - gap * 2, y - gap
        if side == "right":
            return x + gap // 2, y - gap
        if side == "top":
            return x + gap // 2, y - gap * 2
        return x + gap // 2, y + gap // 2

    def _draw_edge_annotations(self, edge):
        p1, p2, points = self._edge_points(edge)
        size = max(14, int(20 * self.scale))
        self.draw.text(
            self._endpoint_text_position(p1, edge["source_side"]),
            edge["source_mult"],
            font=font(size),
            fill=RELATION_TEXT,
        )
        self.draw.text(
            self._endpoint_text_position(p2, edge["target_side"]),
            edge["target_mult"],
            font=font(size),
            fill=RELATION_TEXT,
        )

        # Put the relationship verb on the middle segment, like the report.
        if len(points) == 4:
            a, b = points[1], points[2]
            label_x = (a[0] + b[0]) // 2
            label_y = (a[1] + b[1]) // 2
        else:
            label_x = (p1[0] + p2[0]) // 2
            label_y = (p1[1] + p2[1]) // 2
        label_x += edge["label_offset"][0]
        label_y += edge["label_offset"][1]
        label_font = font(max(14, int(19 * self.scale)))
        box = self.draw.textbbox((0, 0), edge["label"], font=label_font)
        label_w = box[2] - box[0]
        label_h = box[3] - box[1]
        pad_x = max(4, int(7 * self.scale))
        pad_y = max(2, int(4 * self.scale))
        self.draw.rectangle(
            (
                label_x - label_w // 2 - pad_x,
                label_y - label_h // 2 - pad_y,
                label_x + label_w // 2 + pad_x,
                label_y + label_h // 2 + pad_y,
            ),
            fill=RELATION_FILL,
        )
        self.draw.text(
            (label_x - label_w // 2, label_y - label_h // 2 - box[1]),
            edge["label"],
            font=label_font,
            fill=RELATION_TEXT,
        )

    def _draw_node(self, name):
        n = self.nodes[name]
        x, y, w, h = n["x"], n["y"], n["w"], n["h"]
        border_w = max(2, int(2 * self.scale))
        self.draw.rectangle((x, y, x + w, y + h), fill=CLASS_FILL, outline=CLASS_BORDER, width=border_w)
        self.draw.line((x, y + n["header_h"], x + w, y + n["header_h"]), fill=CLASS_BORDER, width=border_w)
        name_font = font(max(17, int(25 * self.scale)), True)
        name_box = self.draw.textbbox((0, 0), name, font=name_font)
        name_w = name_box[2] - name_box[0]
        self.draw.text(
            (x + (w - name_w) // 2, y + int(17 * self.scale)),
            name,
            font=name_font,
            fill=TEXT,
        )
        row_y = y + n["header_h"] + int(18 * self.scale)
        attr_font = font(max(15, int(22 * self.scale)))
        for attribute in n["attributes"]:
            self.draw.text((x + int(20 * self.scale), row_y), f"+{attribute}", font=attr_font, fill=TEXT)
            row_y += n["row_h"]

    def save(self, path):
        for edge in self.edges:
            self._draw_edge_line(edge)
        for name in self.nodes:
            self._draw_node(name)
        for edge in self.edges:
            self._draw_edge_annotations(edge)
        self.image.save(path, optimize=True)


def overview():
    d = ClassDiagram(5600, 3700, 0.62)
    cards = [
        ("UserAccount", 90, 80, ["String id PK", "String username", "String fullName", "AccountRole role"]),
        ("PetOwnerProfile", 1130, 80, ["String id PK", "String accountId FK", "String phone", "String address"]),
        ("DoctorProfile", 2170, 80, ["String id PK", "String accountId FK", "String specialty", "String licenseNumber"]),
        ("StaffProfile", 3210, 80, ["String id PK", "String accountId FK", "String position", "String phone"]),
        ("AdminProfile", 4250, 80, ["String id PK", "String accountId FK", "String displayName", "bool notifications"]),
        ("Pet", 90, 850, ["String id PK", "String ownerId FK", "String name", "String species", "DateTime birthDate"]),
        ("Appointment", 1130, 850, ["String id PK", "String petId FK", "String doctorId FK", "DateTime date", "String status"]),
        ("QueueEntry", 2170, 850, ["String id PK", "String appointmentId FK", "int queueNumber", "String serviceGroup", "String status"]),
        ("HomeVisit", 3210, 850, ["String id PK", "String petId FK", "String doctorId FK", "String address", "String status"]),
        ("EmergencyRequest", 4250, 850, ["String id PK", "String petId FK", "String symptoms", "EmergencyStatus status", "DateTime createdAt"]),
        ("PetCareBooking", 90, 1680, ["String id PK", "String petId FK", "String service", "DateTime date", "String status"]),
        ("MedicalRecord", 1130, 1680, ["String id PK", "String petId FK", "String doctorId FK", "String diagnosis", "String treatment"]),
        ("Payment", 2170, 1680, ["String id PK", "String ownerId FK", "String serviceRecordId FK", "double amount", "String status"]),
        ("InventoryItem", 3210, 1680, ["String id PK", "String name", "String category", "int stock", "DateTime expiryDate"]),
        ("Reminder", 4250, 1680, ["String id PK", "String petId FK", "DateTime scheduledFor", "String title", "bool completed"]),
        ("ClinicMessage", 90, 2510, ["String id PK", "String senderId FK", "String recipientId FK", "String message", "DateTime sentAt"]),
        ("HealthPost", 1130, 2510, ["String id PK", "String authorId FK", "String title", "String content", "String status"]),
        ("SupportTicket", 2170, 2510, ["String id PK", "String ownerId FK", "String subject", "SupportStatus status", "DateTime createdAt"]),
        ("DoctorApplication", 3210, 2510, ["String id PK", "String licenseNumber", "String qualifications", "VerificationStatus status", "String decisionReason"]),
        ("AuditEntry", 4250, 2510, ["String id PK", "String actor", "String module", "String action", "DateTime timestamp"]),
    ]
    for name, x, y, attrs in cards:
        d.add(name, x, y, attrs, 820)

    d.relation("UserAccount", "PetOwnerProfile", "owns", "1", "0..1")
    d.relation("UserAccount", "DoctorProfile", "owns", "1", "0..1")
    d.relation("UserAccount", "StaffProfile", "owns", "1", "0..1")
    d.relation("UserAccount", "AdminProfile", "owns", "1", "0..1")
    d.relation("PetOwnerProfile", "Pet", "registers", "1", "*", "bottom", "top")
    d.relation("Pet", "Appointment", "books", "1", "*", label_offset=(0, -25))
    d.relation("Appointment", "QueueEntry", "creates", "1", "0..1", label_offset=(0, -25))
    d.relation("Appointment", "HomeVisit", "may become", "1", "0..1", label_offset=(0, 30))
    d.relation("Pet", "EmergencyRequest", "has emergency", "1", "*", "bottom", "top", label_offset=(0, -25))
    d.relation("Pet", "PetCareBooking", "receives care", "1", "*", "bottom", "top")
    d.relation("Appointment", "MedicalRecord", "produces", "1", "0..*", "bottom", "top")
    d.relation("MedicalRecord", "Payment", "is billed by", "1", "0..1")
    d.relation("Payment", "InventoryItem", "charges items", "*", "*", label_offset=(0, -25))
    d.relation("Pet", "Reminder", "has", "1", "*", "bottom", "top", label_offset=(0, 25))
    d.relation("UserAccount", "ClinicMessage", "sends", "1", "*", "bottom", "top")
    d.relation("DoctorProfile", "HealthPost", "publishes", "1", "*", "bottom", "top")
    d.relation("UserAccount", "SupportTicket", "submits", "1", "*", "bottom", "top")
    d.relation("DoctorProfile", "DoctorApplication", "is verified by", "1", "0..1", "bottom", "top")
    d.relation("AdminProfile", "AuditEntry", "records", "1", "*", "bottom", "top")
    d.save(OUT / "nways-class-diagram-overview.png")


def detail_one():
    d = ClassDiagram(4400, 2100, 1.0)
    cards = [
        ("AppSession", 120, 480, ["String tokenHash PK", "String accountId FK", "AccountRole role", "DateTime expiresAt", "DateTime createdAt"]),
        ("DeviceToken", 840, 480, ["String token PK", "String accountId FK", "String platform", "DateTime updatedAt"]),
        ("SavedAddress", 1560, 480, ["String id PK", "String ownerId FK", "String label", "String address", "bool isDefault"]),
        ("NotificationPreferences", 2280, 480, ["String id PK", "String ownerId FK", "bool appointmentAlerts", "bool emergencyAlerts", "bool queueAlerts"]),
        ("ClinicPerson", 3000, 480, ["String id PK", "String name", "String role", "String specialty", "String photoAsset"]),
        ("QueueDailyCounter", 3720, 480, ["DateTime clinicDate PK", "int lastNumber"]),
    ]
    for name, x, y, attrs in cards:
        d.add(name, x, y, attrs, 600)
    d.save(OUT / "nways-class-diagram-detail-1.png")


def detail_two():
    d = ClassDiagram(4400, 2700, 1.0)
    d.add("Appointment", 1550, 120, [
        "String id PK", "String ownerId FK", "String petId FK", "String doctorId FK",
        "String service", "DateTime date", "String time", "String status",
    ], 820)
    d.add("MedicalRecord", 500, 1230, [
        "String id PK", "String appointmentId FK", "String petId FK", "String doctorId FK",
        "String diagnosis", "String treatment", "String prescription", "String followUp",
    ], 780)
    d.add("DoctorAppointmentState", 1450, 1230, [
        "String appointmentId PK", "String status", "String consultationNotes",
        "String diagnosis", "String treatment", "String vaccination",
    ], 860)
    d.add("Payment", 2480, 1230, [
        "String id PK", "String ownerId FK", "String serviceRecordId FK",
        "double amount", "String paymentMethod", "String status", "DateTime paidAt",
    ], 760)
    d.add("InventoryItem", 3420, 1230, [
        "String id PK", "String name", "String category", "int stock",
        "double unitPrice", "DateTime expiryDate",
    ], 760)
    d.relation("Appointment", "MedicalRecord", "produces", "1", "0..*", "bottom", "top", source_fraction=0.2)
    d.relation("Appointment", "DoctorAppointmentState", "tracks", "1", "0..1", "bottom", "top", source_fraction=0.45)
    d.relation("Appointment", "Payment", "generates", "1", "0..1", "bottom", "top", source_fraction=0.7)
    d.relation("Payment", "InventoryItem", "includes", "*", "*", label_offset=(0, -30))
    d.save(OUT / "nways-class-diagram-detail-2.png")


def detail_three():
    d = ClassDiagram(4700, 3100, 0.9)
    top = [
        ("UserAccount", 80, 80, ["String id PK", "String username", "String fullName", "String email", "String phone", "AccountRole role"]),
        ("PetOwnerProfile", 1010, 80, ["String id PK", "String accountId FK", "String displayName", "String phone", "String address"]),
        ("DoctorProfile", 1940, 80, ["String id PK", "String accountId FK", "String specialty", "String licenseNumber", "List<String> availability"]),
        ("StaffProfile", 2870, 80, ["String id PK", "String accountId FK", "String position", "String phone"]),
        ("Pet", 3800, 80, ["String id PK", "String ownerId FK", "String name", "String species", "String breed", "DateTime birthDate"]),
    ]
    lower = [
        ("Appointment", 220, 1430, ["String id PK", "String petId FK", "String doctorId FK", "String service", "DateTime date", "String status"]),
        ("QueueEntry", 1250, 1430, ["String id PK", "String appointmentId FK", "int queueNumber", "String serviceGroup", "String status"]),
        ("HomeVisit", 2280, 1430, ["String id PK", "String petId FK", "String doctorId FK", "String address", "DateTime scheduledFor", "String status"]),
        ("EmergencyRequest", 3310, 1430, ["String id PK", "String petId FK", "String symptoms", "String location", "EmergencyStatus status", "DateTime createdAt"]),
    ]
    for name, x, y, attrs in top + lower:
        d.add(name, x, y, attrs, 790)
    d.relation("UserAccount", "PetOwnerProfile", "owns", "1", "0..1")
    d.relation("UserAccount", "DoctorProfile", "owns", "1", "0..1", label_offset=(0, -28))
    d.relation("UserAccount", "StaffProfile", "owns", "1", "0..1", label_offset=(0, 28))
    d.relation("PetOwnerProfile", "Pet", "registers", "1", "*", label_offset=(0, -30))
    d.relation("Pet", "Appointment", "is booked for", "1", "*", "bottom", "top", target_fraction=0.2)
    d.relation("DoctorProfile", "Appointment", "conducts", "1", "*", "bottom", "top", target_fraction=0.5)
    d.relation("Appointment", "QueueEntry", "creates", "1", "0..1", label_offset=(0, -30))
    d.relation("Pet", "HomeVisit", "receives", "1", "*", "bottom", "top")
    d.relation("Pet", "EmergencyRequest", "has", "1", "*", "bottom", "top")
    d.save(OUT / "nways-class-diagram-detail-3.png")


def detail_four():
    d = ClassDiagram(4700, 3100, 0.9)
    top = [
        ("HealthPost", 100, 100, ["String id PK", "String authorId FK", "String title", "String content", "String status", "DateTime publishedAt"]),
        ("HealthPostDraft", 1030, 100, ["String id PK", "String doctorId FK", "String title", "String content", "DateTime scheduledFor"]),
        ("ClinicMessage", 1960, 100, ["String id PK", "String senderId FK", "String recipientId FK", "String message", "DateTime sentAt", "bool read"]),
        ("OwnerNotification", 2890, 100, ["String id PK", "String ownerId FK", "String title", "String message", "String type", "bool read"]),
        ("SupportTicket", 3820, 100, ["String id PK", "String ownerId FK", "String subject", "String description", "SupportStatus status", "DateTime createdAt"]),
    ]
    lower = [
        ("AdminUser", 250, 1510, ["String id PK", "String name", "String email", "AdminUserRole role", "AdminAccountStatus status"]),
        ("DoctorApplication", 1400, 1510, ["String id PK", "String licenseNumber", "String qualifications", "List<String> documents", "VerificationStatus status", "String decisionReason"]),
        ("AuditEntry", 2550, 1510, ["String id PK", "String actor", "String module", "String action", "String record", "DateTime timestamp"]),
        ("SavedFirstAidGuide", 3700, 1510, ["String id PK", "String ownerId FK", "String guideId", "DateTime savedAt"]),
    ]
    for name, x, y, attrs in top + lower:
        d.add(name, x, y, attrs, 800)
    d.relation("HealthPostDraft", "HealthPost", "publishes as", "1", "0..1", "left", "right", label_offset=(0, -30))
    d.relation("ClinicMessage", "OwnerNotification", "triggers", "1", "0..*", label_offset=(0, -30))
    d.relation("SupportTicket", "AdminUser", "reviewed by", "*", "0..1", "bottom", "top")
    d.relation("AdminUser", "DoctorApplication", "reviews", "1", "*", label_offset=(0, -30))
    d.relation("AdminUser", "AuditEntry", "creates", "1", "*", label_offset=(0, 30))
    d.relation("OwnerNotification", "SavedFirstAidGuide", "links to", "*", "0..1", "bottom", "top")
    d.save(OUT / "nways-class-diagram-detail-4.png")


overview()
detail_one()
detail_two()
detail_three()
detail_four()
print(f"Created class diagram overview and four details in {OUT}")
