const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const out = path.join(__dirname, 'NwaysLoveVetClinic_ERD.drawio');
const webLauncher = path.join(__dirname, 'open_erd.html');

const esc = (value) => String(value)
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;');

const fields = (...rows) => rows;

const pages = [
  {
    name: '1 - Accounts and Access',
    subtitle: 'Authentication, role profiles, sessions, password recovery, devices, and access auditing',
    tables: [
      ['app_accounts', 610, 95, fields(['PK','id','text'],['','username','varchar'],['','email','varchar'],['','phone','varchar'],['','password_hash','text'],['','full_name','varchar'],['','role','enum'],['','active','boolean'],['','created_at','timestamp'])],
      ['app_sessions', 45, 390, fields(['PK','token_hash','text'],['FK','account_id','text'],['','role','varchar'],['','expires_at','timestamp'],['','created_at','timestamp'])],
      ['password_reset_codes', 350, 390, fields(['PK/FK','account_id','text'],['','code_hash','text'],['','expires_at','timestamp'],['','attempts','integer'],['','consumed_at','timestamp'],['','requested_at','timestamp'])],
      ['device_tokens', 655, 390, fields(['PK','token','text'],['FK','account_id','text'],['','platform','varchar'],['','created_at','timestamp'],['','updated_at','timestamp'])],
      ['owner_profiles', 960, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'],['','updated_at','timestamp'])],
      ['doctor_profiles', 1265, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','license_number','varchar'],['','availability','jsonb'],['','version','integer'])],
      ['staff_profiles', 45, 720, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['admin_profiles', 350, 720, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['user_directory', 655, 720, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['doctor_verifications', 960, 720, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['audit_logs', 1265, 720, fields(['PK','id','text'],['FK','owner_id','text'],['','module','varchar'],['','action','varchar'],['','data','jsonb'],['','created_at','timestamp'])],
    ],
    relationships: [
      ['app_accounts','app_sessions','1','0..N'],['app_accounts','password_reset_codes','1','0..1'],['app_accounts','device_tokens','1','0..N'],
      ['app_accounts','owner_profiles','1','0..1'],['app_accounts','doctor_profiles','1','0..1'],['app_accounts','staff_profiles','1','0..1'],
      ['app_accounts','admin_profiles','1','0..1'],['app_accounts','user_directory','1','0..1'],['app_accounts','doctor_verifications','1','0..N'],['app_accounts','audit_logs','1','0..N'],
    ],
  },
  {
    name: '2 - Pets and Bookings',
    subtitle: 'Pet ownership, scheduled and walk-in visits, service requests, reminders, and owner preferences',
    pageWidth: 1760,
    pageHeight: 1260,
    tables: [
      ['app_accounts', 40, 500, fields(['PK','id','text'],['','full_name','varchar'],['','role','enum'])],
      ['saved_addresses', 40, 150, fields(['PK','id','text'],['FK','owner_id','text'],['','label','varchar'],['','address','text'],['','data','jsonb'])],
      ['notification_settings', 40, 790, fields(['PK','id','text'],['FK','owner_id','text'],['','appointments','boolean'],['','queue_alerts','boolean'])],
      ['owner_notifications', 40, 1010, fields(['PK','id','text'],['FK','owner_id','text'],['','title','varchar'],['','message','text'],['','read','boolean'])],
      ['pets', 380, 500, fields(['PK','id','text'],['FK','owner_id','text'],['','name','varchar'],['','species','varchar'],['','data','jsonb'])],
      ['appointments', 720, 150, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['FK','doctor_id','text'],['','status','varchar'],['','data','jsonb'])],
      ['queue_entries', 1060, 150, fields(['PK','id','text'],['FK','owner_id','text'],['FK','appointment_id','text'],['','queue_number','integer'],['','status','varchar'],['','data','jsonb'])],
      ['appointment_reminders', 1400, 150, fields(['PK/FK','appointment_id','text'],['PK','scheduled_for','timestamp'],['FK','owner_id','text'],['','sent_at','timestamp'])],
      ['walk_in_appointments', 720, 500, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['FK','doctor_id','text'],['','status','varchar'],['','data','jsonb'])],
      ['emergency_requests', 1060, 500, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['','symptoms','text'],['','status','varchar'])],
      ['home_visits', 720, 850, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['','address','text'],['','status','varchar'])],
      ['pet_care_bookings', 1060, 850, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['','service','varchar'],['','status','varchar'])],
      ['reminders', 1400, 850, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['','scheduled_for','timestamp'],['','data','jsonb'])],
    ],
    relationships: [
      ['app_accounts','pets','1','0..N'],['app_accounts','saved_addresses','1','0..N'],['app_accounts','notification_settings','1','0..1'],['app_accounts','owner_notifications','1','0..N'],
      ['pets','appointments','1','0..N'],['appointments','queue_entries','1','0..1'],['appointments','appointment_reminders','1','0..N'],
      ['pets','walk_in_appointments','1','0..N'],['pets','emergency_requests','1','0..N'],['pets','home_visits','1','0..N'],['pets','pet_care_bookings','1','0..N'],['pets','reminders','1','0..N'],
      ['app_accounts','appointments','1','0..N','secondary'],['app_accounts','walk_in_appointments','1','0..N','secondary'],['app_accounts','emergency_requests','1','0..N','secondary'],
      ['app_accounts','home_visits','1','0..N','secondary'],['app_accounts','pet_care_bookings','1','0..N','secondary'],['app_accounts','reminders','1','0..N','secondary'],
      ['app_accounts','appointment_reminders','1','0..N','secondary'],
    ],
  },
  {
    name: '3 - Clinical Operations',
    subtitle: 'Doctor workflow, appointments, patient records, queues, billing, and clinic inventory',
    tables: [
      ['doctor_profiles', 45, 95, fields(['PK','id','text'],['FK','owner_id','text'],['','license_number','varchar'],['','availability','jsonb'])],
      ['appointments', 360, 95, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['FK','doctor_id','text'],['','status','varchar'],['','data','jsonb'])],
      ['medical_records', 675, 95, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['FK','doctor_id','text'],['FK','appointment_id','text'],['','diagnosis','text'],['','treatment','text'])],
      ['payments', 990, 95, fields(['PK','id','text'],['FK','owner_id','text'],['FK','service_record_id','text'],['','amount','numeric'],['','status','varchar'])],
      ['inventory', 1305, 95, fields(['PK','id','text'],['FK','owner_id','text'],['','item_name','varchar'],['','stock','integer'],['','expiry_date','date'])],
      ['walk_in_appointments', 45, 500, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['FK','doctor_id','text'],['','arrival_time','timestamp'],['','status','varchar'])],
      ['queue_entries', 360, 500, fields(['PK','id','text'],['FK','appointment_id','text'],['FK','walk_in_id','text'],['','queue_number','integer'],['','status','varchar'])],
      ['doctor_appointment_state', 675, 500, fields(['PK','id','text'],['FK','appointment_id','text'],['FK','doctor_id','text'],['','state','varchar'],['','data','jsonb'])],
      ['queue_daily_counters', 990, 500, fields(['PK','clinic_date','date'],['','last_number','integer'],['','updated_at','timestamp'])],
      ['appointment_reminders', 1305, 500, fields(['PK/FK','appointment_id','text'],['PK','scheduled_for','timestamp'],['FK','owner_id','text'],['','sent_at','timestamp'])],
    ],
    relationships: [
      ['doctor_profiles','appointments','1','0..N'],['appointments','medical_records','1','0..N'],['doctor_profiles','medical_records','1','0..N'],
      ['medical_records','payments','1','0..N'],['doctor_profiles','walk_in_appointments','1','0..N'],['appointments','queue_entries','1','0..1'],
      ['walk_in_appointments','queue_entries','1','0..1'],['appointments','doctor_appointment_state','1','0..1'],['doctor_profiles','doctor_appointment_state','1','0..N'],
      ['queue_daily_counters','queue_entries','1','0..N'],['appointments','appointment_reminders','1','0..N'],
    ],
  },
  {
    name: '4 - Content',
    subtitle: 'Clinic-authored health content, drafts, saved guides, reviews, and clinic discovery',
    tables: [
      ['app_accounts', 615, 80, fields(['PK','id','text'],['','full_name','varchar'],['','role','enum'])],
      ['health_posts', 120, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','title','varchar'],['','content','text'],['','status','varchar'])],
      ['health_post_drafts', 455, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','title','varchar'],['','content','text'],['','scheduled_for','timestamp'])],
      ['saved_first_aid_guides', 790, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','guide_id','text'],['','saved_at','timestamp'])],
      ['history_reviews', 1125, 340, fields(['PK','id','text'],['FK','owner_id','text'],['FK','record_id','text'],['','rating','integer'],['','comment','text'])],
      ['clinic_directory', 455, 700, fields(['PK','id','text'],['FK','owner_id','text'],['','name','varchar'],['','specialty','varchar'],['','data','jsonb'])],
      ['medical_records', 790, 700, fields(['PK','id','text'],['FK','owner_id','text'],['FK','pet_id','text'],['','diagnosis','text'],['','treatment','text'])],
    ],
    relationships: [
      ['app_accounts','health_posts','1','0..N'],['app_accounts','health_post_drafts','1','0..N'],['health_post_drafts','health_posts','0..1','0..1'],
      ['app_accounts','saved_first_aid_guides','1','0..N'],['app_accounts','history_reviews','1','0..N'],['medical_records','history_reviews','1','0..N'],['app_accounts','clinic_directory','1','0..N'],
    ],
  },
  {
    name: '5 - Communication',
    subtitle: 'Owner-clinic messaging, notifications, support, delivery devices, and preferences',
    tables: [
      ['app_accounts', 615, 80, fields(['PK','id','text'],['','full_name','varchar'],['','role','enum'])],
      ['clinic_messages', 65, 340, fields(['PK','id','text'],['FK','owner_id','text'],['FK','sender_id','text'],['FK','recipient_id','text'],['','message','text'],['','status','varchar'])],
      ['owner_notifications', 385, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','title','varchar'],['','message','text'],['','read','boolean'])],
      ['doctor_notifications', 705, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','title','varchar'],['','message','text'],['','read','boolean'])],
      ['support_tickets', 1025, 340, fields(['PK','id','text'],['FK','owner_id','text'],['','subject','varchar'],['','status','varchar'],['','data','jsonb'])],
      ['device_tokens', 290, 710, fields(['PK','token','text'],['FK','account_id','text'],['','platform','varchar'],['','updated_at','timestamp'])],
      ['notification_settings', 720, 710, fields(['PK','id','text'],['FK','owner_id','text'],['','appointments','boolean'],['','queue_alerts','boolean'])],
      ['appointment_reminders', 1150, 710, fields(['PK/FK','appointment_id','text'],['PK','scheduled_for','timestamp'],['FK','owner_id','text'],['','sent_at','timestamp'])],
    ],
    relationships: [
      ['app_accounts','clinic_messages','1','0..N'],['app_accounts','owner_notifications','1','0..N'],['app_accounts','doctor_notifications','1','0..N'],
      ['app_accounts','support_tickets','1','0..N'],['app_accounts','device_tokens','1','0..N'],['app_accounts','notification_settings','1','0..1'],['app_accounts','appointment_reminders','1','0..N'],
    ],
  },
  {
    name: '6 - Administration',
    subtitle: 'Account administration, staff and doctor governance, directory, verification, and audit controls',
    tables: [
      ['app_accounts', 615, 65, fields(['PK','id','text'],['','username','varchar'],['','email','varchar'],['','phone','varchar'],['','full_name','varchar'],['','role','enum'],['','active','boolean'],['','created_at','timestamp'])],
      ['admin_profiles', 45, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['staff_profiles', 350, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['user_directory', 655, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['doctor_verifications', 960, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','data','jsonb'],['','version','integer'])],
      ['audit_logs', 1265, 390, fields(['PK','id','text'],['FK','owner_id','text'],['','module','varchar'],['','action','varchar'],['','data','jsonb'],['','created_at','timestamp'])],
      ['password_reset_audit', 350, 735, fields(['PK','id','bigint'],['FK','account_id','text'],['','identifier_hash','text'],['','event','varchar'],['','ip_hash','text'],['','created_at','timestamp'])],
      ['clinic_directory', 960, 735, fields(['PK','id','text'],['FK','owner_id','text'],['','name','varchar'],['','specialty','varchar'],['','data','jsonb'])],
    ],
    relationships: [
      ['app_accounts','admin_profiles','1','0..1'],['app_accounts','staff_profiles','1','0..1'],['app_accounts','user_directory','1','0..1'],
      ['app_accounts','doctor_verifications','1','0..N'],['app_accounts','audit_logs','1','0..N'],['app_accounts','password_reset_audit','1','0..N'],['app_accounts','clinic_directory','1','0..N'],
    ],
  },
];

function tableHtml(name, rows) {
  const body = rows.map(([key, field, type]) => {
    const keyColor = key.includes('PK') ? '#9C5700' : key === 'FK' ? '#1F4E78' : '#6B7280';
    const underline = key.includes('PK') ? 'text-decoration:underline;font-weight:700;' : '';
    return `<tr style="border-top:1px solid #E5E7EB"><td style="width:45px;color:${keyColor};font-weight:700;border-right:1px solid #D1D5DB">${esc(key)}</td><td style="width:150px;${underline}">${esc(field)}</td><td style="width:75px;text-align:right;color:#667085">${esc(type)}</td></tr>`;
  }).join('');
  return `<div style="font-family:Helvetica,Arial,sans-serif;font-size:12px;line-height:1.2"><div style="background:#E5E7EB;color:#111827;font-weight:700;font-size:15px;text-align:center;padding:8px 10px;border-bottom:1px solid #4B5563">${esc(name)}</div><table cellpadding="5" cellspacing="0" style="width:100%;border-collapse:collapse;background:white">${body}</table></div>`;
}

function cardinalityArrow(cardinality) {
  return ({
    '1': 'ERone',
    '0..1': 'ERzeroToOne',
    '0..N': 'ERzeroToMany',
    '1..N': 'ERoneToMany',
  })[cardinality] || 'none';
}

function makePage(page, index) {
  const pageWidth = page.pageWidth || 1600;
  const pageHeight = page.pageHeight || 1000;
  let nextId = 2;
  const cells = ['<mxCell id="0"/>','<mxCell id="1" parent="0"/>'];
  const ids = {};
  const positions = {};
  cells.push(`<mxCell id="${nextId++}" value="${esc(page.name)}" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=26;fontStyle=1;fontColor=#17324D;" vertex="1" parent="1"><mxGeometry x="40" y="20" width="850" height="40" as="geometry"/></mxCell>`);
  cells.push(`<mxCell id="${nextId++}" value="${esc(page.subtitle)}" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=13;fontColor=#5E6C84;" vertex="1" parent="1"><mxGeometry x="40" y="58" width="1100" height="25" as="geometry"/></mxCell>`);
  cells.push(`<mxCell id="${nextId++}" value="&lt;b&gt;Crow's-foot notation&lt;/b&gt;&amp;nbsp;&amp;nbsp; ||—|| one-to-one &amp;nbsp; • &amp;nbsp; ||—o&amp;lt; one-to-many &amp;nbsp; • &amp;nbsp; &amp;gt;o—|| many-to-one (reverse reading)&lt;br&gt;Solid = primary relationship &amp;nbsp; • &amp;nbsp; Dashed = direct owner_id reference &amp;nbsp; • &amp;nbsp; PK/FK = primary/foreign key" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#F3F4F6;strokeColor=#6B7280;fontColor=#374151;fontSize=11;align=left;spacingLeft=10;verticalAlign=middle;" vertex="1" parent="1"><mxGeometry x="${pageWidth - 700}" y="20" width="660" height="58" as="geometry"/></mxCell>`);
  for (const [name, x, y, rows] of page.tables) {
    const id = String(nextId++);
    ids[name] = id;
    positions[name] = { x, y };
    const h = 40 + rows.length * 27;
    cells.push(`<mxCell id="${id}" value="${esc(tableHtml(name, rows))}" style="rounded=0;whiteSpace=wrap;html=1;strokeColor=#4B5563;strokeWidth=1.4;fillColor=#FFFFFF;shadow=0;spacing=0;verticalAlign=top;overflow=hidden;" vertex="1" parent="1"><mxGeometry x="${x}" y="${y}" width="275" height="${h}" as="geometry"/></mxCell>`);
  }
  for (const [source, target, left, right, kind] of page.relationships) {
    const id = String(nextId++);
    const label = `${left} : ${right}`;
    const startArrow = cardinalityArrow(left);
    const endArrow = cardinalityArrow(right);
    const sourcePos = positions[source];
    const targetPos = positions[target];
    const horizontal = Math.abs(targetPos.x - sourcePos.x) >= Math.abs(targetPos.y - sourcePos.y);
    const forward = horizontal ? targetPos.x >= sourcePos.x : targetPos.y >= sourcePos.y;
    const ports = horizontal
      ? `exitX=${forward ? 1 : 0};exitY=0.5;entryX=${forward ? 0 : 1};entryY=0.5;`
      : `exitX=0.5;exitY=${forward ? 1 : 0};entryX=0.5;entryY=${forward ? 0 : 1};`;
    const secondary = kind === 'secondary';
    const edgeLabel = secondary ? '' : label;
    const edgeColor = secondary ? '#94A3B8' : '#374151';
    const edgeWidth = secondary ? '1.0' : '1.5';
    const dashed = secondary ? 'dashed=1;dashPattern=6 6;opacity=55;' : '';
    cells.push(`<mxCell id="${id}" value="${esc(edgeLabel)}" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=22;html=1;${ports}${dashed}strokeColor=${edgeColor};strokeWidth=${edgeWidth};endArrow=${endArrow};endFill=0;startArrow=${startArrow};startFill=0;sourcePerimeterSpacing=5;targetPerimeterSpacing=5;fontSize=10;fontStyle=1;fontColor=#111827;labelBackgroundColor=#FFFFFF;" edge="1" parent="1" source="${ids[source]}" target="${ids[target]}"><mxGeometry relative="1" as="geometry"/></mxCell>`);
  }
  const model = `<mxGraphModel dx="${pageWidth}" dy="${pageHeight}" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="${pageWidth}" pageHeight="${pageHeight}" math="0" shadow="0"><root>${cells.join('')}</root></mxGraphModel>`;
  const compressed = zlib.deflateRawSync(Buffer.from(encodeURIComponent(model), 'utf8')).toString('base64');
  return `<diagram id="erd-page-${index + 1}" name="${esc(page.name)}">${compressed}</diagram>`;
}

const xml = `<mxfile host="app.diagrams.net" modified="${new Date().toISOString()}" agent="Codex" version="24.7.17" type="device" compressed="true">${pages.map(makePage).join('')}</mxfile>\n`;
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, xml);
const editorUrl = `https://app.diagrams.net/?splash=0&drafts=0#R${encodeURIComponent(xml)}`;
fs.writeFileSync(webLauncher, `<!doctype html><meta charset="utf-8"><title>Opening Vet Clinic ERD</title><script>location.replace(${JSON.stringify(editorUrl)})</script>`);
console.log(`Wrote ${out} (${pages.length} pages)`);
