const GameModel = require('../models/gameModel');
const ReviewModel = require('../models/reviewsModel');
const OwnerModel = require('../models/ownerModel');
const StatsModel = require('../models/statsModel');
const PurchaseModel = require('../models/purchaseModel');
const Wallet = require('../models/wallet');
const StatisticsModel = require("../models/StatisticsModel");


exports.getHomePage = (req, res) => {
    res.render('index', { title: 'Home', user: req.session.user });
};

exports.getSklepPage = async (req, res) => {
    if (req.session.user) {
    try {
        const balance = await Wallet.getBalance(req.session.user);
        const games1 = await GameModel.getAllGames();
        const platforms = await GameModel.getAllPlatformNames();
        //console.log(platforms)
        const games = games1.map(game => ({
            ...game,
            platformy: platforms // Add the platforms array to each game
        }));
        //console.log(gryWithPlatforms);
        res.render('sklep', { title: 'Sklep', gry: games, user: req.session.user, balance: balance});
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
            res.render('posiadanie', { title: 'Posiadanie', posiadanie: posiadanie, user: req.session.user});
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
        res.render('recenzje', { title: 'Recenzje', review: review,gameNames:gra, user: req.session.user});
    } catch (err) {
        console.error('Błąd podczas pobierania gier:', err.message);
        res.status(500).json({ error: 'Wystąpił błąd podczas ładowania strony sklepu.' });//post dac aby napisac recenzje
    }
} else {
    res.redirect('/');
}
};

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
            res.status(500).json({ error: 'Skomentowałeś już tą grę' });
        }
    } else {
        res.redirect('/');
    }
};

exports.handlePurchase = async (req, res) => {
    const { nazwaGry, platforma } = req.body;
    const userId = req.session.user; // Assuming user ID is stored in session
    const result = await PurchaseModel.purchaseGame(userId, nazwaGry, platforma);
    res.json(result);
};
// controllers/indexController.js
exports.startPlaying = async (req, res) => {
    const { gameName, platformName } = req.body;
    const userId = req.session.user;

    try {
        await StatisticsModel.startPlaying(userId, gameName, platformName);
        res.json({ message: 'Pomyślnie wykonano zadanie' });
    } catch (error) {
        console.error('Błąd podczas rozpoczynania gry:', error.message);
        res.status(500).json({ message: 'Wystąpił błąd podczas rozpoczynania gry.' });
    }
};
