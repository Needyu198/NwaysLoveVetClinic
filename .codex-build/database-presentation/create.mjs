import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/apple/NwaysLoveVetClinic";
const buildDir = path.join(workspaceDir, ".codex-build/database-presentation");
const previewDir = path.join(buildDir, "previews");
const finalPath = path.join(workspaceDir, "output", "Nways_Love_Database_Presentation.pptx");
const skillDir = "/Users/apple/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations";
const pythonExecutable = "/Users/apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const fontFamily = "Avenir Next";

const C = {
  navy: "#102A43",
  blue: "#176B87",
  teal: "#14866D",
  mint: "#DDF5EC",
  cyan: "#DDEFF5",
  cream: "#F7F6F1",
  white: "#FFFFFF",
  ink: "#14211D",
  muted: "#5B6B65",
  line: "#CAD8D2",
  orange: "#EEA552",
};

function addText(slide, text, x, y, w, h, size, color, bold = false, opts = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name: opts.name,
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: fontFamily,
    fontSize: size,
    color,
    bold,
    alignment: opts.alignment || "left",
    verticalAlignment: opts.verticalAlignment || "middle",
  };
  shape.text.insets = opts.insets ?? 0;
  return shape;
}

function addBox(slide, x, y, w, h, fill, line = "none", radius = "rounded-xl", name) {
  return slide.shapes.add({
    geometry: "roundRect",
    name,
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill: line, width: line === "none" ? 0 : 1 },
    borderRadius: radius,
  });
}

function addArrow(slide, x, y, w = 52, h = 26, fill = C.teal) {
  return slide.shapes.add({
    geometry: "rightArrow",
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill, width: 0 },
  });
}

function addSlideNumber(slide, number, dark = false) {
  addText(slide, String(number).padStart(2, "0"), 1184, 664, 40, 22, 12,
    dark ? "#A6C1B8" : C.muted, true, { alignment: "right" });
}

function addTitle(slide, title, subtitle, dark = false) {
  addText(slide, title, 72, 48, 1000, 52, 32, dark ? C.white : C.navy, true);
  addText(slide, subtitle, 72, 102, 1040, 36, 16, dark ? "#C9DED8" : C.muted);
  slide.shapes.add({
    geometry: "rect",
    position: { left: 72, top: 143, width: 72, height: 5 },
    fill: C.orange,
    line: { style: "solid", fill: C.orange, width: 0 },
  });
}

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

async function main() {
  await fs.mkdir(previewDir, { recursive: true });
  await fs.mkdir(path.dirname(finalPath), { recursive: true });

  const deck = Presentation.create({ slideSize: { width: 1280, height: 720 } });
  deck.theme.defaultFont = fontFamily;

  // Slide 1: architecture
  {
    const slide = deck.slides.add();
    slide.background.fill = C.navy;
    addTitle(
      slide,
      "Database architecture",
      "One cloud database supports the mobile app and web portal",
      true,
    );

    addText(slide, "CENTRAL DATA MODEL", 72, 184, 320, 24, 13, "#75D2B7", true);
    addText(
      slide,
      "Neon PostgreSQL is the single source of truth for accounts, pets, appointments and clinic operations.",
      72, 220, 350, 168, 27, C.white, true,
    );
    addText(
      slide,
      "Clients access the database through the backend API. Database credentials remain on the server.",
      72, 418, 350, 100, 17, "#C9DED8",
    );

    const nodeY = 228;
    addBox(slide, 500, nodeY, 160, 92, C.cyan, "#86B6C7", "rounded-xl", "mobile-app");
    addText(slide, "Flutter\nmobile app", 518, nodeY + 13, 124, 64, 19, C.navy, true, { alignment: "center" });
    addBox(slide, 500, nodeY + 138, 160, 92, C.mint, "#75BDAA", "rounded-xl", "web-portal");
    addText(slide, "Vercel\nweb portal", 518, nodeY + 151, 124, 64, 19, C.navy, true, { alignment: "center" });

    addArrow(slide, 684, 319, 58, 30, C.orange);
    addBox(slide, 762, nodeY + 69, 184, 110, C.white, "#B9D4CB", "rounded-xl", "backend-api");
    addText(slide, "Node.js API\non Render", 782, nodeY + 89, 144, 68, 20, C.navy, true, { alignment: "center" });
    addArrow(slide, 970, 319, 58, 30, C.orange);
    addBox(slide, 1048, nodeY + 53, 160, 142, C.teal, "#82D1BA", "rounded-xl", "neon-db");
    addText(slide, "Neon\nPostgreSQL", 1064, nodeY + 80, 128, 82, 22, C.white, true, { alignment: "center" });

    addBox(slide, 500, 530, 708, 72, "#173C54", "#2A596D", "rounded-xl", "realtime-band");
    addText(slide, "REAL-TIME SYNC", 526, 548, 150, 36, 13, "#75D2B7", true);
    addText(slide, "Socket events refresh staff and owner screens after data changes", 682, 548, 492, 36, 17, C.white, false);
    addSlideNumber(slide, 1, true);

    slide.speakerNotes.text = [
      "The system uses PostgreSQL hosted on Neon as its central database.",
      "The Flutter mobile application and the Vercel web portal do not connect directly to PostgreSQL. They send authenticated requests to the Node.js backend hosted on Render.",
      "This keeps the database credentials on the server and applies the same validation rules to every platform.",
      "Real-time socket events notify the apps when shared records change.",
      "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/db.js; /Users/apple/NwaysLoveVetClinic/lib/data/clinic_api.dart; /Users/apple/NwaysLoveVetClinic/web-as/src/api.js; /Users/apple/NwaysLoveVetClinic/backend/src/realtime.js",
    ];
    slide.speakerNotes.setVisible(true);
  }

  // Slide 2: data organization
  {
    const slide = deck.slides.add();
    slide.background.fill = C.cream;
    addTitle(
      slide,
      "How the data is organized",
      "Feature tables separate clinical, pet-care and administrative records",
    );

    const table = slide.tables.add({
      rows: 7,
      columns: 2,
      left: 72,
      top: 182,
      width: 718,
      height: 438,
      columnWidths: [222, 496],
      values: [
        ["Data area", "PostgreSQL tables"],
        ["Authentication", "app_accounts, app_sessions"],
        ["Pet information", "pets, owner_profiles"],
        ["Medical service", "appointments, medical_records"],
        ["Home and pet care", "home_visits, pet_care_bookings"],
        ["Clinic operations", "queue_entries, payments, inventory"],
        ["Administration", "user_directory, audit_logs"],
      ],
    });
    table.borders.assign({ style: "solid", fill: C.line, width: 1 });
    table.cells.block({ row: 0, column: 0, rowCount: 1, columnCount: 2 }).assign({
      fill: C.navy,
      textStyle: { typeface: fontFamily, fontSize: 16, bold: true, color: C.white },
      margins: { left: 16, right: 12, top: 8, bottom: 8 },
      verticalAlignment: "middle",
    });
    table.cells.block({ row: 1, column: 0, rowCount: 6, columnCount: 2 }).assign({
      textStyle: { typeface: fontFamily, fontSize: 15, color: C.ink },
      margins: { left: 16, right: 12, top: 8, bottom: 8 },
      verticalAlignment: "middle",
    });
    for (let row = 1; row < 7; row += 1) {
      table.getCell(row, 0).fill = row % 2 ? C.mint : "#EEF4F0";
      table.getCell(row, 1).fill = row % 2 ? C.white : "#FBFCFA";
      table.getCell(row, 0).text.style = { typeface: fontFamily, fontSize: 15, bold: true, color: C.teal };
    }

    addText(slide, "RECORD STRUCTURE", 848, 182, 310, 24, 13, C.teal, true);
    const fields = [
      ["id", "Unique record"],
      ["owner_id", "Data ownership"],
      ["data", "Feature details in JSON"],
      ["version", "Update conflict control"],
      ["timestamps", "Created and updated"],
    ];
    fields.forEach(([key, description], index) => {
      const y = 224 + index * 70;
      addText(slide, key, 848, y, 126, 42, 17, C.navy, true);
      addText(slide, description, 978, y, 230, 42, 15, C.muted);
      slide.shapes.add({
        geometry: "line",
        position: { left: 848, top: y + 48, width: 360, height: 0 },
        fill: "none",
        line: { style: "solid", fill: C.line, width: 1 },
      });
    });
    addBox(slide, 848, 584, 360, 52, C.cyan, "#AACDD9", "rounded-lg");
    addText(slide, "Role rules control who can read or change each table", 868, 593, 320, 34, 14, C.navy, true, { alignment: "center" });
    addSlideNumber(slide, 2);

    slide.speakerNotes.text = [
      "The database separates information by feature so each workflow has a clear data source.",
      "Medical appointments, home visits and pet-care bookings use separate tables. This supports the categories shown on the staff appointment page.",
      "Each shared feature record includes an owner ID, JSON details, a version number and timestamps.",
      "The version number supports optimistic concurrency, which prevents an older edit from silently replacing a newer one.",
      "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/schema.js; /Users/apple/NwaysLoveVetClinic/backend/src/resources.js",
    ];
    slide.speakerNotes.setVisible(true);
  }

  // Slide 3: appointment flow and protection
  {
    const slide = deck.slides.add();
    slide.background.fill = C.white;
    addTitle(
      slide,
      "Appointment data flow and protection",
      "One booking becomes a validated record visible to the correct clinic team",
    );

    const steps = [
      ["1", "Select pet\nand service"],
      ["2", "Send authenticated\nrequest"],
      ["3", "Validate role\nand ownership"],
      ["4", "Store booking\nin PostgreSQL"],
      ["5", "Refresh staff\nappointment view"],
    ];
    steps.forEach(([number, label], index) => {
      const x = 72 + index * 234;
      addBox(slide, x, 204, 186, 122, index === 3 ? C.teal : C.cream,
        index === 3 ? C.teal : C.line, "rounded-xl");
      addText(slide, number, x + 16, 218, 34, 30, 16, index === 3 ? C.white : C.teal, true);
      addText(slide, label, x + 16, 252, 154, 56, 17, index === 3 ? C.white : C.navy, true);
      if (index < steps.length - 1) addArrow(slide, x + 190, 252, 38, 24, C.orange);
    });

    addText(slide, "STAFF VIEW", 72, 380, 130, 24, 13, C.teal, true);
    addText(slide, "The saved record appears under the correct service topic", 72, 410, 610, 38, 23, C.navy, true);
    const categories = [
      ["Medical Service", C.cyan, C.blue],
      ["Home Visit", C.mint, C.teal],
      ["Pet Care Service", "#FFF0DA", "#B56D18"],
    ];
    categories.forEach(([label, fill, color], index) => {
      const x = 72 + index * 210;
      addBox(slide, x, 472, 190, 62, fill, "none", "rounded-xl");
      addText(slide, label, x + 12, 485, 166, 36, 15, color, true, { alignment: "center" });
    });

    addBox(slide, 760, 380, 448, 204, C.navy, C.navy, "rounded-xl");
    addText(slide, "Security checks", 788, 400, 280, 36, 22, C.white, true);
    const checks = [
      "Passwords are stored as hashes",
      "Session tokens protect API requests",
      "Roles and ownership limit data access",
    ];
    checks.forEach((text, index) => {
      const y = 454 + index * 40;
      slide.shapes.add({
        geometry: "ellipse",
        position: { left: 790, top: y + 7, width: 12, height: 12 },
        fill: "#75D2B7",
        line: { style: "solid", fill: "#75D2B7", width: 0 },
      });
      addText(slide, text, 816, y, 360, 28, 15, "#DDEBE7");
    });
    addText(slide, "Single source of truth across mobile, staff and administrator interfaces", 72, 610, 1030, 36, 18, C.teal, true);
    addSlideNumber(slide, 3);

    slide.speakerNotes.text = [
      "When an owner chooses a pet and service, the application sends an authenticated booking request to the backend.",
      "The backend checks the session, account role and record ownership before saving the appointment.",
      "Medical appointments, home visits and pet-care bookings remain separate, so staff can view them under the correct topic.",
      "Passwords use hashes, API requests use session tokens, and access rules restrict each role to the appropriate records.",
      "Sources: /Users/apple/NwaysLoveVetClinic/backend/src/api.js; /Users/apple/NwaysLoveVetClinic/backend/src/resources.js; /Users/apple/NwaysLoveVetClinic/lib/data/database_sync.dart; /Users/apple/NwaysLoveVetClinic/lib/data/database_stores.dart; /Users/apple/NwaysLoveVetClinic/web-as/src/api.js",
    ];
    slide.speakerNotes.setVisible(true);
  }

  for (const [index, slide] of deck.slides.items.entries()) {
    const png = await deck.export({ slide, format: "png", scale: 1 });
    await writeBlob(path.join(previewDir, `slide-${index + 1}.png`), png);
    const layout = await slide.export({ format: "layout" });
    await fs.writeFile(path.join(previewDir, `slide-${index + 1}.layout.json`), await layout.text());
  }
  const montage = await deck.export({ format: "webp", montage: true });
  await writeBlob(path.join(previewDir, "montage.webp"), montage);

  const { finalizePresentation } = await import(pathToFileURL(
    path.join(skillDir, "container_tools/artifact_tool_utils.mjs"),
  ).href);
  const stagingDir = path.join(buildDir, "finalizer");
  await fs.mkdir(stagingDir, { recursive: true });
  const candidatePath = path.join(stagingDir, "candidate.pptx");
  await (await PresentationFile.exportPptx(deck)).save(candidatePath);

  const result = await finalizePresentation({
    explicitTotalSlideCount: 3,
    requiredNativeTableOwnerSlides: [2],
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
      "--require-native-table-slide", "2",
    ],
    fontPolicy: { basis: "design", families: [fontFamily] },
    verifyArtifactToolImport: true,
    receiptPath: path.join(stagingDir, "validation.json"),
  });
  console.log(JSON.stringify({ finalPath, result }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
