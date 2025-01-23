const GameModel = require('../models/gameModel');
const ReviewModel = require('../models/reviewsModel');
const OwnerModel = require('../models/ownerModel');
const StatsModel = require('../models/statsModel');

exports.getHomePage = (req, res) => {
    res.render('index', { title: 'Home', user: req.session.user });
};

exports.getSklepPage = async (req, res) => {
    if (req.session.user) {
    try {
        const games = await GameModel.getAllGames();
        res.render('sklep', { title: 'Sklep', gry: games, user: req.session.user });
    } catch (err) {
        console.error('Błąd podczas pobierania gier:', err.message);
        res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony sklepu.' });
    }
    } else {
        res.redirect('/');
    }
};

exports.getBibliotekaPage = async (req, res) => {
    if (req.session.user) {
        try {
            const posiadanie = await OwnerModel.owned(req.session.user);
            res.render('posiadanie', { title: 'Posiadanie', posiadanie: posiadanie, user: req.session.user });
        } catch (err) {
            console.error('Błąd podczas pobierania posiadanych tytułów:', err.message);
            res.status(500).json({ error: 'Wystąpił błąd podczas ładowania posidanych gier.' });
        }
    } else {
        res.redirect('/');
    }
};

exports.getRecenzjePage = async (req, res) => {
    if (req.session.user) {
    try {
        const gra1 = await GameModel.getAllGames();
        const review = await ReviewModel.getAllReviews();
        const gra = gra1.map(r => r.gierka);
        res.render('recenzje', { title: 'Recenzje', review: review,gameNames:gra, user: req.session.user });
    } catch (err) {
        console.error('Błąd podczas pobierania gier:', err.message);
        res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony sklepu.' });//post dac aby napisac recenzje
    }
} else {
    res.redirect('/');
}
};/*
exports.getRecenzjePage = async (req, res) => {
    try {
        const gry = await GameModel.getAllGames();
        const review = await ReviewModel.getAllReviews();
        res.render('recenzje', { gry, review });
    } catch (err) {
        console.error('Error fetching data:', err.message);
        res.status(500).json({ error: 'An error occurred while fetching data.' });
    }
};*/
exports.getStatystykaKontaPage = async (req, res) => {
    if (req.session.user) {
        try {
            const stats = await StatsModel.stats(req.session.user);
            res.render('staty', { title: 'Statysyka Konta', stats: stats, user: req.session.user });
        } catch (err) {
            console.error('Błąd podczas pobierania statysyk konta:', err.message);
            res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony statystyk.' });
        }
    } else {
        res.redirect('/');
    }
};

exports.addReview = async (req, res) => {
    if (req.session.user) {
        const { game, rating, comment } = req.body;
        const id_osoby = req.session.user; // Assuming user session contains the name

        try {
            await ReviewModel.addReview(game,id_osoby, rating, comment);
            res.redirect('/recenzje');
        } catch (err) {
            console.error('Błąd podczas dodawania recenzji:', err.message);
            res.status(500).json({ error: 'Wystąpił błąd podczas dodawania recenzji.' });
        }
    } else {
        res.redirect('/');
    }
};