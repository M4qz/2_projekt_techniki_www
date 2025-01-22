const db = require('./model');

class GameModel {
    static async getAllGames() {
        try {
            const [results] = await db.promise().query('SELECT * FROM widok_gry');
            return results;
        } catch (error) {
            throw new Error('Błąd podczas pobierania gier: ' + error.message);
        }
    }
}
module.exports = GameModel;
