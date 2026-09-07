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
    await pool.query(`CREATE SCHEMA ${schema}`);
    database = new Pool({ ...pool.options, password: pool.options.password, options: `-c search_path=${schema}`, max: 3 });
    await ensureDatabaseSchema(database);
    await ensureDatabaseSchema(database); // migration is repeatable
    const password = await bcrypt.hash('integration-only-password', 4);
    for (const [id,role] of [['ownerA','petOwner'],['ownerB','petOwner'],['staff','staff'],['doctor','doctor'],['admin','systemAdmin']]) {
      await database.query('INSERT INTO app_accounts(id,username,password_hash,role) VALUES($1,$1,$2,$3)',[id,password,role]);
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
    for (const id of ['ownerA','ownerB','staff','doctor','admin']) {
      const result = await request('/auth/login',null,{username:id,password:'integration-only-password'});
      assert.equal(result.status,200);tokens[id]=result.token;
    }
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
    // Exercise every named feature table with a permitted writer.
    for (const [table,p] of Object.entries(resources)) {
      if (p.writers?.length === 0) continue;
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
