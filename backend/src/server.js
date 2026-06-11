require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");

const { pool } = require("./db");
const { ensureDatabaseSchema } = require("./schema");

const app = express();
const port = Number(process.env.PORT || 5000);

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Nway Love Vet Clinic API is running" });
});

app.get("/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW() AS server_time");
    res.json({
      status: "ok",
      database: "connected",
      serverTime: result.rows[0].server_time,
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      database: "disconnected",
      message: error.message,
    });
  }
});

app.post("/auth/pet-owner/login", async (req, res) => {
  const username = String(req.body.username || "").trim();
  const password = String(req.body.password || "");

  if (!username || !password) {
    return res.status(400).json({ message: "Username and password required" });
  }

  try {
    const result = await pool.query(
      `
        SELECT id, username, password_hash, full_name
        FROM pet_owners
        WHERE username = $1
        LIMIT 1
      `,
      [username],
    );

    const petOwner = result.rows[0];
    const passwordMatches =
      petOwner && (await bcrypt.compare(password, petOwner.password_hash));

    if (!passwordMatches) {
      return res.status(401).json({ message: "Invalid username or password" });
    }

    return res.json({
      petOwner: {
        id: petOwner.id,
        username: petOwner.username,
        fullName: petOwner.full_name,
      },
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.listen(port, async () => {
  console.log(`Server running on http://localhost:${port}`);

  try {
    await ensureDatabaseSchema();
    await pool.query("SELECT 1");
    console.log("Connected to PostgreSQL database NwayLoveVetClinicSever");
  } catch (error) {
    console.error("PostgreSQL connection failed:", error.message);
  }
});

module.exports = { app, pool };
