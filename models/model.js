// models/model.js
const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '123', // Hasło do MySQL, jeśli używasz XAMPP/WAMP, zostaw puste
    database: 'www', // Nazwa bazy danych
});

db.connect((err) => {
    if (err) {
        console.error('Nie udało się połączyć z bazą danych:', err);
        return;
    }
    console.log('Połączono z bazą danych MySQL.');
});

module.exports = db;