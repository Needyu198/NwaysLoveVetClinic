import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/apple/NwaysLoveVetClinic";
const buildDir = path.join(workspaceDir, ".codex-build/full-database-presentation");
const previewDir = path.join(buildDir, "previews");
const finalPath = path.join(workspaceDir, "output", "Nways_Love_Complete_Database_Design_v2.pptx");
const skillDir = "/Users/apple/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations";
const pythonExecutable = "/Users/apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const font = "Avenir Next";

const C = {
  bg: "#F1F3F8",
  navy: "#182E55",
  blue: "#2C6CB5",
  text: "#53647D",
  panel: "#FFFFFF",
  panelLine: "#D7DFEA",
  tableHead: "#E5E7EA",
  accountHead: "#DCE7F6",
  ownerHead: "#DDF2EB",
  clinicHead: "#E7E1F3",
  privateHead: "#F8E8D0",
  line: "#4C5663",
};

const fixed = [
  "pet_owners", "app_accounts", "app_sessions", "password_reset_codes",
  "password_reset_audit", "device_tokens", "appointment_reminders", "queue_daily_counters",
];
const groups = [
  {
    title: "Owner profile and preferences",
    subtitle: "Personal details, pets, saved choices and owner-facing history",
    anchor: "app_accounts",
    tables: [
      ["clinic_directory", "clinic"], ["owner_profiles", "private"], ["pets", "owner"],
      ["reminders", "owner"], ["owner_notifications", "owner"], ["saved_addresses", "private"],
      ["notification_settings", "private"], ["history_reviews", "private"],
      ["saved_first_aid_guides", "private"],
    ],
    points: [
      ["owner_profiles", "contact and profile information"],
      ["pets", "pet identity and profile data"],
      ["saved settings", "addresses and notification preferences"],
      ["owner history", "reviews, reminders and saved first-aid guides"],
      ["clinic_directory", "shared clinic contact information"],
    ],
  },
  {
    title: "Appointments and service bookings",
    subtitle: "Medical, home-visit and pet-care workflows remain separate",
    anchor: "app_accounts",
    tables: [
      ["appointments", "owner"], ["queue_entries", "owner"], ["home_visits", "owner"],
      ["pet_care_bookings", "owner"], ["emergency_requests", "owner"],
      ["walk_in_appointments", "clinic"], ["doctor_appointment_state", "clinic"],
    ],
    points: [
      ["appointments", "medical-service bookings"],
      ["home_visits", "services at the owner's address"],
      ["pet_care_bookings", "grooming, bathing, nail trimming and boarding"],
      ["queue tables", "check-in order and walk-in processing"],
      ["doctor state", "clinic view of appointment progress"],
    ],
  },
  {
    title: "Clinical content and communication",
    subtitle: "Clinic records and messages use role-controlled access",
    anchor: "clinic roles",
    tables: [
      ["medical_records", "clinic"], ["health_posts", "clinic"],
      ["health_post_drafts", "private"], ["clinic_messages", "owner"],
      ["support_tickets", "owner"], ["doctor_notifications", "private"],
      ["doctor_profiles", "private"],
    ],
    points: [
      ["medical_records", "treatment history written by clinic roles"],
      ["health content", "published posts and doctor drafts"],
      ["clinic_messages", "owner conversations with the clinic"],
      ["support_tickets", "reported questions and problems"],
      ["doctor data", "profiles and private notifications"],
    ],
  },
  {
    title: "Clinic operations and administration",
    subtitle: "Operational and administrative records support daily control",
    anchor: "staff and admin",
    tables: [
      ["payments", "clinic"], ["inventory", "clinic"], ["staff_profiles", "private"],
      ["user_directory", "admin"], ["doctor_verifications", "admin"],
      ["audit_logs", "admin"], ["admin_profiles", "private"],
    ],
    points: [
      ["payments", "billing and payment status"],
      ["inventory", "medicine and product stock"],
      ["staff_profiles", "private staff account details"],
      ["verification", "administrator review of doctor accounts"],
      ["audit_logs", "append-only record of administrative actions"],
    ],
  },
];

const expectedResources = groups.flatMap(group => group.tables.map(([name]) => name));
const allNames = [...fixed, ...expectedResources];
if (allNames.length !== 38 || new Set(allNames).size !== 38) {
  throw new Error(`Expected 38 unique tables, found ${allNames.length} entries and ${new Set(allNames).size} unique names.`);
}

function addText(slide, text, x, y, w, h, size, color, bold = false, options = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: font,
    fontSize: size,
    color,
    bold,
    alignment: options.alignment || "left",
    verticalAlignment: options.verticalAlignment || "middle",
  };
  shape.text.insets = options.insets ?? 0;
  return shape;
}

function addRichLine(slide, label, description, y) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left: 72, top: y, width: 400, height: 54 },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = [[
    { run: `${label}: `, style: { typeface: font, fontSize: "15pt", bold: true, color: C.navy } },
    { run: description, style: { typeface: font, fontSize: "15pt", color: C.text } },
  ]];
  shape.text.insets = 0;
}

function addLine(slide, x1, y1, x2, y2, width = 1.25, color = C.line) {
  slide.shapes.add({
    geometry: "line",
    position: { left: x1, top: y1, width: x2 - x1, height: y2 - y1 },
    fill: "none",
    line: { style: "solid", fill: color, width },
  });
}

function headerFill(scope, account = false) {
  if (account) return C.accountHead;
  if (scope === "owner") return C.ownerHead;
  if (scope === "clinic" || scope === "admin") return C.clinicHead;
  if (scope === "private") return C.privateHead;
  return C.tableHead;
}

function addTable(slide, { x, y, w, h, title, fields, scope = "system", account = false }) {
  slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height: h },
    fill: C.panel,
    line: { style: "solid", fill: C.line, width: account ? 1.5 : 1.1 },
  });
  slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height: 25 },
    fill: headerFill(scope, account),
    line: { style: "solid", fill: C.line, width: account ? 1.5 : 1.1 },
  });
  const titleSize = title.length > 20 ? 8.4 : title.length > 15 ? 9.3 : 10.5;
  addText(slide, title, x + 5, y + 2, w - 10, 20, titleSize, C.navy, true, { alignment: "center" });
  const available = h - 31;
  const rowHeight = available / fields.length;
  fields.forEach((field, index) => {
    const [tag, name, type] = field;
    const rowY = y + 28 + index * rowHeight;
    if (tag) addText(slide, tag, x + 5, rowY, 22, rowHeight, 7.2, C.navy, true);
    addText(slide, name, x + 29, rowY, w * 0.53, rowHeight, 7.7, C.navy, index === 0);
    addText(slide, type, x + w * 0.73, rowY, w * 0.23, rowHeight, 6.8, C.text, false, { alignment: "right" });
  });
}

function addFrame(slide, category, title, subtitle, number) {
  slide.background.fill = C.bg;
  addText(slide, category.toUpperCase(), 72, 72, 380, 28, 14, C.blue, true);
  addText(slide, title, 72, 114, 410, 145, 39, C.navy, true);
  addText(slide, subtitle, 72, 262, 400, 56, 16, C.text);
  addText(slide, `Nway's Love Vet Clinic  ·  Database Design  ·  ${String(number).padStart(2, "0")}`, 72, 666, 430, 22, 12.5, "#65758D");
  slide.shapes.add({
    geometry: "roundRect",
    position: { left: 525, top: 52, width: 690, height: 612 },
    fill: C.panel,
    line: { style: "solid", fill: C.panelLine, width: 1 },
    borderRadius: "rounded-2xl",
  });
}

function genericFields() {
  return [
    ["PK", "id", "text"],
    ["", "owner_id", "text"],
    ["", "data", "jsonb"],
    ["", "version", "integer"],
  ];
}

function addResourceMap(slide, anchor, tables) {
  const anchorX = 555;
  const anchorY = 184;
  addTable(slide, {
    x: anchorX, y: anchorY, w: 150, h: 226, title: anchor, account: true,
    fields: [
      ["PK", "id", "text"], ["", "role", "text"],
      ["", "scope", "access"], ["", "status", "state"],
    ],
  });

  const busX = 724;
  const leftX = 755;
  const rightX = 985;
  const startY = 82;
  const gapY = 105;
  const boxW = 200;
  const boxH = 96;
  const leftCount = Math.ceil(tables.length / 2);
  const leftTables = tables.slice(0, leftCount);
  const rightTables = tables.slice(leftCount);
  const allPositions = [];
  leftTables.forEach((entry, index) => allPositions.push([entry, leftX, startY + index * gapY]));
  rightTables.forEach((entry, index) => allPositions.push([entry, rightX, startY + index * gapY]));

  addLine(slide, 705, 298, busX, 298);
  const centers = allPositions.map(([, , y]) => y + boxH / 2);
  addLine(slide, busX, Math.min(...centers), busX, Math.max(...centers));
  allPositions.forEach(([[name, scope], x, y]) => {
    addLine(slide, busX, y + boxH / 2, x, y + boxH / 2);
    addText(slide, "N", x - 17, y + boxH / 2 - 11, 14, 16, 7.5, C.line, true, { alignment: "center" });
    addTable(slide, { x, y, w: boxW, h: boxH, title: name, fields: genericFields(), scope });
  });
  addText(slide, "1", 708, 284, 14, 16, 7.5, C.line, true, { alignment: "center" });
  addText(slide, "Header color shows access scope", 555, 620, 310, 18, 9.2, C.text);
  addText(slide, "owner", 885, 620, 58, 18, 8.5, "#287B66", true, { alignment: "center" });
  addText(slide, "clinic/admin", 956, 620, 90, 18, 8.5, "#69548A", true, { alignment: "center" });
  addText(slide, "private", 1056, 620, 65, 18, 8.5, "#9A672B", true, { alignment: "center" });
}

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

async function main() {
  await fs.mkdir(previewDir, { recursive: true });
  await fs.mkdir(path.dirname(finalPath), { recursive: true });
  const deck = Presentation.create({ slideSize: { width: 1280, height: 720 } });
  deck.theme.defaultFont = font;

  // Slide 1: eight fixed system tables.
  {
    const slide = deck.slides.add();
    addFrame(slide, "Database foundation", "Identity and system tables", "Eight tables support login, recovery, notifications and queue numbering", 1);
    const points = [
      ["app_accounts", "identity, role and account status"],
      ["app_sessions", "hashed login sessions with expiry"],
      ["password reset", "verification codes and audit events"],
      ["device tokens", "push-notification destinations"],
      ["system helpers", "appointment reminders and daily queue counters"],
      ["pet_owners", "legacy owner records migrated into accounts"],
    ];
    points.forEach((point, index) => addRichLine(slide, point[0], point[1], 330 + index * 50));

    // Connections behind boxes.
    addLine(slide, 765, 300, 790, 300);
    addLine(slide, 790, 124, 790, 562);
    const peripheral = [
      { x: 815, y: 80, w: 175, h: 120, title: "pet_owners", fields: [["PK", "id", "serial"], ["", "username", "text"], ["", "password_hash", "text"], ["", "full_name", "text"]] },
      { x: 1000, y: 80, w: 175, h: 120, title: "app_sessions", fields: [["PK", "token_hash", "text"], ["", "account_id", "text"], ["", "role", "text"], ["", "expires_at", "timestamptz"]] },
      { x: 815, y: 220, w: 175, h: 120, title: "password_reset_codes", fields: [["PK", "account_id", "text"], ["", "code_hash", "text"], ["", "expires_at", "timestamptz"], ["", "attempts", "integer"]] },
      { x: 1000, y: 220, w: 175, h: 120, title: "password_reset_audit", fields: [["PK", "id", "bigserial"], ["", "event", "text"], ["", "account_id", "text"], ["", "created_at", "timestamptz"]] },
      { x: 815, y: 360, w: 175, h: 120, title: "device_tokens", fields: [["PK", "token", "text"], ["", "account_id", "text"], ["", "platform", "text"], ["", "updated_at", "timestamptz"]] },
      { x: 1000, y: 360, w: 175, h: 120, title: "appointment_reminders", fields: [["PK", "appointment_id", "text"], ["PK", "scheduled_for", "timestamptz"], ["", "owner_id", "text"], ["", "sent_at", "timestamptz"]] },
      { x: 815, y: 500, w: 175, h: 120, title: "queue_daily_counters", fields: [["PK", "clinic_date", "date"], ["", "last_number", "integer"]] },
    ];
    peripheral.forEach(item => {
      addLine(slide, 790, item.y + item.h / 2, item.x, item.y + item.h / 2);
      addTable(slide, item);
    });
    addTable(slide, {
      x: 555, y: 150, w: 210, h: 300, title: "app_accounts", account: true,
      fields: [
        ["PK", "id", "text"], ["", "username", "text"], ["", "email", "text"],
        ["", "phone", "text"], ["", "password_hash", "text"], ["", "full_name", "text"],
        ["", "role", "text"], ["", "active", "boolean"], ["", "created_at", "timestamptz"],
      ],
    });
    addText(slide, "8 foundation tables", 1032, 552, 143, 20, 9, C.blue, true, { alignment: "right" });
    slide.speakerNotes.text = [
      "The foundation contains eight PostgreSQL tables.",
      "app_accounts is the primary identity table. Sessions, reset records, device tokens and operational helper tables support authentication and notifications.",
      "pet_owners is retained for migration compatibility and its records are copied into app_accounts.",
      "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/schema.js",
    ];
    slide.speakerNotes.setVisible(true);
  }

  groups.forEach((group, index) => {
    const slide = deck.slides.add();
    addFrame(slide, "Feature database", group.title, group.subtitle, index + 2);
    group.points.forEach((point, pointIndex) => addRichLine(slide, point[0], point[1], 338 + pointIndex * 56));
    addResourceMap(slide, group.anchor, group.tables);
    addText(slide, `${group.tables.length} feature tables`, 1040, 646, 145, 16, 8.8, C.blue, true, { alignment: "right" });
    slide.speakerNotes.text = [
      `${group.title} contains ${group.tables.length} feature tables.`,
      `Tables on this slide: ${group.tables.map(([name]) => name).join(", ")}.`,
      "Each feature table uses the shared record structure: id, owner_id, JSONB data, version, created_at and updated_at.",
      "Header colors indicate whether the resource uses owner, clinic or private access scope.",
      "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/schema.js; /Users/apple/NwaysLoveVetClinic/backend/src/resources.js",
    ];
    slide.speakerNotes.setVisible(true);
  });

  for (const [index, slide] of deck.slides.items.entries()) {
    await writeBlob(path.join(previewDir, `slide-${index + 1}.png`), await deck.export({ slide, format: "png", scale: 1 }));
    const layout = await slide.export({ format: "layout" });
    await fs.writeFile(path.join(previewDir, `slide-${index + 1}.layout.json`), await layout.text());
  }
  await writeBlob(path.join(previewDir, "montage.webp"), await deck.export({ format: "webp", montage: true }));

  const { finalizePresentation } = await import(pathToFileURL(
    path.join(skillDir, "container_tools/artifact_tool_utils.mjs"),
  ).href);
  const stagingDir = path.join(buildDir, "finalizer");
  await fs.mkdir(stagingDir, { recursive: true });
  const candidatePath = path.join(stagingDir, "candidate.pptx");
  await (await PresentationFile.exportPptx(deck)).save(candidatePath);
  const result = await finalizePresentation({
    explicitTotalSlideCount: 5,
    requiredNativeTableOwnerSlides: [],
    requiredNativeChartOwnerSlides: [],
    workspaceDir,
    candidatePath,
    finalPath,
    pythonExecutable,
    integrityValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_package_integrity.py"),
    layoutValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_layout_geometry.py"),
    layoutArgs: [
      "--expected-slide-size-emu", "12192000,6858000",
      "--validate-bullet-geometry",
      "--validate-heading-fit",
    ],
    fontPolicy: { basis: "design", families: [font] },
    verifyArtifactToolImport: true,
    receiptPath: path.join(stagingDir, "validation-v2.json"),
  });
  console.log(JSON.stringify({ finalPath, tableCount: allNames.length, result }, null, 2));
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
