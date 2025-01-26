const db = require('./model');

class StatsModel {
    static async stats(id) {
        const query = 'SELECT gierka,czas_gry,ostatnia_rozgrywka,platform_name FROM widok_statystyki_graczy WHERE id_osoby = ?';
        const [results] = await db.promise().query(query, [id]);
        return results;
    }
}

module.exports = StatsModel;