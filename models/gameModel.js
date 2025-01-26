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


static async getAllPlatformNames() {
    try {
        const [results] = await db.promise().query('SELECT platform_name FROM platforms');
        return results.map(row => row.platform_name);
    } catch (error) {
        throw new Error('Błąd podczas pobierania nazw platform: ' + error.message);
    }
}
}
module.exports = GameModel;
