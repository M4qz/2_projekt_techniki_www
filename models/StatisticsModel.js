const db = require('./model');

exports.startPlaying = async (userId, gameName, platformName) => {
    try {
        const [gameResult] = await db.promise().query('SELECT id_gry FROM gry WHERE gierka = ?', [gameName]);
        const [platformResult] = await db.promise().query('SELECT id FROM platforms WHERE platform_name = ?', [platformName]);
        if (gameResult.length === 0 || platformResult.length === 0) {
            throw new Error('Game or platform not found');
        }

        const gameId = gameResult[0].id_gry;
        const platformId = platformResult[0].id;
        await db.promise().query('CALL AktualizujRozgrywkeGracza(?,?,?)', [userId, gameId, platformId]);
        return { message: 'Game started successfully' };
    } catch (error) {
        console.error('Error:', error.message);
        throw new Error('An error occurred while starting the game');
    }
};