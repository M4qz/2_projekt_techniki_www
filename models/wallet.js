const db = require('./model');

class Wallet {
    static async getBalance(userId) {
        const query = 'SELECT portfel FROM dane WHERE id = ?';
        const [result] = await db.promise().query(query, [userId]);
        return result[0].portfel;
    }
}


module.exports = Wallet;