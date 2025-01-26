-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sty 26, 2025 at 03:42 AM
-- Wersja serwera: 10.4.32-MariaDB
-- Wersja PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `www`
--

DELIMITER $$
--
-- Procedury
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AktualizujRozgrywkeGracza` (IN `osobaId` INT, IN `gierka` TEXT, IN `platformId` INT)   BEGIN
    DECLARE obecnaData DATETIME;
    DECLARE czasRozgrywki INT;

    -- Pobierz bieżącą datę i czas
    SET obecnaData = NOW();

    -- Sprawdź, czy gracz (osoba) na tej platformie jest w trakcie rozgrywki
    IF EXISTS (
        SELECT 1
        FROM statystyki_graczy
        WHERE id_osoby = osobaId AND gierka = gierka AND id_platform = platformId AND playing = TRUE
    ) THEN
        -- Oblicz różnicę czasu między obecnym czasem a ostatnią rozgrywką
        SET czasRozgrywki = TIMESTAMPDIFF(SECOND, 
            (SELECT ostatnia_rozgrywka 
             FROM statystyki_graczy 
             WHERE id_osoby = osobaId AND gierka = gierka AND id_platform = platformId), 
            obecnaData
        );

        -- Zaktualizuj czas gry i zmień flagę na FALSE
        UPDATE statystyki_graczy
        SET czas_gry = czas_gry + czasRozgrywki,
            playing = FALSE
        WHERE id_osoby = osobaId AND gierka = gierka AND id_platform = platformId;

    ELSE
        -- Ustaw bieżącą datę jako ostatnia_rozgrywka i zmień flagę na TRUE
        UPDATE statystyki_graczy
        SET ostatnia_rozgrywka = obecnaData,
            playing = TRUE
        WHERE id_osoby = osobaId AND gierka = gierka AND id_platform = platformId;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `WypiszTrofea` (IN `nazwa_gry` TEXT)   BEGIN
    -- Wybieramy wszystkie trofea dla podanej gry
    SELECT a.achievement_name, a.description
    FROM gry g
    JOIN achievements a ON g.id_gry = a.id_gry
    WHERE g.gierka = nazwa_gry COLLATE utf8mb4_polish_ci;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ZakupGry` (IN `klient_imie` TEXT, IN `klient_nazwisko` TEXT, IN `nazwa_gry` TEXT, IN `nazwa_platformy` VARCHAR(255))   BEGIN
    DECLARE klient_id INT;
    DECLARE klient_portfel DECIMAL(10,2);
    DECLARE gra_id VARCHAR(9);
    DECLARE gra_cena DECIMAL(10,2);
    DECLARE platforma_id INT;
    DECLARE num_rows_klient INT;
    DECLARE num_rows_gra INT;
    DECLARE num_rows_platforma INT;
    DECLARE istnieje_rekord INT;

    -- Pobierz ID klienta oraz portfel na podstawie imienia i nazwiska
    SELECT id, portfel, FOUND_ROWS() INTO klient_id, klient_portfel, num_rows_klient
    FROM dane
    WHERE CONVERT(imie USING utf8mb4) = CONVERT(klient_imie USING utf8mb4)
    AND CONVERT(nazwisko USING utf8mb4) = CONVERT(klient_nazwisko USING utf8mb4)
    LIMIT 1;

    IF num_rows_klient != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono klienta lub znaleziono więcej niż jednego klienta.';
    END IF;

    -- Pobierz ID gry oraz cenę na podstawie nazwy gry
    SELECT id_gry, cena, FOUND_ROWS() INTO gra_id, gra_cena, num_rows_gra
    FROM gry
    WHERE CONVERT(gierka USING utf8mb4) = CONVERT(nazwa_gry USING utf8mb4)
    LIMIT 1;

    IF num_rows_gra != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono gry lub znaleziono więcej niż jedną grę.';
    END IF;

    -- Pobierz ID platformy na podstawie jej nazwy
    SELECT id, FOUND_ROWS() INTO platforma_id, num_rows_platforma
    FROM platforms
    WHERE CONVERT(platform_name USING utf8mb4) = CONVERT(nazwa_platformy USING utf8mb4)
    LIMIT 1;

    IF num_rows_platforma != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono platformy lub znaleziono więcej niż jedną platformę.';
    END IF;

    -- Sprawdź, czy rekord już istnieje w tabeli 'posiadanie'
    SELECT COUNT(*) INTO istnieje_rekord
    FROM posiadanie
    WHERE CONVERT(id_osoby USING utf8mb4) = CONVERT(klient_id USING utf8mb4) 
    AND CONVERT(id_gry USING utf8mb4) = CONVERT(gra_id USING utf8mb4) 
    AND CONVERT(id_platform USING utf8mb4) = CONVERT(platforma_id USING utf8mb4);

    IF istnieje_rekord > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Ten produkt został już zakupiony.';
    END IF;

    -- Sprawdzamy, czy klient ma wystarczająco pieniędzy na zakup gry
    IF klient_portfel >= gra_cena THEN
        -- Zmniejszamy portfel klienta o cenę gry
        UPDATE dane
        SET portfel = klient_portfel - gra_cena
        WHERE id = klient_id;

        -- Dodajemy rekord do tabeli 'posiadanie'
        INSERT INTO posiadanie (id_osoby, id_gry, id_platform)
        VALUES (klient_id, gra_id, platforma_id);

        -- Dodajemy rekord do tabeli 'statystyki_graczy'
        INSERT INTO statystyki_graczy (id_gry, id_osoby, id_platform, czas_gry, liczba_zwyciestw, liczba_porazek, ostatnia_rozgrywka)
        VALUES (gra_id, klient_id, platforma_id, '0:00:00', 0, 0, CURDATE());

        -- Potwierdzenie udanego zakupu
        SELECT CONCAT('Zakup udany! Twoje konto zostało obciążone kwotą ', gra_cena) AS wynik;
    ELSE
        -- Jeśli nie ma wystarczających środków
        SELECT CONCAT('Brak wystarczających środków na zakup tej gry. Twoje dostępne środki to: ', klient_portfel, ' a cena gry to: ', gra_cena) AS wynik;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ZmienCeneDlaWszystkich` (`tryb` VARCHAR(10))   BEGIN
    -- Sprawdzamy wartość trybu i obliczamy nową cenę dla wszystkich gier
    IF tryb = 'normal' THEN
        -- Jeśli tryb "normal", dzielimy cenę przez 0.65 dla wszystkich rekordów
        UPDATE gry
        SET cena = cena *2;
        
    ELSEIF tryb = 'summer' THEN
        -- Jeśli tryb "summer", mnożymy cenę przez 0.65 dla wszystkich rekordów
        UPDATE gry
        SET cena = cena /2;
        
    END IF;
    
    -- Opcjonalnie możemy zwrócić informację o liczbie zmodyfikowanych rekordów
    SELECT ROW_COUNT() AS liczba_zmienionych_rekordow;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CenaPoZnizce` (`klient_imie` TEXT, `klient_nazwisko` TEXT, `nazwa_gry` TEXT) RETURNS DECIMAL(10,2)  BEGIN
    DECLARE klient_id INT;
    DECLARE klient_portfel DECIMAL(10,2);
    DECLARE status_usera VARCHAR(50);
    DECLARE gra_cena DECIMAL(10,2);
    DECLARE num_rows_klient INT;
    DECLARE num_rows_gra INT;

    -- Pobieramy dane klienta: id, portfel i sprawdzamy, ile rekordów pasuje
    SELECT id, portfel, status, FOUND_ROWS()
    INTO klient_id, klient_portfel, status_usera, num_rows_klient
    FROM dane
    WHERE CONVERT(imie USING utf8mb4) = CONVERT(klient_imie USING utf8mb4)
    AND CONVERT(nazwisko USING utf8mb4) = CONVERT(klient_nazwisko USING utf8mb4)
    LIMIT 1;

    -- Sprawdzamy, czy znaleziono dokładnie 1 klienta
    IF num_rows_klient != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono klienta lub znaleziono więcej niż jednego klienta.';
    END IF;

    -- Pobieramy cenę gry na podstawie jej nazwy i sprawdzamy, ile rekordów pasuje
    SELECT cena, FOUND_ROWS()
    INTO gra_cena, num_rows_gra
    FROM gry
    WHERE CONVERT(gierka USING utf8mb4) = CONVERT(nazwa_gry USING utf8mb4)
    LIMIT 1;

    -- Sprawdzamy, czy znaleziono dokładnie 1 grę
    IF num_rows_gra != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono gry lub znaleziono więcej niż jedną grę.';
    END IF;

    -- Jeśli użytkownik ma status premium, obniżamy cenę o 40%
    IF status_usera = 'premium' THEN
        RETURN gra_cena * 0.6;  -- Cena po zniżce 40%
    ELSE
        RETURN gra_cena;  -- Normalna cena
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `srednia_ocena` (`tytul_gry` VARCHAR(255)) RETURNS DECIMAL(5,2) DETERMINISTIC BEGIN
    DECLARE srednia DECIMAL(5,2);
    
    -- Obliczanie średniej ocen i zabezpieczenie przed problemami z collation
    SELECT AVG(r.rating) INTO srednia
    FROM reviews r
    INNER JOIN gry g ON r.id_gry = g.id_gry
    WHERE g.gierka = tytul_gry COLLATE utf8mb4_general_ci;

    -- Zwracamy wynik
    RETURN srednia;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `achievements`
--

CREATE TABLE `achievements` (
  `id` int(11) NOT NULL,
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci DEFAULT NULL,
  `achievement_name` varchar(255) CHARACTER SET ucs2 COLLATE ucs2_polish_ci NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `achievements`
--

INSERT INTO `achievements` (`id`, `id_gry`, `achievement_name`, `description`) VALUES
(4, 'BCES00065', 'Hell Walker', 'Complete the game on Hell difficulty.'),
(5, 'BCES00065', 'Treasure Hoarder', 'Collect 1,000,000 gold.'),
(6, 'BCES00065', 'Demon Slayer', 'Defeat 100 elite demons.'),
(7, 'BCES00129', 'Sharpshooter', 'Achieve 10 headshots in a single match.'),
(8, 'BCES00129', 'Team Player', 'Win 10 matches with your team.'),
(9, 'BCES00129', 'Bomb Defuser', 'Successfully defuse 50 bombs.'),
(10, 'BCES00089', 'Bomb Defuser', 'Win a match as the last player standing.'),
(11, 'BCES00089', 'Builder Extaordinaire', 'Build 500 structures in a single match.'),
(12, 'BCES00089', 'Master Sniper', 'Eliminate 10 players using a sniper rifle.'),
(13, 'BCES00064', 'Perfect Parry', 'Perform 50 perfect parries.'),
(14, 'BCES00064', 'No Hit Wonder', 'Complete a level without taking damage.'),
(15, 'BCES00064', 'Boss Slayer', 'Defeat 5 bosses on expert mode.');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `dane`
--

CREATE TABLE `dane` (
  `imie` text NOT NULL,
  `nazwisko` text NOT NULL,
  `wiek` int(2) NOT NULL,
  `data_dołączenia` date NOT NULL,
  `id` int(12) NOT NULL,
  `status` text DEFAULT NULL,
  `portfel` decimal(10,2) DEFAULT NULL,
  `login` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=ucs2 COLLATE=ucs2_polish_ci;

--
-- Dumping data for table `dane`
--

INSERT INTO `dane` (`imie`, `nazwisko`, `wiek`, `data_dołączenia`, `id`, `status`, `portfel`, `login`, `password`) VALUES
('Łukasz', 'Gałek', 12, '2016-02-10', 1, 'premium', 121.48, 'ŁGałek73', 'Password123!'),
('Karol', 'Wójcik', 2, '2019-02-10', 2, 'non-premium', 1160.00, 'KWójcik53', 'SecurePass45$'),
('Jakub', 'Cyran', 1, '2024-01-03', 3, 'non-premium', 483.77, 'JCyran5', 'GameLover99%'),
('Jakub', 'Piotrowicz', 26, '2014-08-06', 4, 'premium', 201.91, 'JPiotrowicz94', 'MySQLFun67&'),
('Kamil', 'Wrażeń', 22, '2009-02-28', 5, 'non-premium', 358.23, 'KWrażeń24', 'HelloWorld78#'),
('Anna', 'Nowak', 41, '2023-10-10', 6, 'premium', 185.42, 'ANowak1', 'TopSecret44!'),
('Jan', 'Kowalski', 45, '2023-11-19', 7, 'non-premium', 652.43, 'JKowalski66', 'NodeJSRule88*'),
('Magdalena', 'Wójcik', 51, '2023-11-29', 8, 'premium', 805.88, 'MWójcik44', 'ReactMaster77^'),
('Piotr', 'Kamiński', 30, '2024-06-12', 9, 'premium', 172.12, 'PKamiński80', 'ExpressPro22@'),
('Karolina', 'Dąbrowska', 25, '2024-05-22', 10, 'non-premium', 142.96, 'KDąbrowska25', 'TableEdit55$'),
('Michał', 'Zieliński', 50, '2024-06-18', 11, 'premium', 998.42, 'MZieliński21', 'LoginSecure11!'),
('Natalia', 'Szymańska', 40, '2024-06-01', 12, 'premium', 863.23, 'NSzymańska76', 'DBAdmin99%'),
('Krzysztof', 'Woźniak', 38, '2023-11-16', 13, 'non-premium', 320.90, 'KWoźniak97', 'UserPass66^'),
('Alicja', 'Kozłowska', 35, '2023-12-08', 14, 'premium', 714.80, 'AKozłowska4', 'HashItUp33#'),
('Tomasz', 'Jankowski', 32, '2024-01-03', 15, 'premium', 511.28, 'TJankowski41', 'FinalPass00&');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `developers`
--

CREATE TABLE `developers` (
  `id` int(11) NOT NULL,
  `developer_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `developers`
--

INSERT INTO `developers` (`id`, `developer_name`) VALUES
(2, 'Blizzard Entertainment'),
(4, 'Epic Games'),
(1, 'Naughty Dog'),
(5, 'StudioMDHR'),
(3, 'Valve');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `game_modes`
--

CREATE TABLE `game_modes` (
  `id` int(11) NOT NULL,
  `game_mode` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `game_modes`
--

INSERT INTO `game_modes` (`id`, `game_mode`) VALUES
(3, 'Co-op'),
(2, 'Multiplayer'),
(1, 'Singleplayer');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `genres`
--

CREATE TABLE `genres` (
  `id` int(11) NOT NULL,
  `genre` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `genres`
--

INSERT INTO `genres` (`id`, `genre`) VALUES
(2, 'Adventure'),
(1, 'Battle Royale'),
(4, 'Platformer'),
(3, 'RPG'),
(5, 'Shooter');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `gry`
--

CREATE TABLE `gry` (
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci NOT NULL,
  `gierka` text CHARACTER SET ucs2 COLLATE ucs2_polish_ci DEFAULT NULL,
  `id_developer` int(11) DEFAULT NULL,
  `id_publisher` int(11) DEFAULT NULL,
  `release_date` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `cena` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;

--
-- Dumping data for table `gry`
--

INSERT INTO `gry` (`id_gry`, `gierka`, `id_developer`, `id_publisher`, `release_date`, `description`, `cena`) VALUES
('BCES00064', 'Cuphead', 5, 5, '2017-09-29', 'Hard comic game', 20.00),
('BCES00065', 'Diablo 3', 2, 2, '2012-05-15', 'Diablo will never die', 50.00),
('BCES00089', 'Fortnite', 4, 4, '2017-07-21', 'Cool battleroyale', 0.00),
('BCES00129', 'CS2', 3, 3, '2023-09-27', 'Free upgrade to CS:GO', 0.00),
('BCES00130', 'Uncharted', 1, 1, '2007-11-19', 'Adventure game', 30.00);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `gry_genres`
--

CREATE TABLE `gry_genres` (
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci DEFAULT NULL,
  `id_genre` int(11) NOT NULL,
  `id_game_mode` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gry_genres`
--

INSERT INTO `gry_genres` (`id_gry`, `id_genre`, `id_game_mode`) VALUES
('BCES00089', 1, 2),
('BCES00065', 3, 3),
('BCES00064', 4, 3),
('BCES00129', 5, 2);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `platforms`
--

CREATE TABLE `platforms` (
  `id` int(11) NOT NULL,
  `platform_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `platforms`
--

INSERT INTO `platforms` (`id`, `platform_name`) VALUES
(4, 'Nintendo Switch'),
(3, 'PC'),
(1, 'PlayStation 5'),
(2, 'Xbox Series X');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `posiadanie`
--

CREATE TABLE `posiadanie` (
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci NOT NULL,
  `id_osoby` int(12) NOT NULL,
  `id_platform` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf16 COLLATE=utf16_polish_ci;

--
-- Dumping data for table `posiadanie`
--

INSERT INTO `posiadanie` (`id_gry`, `id_osoby`, `id_platform`) VALUES
('BCES00129', 2, 3),
('BCES00065', 2, 2);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `publishers`
--

CREATE TABLE `publishers` (
  `id` int(11) NOT NULL,
  `publisher_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `publishers`
--

INSERT INTO `publishers` (`id`, `publisher_name`) VALUES
(2, 'Activision Blizzard'),
(4, 'Epic Games'),
(1, 'Sony Interactive Entertainment'),
(5, 'StudioMDHR'),
(3, 'Valve');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci DEFAULT NULL,
  `id_osoby` int(12) DEFAULT NULL,
  `rating` int(1) DEFAULT NULL,
  `review_text` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `id_gry`, `id_osoby`, `rating`, `review_text`) VALUES
(30, 'BCES00064', 2, 1, '123'),
(31, 'BCES00065', 2, 1, ''),
(32, 'BCES00089', 2, 1, ''),
(33, 'BCES00130', 2, 1, 'gitara');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `statystyki_graczy`
--

CREATE TABLE `statystyki_graczy` (
  `id` int(11) NOT NULL,
  `id_gry` varchar(9) CHARACTER SET ucs2 COLLATE ucs2_polish_ci NOT NULL,
  `id_osoby` int(12) NOT NULL,
  `czas_gry` time(6) DEFAULT NULL,
  `liczba_zwyciestw` int(11) DEFAULT NULL,
  `liczba_porazek` int(11) DEFAULT NULL,
  `ostatnia_rozgrywka` datetime DEFAULT NULL,
  `id_platform` int(11) DEFAULT NULL,
  `playing` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `statystyki_graczy`
--

INSERT INTO `statystyki_graczy` (`id`, `id_gry`, `id_osoby`, `czas_gry`, `liczba_zwyciestw`, `liczba_porazek`, `ostatnia_rozgrywka`, `id_platform`, `playing`) VALUES
(81, 'BCES00129', 2, '00:00:30.000000', 0, 0, '2025-01-26 03:40:45', 3, 0),
(82, 'BCES00065', 2, '00:00:00.000000', 0, 0, '2025-01-26 00:00:00', 2, 0);

--
-- Wyzwalacze `statystyki_graczy`
--
DELIMITER $$
CREATE TRIGGER `dodaj_ostatnia_rozgrywke` BEFORE UPDATE ON `statystyki_graczy` FOR EACH ROW BEGIN
    -- Wyzwalacz aktualizuje kolumne data_modyfikacji przy kazdej zmianie rekordu
    SET NEW.ostatnia_rozgrywka = NOW();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `widok_gry`
-- (See below for the actual view)
--
CREATE TABLE `widok_gry` (
`cena` decimal(10,2)
,`gierka` text
,`release_date` date
,`developer_name` varchar(255)
,`publisher_name` varchar(255)
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `widok_posiadanie`
-- (See below for the actual view)
--
CREATE TABLE `widok_posiadanie` (
`id_osoby` int(12)
,`platform_name` varchar(255)
,`gierka` text
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `widok_reviews`
-- (See below for the actual view)
--
CREATE TABLE `widok_reviews` (
`imie` text
,`nazwisko` text
,`gierka` text
,`rating` int(1)
,`review_text` text
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `widok_statystyki_graczy`
-- (See below for the actual view)
--
CREATE TABLE `widok_statystyki_graczy` (
`gierka` text
,`id_gry` varchar(9)
,`id_osoby` int(12)
,`id_platform` int(11)
,`platform_name` varchar(255)
,`czas_gry` time(6)
,`liczba_zwyciestw` int(11)
,`liczba_porazek` int(11)
,`ostatnia_rozgrywka` datetime
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `widok_zdobytych_osiagniec`
-- (See below for the actual view)
--
CREATE TABLE `widok_zdobytych_osiagniec` (
`imie` text
,`nazwisko` text
,`achievement_description` text
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `zdobyte_osiagniecia`
--

CREATE TABLE `zdobyte_osiagniecia` (
  `id_osoby` int(11) NOT NULL,
  `id_achievment` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `zdobyte_osiagniecia`
--

INSERT INTO `zdobyte_osiagniecia` (`id_osoby`, `id_achievment`) VALUES
(2, 5),
(3, 7),
(3, 8),
(3, 12),
(4, 5),
(4, 6),
(4, 4),
(5, 8),
(5, 9),
(7, 4),
(8, 8),
(9, 13),
(9, 14),
(9, 15),
(10, 5),
(10, 6),
(11, 9),
(12, 10),
(12, 11),
(13, 4),
(13, 6),
(15, 7),
(15, 10),
(15, 11),
(15, 12),
(11, 5),
(7, 14),
(7, 15),
(2, 4);

--
-- Wyzwalacze `zdobyte_osiagniecia`
--
DELIMITER $$
CREATE TRIGGER `update_ostatnia_rozgrywka_after_insert_zdobyte_osiagniecia` AFTER INSERT ON `zdobyte_osiagniecia` FOR EACH ROW BEGIN
    UPDATE `statystyki_graczy`
    SET `ostatnia_rozgrywka` = NOW()
    WHERE `id_osoby` = NEW.id_osoby;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura widoku `widok_gry`
--
DROP TABLE IF EXISTS `widok_gry`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `widok_gry`  AS SELECT `g`.`cena` AS `cena`, `g`.`gierka` AS `gierka`, `g`.`release_date` AS `release_date`, `d`.`developer_name` AS `developer_name`, `p`.`publisher_name` AS `publisher_name` FROM ((`gry` `g` join `developers` `d` on(`g`.`id_developer` = `d`.`id`)) join `publishers` `p` on(`g`.`id_publisher` = `p`.`id`)) ;

-- --------------------------------------------------------

--
-- Struktura widoku `widok_posiadanie`
--
DROP TABLE IF EXISTS `widok_posiadanie`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `widok_posiadanie`  AS SELECT `p`.`id_osoby` AS `id_osoby`, `plat`.`platform_name` AS `platform_name`, `g`.`gierka` AS `gierka` FROM ((`posiadanie` `p` join `platforms` `plat` on(`p`.`id_platform` = `plat`.`id`)) join `gry` `g` on(`p`.`id_gry` = `g`.`id_gry`)) ;

-- --------------------------------------------------------

--
-- Struktura widoku `widok_reviews`
--
DROP TABLE IF EXISTS `widok_reviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `widok_reviews`  AS SELECT `d`.`imie` AS `imie`, `d`.`nazwisko` AS `nazwisko`, `g`.`gierka` AS `gierka`, `r`.`rating` AS `rating`, `r`.`review_text` AS `review_text` FROM ((`reviews` `r` join `dane` `d` on(`r`.`id_osoby` = `d`.`id`)) join `gry` `g` on(`r`.`id_gry` = `g`.`id_gry`)) ;

-- --------------------------------------------------------

--
-- Struktura widoku `widok_statystyki_graczy`
--
DROP TABLE IF EXISTS `widok_statystyki_graczy`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `widok_statystyki_graczy`  AS SELECT `g`.`gierka` AS `gierka`, `sg`.`id_gry` AS `id_gry`, `sg`.`id_osoby` AS `id_osoby`, `sg`.`id_platform` AS `id_platform`, `p`.`platform_name` AS `platform_name`, `sg`.`czas_gry` AS `czas_gry`, `sg`.`liczba_zwyciestw` AS `liczba_zwyciestw`, `sg`.`liczba_porazek` AS `liczba_porazek`, `sg`.`ostatnia_rozgrywka` AS `ostatnia_rozgrywka` FROM ((`statystyki_graczy` `sg` join `platforms` `p` on(`sg`.`id_platform` = `p`.`id`)) join `gry` `g` on(`sg`.`id_gry` = `g`.`id_gry`)) ;

-- --------------------------------------------------------

--
-- Struktura widoku `widok_zdobytych_osiagniec`
--
DROP TABLE IF EXISTS `widok_zdobytych_osiagniec`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `widok_zdobytych_osiagniec`  AS SELECT `o`.`imie` AS `imie`, `o`.`nazwisko` AS `nazwisko`, `a`.`description` AS `achievement_description` FROM ((`zdobyte_osiagniecia` `ao` join `dane` `o` on(`ao`.`id_osoby` = `o`.`id`)) join `achievements` `a` on(`ao`.`id_achievment` = `a`.`id`)) ;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `achievements`
--
ALTER TABLE `achievements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_acheivements_gry` (`id_gry`);

--
-- Indeksy dla tabeli `dane`
--
ALTER TABLE `dane`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`);

--
-- Indeksy dla tabeli `developers`
--
ALTER TABLE `developers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `developer_name` (`developer_name`);

--
-- Indeksy dla tabeli `game_modes`
--
ALTER TABLE `game_modes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `game_mode` (`game_mode`);

--
-- Indeksy dla tabeli `genres`
--
ALTER TABLE `genres`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `genre` (`genre`);

--
-- Indeksy dla tabeli `gry`
--
ALTER TABLE `gry`
  ADD PRIMARY KEY (`id_gry`),
  ADD KEY `fk_gry_developer` (`id_developer`),
  ADD KEY `fk_gry_publisher` (`id_publisher`);

--
-- Indeksy dla tabeli `gry_genres`
--
ALTER TABLE `gry_genres`
  ADD PRIMARY KEY (`id_genre`),
  ADD KEY `fk_gry_genres_gry` (`id_gry`),
  ADD KEY `fk_game_mode` (`id_game_mode`);

--
-- Indeksy dla tabeli `platforms`
--
ALTER TABLE `platforms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `platform_name` (`platform_name`);

--
-- Indeksy dla tabeli `posiadanie`
--
ALTER TABLE `posiadanie`
  ADD KEY `fk_posiadanie_gry` (`id_gry`),
  ADD KEY `fk_posiadanie_platform` (`id_platform`),
  ADD KEY `fk_dane_posiadanie` (`id_osoby`);

--
-- Indeksy dla tabeli `publishers`
--
ALTER TABLE `publishers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `publisher_name` (`publisher_name`);

--
-- Indeksy dla tabeli `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_reviews_gry` (`id_gry`),
  ADD KEY `fk_dane_reviews` (`id_osoby`);

--
-- Indeksy dla tabeli `statystyki_graczy`
--
ALTER TABLE `statystyki_graczy`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_statystyki_graczy_gry` (`id_gry`),
  ADD KEY `fk_dane_statystyki` (`id_osoby`);

--
-- Indeksy dla tabeli `zdobyte_osiagniecia`
--
ALTER TABLE `zdobyte_osiagniecia`
  ADD KEY `fk_id_osoby` (`id_osoby`),
  ADD KEY `fk_id_achievment` (`id_achievment`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `achievements`
--
ALTER TABLE `achievements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `dane`
--
ALTER TABLE `dane`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `developers`
--
ALTER TABLE `developers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `game_modes`
--
ALTER TABLE `game_modes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `genres`
--
ALTER TABLE `genres`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `platforms`
--
ALTER TABLE `platforms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `publishers`
--
ALTER TABLE `publishers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `statystyki_graczy`
--
ALTER TABLE `statystyki_graczy`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `achievements`
--
ALTER TABLE `achievements`
  ADD CONSTRAINT `fk_acheivements_gry` FOREIGN KEY (`id_gry`) REFERENCES `gry` (`id_gry`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `gry`
--
ALTER TABLE `gry`
  ADD CONSTRAINT `fk_gry_developer` FOREIGN KEY (`id_developer`) REFERENCES `developers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_gry_publisher` FOREIGN KEY (`id_publisher`) REFERENCES `publishers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `gry_genres`
--
ALTER TABLE `gry_genres`
  ADD CONSTRAINT `fk_game_mode` FOREIGN KEY (`id_game_mode`) REFERENCES `game_modes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_genre` FOREIGN KEY (`id_genre`) REFERENCES `genres` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_gry_genres_gry` FOREIGN KEY (`id_gry`) REFERENCES `gry` (`id_gry`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `posiadanie`
--
ALTER TABLE `posiadanie`
  ADD CONSTRAINT `fk_dane_posiadanie` FOREIGN KEY (`id_osoby`) REFERENCES `dane` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_posiadanie_gry` FOREIGN KEY (`id_gry`) REFERENCES `gry` (`id_gry`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_posiadanie_platform` FOREIGN KEY (`id_platform`) REFERENCES `platforms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `fk_dane_reviews` FOREIGN KEY (`id_osoby`) REFERENCES `dane` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_reviews_gry` FOREIGN KEY (`id_gry`) REFERENCES `gry` (`id_gry`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `statystyki_graczy`
--
ALTER TABLE `statystyki_graczy`
  ADD CONSTRAINT `fk_dane_statystyki` FOREIGN KEY (`id_osoby`) REFERENCES `dane` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_statystyki_graczy_gry` FOREIGN KEY (`id_gry`) REFERENCES `gry` (`id_gry`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `zdobyte_osiagniecia`
--
ALTER TABLE `zdobyte_osiagniecia`
  ADD CONSTRAINT `fk_id_achievment` FOREIGN KEY (`id_achievment`) REFERENCES `achievements` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_id_osoby` FOREIGN KEY (`id_osoby`) REFERENCES `dane` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
