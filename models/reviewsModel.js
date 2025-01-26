const db = require('./model');

exports.getAllReviews = async () => {
    try {
        const [results] = await db.promise().query('SELECT * FROM widok_reviews');
        return results;
    } catch (error) {
        throw new Error('Błąd podczas pobierania gier: ' + error.message);
    }
};

exports.addReview = async (nazwa_gry, id_osoby, rating, comment) => {
    try {
        const query2 = 'SELECT id_gry FROM gry WHERE gierka = ?';
        const result = await db.promise().query(query2, [nazwa_gry]);
        const result1 = result[0][0]?.id_gry;

        const [existingReview] = await db.promise().query('SELECT id FROM reviews WHERE id_gry = ? AND id_osoby = ?', [result1, id_osoby]);
        if (existingReview.length > 0) {
            throw new Error('Już istnieje taki sam komentarz dla tej gry.');
        }
        const query = 'INSERT INTO reviews (id_gry, id_osoby, rating, review_text) VALUES (?, ?, ?, ?)';
        await db.promise().query(query, [result1, id_osoby, rating, comment]);
        return { success: true };
    } catch (error) {
        throw new Error(error.message);
    }
};