const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const bodyParser = require('body-parser');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const frontendUrl = process.env.FRONTEND_URL;

app.use(bodyParser.json());
app.use(cors({ origin: frontendUrl }));

// Initialisation de Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json'); // Chemin vers votre fichier de clé de compte de service Firebase

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore(); // Initialisation de Firestore

// Vos endpoints API seront ajoutés ici

app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});