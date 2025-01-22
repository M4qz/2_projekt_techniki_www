const db = require('./model');

class ReviewModel {
    static async getAllReviews() {
        try {
            const [results] = await db.promise().query('SELECT * FROM widok_reviews');
            return results;
        } catch (error) {
            throw new Error('Błąd podczas pobierania gier: ' + error.message);
        }
    }
}
module.exports = ReviewModel;
