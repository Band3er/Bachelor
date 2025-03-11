const express = require("express");
const app = express();
const port = 3000;

// Middleware pentru a permite JSON parsing
app.use(express.json());

// Stocare temporară a datelor primite
let storedData = [];

// Endpoint pentru ESP32
app.get("/data", (req, res) => {
    res.json({ message: "Salut ESP32!", storedData });
});

// Endpoint pentru a primi și stoca date
app.post("/data", (req, res) => {
    const { value } = req.body;
    if (value !== undefined) {
        storedData.push(value);
        console.log("Date primite de la ESP32:", value);
        res.json({ message: "Datele au fost stocate cu succes!", storedData });
    } else {
        res.status(400).json({ error: "Lipsesc datele!" });
    }
});

// Pornirea serverului
app.listen(port, "0.0.0.0", () => {
    console.log(`Serverul rulează la http://localhost:${port}`);
});