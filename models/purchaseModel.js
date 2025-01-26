// models/purchaseModel.js
const db = require('./model');

exports.purchaseGame = async (userId, nazwaGry, platforma) => {
    try {
        const [user] = await db.promise().query('SELECT imie, nazwisko FROM dane WHERE id = ?', [userId]);
        if (user.length === 0) {
            throw new Error('Użytkownik nie znaleziony');
        }

        const { imie, nazwisko } = user[0];
        await db.promise().query('CALL ZakupGry(?, ?, ?, ?)', [imie, nazwisko, nazwaGry, platforma]);
        return { success: true };
    } catch (error) {
        return { success: false, message: error.message };
    }
};