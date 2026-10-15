import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/apple/NwaysLoveVetClinic";
const skillDir = "/Users/apple/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations";
const buildDir = path.join(workspaceDir, "tmp/ppt-db-features");
const outputDir = path.join(workspaceDir, "output");
const finalPath = path.join(outputDir, "database_features_appointment_posts_inventory_v2.pptx");
const fontFamily = "Arial";

await fs.mkdir(buildDir, { recursive: true });
await fs.mkdir(outputDir, { recursive: true });

const C = {
  bg: "#F4F6FA",
  navy: "#162B53",
  blue: "#2F6FB8",
  ink: "#27364F",
  muted: "#66738A",
  card: "#FFFFFF",
  border: "#CED5E2",
  header: "#E7E9ED",
  green: "#2A8C72",
  paleGreen: "#E5F4EE",
  paleBlue: "#E7F0FA",
  orange: "#D78031",
  paleOrange: "#FFF0DF",
  line: "#78869A",
};

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

function addText(slide, text, position, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: fontFamily,
    fontSize: 18,
    color: C.ink,
    verticalAlignment: "top",
    autoFit: "shrinkText",
    insets: 0,
    ...style,
  };
  return shape;
}

function addBase(slide, title, subtitle, page) {
  slide.background.fill = C.bg;
  addText(slide, "DATABASE DESIGN", { left: 70, top: 64, width: 340, height: 28 }, {
    fontSize: 15, bold: true, color: C.blue,
  });
  addText(slide, title, { left: 70, top: 112, width: 410, height: 120 }, {
    fontSize: 43, bold: true, color: C.navy, lineSpacing: 0.94,
  });
  addText(slide, subtitle, { left: 70, top: 236, width: 404, height: 68 }, {
    fontSize: 18, color: C.muted, lineSpacing: 1.1,
  });
  addText(slide, `Nway's Love Vet Clinic  ·  ${page}/3`, { left: 70, top: 666, width: 410, height: 22 }, {
    fontSize: 13, color: C.muted,
  });
  slide.shapes.add({
    geometry: "roundRect",
    name: `diagram-surface-${page}`,
    position: { left: 510, top: 58, width: 700, height: 604 },
    fill: C.card,
    line: { style: "solid", fill: "#D8DEE9", width: 1 },
    borderRadius: "rounded-2xl",
    shadow: "shadow-sm",
  });
}

function addBullet(slide, y, heading, body, color = C.blue) {
  slide.shapes.add({
    geometry: "ellipse",
    position: { left: 72, top: y + 5, width: 10, height: 10 },
    fill: color,
    line: { style: "solid", fill: color, width: 0 },
  });
  const box = addText(slide, "", { left: 94, top: y, width: 382, height: 70 }, {
    fontSize: 17, color: C.muted, lineSpacing: 1.08,
  });
  box.text.set([[{ run: heading, style: { bold: true, color: C.navy } }, { run: `: ${body}`, style: { color: C.muted } }]]);
  return box;
}

function addTableBox(slide, { name, x, y, w, rows, accent = C.header }) {
  const rowH = 24;
  const headerH = 32;
  const h = headerH + rows.length * rowH + 6;
  const outer = slide.shapes.add({
    geometry: "rect",
    name: `table-${name}`,
    position: { left: x, top: y, width: w, height: h },
    fill: C.card,
    line: { style: "solid", fill: "#565E68", width: 1.4 },
  });
  slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height: headerH },
    fill: accent,
    line: { style: "solid", fill: "#565E68", width: 1.2 },
  });
  addText(slide, name, { left: x + 8, top: y + 5, width: w - 16, height: 22 }, {
    fontSize: 16, bold: true, color: C.navy, alignment: "center", verticalAlignment: "middle",
  });
  rows.forEach((row, index) => {
    const yy = y + headerH + index * rowH;
    if (index > 0) {
      slide.shapes.add({
        geometry: "line",
        position: { left: x, top: yy, width: w, height: 0 },
        fill: "none",
        line: { style: "solid", fill: "#E2E5EB", width: 0.7 },
      });
    }
    if (row.key) {
      addText(slide, row.key, { left: x + 7, top: yy + 4, width: 28, height: 18 }, {
        fontSize: 11, bold: true, color: row.key === "PK" ? C.blue : C.orange,
      });
    }
    addText(slide, row.field, { left: x + (row.key ? 36 : 12), top: yy + 3, width: w * 0.49, height: 18 }, {
      fontSize: 12.5, bold: row.key === "PK", color: C.ink,
    });
    addText(slide, row.type, { left: x + w * 0.60, top: yy + 3, width: w * 0.37, height: 18 }, {
      fontSize: 10.5, color: C.muted, alignment: "right", wrap: "none",
    });
  });
  return outer;
}

function connect(slide, from, to, { dashed = false, fromSide = "right", toSide = "left" } = {}) {
  const start = {
    x: fromSide === "bottom" ? from.position.left + from.position.width / 2 : from.position.left + from.position.width,
    y: fromSide === "bottom" ? from.position.top + from.position.height : from.position.top + from.position.height / 2,
  };
  const end = {
    x: toSide === "top" ? to.position.left + to.position.width / 2 : to.position.left,
    y: toSide === "top" ? to.position.top : to.position.top + to.position.height / 2,
  };
  return slide.shapes.add({
    geometry: "line",
    position: {
      left: Math.min(start.x, end.x),
      top: Math.min(start.y, end.y),
      width: Math.abs(end.x - start.x),
      height: Math.abs(end.y - start.y),
      horizontalFlip: end.x < start.x,
      verticalFlip: end.y < start.y,
    },
    fill: "none",
    line: { style: dashed ? "dash" : "solid", fill: C.line, width: dashed ? 1.4 : 2 },
  });
}

function addLegend(slide, x, y) {
  slide.shapes.add({ geometry: "line", position: { left: x, top: y + 8, width: 34, height: 0 }, fill: "none", line: { style: "solid", fill: C.line, width: 2 } });
  addText(slide, "Foreign key", { left: x + 42, top: y, width: 110, height: 18 }, { fontSize: 11.5, color: C.muted });
  slide.shapes.add({ geometry: "line", position: { left: x + 145, top: y + 8, width: 34, height: 0 }, fill: "none", line: { style: "dash", fill: C.line, width: 1.4 } });
  addText(slide, "JSONB reference", { left: x + 187, top: y, width: 125, height: 18 }, { fontSize: 11.5, color: C.muted });
}

// Slide 1: Appointment flow
{
  const slide = presentation.slides.add();
  addBase(slide, "Appointment flow", "One booking record connects scheduling, clinic queue, consultation progress, and the final medical record.", 1);
  addBullet(slide, 330, "appointments", "stores the selected pet, service, veterinarian, date, time, and booking status");
  addBullet(slide, 414, "queue_entries", "tracks same-day check-in, queue number, and the live visit status", C.green);
  addBullet(slide, 498, "doctor_appointment_state", "keeps clinical notes and consultation progress private to clinic users", C.orange);
  addBullet(slide, 582, "medical_records", "stores the finalized diagnosis, treatment, prescription, and follow-up");

  const account = addTableBox(slide, { name: "app_accounts", x: 548, y: 118, w: 176, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { field: "role", type: "TEXT" },
    { field: "active", type: "BOOLEAN" },
  ]});
  const appointments = addTableBox(slide, { name: "appointments", x: 790, y: 98, w: 190, accent: C.paleBlue, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
    { field: "updated_at", type: "TIMESTAMPTZ" },
  ]});
  const queue = addTableBox(slide, { name: "queue_entries", x: 1010, y: 98, w: 170, accent: C.paleGreen, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
  ]});
  const state = addTableBox(slide, { name: "doctor_appointment_state", x: 758, y: 356, w: 232, accent: C.paleOrange, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
  ]});
  const records = addTableBox(slide, { name: "medical_records", x: 1018, y: 356, w: 170, accent: C.paleBlue, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "updated_at", type: "TIMESTAMPTZ" },
  ]});
  connect(slide, account, appointments);
  connect(slide, appointments, queue, { dashed: true });
  connect(slide, appointments, state, { dashed: true, fromSide: "bottom", toSide: "top" });
  connect(slide, state, records, { dashed: true });
  addText(slide, "booking", { left: 731, top: 145, width: 55, height: 18 }, { fontSize: 11, color: C.muted, alignment: "center" });
  addText(slide, "check-in", { left: 977, top: 145, width: 42, height: 18 }, { fontSize: 11, color: C.muted, alignment: "center" });
  addText(slide, "consultation", { left: 821, top: 320, width: 95, height: 18 }, { fontSize: 11, color: C.muted, alignment: "center" });
  addText(slide, "finalize", { left: 990, top: 408, width: 42, height: 18 }, { fontSize: 11, color: C.muted, alignment: "center" });
  addLegend(slide, 770, 615);
}

// Slide 2: Doctor posts
{
  const slide = presentation.slides.add();
  addBase(slide, "Doctor posts", "Doctors prepare educational content as private drafts, then publish it to the clinic-wide health feed.", 2);
  addBullet(slide, 330, "health_post_drafts", "stores unfinished content that only the doctor account can access");
  addBullet(slide, 418, "health_posts", "stores published, scheduled, or archived posts for the app and web portal", C.green);
  addBullet(slide, 506, "Access control", "doctors and staff can publish; owners can read the shared clinic feed", C.orange);
  addText(slide, "Post content inside data JSONB", { left: 94, top: 590, width: 310, height: 24 }, { fontSize: 15, bold: true, color: C.navy });
  addText(slide, "title · content · category · audience · images · status · timestamps", { left: 94, top: 620, width: 365, height: 42 }, { fontSize: 14, color: C.muted });

  const account = addTableBox(slide, { name: "app_accounts", x: 548, y: 233, w: 180, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { field: "role", type: "TEXT" },
    { field: "active", type: "BOOLEAN" },
  ]});
  const drafts = addTableBox(slide, { name: "health_post_drafts", x: 805, y: 108, w: 210, accent: C.paleOrange, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
    { field: "updated_at", type: "TIMESTAMPTZ" },
  ]});
  const posts = addTableBox(slide, { name: "health_posts", x: 805, y: 395, w: 210, accent: C.paleGreen, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
    { field: "updated_at", type: "TIMESTAMPTZ" },
  ]});
  connect(slide, account, drafts);
  connect(slide, account, posts);
  connect(slide, drafts, posts, { dashed: true, fromSide: "bottom", toSide: "top" });

  const workflow = slide.shapes.add({
    geometry: "roundRect",
    position: { left: 1045, top: 189, width: 132, height: 286 },
    fill: "#F8FAFD",
    line: { style: "solid", fill: C.border, width: 1 },
    borderRadius: "rounded-xl",
  });
  addText(slide, "Post lifecycle", { left: 1061, top: 209, width: 102, height: 24 }, { fontSize: 15, bold: true, color: C.navy, alignment: "center" });
  for (const [label, yy, fill] of [
    ["Draft", 254, C.paleOrange], ["Scheduled", 316, C.paleBlue], ["Published", 378, C.paleGreen], ["Archived", 440, C.header],
  ]) {
    const step = slide.shapes.add({ geometry: "roundRect", position: { left: 1062, top: yy, width: 98, height: 34 }, fill, line: { style: "solid", fill: C.border, width: 1 }, borderRadius: "rounded-full" });
    addText(slide, label, { left: 1068, top: yy + 7, width: 86, height: 18 }, { fontSize: 12.5, bold: true, color: C.ink, alignment: "center" });
  }
  addLegend(slide, 770, 615);
}

// Slide 3: Inventory
{
  const slide = presentation.slides.add();
  addBase(slide, "Inventory", "A shared inventory record keeps product information, stock quantity, expiry dates, and movement history together.", 3);
  addBullet(slide, 330, "inventory", "stores products and clinic supplies in one table for the mobile app and web portal");
  addBullet(slide, 418, "Stock control", "records stock in, stock out, and adjustments with previous and new balances", C.green);
  addBullet(slide, 506, "Monitoring", "supports low-stock warnings, expiry checks, restock requests, and archived items", C.orange);
  addText(slide, "Write access: staff, doctors, and administrators", { left: 94, top: 600, width: 360, height: 28 }, { fontSize: 15, bold: true, color: C.navy });
  addText(slide, "Read access: all signed-in roles", { left: 94, top: 631, width: 330, height: 24 }, { fontSize: 14, color: C.muted });

  const account = addTableBox(slide, { name: "app_accounts", x: 548, y: 242, w: 178, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { field: "role", type: "TEXT" },
    { field: "active", type: "BOOLEAN" },
  ]});
  const inventory = addTableBox(slide, { name: "inventory", x: 784, y: 104, w: 205, accent: C.paleGreen, rows: [
    { key: "PK", field: "id", type: "TEXT" },
    { key: "FK", field: "owner_id", type: "TEXT" },
    { field: "data", type: "JSONB" },
    { field: "version", type: "INT" },
    { field: "created_at", type: "TIMESTAMPTZ" },
    { field: "updated_at", type: "TIMESTAMPTZ" },
  ]});
  connect(slide, account, inventory);

  const payload = slide.shapes.add({
    geometry: "roundRect",
    name: "inventory-jsonb-payload",
    position: { left: 1018, top: 98, width: 164, height: 453 },
    fill: "#F8FAFD",
    line: { style: "solid", fill: C.border, width: 1 },
    borderRadius: "rounded-xl",
  });
  addText(slide, "data.value", { left: 1034, top: 117, width: 130, height: 26 }, { fontSize: 16, bold: true, color: C.navy, alignment: "center" });
  const payloadFields = [
    ["Product", "name, category, brand, pet type"],
    ["Stock", "quantity, unit, reorder level"],
    ["Pricing", "purchase and selling price"],
    ["Expiry", "expiresOn and status"],
    ["Media", "main image and product photos"],
    ["Movements", "type, quantity, balances, staff, time"],
    ["Restock", "request quantity, note, approval status"],
  ];
  payloadFields.forEach(([heading, body], i) => {
    const yy = 158 + i * 53;
    addText(slide, heading, { left: 1033, top: yy, width: 132, height: 18 }, { fontSize: 12.5, bold: true, color: i === 5 ? C.green : C.blue });
    addText(slide, body, { left: 1033, top: yy + 18, width: 132, height: 30 }, { fontSize: 10.5, color: C.muted, lineSpacing: 1.0 });
  });
  connect(slide, inventory, payload, { dashed: true });
  addText(slide, "JSONB payload", { left: 960, top: 317, width: 74, height: 18 }, { fontSize: 11, color: C.muted, alignment: "center" });
  addLegend(slide, 770, 615);
}

for (const [index, slide] of presentation.slides.items.entries()) {
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(buildDir, `slide-${index + 1}.png`), new Uint8Array(await png.arrayBuffer()));
}
const montage = await presentation.export({ format: "webp", montage: true });
await fs.writeFile(path.join(buildDir, "montage.webp"), new Uint8Array(await montage.arrayBuffer()));

const { finalizePresentation } = await import(pathToFileURL(path.join(skillDir, "container_tools/artifact_tool_utils.mjs")).href);
const stagingDir = path.join(workspaceDir, ".codex-finalizer");
await fs.mkdir(stagingDir, { recursive: true });
const candidatePath = path.join(stagingDir, "database-features-candidate.pptx");
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

await finalizePresentation({
  explicitTotalSlideCount: 3,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  workspaceDir,
  candidatePath,
  finalPath,
  pythonExecutable: "/Users/apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3",
  integrityValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: ["--expected-slide-size-emu", "12192000,6858000", "--validate-heading-fit"],
  fontPolicy: { basis: "design", families: [fontFamily] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, "database_features_v2.validation.json"),
});

console.log(finalPath);
