const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
const { pool } = require('../src/db');
const { ensureDatabaseSchema } = require('../src/schema');
const { installApi } = require('../src/api');
const { resources } = require('../src/resources');

test('PostgreSQL API: round trips, ownership, roles, conflicts, rollback, logout', async () => {
  const schema = `vet_test_${process.pid}_${Date.now()}`;
  let database, server;
  try {
    // Keep the test on one pooled connection and select the temporary schema
    // after connecting. Hosted poolers such as Neon reject search_path when it
    // is sent as a PostgreSQL startup parameter.
    database = new Pool({ ...pool.options, password: pool.options.password, max: 1 });
    await ensureDatabaseSchema(database, schema);
    await database.query(`SET search_path TO ${schema}`);
    await ensureDatabaseSchema(database, schema); // migration is repeatable
    const password = await bcrypt.hash('integration-only-password', 4);
    for (const [id,role] of [['ownerA','petOwner'],['ownerB','petOwner'],['staff','staff'],['doctor','doctor'],['doctorB','doctor'],['admin','systemAdmin']]) {
      await database.query('INSERT INTO app_accounts(id,username,password_hash,role) VALUES($1,$2,$3,$4)',[id,id.toLowerCase(),password,role]);
    }
    const app = express();
    app.use(express.json());
    installApi(app, database);
    server = await new Promise(resolve => {const s=app.listen(0,'127.0.0.1',()=>resolve(s));});
    const base = `http://127.0.0.1:${server.address().port}`;
    async function request(path, token, body) {
      const response = await fetch(base+path,{method:body ? 'POST':'GET',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});
      return {status:response.status,...await response.json()};
    }
    const tokens = {};
    for (const id of ['ownerA','ownerB','staff','doctor','doctorB','admin']) {
      const result = await request('/auth/login',null,{username:id,password:'integration-only-password'});
      assert.equal(result.status,200);tokens[id]=result.token;
    }
    // Active staff are immediately available to owner-facing pet-care
    // provider selection, then follow their persisted on-shift status.
    let directory = await request('/data/clinic_directory',tokens.ownerA);
    let staffDirectoryEntry = directory.records.find(r=>r.data.value.id==='staff');
    assert.equal(staffDirectoryEntry.data.value.available,true);
    const staffProfile = {id:'staff-profile',version:0,data:{key:'staff:profile',value:{name:'Clinic Staff',shift:'Evening',onShift:false}}};
    assert.equal((await request('/data/staff_profiles/sync',tokens.staff,{changes:[staffProfile]})).status,200);
    directory = await request('/data/clinic_directory',tokens.ownerA);
    staffDirectoryEntry = directory.records.find(r=>r.data.value.id==='staff');
    assert.equal(staffDirectoryEntry.data.value.available,false);
    assert.equal(staffDirectoryEntry.data.value.specialty,'Evening');
    assert.equal((await request('/data/pets')).status,401);
    assert.equal((await request('/data/inventory;DROP TABLE pets',tokens.admin)).status,404);
    assert.equal((await request('/data/payments',tokens.ownerA)).status,403);
    const row = {id:'pet-1',version:0,data:{key:'ownerA:pet-1',value:{id:'pet-1',name:'Test pet'}}};
    let result = await request('/data/pets/sync',tokens.ownerA,{changes:[row]});
    assert.equal(result.status,200);assert.equal(result.records[0].version,1);
    assert.equal((await request('/data/pets',tokens.ownerB)).records.length,0);
    assert.equal((await request('/data/pets',tokens.staff)).records.length,1);
    assert.equal((await request('/data/pets/sync',tokens.ownerB,{changes:[{...row,version:1}]})).status,403);
    assert.equal((await request('/data/pets/sync',tokens.ownerA,{changes:[row]})).status,409);
    assert.equal((await request('/data/pets/sync',tokens.ownerA,{changes:[{...row,id:'pet-2'},row]})).status,409);
    assert.equal((await request('/data/pets',tokens.ownerA)).records.length,1); // batch rolled back
    result = await request('/data/pets/sync',tokens.ownerA,{changes:[{...row,version:1,data:{...row.data,value:{name:'Updated'}}}]});
    assert.equal(result.records[0].version,2);
    assert.equal((await request('/data/pets',tokens.ownerA)).records[0].data.value.name,'Updated');
    assert.equal((await request('/data/pets/sync',tokens.ownerA,{deletions:[{id:'pet-1',version:2}]})).status,200);
    assert.equal((await request('/data/pets',tokens.ownerA)).records.length,0);
    // Health posts are clinic-visible but doctor-owned for mutation. Publishing
    // also creates an in-app notification for every active pet owner.
    const healthPost = {
      id:'doctor-health-post',version:0,
      data:{key:'doctor:health-post',value:{
        id:'doctor-health-post',title:'Dental care',content:'Brush regularly.',
        coverAsset:'',attachmentAssets:[],createdAt:new Date().toISOString(),
        updatedAt:new Date().toISOString(),authorId:'doctor',authorName:'Dr. Test',
        category:'Prevention',audience:'All Pets',status:'published',
      }},
    };
    result = await request('/data/health_posts/sync',tokens.doctor,{changes:[healthPost]});
    assert.equal(result.status,200);
    assert.equal((await request('/data/health_posts',tokens.ownerA)).records.some(r=>r.id===healthPost.id),true);
    assert.equal((await request('/data/owner_notifications',tokens.ownerA)).records.some(r=>r.data.value.message.includes('Dental care')),true);
    assert.equal((await request('/data/health_posts/sync',tokens.doctorB,{changes:[{...healthPost,version:1}]})).status,403);
    assert.equal((await request('/data/health_posts/sync',tokens.doctorB,{deletions:[{id:healthPost.id,version:1}]})).status,403);
    // Queue tickets are clinic-owned, receive atomic daily numbers, expose a
    // derived owner position, and enforce versioned lifecycle transitions.
    const appointmentValue = {
      id:'queue-appointment', date:new Date().toISOString(), time:'09:00 AM',
      status:'Confirmed', veterinarian:'Dr. Queue', pet:{id:'pet-a',name:'Max'},
      service:{name:'Checkup',homeVisit:false},
    };
    result = await request('/data/appointments/sync',tokens.ownerA,{changes:[{
      id:'appointment-row',version:0,
      data:{key:'ownerA:queue-appointment',value:appointmentValue},
    }]});
    assert.equal(result.status,200);
    assert.equal((await request('/data/queue_entries/sync',tokens.ownerA,{changes:[{
      id:'forged-queue',version:0,data:{key:'forged',value:{status:'called'}},
    }]})).status,403);
    const checkedIn = await request('/queue/check-in',tokens.staff,{
      appointmentId:'queue-appointment',priority:'normal',
    });
    assert.equal(checkedIn.status,201);
    assert.equal(checkedIn.record.data.value.queueNumber,'Q001');
    assert.equal(checkedIn.record.data.value.serviceGroup,'medicalService');
    assert.equal(checkedIn.record.data.value.status,'waiting');
    const myQueue = await request('/queue/my',tokens.ownerA);
    assert.equal(myQueue.records[0].data.value.position,1);
    assert.equal(myQueue.records[0].data.value.petsAhead,0);
    assert.equal((await request('/queue/queue-appointment/transition',tokens.staff,{status:'arrived',version:1})).status,409);
    result = await request('/queue/queue-appointment/transition',tokens.staff,{status:'called',version:1,room:'Room 1'});
    assert.equal(result.status,200);
    assert.ok(result.record.data.value.calledAt);
    result = await request('/queue/queue-appointment/acknowledge',tokens.ownerA,{});
    assert.equal(result.status,200);
    assert.ok(result.record.data.value.ownerAcknowledgedAt);
    assert.equal((await request('/queue/queue-appointment/transition',tokens.staff,{status:'arrived',version:2})).status,409);
    result = await request('/queue/queue-appointment/transition',tokens.staff,{status:'arrived',version:3});
    assert.equal(result.status,200);
    result = await request('/queue/queue-appointment/transition',tokens.doctor,{status:'inConsultation',version:4});
    assert.equal(result.status,200);
    assert.equal((await request('/queue/queue-appointment/transition',tokens.doctor,{status:'completed',version:5})).status,400);
    result = await request('/data/medical_records/sync',tokens.doctor,{changes:[{
      id:'medical-queue-appointment',version:0,
      data:{key:'MED-queue-appointment',value:{id:'MED-queue-appointment',appointmentId:'queue-appointment',finalized:true}},
    }]});
    assert.equal(result.status,200);
    result = await request('/queue/queue-appointment/transition',tokens.doctor,{status:'completed',version:5,medicalRecordId:'MED-queue-appointment'});
    assert.equal(result.status,200);
    assert.equal(result.record.data.value.medicalRecordId,'MED-queue-appointment');
    // Administrator provisioning creates both the directory row and a real,
    // hashed login for every assignable role. Pending users cannot sign in.
    const provisioned = [];
    for (const [index,[role,accountRole]] of [['owner','petOwner'],['doctor','doctor'],['staff','staff']].entries()) {
      const id = `created-${role}`;
      const value = {id,name:`Created ${role}`,username:`created.${role}`,email:`created-${role}@clinic.test`,phone:`091234567${index}`,role,status:'pending',lastActive:'Never',createdOn:new Date().toISOString(),password:'Created@123'};
      const created = await request('/data/user_directory/sync',tokens.admin,{changes:[{id:`directory-${role}`,version:0,data:{key:id,value}}]});
      assert.equal(created.status,200,`provision ${role}`);
      assert.equal(created.records[0].data.value.password,undefined);
      const account = (await database.query('SELECT * FROM app_accounts WHERE id=$1',[id])).rows[0];
      assert.equal(account.role,accountRole);
      assert.equal(account.active,false);
      assert.equal(await bcrypt.compare('Created@123',account.password_hash),true);
      assert.equal((await request('/auth/login',null,{username:value.email.toUpperCase(),password:'Created@123'})).status,401);
      provisioned.push(created.records[0]);
    }
    // Activation updates the same login and permits username, case-insensitive
    // email, and normalized phone-number sign-in for one registered account.
    const doctorRecord = provisioned[1];
    doctorRecord.data.value.status = 'active';
    result = await request('/data/user_directory/sync',tokens.admin,{changes:[{id:doctorRecord.id,version:doctorRecord.version,data:doctorRecord.data}]});
    assert.equal(result.status,200);
    assert.equal((await request('/auth/login',null,{username:'CREATED-DOCTOR@CLINIC.TEST',password:'Created@123'})).status,200);
    assert.equal((await request('/auth/login',null,{username:'CREATED.DOCTOR',password:'Created@123'})).status,200);
    assert.equal((await request('/auth/login',null,{username:'091-234-5671',password:'Created@123'})).status,200);
    // Email uniqueness is enforced by the database-backed account table.
    const duplicate = {id:'created-duplicate',name:'Duplicate',username:'different.staff',email:'CREATED-DOCTOR@CLINIC.TEST',phone:'0999999999',role:'staff',status:'pending',lastActive:'Never',createdOn:new Date().toISOString(),password:'Created@123'};
    assert.equal((await request('/data/user_directory/sync',tokens.admin,{changes:[{id:'directory-duplicate',version:0,data:{key:duplicate.id,value:duplicate}}]})).status,409);
    // Exercise every named feature table with a permitted writer.
    for (const [table,p] of Object.entries(resources)) {
      if (p.writers?.length === 0) continue;
      if (table === 'user_directory') continue; // covered by provisioning above
      const role=(p.writers||p.roles)[0];
      const who={petOwner:'ownerA',doctor:'doctor',staff:'staff',systemAdmin:'admin'}[role];
      const item={id:`roundtrip-${table}`,version:0,data:{key:'roundtrip',value: table === 'user_directory' ? {id:'directory-test',name:'Test',role:'owner',status:'pending'} : {test:true}}};
      assert.equal((await request(`/data/${table}/sync`,tokens[who],{changes:[item]})).status,200,table);
      assert.ok((await request(`/data/${table}`,tokens[who])).records.some(r=>r.id===item.id),table);
    }
    assert.equal((await request('/auth/logout',tokens.ownerA,{})).status,200);
    assert.equal((await request('/data/pets',tokens.ownerA)).status,401);
  } finally {
    if(server) await new Promise(resolve=>server.close(resolve));
    if(database) await database.end();
    await pool.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
    await pool.end();
  }
});
