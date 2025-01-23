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
    static async addReview(nazwa_gry,id_osoby, rating, comment) {
        const query2 = 'SELECT id_gry FROM gry WHERE gierka = ?';//SELECT id_gry FROM gry WHERE gierka ='Cuphead';
        const result=await db.promise().query(query2, [nazwa_gry]);
        const result1=result[0][0]?.id_gry
        const query = 'INSERT INTO reviews (id_gry, id_osoby, rating,review_text) VALUES (?, ?, ?, ?)';
        console.log(result1,id_osoby,rating,comment);
        await db.promise().query(query, [result1,id_osoby,rating,comment]);

    }//INSERT INTO reviews (id_gry, id_osoby, rating,review_text) VALUES ('BCES00924',4,5,'good');
}

module.exports = ReviewModel;
