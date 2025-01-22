const express = require('express');
const router = express.Router();
const indexController = require('../controllers/indexController');
const UserModel = require('../models/userModel');

// Strona główna, dostępna bez logowania
router.get('/', indexController.getHomePage);

// Strony wymagające zalogowania
router.get('/sklep', indexController.getSklepPage);
router.get('/biblioteka', indexController.getBibliotekaPage);
router.get('/recenzje', indexController.getRecenzjePage);
router.get('/statystyka-konta', indexController.getStatystykaKontaPage);

// Strona logowania
router.get('/login', (req, res) => {
    if (req.session.loginFailed) {
        req.session.loginFailed = false; // Reset the flag
        res.render('login_zle'); // Render the login_zle page
    } else {
        res.render('login'); // Render the login page
    }
});

// Obsługa logowania
router.post('/login', async (req, res) => {
    const { login, password } = req.body;
    try {
        const user = await UserModel.login(login, password);
        if (user) {
            req.session.user = user;
            res.redirect('/'); // Redirect to the home page
        } else {
            req.session.loginFailed = true; // Set the flag
            res.redirect('/login'); // Redirect to login route
        }
    } catch (err) {
        console.error('Unexpected error:', err);
        res.status(500).send('Server error');
    }
});

// Wylogowanie
router.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect('/'); // Przekierowanie na stronę główną po wylogowaniu
});

module.exports = router;