# Architektura Aplikacji

Aplikacja oparta jest na warstwowej architekturze, która jest zgodna z logiką wzorca Model-View-Controller (MVC).

*   Aplikacja jest podzielona na odpowiednie serwisy funkcjonalne, co umożliwia logiczne i przejrzyste rozdzielenie poszczególnych elementów systemu.

## 2. Back-end

*   Aplikacja została zbudowana w środowisku Node.js.
*   Wykorzystano framework Express do implementacji wzorca MVC.
*   Jako bazę danych zastosowano relacyjną bazę danych MySQL z odpowiednimi procedurami/funkcjami odpowiedzialnymi za:
    *   Zakup gier
    *   Dodawanie recenzji
    *   Dane logowania użytkowników
    *   Informacje ogólne o grach

## 3. Front-end

*   Zastosowano szablon EJS.

#Aplikacja umożliwia zakupy, recenzowanie gier, uruchamianie rozgrywek oraz śledzenie statystyk związanych z przebiegiem gry.
#Sql był odpalany w lokalnym serwerze apache (xampp 127.0.0.1).

