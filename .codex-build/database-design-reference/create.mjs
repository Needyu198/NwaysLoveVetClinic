import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/apple/NwaysLoveVetClinic";
const buildDir = path.join(workspaceDir, ".codex-build/database-design-reference");
const previewPath = path.join(buildDir, "database-design-slide.png");
const finalPath = path.join(workspaceDir, "output", "Nways_Love_Database_Design_Reference_Style.pptx");
const skillDir = "/Users/apple/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations";
const pythonExecutable = "/Users/apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const font = "Avenir Next";

const colors = {
  background: "#F1F3F8",
  navy: "#182E55",
  blue: "#2C6CB5",
  text: "#50617A",
  panel: "#FFFFFF",
  panelLine: "#D8DFEA",
  tableHeader: "#E5E7EA",
  tableLine: "#49515B",
  key: "#172B4D",
  accent: "#16856F",
};

function addText(slide, text, left, top, width, height, size, color, bold = false, options = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name: options.name,
    position: { left, top, width, height },
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

function addRichLine(slide, label, description, top) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left: 72, top, width: 405, height: 50 },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = [[
    { run: `${label}: `, style: { typeface: font, fontSize: "16pt", bold: true, color: colors.navy } },
    { run: description, style: { typeface: font, fontSize: "16pt", color: colors.text } },
  ]];
  shape.text.insets = 0;
  return shape;
}

function addLine(slide, x1, y1, x2, y2, width = 1.5, color = colors.tableLine, dash = "solid") {
  return slide.shapes.add({
    geometry: "line",
    position: { left: x1, top: y1, width: x2 - x1, height: y2 - y1 },
    fill: "none",
    line: { style: dash, fill: color, width },
  });
}

function addTableBox(slide, { x, y, w, h, title, rows, central = false }) {
  slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height: h },
    fill: colors.panel,
    line: { style: "solid", fill: colors.tableLine, width: central ? 1.5 : 1.2 },
  });
  slide.shapes.add({
    geometry: "rect",
    position: { left: x, top: y, width: w, height: 25 },
    fill: central ? "#DCE7F6" : colors.tableHeader,
    line: { style: "solid", fill: colors.tableLine, width: central ? 1.5 : 1.2 },
  });
  addText(slide, title, x + 5, y + 2, w - 10, 20, central ? 12 : 11, colors.key, true, { alignment: "center" });
  const bodyTop = y + 30;
  const rowHeight = (h - 35) / rows.length;
  rows.forEach((row, index) => {
    const rowY = bodyTop + index * rowHeight;
    const markerWidth = row[0] ? 25 : 8;
    if (row[0]) addText(slide, row[0], x + 6, rowY, 22, rowHeight, 8.2, colors.key, true);
    addText(slide, row[1], x + markerWidth + 5, rowY, w * 0.55, rowHeight, 8.5, colors.key, index === 0);
    addText(slide, row[2], x + w * 0.73, rowY, w * 0.23, rowHeight, 7.8, colors.text, false, { alignment: "right" });
  });
}

function addCardinality(slide, left, top, text) {
  addText(slide, text, left, top, 16, 18, 9, colors.tableLine, true, { alignment: "center" });
}

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

async function main() {
  await fs.mkdir(buildDir, { recursive: true });
  await fs.mkdir(path.dirname(finalPath), { recursive: true });

  const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });
  presentation.theme.defaultFont = font;
  const slide = presentation.slides.add();
  slide.background.fill = colors.background;

  // Left narrative column, following the supplied reference layout.
  addText(slide, "DATABASE DESIGN", 72, 82, 360, 32, 15, colors.blue, true);
  addText(slide, "Everything connects\nto the account", 72, 130, 420, 150, 44, colors.navy, true);

  addRichLine(slide, "app_accounts", "login identity, role and account status", 320);
  addRichLine(slide, "pets", "owner-linked pet profiles", 373);
  addRichLine(slide, "appointments", "medical-service bookings", 426);
  addRichLine(slide, "home_visits", "care requested at the owner's address", 479);
  addRichLine(slide, "pet_care_bookings", "grooming, bathing, nail trimming and boarding", 532);
  addRichLine(slide, "medical_records", "treatment history maintained by clinic roles", 585);

  addText(slide, "Nway's Love Vet Clinic  ·  Database Design", 72, 664, 390, 24, 14, "#61728D");

  // Right ERD panel.
  slide.shapes.add({
    geometry: "roundRect",
    position: { left: 525, top: 58, width: 690, height: 604 },
    fill: colors.panel,
    line: { style: "solid", fill: colors.panelLine, width: 1 },
    borderRadius: "rounded-2xl",
  });
  addText(slide, "LOGICAL DATA MODEL", 565, 78, 250, 22, 11, colors.blue, true);
  addText(slide, "Ownership relationships use owner_id", 900, 78, 275, 22, 10, colors.text, false, { alignment: "right" });

  // Relationship lines sit behind table boxes.
  addLine(slide, 770, 210, 815, 210);
  addLine(slide, 815, 160, 815, 490);
  addLine(slide, 815, 160, 845, 160);
  addLine(slide, 815, 160, 1000, 160);
  addLine(slide, 815, 324, 845, 324);
  addLine(slide, 815, 324, 1000, 324);
  addLine(slide, 770, 440, 815, 440);
  addLine(slide, 815, 490, 920, 490);

  // Central identity table.
  addTableBox(slide, {
    x: 565, y: 126, w: 205, h: 360, title: "app_accounts", central: true,
    rows: [
      ["PK", "id", "text"],
      ["", "username", "text"],
      ["", "email", "text"],
      ["", "phone", "text"],
      ["", "password_hash", "text"],
      ["", "full_name", "text"],
      ["", "role", "text"],
      ["", "active", "boolean"],
      ["", "created_at", "timestamptz"],
    ],
  });

  const featureRows = [
    ["PK", "id", "text"],
    ["FK", "owner_id", "text"],
    ["", "data", "jsonb"],
    ["", "version", "integer"],
    ["", "updated_at", "timestamptz"],
  ];
  addTableBox(slide, { x: 845, y: 112, w: 145, h: 145, title: "pets", rows: featureRows });
  addTableBox(slide, { x: 1000, y: 112, w: 175, h: 145, title: "appointments", rows: featureRows });
  addTableBox(slide, { x: 845, y: 276, w: 145, h: 145, title: "home_visits", rows: featureRows });
  addTableBox(slide, { x: 1000, y: 276, w: 175, h: 145, title: "pet_care_bookings", rows: featureRows });
  addTableBox(slide, { x: 920, y: 440, w: 180, h: 145, title: "medical_records", rows: featureRows });

  // Compact cardinality labels clarify the logical one-to-many ownership model.
  addCardinality(slide, 780, 198, "1"); addCardinality(slide, 827, 148, "N");
  addCardinality(slide, 780, 312, "1"); addCardinality(slide, 827, 312, "N");
  addCardinality(slide, 780, 428, "1"); addCardinality(slide, 900, 478, "N");
  addCardinality(slide, 982, 148, "N"); addCardinality(slide, 982, 312, "N");

  addText(
    slide,
    "Feature details are stored in JSONB. The diagram shows the application's logical ownership model.",
    565, 612, 610, 26, 9.5, colors.text,
  );

  slide.speakerNotes.text = [
    "The database design centers on app_accounts. This table stores the user's identity, role and account status.",
    "Each feature table stores owner_id, which lets the backend apply ownership and role checks before returning or changing data.",
    "Pets, medical appointments, home visits, pet-care bookings and medical records remain separate so each workflow has a clear data source.",
    "The feature tables use JSONB for feature-specific fields and a version number for update conflict control.",
    "The diagram shows logical application relationships. The current schema does not declare PostgreSQL foreign-key constraints for owner_id.",
    "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/schema.js; /Users/apple/NwaysLoveVetClinic/backend/src/resources.js",
  ];
  slide.speakerNotes.setVisible(true);

  await writeBlob(previewPath, await presentation.export({ slide, format: "png", scale: 1 }));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(buildDir, "database-design-slide.layout.json"), await layout.text());

  const { finalizePresentation } = await import(pathToFileURL(
    path.join(skillDir, "container_tools/artifact_tool_utils.mjs"),
  ).href);
  const stagingDir = path.join(buildDir, "finalizer");
  await fs.mkdir(stagingDir, { recursive: true });
  const candidatePath = path.join(stagingDir, "candidate.pptx");
  await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

  const result = await finalizePresentation({
    explicitTotalSlideCount: 1,
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
    receiptPath: path.join(stagingDir, "validation.json"),
  });
  console.log(JSON.stringify({ finalPath, previewPath, result }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
