const db = require('./model');

class UserModel {
    static async login(login, password) {
        const query = 'SELECT id FROM dane WHERE login = ? AND password = ?';
        const [results] = await db.promise().query(query, [login, password]);
        return results.length > 0 ? results[0].id : null;
    }
}

module.exports = UserModel;