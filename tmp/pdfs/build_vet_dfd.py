from pathlib import Path
from textwrap import wrap

from reportlab.lib.colors import HexColor, black, white
from reportlab.lib.enums import TA_JUSTIFY
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


OUTPUT = Path("output/pdf/nways-love-vet-clinic-data-flow-diagrams.pdf")
PAGE_W, PAGE_H = letter
ORANGE = HexColor("#F7AE49")
BLUE = HexColor("#315F96")
LINE = HexColor("#31495F")


WORKFLOWS = [
    {
        "title": "User Login and Role-Based Access",
        "actors": ["Pet Owner", "Doctor", "Staff", "System Admin"],
        "stores": ["User Account"],
        "mode": "access",
        "write": "Check credentials",
        "read": "Fetch user role",
        "display": "Load role-based portal",
        "input": "username / password",
        "record": "credentials and role",
        "output": "login result and portal",
        "description": "A user enters a username, email, or phone number and password. The application validates the credentials against the user account data, identifies the account role and status, and opens the correct Pet Owner, Doctor, Staff, or System Admin portal.",
    },
    {
        "title": "Password Recovery",
        "actors": ["Pet Owner", "Doctor", "Staff", "System Admin"],
        "stores": ["User Account", "Password Reset Record"],
        "mode": "manage",
        "write": "Request reset code",
        "read": "Verify reset code",
        "display": "Display reset result",
        "update": "Update password",
        "input": "registered identifier",
        "record": "reset request / code",
        "output": "reset status",
        "description": "A user requests password recovery using a registered identifier. The system locates the account, creates and sends a reset code, verifies the submitted code, and stores the new password after successful validation.",
    },
    {
        "title": "Profile, Security, and Notification Settings",
        "actors": ["Pet Owner", "Doctor", "Staff", "System Admin"],
        "stores": ["User Profile", "Notification Preferences"],
        "mode": "manage",
        "write": "Submit profile changes",
        "read": "Fetch profile and settings",
        "display": "Display profile",
        "update": "Update preferences",
        "input": "profile / security changes",
        "record": "profile and preferences",
        "output": "updated profile",
        "description": "Authenticated users view and update their profile, photo, contact information, password, security options, and role-specific notification preferences. Validated changes are saved and returned to the account interface.",
    },
    {
        "title": "Pet Profile Management (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Pet Record", "Owner Account"],
        "mode": "manage",
        "write": "Create pet profile",
        "read": "Fetch pet records",
        "display": "Display pet profiles",
        "update": "Update pet information",
        "input": "pet identity / medical info",
        "record": "pet record",
        "output": "pet profiles",
        "description": "The pet owner creates, views, and updates pet profiles containing the pet's name, species, breed, sex, weight, photo, vaccine information, and other medical details. Every pet record remains linked to the authenticated owner account.",
    },
    {
        "title": "Appointment Booking and Tracking (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Appointment Record", "Doctor Availability"],
        "mode": "manage",
        "write": "Create appointment",
        "read": "Fetch slots and bookings",
        "display": "Display appointments",
        "update": "Update / cancel booking",
        "input": "pet, service, doctor, date, time",
        "record": "appointment record",
        "output": "booking and status",
        "description": "A pet owner selects a pet, service, veterinarian, date, time, and reason. The application checks doctor availability, stores the booking, and displays appointment details and subsequent confirmation, rescheduling, cancellation, or completion status.",
    },
    {
        "title": "Queue Status and Queue History (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Queue Record", "Appointment Record"],
        "mode": "view",
        "read": "Fetch owner queue entries",
        "display": "Display live queue",
        "input": "owner and appointment ID",
        "record": "queue number / status",
        "output": "live position and history",
        "description": "The pet owner opens the queue screen to retrieve active and historical queue entries linked to the owner's appointments. The application displays the queue number, service group, doctor, current status, and previous queue activity.",
    },
    {
        "title": "Home Visit Booking and Tracking (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Home Visit Record", "Pet Record"],
        "mode": "manage",
        "write": "Create home visit request",
        "read": "Fetch home visits",
        "display": "Display visit status",
        "update": "Update / cancel request",
        "input": "pet, address, reason, slot",
        "record": "home visit record",
        "output": "visit status and record",
        "description": "The pet owner submits a home-visit request with the selected pet, address, contact details, reason, preferred date, and time. The system stores the request and displays assignment, progress, completion, and the resulting home-visit medical record.",
    },
    {
        "title": "Emergency Service Request and Tracking (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Emergency Request", "Pet Record"],
        "mode": "manage",
        "write": "Submit emergency request",
        "read": "Fetch emergency status",
        "display": "Display case status",
        "update": "Update contact details",
        "input": "symptoms / description / contact",
        "record": "emergency case",
        "output": "case status and record",
        "description": "A pet owner reports an emergency by selecting a pet and providing symptoms, a description, and contact details. The application stores the case and displays staff review, acceptance, arrival, treatment, and the completed emergency medical record.",
    },
    {
        "title": "Pet-Care Service Booking (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Pet-Care Booking", "Service Catalogue"],
        "mode": "manage",
        "write": "Create service booking",
        "read": "Fetch services and bookings",
        "display": "Display booking status",
        "update": "Update / cancel booking",
        "input": "pet, service, date, time",
        "record": "pet-care booking",
        "output": "service summary and status",
        "description": "The pet owner selects a grooming, bathing, nail-trimming, boarding, or wellness service and submits the pet, date, and time information. The system stores the service booking and returns its summary and current status.",
    },
    {
        "title": "Pet Reminder Management (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Reminder Record", "Pet Record"],
        "mode": "manage",
        "write": "Create reminder",
        "read": "Fetch reminders",
        "display": "Display reminders",
        "update": "Complete / delete reminder",
        "input": "type, pet, date, note",
        "record": "reminder record",
        "output": "upcoming / completed reminders",
        "description": "The pet owner creates reminders for medicine, vaccines, checkups, or other care tasks. The application stores each reminder, retrieves upcoming and completed items, and records completion or deletion commands.",
    },
    {
        "title": "Medical and Treatment History Viewing (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Medical Record", "Appointment Record", "Service Records"],
        "mode": "view",
        "read": "Fetch pet history",
        "display": "Display history details",
        "input": "owner ID / pet ID",
        "record": "visits and treatment records",
        "output": "medical, vaccine, and service history",
        "description": "The pet owner requests a selected pet's history. The application combines clinic appointments, diagnoses, prescriptions, vaccinations, home visits, emergencies, pet-care services, and queue records and displays detailed historical information.",
    },
    {
        "title": "Products and Clinic Information Viewing (Pet Owner)",
        "actors": ["Pet Owner"],
        "stores": ["Product Inventory", "Doctor Posts", "Clinic Directory"],
        "mode": "view",
        "read": "Fetch products and information",
        "display": "Display selected content",
        "input": "category / search selection",
        "record": "products, posts, clinic info",
        "output": "catalogue and clinic guidance",
        "description": "The pet owner browses products, doctor profiles, medical services, health posts, first-aid guides, clinic contact information, and available service categories. The application retrieves and displays the selected information without changing operational records.",
    },
    {
        "title": "Doctor Appointment and Queue Management",
        "actors": ["Doctor"],
        "stores": ["Appointment Record", "Queue Record"],
        "mode": "manage",
        "write": "Update appointment state",
        "read": "Fetch assigned cases",
        "display": "Display schedule and queue",
        "update": "Call / serve / complete patient",
        "input": "appointment / queue action",
        "record": "doctor appointment state",
        "output": "schedule and active queue",
        "description": "The doctor retrieves assigned appointments and the live patient queue, opens patient details, and records workflow actions such as calling the next patient, starting a consultation, marking a patient missed, or completing the visit.",
    },
    {
        "title": "Doctor Consultation and Medical Record Update",
        "actors": ["Doctor"],
        "stores": ["Medical Record", "Pet Record", "Appointment Record"],
        "mode": "manage",
        "write": "Record consultation",
        "read": "Fetch pet history",
        "display": "Display clinical details",
        "update": "Update diagnosis / treatment",
        "input": "symptoms, diagnosis, treatment, prescription",
        "record": "consultation and medical record",
        "output": "saved clinical record",
        "description": "During a consultation, the doctor reviews the pet profile and previous history, records symptoms and findings, enters diagnosis, treatment, prescription, vaccination, and follow-up details, and stores the completed medical record.",
    },
    {
        "title": "Doctor Emergency and Home-Visit Handling",
        "actors": ["Doctor"],
        "stores": ["Emergency Request", "Home Visit Record", "Medical Record"],
        "mode": "manage",
        "write": "Accept assigned case",
        "read": "Fetch assigned requests",
        "display": "Display case details",
        "update": "Advance status / complete record",
        "input": "case action and clinical notes",
        "record": "case status and treatment",
        "output": "assigned work and completion status",
        "description": "The doctor views assigned emergency cases and home visits, reviews owner and pet details, advances the service status, contacts the owner when needed, and records treatment and completion information for the final medical record.",
    },
    {
        "title": "Doctor Health-Post Management",
        "actors": ["Doctor"],
        "stores": ["Doctor Post Record"],
        "mode": "manage",
        "write": "Create post or draft",
        "read": "Fetch doctor posts",
        "display": "Display posts and previews",
        "update": "Edit / schedule / publish / delete",
        "input": "title, category, content, media",
        "record": "post record",
        "output": "draft, scheduled, or published post",
        "description": "The doctor creates health-information posts containing a title, category, content, cover image, and attachments. Drafts can be previewed, edited, scheduled, published, or deleted, and published posts become available to pet owners and staff.",
    },
    {
        "title": "Doctor Profile, Credentials, and Availability",
        "actors": ["Doctor"],
        "stores": ["Doctor Profile", "Availability Record"],
        "mode": "manage",
        "write": "Submit profile / credential changes",
        "read": "Fetch doctor profile",
        "display": "Display professional profile",
        "update": "Update shifts / leave / breaks",
        "input": "license, specialty, shifts, leave",
        "record": "doctor profile and schedule",
        "output": "updated credentials and availability",
        "description": "The doctor maintains contact details, specialty, qualifications, license information, weekly availability, shifts, breaks, and leave. The application validates and stores these details for appointment scheduling and public doctor profiles.",
    },
    {
        "title": "Staff Appointment and Walk-In Management",
        "actors": ["Staff"],
        "stores": ["Appointment Record", "Walk-In Record", "Doctor Availability"],
        "mode": "manage",
        "write": "Register or confirm visit",
        "read": "Fetch appointments and doctors",
        "display": "Display visit details",
        "update": "Reschedule / cancel / check in",
        "input": "booking or walk-in details",
        "record": "appointment / walk-in record",
        "output": "confirmed visit and assigned doctor",
        "description": "Staff retrieve appointment requests, confirm or reschedule bookings, assign doctors, contact owners, cancel visits, check in scheduled patients, and register walk-in patients before sending them to the live queue.",
    },
    {
        "title": "Staff Live Queue Management",
        "actors": ["Staff"],
        "stores": ["Queue Record", "Appointment Record"],
        "mode": "manage",
        "write": "Add patient to queue",
        "read": "Fetch active queue",
        "display": "Display queue by service",
        "update": "Call / arrive / reassign / delay / miss",
        "input": "queue and doctor action",
        "record": "queue entry and status",
        "output": "updated live queue",
        "description": "Staff manage the real-time patient queue by service group and status. They add checked-in patients, call patients, mark arrival, reassign doctors, announce delays, mark missed visits, and monitor completion.",
    },
    {
        "title": "Staff Patient and Medical Record Management",
        "actors": ["Staff"],
        "stores": ["Pet Record", "Owner Account", "Medical Record"],
        "mode": "manage",
        "write": "Register patient information",
        "read": "Fetch patient records",
        "display": "Display pet and owner details",
        "update": "Update medical administration data",
        "input": "owner / pet / record details",
        "record": "patient and medical record",
        "output": "patient profile and history",
        "description": "Staff search pet owners and patients, open pet profiles, review treatment history, and maintain administrative medical-record details needed for clinic operations while preserving the doctor's clinical entries.",
    },
    {
        "title": "Staff Inventory Management",
        "actors": ["Staff"],
        "stores": ["Inventory Record", "Product Images"],
        "mode": "manage",
        "write": "Create inventory item",
        "read": "Fetch stock records",
        "display": "Display inventory",
        "update": "Update / delete item",
        "input": "name, category, stock, price, expiry",
        "record": "inventory item",
        "output": "stock status and product details",
        "description": "Staff create, view, search, update, and remove inventory items. Each record includes product images, category, brand, pet type, price, stock, reorder level, expiry date, and description, allowing the system to identify low-stock and expired items.",
    },
    {
        "title": "Staff Emergency and Home-Visit Coordination",
        "actors": ["Staff"],
        "stores": ["Emergency Request", "Home Visit Record", "Doctor Availability"],
        "mode": "manage",
        "write": "Review incoming request",
        "read": "Fetch cases and doctors",
        "display": "Display request details",
        "update": "Assign doctor / update status",
        "input": "review, assignment, contact action",
        "record": "request assignment and status",
        "output": "coordinated case",
        "description": "Staff review incoming emergency and home-visit requests, contact the owner, select an available doctor, assign the case, and update acceptance, arrival, scheduling, and completion-related administrative status.",
    },
    {
        "title": "Staff Payment Management and Reporting",
        "actors": ["Staff"],
        "stores": ["Payment Record", "Appointment Record", "Inventory Record"],
        "mode": "manage",
        "write": "Create / record payment",
        "read": "Fetch operational data",
        "display": "Display payment and reports",
        "update": "Update payment status",
        "input": "payment details / report criteria",
        "record": "payment and report data",
        "output": "receipt, totals, and reports",
        "description": "Staff record and review payments and generate operational reports from appointment, service, payment, and inventory information. The system returns report results and stores the latest payment status for clinic accounting.",
    },
    {
        "title": "Staff Messaging",
        "actors": ["Staff"],
        "stores": ["Message Record", "User Account"],
        "mode": "manage",
        "write": "Send message",
        "read": "Fetch conversations",
        "display": "Display chat history",
        "update": "Update conversation state",
        "input": "recipient and message text",
        "record": "message record",
        "output": "conversation history",
        "description": "Staff retrieve user conversations, open a selected thread, and send messages. Each message is stored with sender, recipient, conversation, and time information so the complete communication history can be displayed and traced.",
    },
    {
        "title": "System Administrator User and Role Management",
        "actors": ["System Admin"],
        "stores": ["User Account", "Audit Log"],
        "mode": "manage",
        "write": "Create user account",
        "read": "Fetch users and roles",
        "display": "Display account directory",
        "update": "Activate / suspend / change role / delete",
        "input": "account, role, status, reason",
        "record": "user and audit record",
        "output": "updated account directory",
        "description": "The System Administrator creates accounts, searches and views users, assigns roles, activates or suspends accounts, changes account roles, and deletes accounts. Every sensitive action is recorded in the audit log.",
    },
    {
        "title": "System Administrator Doctor Verification",
        "actors": ["System Admin"],
        "stores": ["Doctor Application", "User Account", "Audit Log"],
        "mode": "manage",
        "write": "Review application",
        "read": "Fetch applications and documents",
        "display": "Display license details",
        "update": "Approve / reject application",
        "input": "verification decision and reason",
        "record": "application status and audit",
        "output": "verification result",
        "description": "The System Administrator retrieves pending doctor applications, reviews contact details, qualifications, license number, expiry date, specialty, and submitted documents, and then approves or rejects the application with a recorded reason.",
    },
    {
        "title": "System Dashboard, Alerts, Reports, and Audit Logs",
        "actors": ["System Admin"],
        "stores": ["User Account", "Appointment / Queue", "Emergency / Home Visit", "Inventory", "Audit Log"],
        "mode": "view",
        "read": "Aggregate operational records",
        "display": "Display dashboard and audit logs",
        "input": "filters / monitoring request",
        "record": "users, operations, alerts, audit entries",
        "output": "counts, alerts, reports, and logs",
        "description": "The System Administrator monitors totals for users, doctors, staff, owners, appointments, and queue entries; reviews doctor-verification, emergency, low-stock, and expiry alerts; and searches the append-only audit trail of sensitive administrative actions.",
    },
]


styles = getSampleStyleSheet()
body_style = ParagraphStyle(
    "Body",
    parent=styles["BodyText"],
    fontName="Helvetica",
    fontSize=10.5,
    leading=15,
    alignment=TA_JUSTIFY,
    textColor=black,
)


def draw_wrapped_center(c, text, x, y, max_chars=19, font_size=6.8, leading=8):
    lines = []
    for part in text.split("\n"):
        lines.extend(wrap(part, max_chars) or [""])
    c.setFont("Helvetica", font_size)
    start = y + (len(lines) - 1) * leading / 2 - font_size / 3
    for i, line in enumerate(lines):
        c.drawCentredString(x, start - i * leading, line)


def draw_actor(c, label, x, y):
    w, h = 76, 34
    c.setFillColor(ORANGE)
    c.setStrokeColor(LINE)
    c.rect(x - w / 2, y - h / 2, w, h, fill=1, stroke=1)
    c.setFillColor(black)
    draw_wrapped_center(c, label, x, y, max_chars=17, font_size=7.2, leading=8)
    return (x, y, w, h)


def draw_process(c, number, label, x, y):
    r = 39
    c.setFillColor(ORANGE)
    c.setStrokeColor(LINE)
    c.circle(x, y, r, fill=1, stroke=1)
    c.setFillColor(black)
    c.setFont("Helvetica", 6.8)
    c.drawCentredString(x, y + 12, f"{number:.1f}")
    draw_wrapped_center(c, label, x, y - 4, max_chars=16, font_size=6.5, leading=7.2)
    return (x, y, r)


def draw_store(c, label, x, y):
    w, h = 112, 38
    left, bottom = x - w / 2, y - h / 2
    c.setStrokeColor(LINE)
    c.setFillColor(white)
    c.rect(left, bottom, w, h, fill=1, stroke=0)
    c.line(left, bottom, left + w, bottom)
    c.line(left, bottom + h, left + w, bottom + h)
    c.line(left + 18, bottom, left + 18, bottom + h)
    c.setFillColor(black)
    draw_wrapped_center(c, label, x + 8, y, max_chars=22, font_size=6.8, leading=7.5)
    return (x, y, w, h)


def boundary_point(node, tx, ty):
    kind = node[0]
    if kind == "circle":
        _, x, y, r = node
        dx, dy = tx - x, ty - y
        d = max((dx * dx + dy * dy) ** 0.5, 0.001)
        return x + r * dx / d, y + r * dy / d
    _, x, y, w, h = node
    dx, dy = tx - x, ty - y
    if abs(dx) * h > abs(dy) * w:
        return x + (w / 2 if dx > 0 else -w / 2), y + dy * (w / 2) / max(abs(dx), 0.001)
    return x + dx * (h / 2) / max(abs(dy), 0.001), y + (h / 2 if dy > 0 else -h / 2)


def draw_arrow(c, source, target, label="", bend=None):
    sx, sy = boundary_point(source, target[1], target[2])
    tx, ty = boundary_point(target, source[1], source[2])
    c.setStrokeColor(LINE)
    c.setFillColor(LINE)
    c.setLineWidth(0.75)
    if bend is None:
        points = [(sx, sy), (tx, ty)]
    elif bend == "h":
        mx = (sx + tx) / 2
        points = [(sx, sy), (mx, sy), (mx, ty), (tx, ty)]
    else:
        my = (sy + ty) / 2
        points = [(sx, sy), (sx, my), (tx, my), (tx, ty)]
    path = c.beginPath()
    path.moveTo(*points[0])
    for p in points[1:]:
        path.lineTo(*p)
    c.drawPath(path, stroke=1, fill=0)
    ax, ay = points[-2]
    bx, by = points[-1]
    angle_dx, angle_dy = bx - ax, by - ay
    length = max((angle_dx * angle_dx + angle_dy * angle_dy) ** 0.5, 0.001)
    ux, uy = angle_dx / length, angle_dy / length
    px, py = -uy, ux
    size = 5
    c.line(bx, by, bx - ux * size + px * 2.2, by - uy * size + py * 2.2)
    c.line(bx, by, bx - ux * size - px * 2.2, by - uy * size - py * 2.2)
    if label:
        mid_index = max(0, (len(points) - 2) // 2)
        x1, y1 = points[mid_index]
        x2, y2 = points[mid_index + 1]
        lx, ly = (x1 + x2) / 2, (y1 + y2) / 2 + 4
        clean = label.replace("\n", " ")
        shown = clean if len(clean) <= 34 else clean[:31] + "..."
        c.setFont("Helvetica", 6.1)
        tw = stringWidth(shown, "Helvetica", 6.1)
        c.setFillColor(white)
        c.rect(lx - tw / 2 - 2, ly - 2, tw + 4, 8, fill=1, stroke=0)
        c.setFillColor(black)
        c.drawCentredString(lx, ly, shown)


def draw_workflow(c, wf, page_number, process_number):
    c.setFillColor(black)
    c.setFont("Helvetica-Bold", 13)
    c.drawString(54, PAGE_H - 65, wf["title"])

    paragraph = Paragraph(wf["description"], body_style)
    _, ph = paragraph.wrap(PAGE_W - 108, 170)
    paragraph.drawOn(c, 54, PAGE_H - 88 - ph)

    diagram_top = min(PAGE_H - 120 - ph, 500)
    diagram_bottom = 78
    center_y = (diagram_top + diagram_bottom) / 2

    actor_nodes = []
    if len(wf["actors"]) == 1:
        actor_y_values = [center_y]
    else:
        spacing = 54
        start = center_y + spacing * (len(wf["actors"]) - 1) / 2
        actor_y_values = [start - i * spacing for i in range(len(wf["actors"]))]
    for label, y in zip(wf["actors"], actor_y_values):
        _, _, w, h = draw_actor(c, label, 88, y)
        actor_nodes.append(("rect", 88, y, w, h))

    store_nodes = []
    store_spacing = 56
    store_start = center_y + store_spacing * (len(wf["stores"]) - 1) / 2
    for i, label in enumerate(wf["stores"]):
        y = store_start - i * store_spacing
        _, _, w, h = draw_store(c, label, 528, y)
        store_nodes.append(("rect", 528, y, w, h))

    p_read_y = center_y + 82
    p_write_y = center_y - 70
    p_display_y = p_read_y
    p_update_y = p_write_y

    processes = {}
    if wf["mode"] == "view":
        draw_process(c, process_number, wf["read"], 370, center_y + 42)
        processes["read"] = ("circle", 370, center_y + 42, 39)
        process_number += 1
        draw_process(c, process_number, wf["display"], 230, center_y + 42)
        processes["display"] = ("circle", 230, center_y + 42, 39)
        process_number += 1
        for store in store_nodes:
            draw_arrow(c, store, processes["read"], wf["record"], bend="h")
        draw_arrow(c, processes["read"], processes["display"], wf["record"])
        for actor in actor_nodes:
            draw_arrow(c, actor, processes["read"], wf["input"], bend="h")
            draw_arrow(c, processes["display"], actor, wf["output"], bend="h")
    else:
        draw_process(c, process_number, wf["read"], 380, p_read_y)
        processes["read"] = ("circle", 380, p_read_y, 39)
        process_number += 1
        draw_process(c, process_number, wf["display"], 235, p_display_y)
        processes["display"] = ("circle", 235, p_display_y, 39)
        process_number += 1
        draw_process(c, process_number, wf["write"], 235, p_write_y)
        processes["write"] = ("circle", 235, p_write_y, 39)
        process_number += 1
        if wf.get("update"):
            draw_process(c, process_number, wf["update"], 380, p_update_y)
            processes["update"] = ("circle", 380, p_update_y, 39)
            process_number += 1

        primary_store = store_nodes[0]
        draw_arrow(c, primary_store, processes["read"], wf["record"], bend="h")
        draw_arrow(c, processes["read"], processes["display"], wf["record"])
        draw_arrow(c, processes["display"], actor_nodes[0], wf["output"], bend="h")
        for actor in actor_nodes:
            draw_arrow(c, actor, processes["write"], wf["input"], bend="h")
        draw_arrow(c, processes["write"], primary_store, wf["record"], bend="h")
        if "update" in processes:
            draw_arrow(c, actor_nodes[-1], processes["update"], "update command", bend="h")
            draw_arrow(c, processes["update"], primary_store, "updated " + wf["record"], bend="h")
        for extra_store in store_nodes[1:]:
            draw_arrow(c, extra_store, processes["read"], "related data", bend="h")
            if "update" in processes:
                draw_arrow(c, processes["update"], extra_store, "related update", bend="h")

    c.setFont("Helvetica", 9)
    c.setFillColor(black)
    c.drawRightString(PAGE_W - 48, 34, str(page_number))
    return process_number


def build():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUTPUT), pagesize=letter)
    c.setTitle("Nway's Love Veterinary Clinic - Data Flow Diagrams")
    c.setAuthor("Nway's Love Veterinary Clinic Project")

    c.setFillColor(BLUE)
    c.setFont("Helvetica-Bold", 19)
    c.drawString(54, PAGE_H - 88, "2. DFD Diagrams")
    c.setFillColor(black)
    c.setFont("Helvetica-Bold", 17)
    c.drawString(54, PAGE_H - 140, "Nway's Love Veterinary Clinic Application")
    intro = Paragraph(
        "The following diagrams use the same feature-by-feature structure as the reference report. "
        "Orange rectangles represent external users, orange circles represent numbered processes, "
        "open rectangles represent data stores, and labeled arrows represent data moving between them.",
        body_style,
    )
    _, h = intro.wrap(PAGE_W - 108, 140)
    intro.drawOn(c, 54, PAGE_H - 176 - h)
    c.setFont("Helvetica", 9)
    c.drawRightString(PAGE_W - 48, 34, "1")
    c.showPage()

    process_number = 1
    page_number = 2
    for wf in WORKFLOWS:
        process_number = draw_workflow(c, wf, page_number, process_number)
        c.showPage()
        page_number += 1

    c.save()


if __name__ == "__main__":
    build()
