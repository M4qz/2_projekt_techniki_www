const db = require('./model');

class OwnerModel {
    static async owned(id) {
        const query = 'SELECT * FROM widok_posiadanie WHERE id_osoby = ?';
        const [results] = await db.promise().query(query, [id]);
        return results;
    }
}

module.exports = OwnerModel;