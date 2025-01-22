const GameModel = require('../models/gameModel');
const ReviewModel = require('../models/reviewsModel');
const OwnerModel = require('../models/ownerModel');

exports.getHomePage = (req, res) => {
    res.render('index', { title: 'Home', user: req.session.user });
};

exports.getSklepPage = async (req, res) => {
    try {
        const games = await GameModel.getAllGames();
        res.render('sklep', { title: 'Sklep', gry: games, user: req.session.user });
    } catch (err) {
        console.error('Błąd podczas pobierania gier:', err.message);
        res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony sklepu.' });
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
        res.redirect('/login');
    }
};

exports.getRecenzjePage = async (req, res) => {
    try {
        const review = await ReviewModel.getAllReviews();
        res.render('recenzje', { title: 'Recenzje', review: review, user: req.session.user });
    } catch (err) {
        console.error('Błąd podczas pobierania gier:', err.message);
        res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony sklepu.' });
    }
};

exports.getStatystykaKontaPage = (req, res) => {
    res.render('statystyka-konta', { title: 'Statystyka konta', user: req.session.user });
};