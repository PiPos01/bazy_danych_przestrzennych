--Utw�rz now� baz� danych nazywaj�c j� firma
create database firma;

--Dodaj schemat o nazwie ksiegowosc.
--create schema ksiegowosc;

-- tworzenie tabeli pracownicy
create table pracownicy (
id_pracownika int PRIMARY KEY not null,
imie nvarchar(50) not null,
nazwisko nvarchar(50) not null,
adres nvarchar(50) not null,
telefon varchar(9) not null
);

-- tworzenie tabeli godziny
create table godziny (
id_godziny varchar(5) PRIMARY KEY not null,
data date not null, 
liczba_godzin int not null,
id_pracownika int not null
);

-- tworzenie tabeli pensja
create table pensja (
id_pensji varchar(5) PRIMARY KEY not null,
stanowisko nvarchar(30) not null,
kwota decimal(15,2) not null --kwota moze byc z groszami
);

-- tworzenie tabeli premia
create table premia (
id_premii varchar(5) PRIMARY KEY not null,
rodzaj nvarchar(20) not null,
kwota decimal(15,2) not null
);

-- tworzenie tabeli wynagrodzenie
create table wynagrodzenie (
id_wynagrodzenia varchar(5) PRIMARY KEY not null,
data date not null, --tu data jako data wplyniecia wynagrodzenia
id_pracownika int not null,
id_godziny varchar(5) not null,
id_pensji varchar(5) not null,
id_premii varchar(5) not null,
FOREIGN KEY (id_pracownika) REFERENCES pracownicy(id_pracownika),
FOREIGN KEY (id_godziny) REFERENCES godziny(id_godziny),
FOREIGN KEY (id_pensji) REFERENCES pensja(id_pensji),
FOREIGN KEY (id_premii) REFERENCES premia(id_premii)
);



-- wype�nianie tabeli pracownicy
insert into pracownicy values
(1, 'Jan', 'Kowalski', 'Zakopane, ul. G�rska 12', '601234567'),
(2, 'Anna', 'Nowak', 'Krak�w, ul. Le�na 5', '602345678'),
(3, 'Piotr', 'Maj', 'Zakopane, ul. Krup�wki 8', '603456789'),
(4, 'Maria', 'Zieli�ska', 'Nowy Targ, ul. Lipowa 10', '604567890'),
(5, 'Adam', 'Konieczny', 'Zakopane, ul. Tatrza�ska 3', '605678901'),
(6, 'Joanna', 'Wi�niewska', 'Bukowina, ul. Wierchowa 2', '606789012'),
(7, 'Pawe�', 'Krawczyk', 'Krak�w, ul. Dolna 11', '607890123'),
(8, 'Alicja', 'Nowicka', 'Zakopane, ul. Jasna 6', '608901234'),
(9, 'Micha�', 'Dudek', 'Poronin, ul. Sosnowa 1', '609012345'),
(10, 'Katarzyna', 'Lis', 'Zakopane, ul. Wysoka 4', '610123456');

-- przyjalem tu miesieczny wymiar godzin
insert into godziny values
('g1', '2025-08-31', 168, 1),
('g2', '2025-09-30', 160, 2),
('g3', '2025-08-31', 170, 3),
('g4', '2025-04-30', 165, 4),
('g5', '2025-04-30', 160, 5),
('g6', '2025-09-30', 150, 6),
('g7', '2025-08-31', 167, 7),
('g8', '2025-07-31', 161, 8),
('g9', '2025-05-31', 152, 9),
('g10', '2025-01-31', 163, 10);

insert into pensja values
('pe1', 'Ksi�gowy', 5200.00),
('pe2', 'Sprzedawca', 4500.00),
('pe3', 'Programista', 8200.00),
('pe4', 'Kierownik', 7000.00),
('pe5', 'Sekretarka', 4300.00),
('pe6', 'Analityk', 7800.00),
('pe7', 'Programista', 8000.00),
('pe8', 'Analityk', 8600.00),
('pe9', 'Asystent', 3900.00),
('pe10', 'Analityk', 7500.00);


insert into premia values
('pr1', 'Brak', 0.00),
('pr2', 'Miesi�czna', 500.00),
('pr3', 'Projektowa', 800.00),
('pr4', 'Roczna', 2000.00),
('pr5', 'Brak', 0.00),
('pr6', 'Motywacyjna', 600.00),
('pr7', 'Projektowa', 1500.00),
('pr8', 'Brak', 0.00),
('pr9', 'Stanowiskowa', 700.00),
('pr10', 'Projektowa', 300.00);

insert into wynagrodzenie values
('w1', '2025-10-01', 1, 'g1', 'pe1', 'pr2'),
('w2', '2025-10-01', 2, 'g2', 'pe2', 'pr3'),
('w3', '2025-10-01', 3, 'g3', 'pe3', 'pr1'),
('w4', '2025-10-01', 4, 'g4', 'pe4', 'pr4'),
('w5', '2025-10-02', 5, 'g5', 'pe5', 'pr5'),
('w6', '2025-10-03', 6, 'g6', 'pe6', 'pr1'),
('w7', '2025-10-03', 7, 'g7', 'pe7', 'pr6'),
('w8', '2025-10-03', 8, 'g8', 'pe8', 'pr7'),
('w9', '2025-10-04', 9, 'g9', 'pe9', 'pr8'),
('w10', '2025-10-04', 10, 'g10', 'pe10', 'pr9');

-- zadanie 5a
select id_pracownika, nazwisko
from pracownicy;

-- zadanie 5b
select w.id_pracownika
from wynagrodzenie w
join pensja pe
on pe.id_pensji = w.id_pensji
where pe.kwota > 4500

-- zadanie 5c
select w.id_pracownika
from wynagrodzenie w
join premia pr
on pr.id_premii=w.id_premii
join pensja pe
on pe.id_pensji=w.id_pensji
where (pr.kwota=0.00 and pe.kwota > 5200)


-- zadanie 5d
select *
from pracownicy
where imie like 'A%'

-- zadanie 5e
select *
from pracownicy
where nazwisko like '%n%' and imie like '%a'

-- zadanie 5f
select p.imie, p.nazwisko,
	case
		 when g.liczba_godzin - 160 < 0 then 0
		 else g.liczba_godzin - 160
	end liczba_nadgodzin,
	case
		when g.liczba_godzin > 160 then 'nadgodziny'
		when g.liczba_godzin = 160 then 'pe�ny etat'
		else 'niepe�ny etat'
	end status_etatu
from pracownicy p
join godziny g
on g.id_pracownika=p.id_pracownika

-- zadanie 5g
select p.imie, p.nazwisko
from pracownicy p
join wynagrodzenie w
on p.id_pracownika=w.id_pracownika
join pensja pe
on pe.id_pensji=w.id_pensji
where pe.kwota between 4000 and 7500

-- zadanie 5h
select p.imie, p.nazwisko
from pracownicy p
join godziny g
on g.id_pracownika=p.id_pracownika
join wynagrodzenie w
on p.id_pracownika=w.id_pracownika
join premia pr
on pr.id_premii=w.id_premii
where (g.liczba_godzin > 160) and (pr.kwota = 0.00)

-- zadanie 5i
select p.imie, p.nazwisko
from pracownicy p
inner join wynagrodzenie w
on p.id_pracownika=w.id_pracownika
join pensja pe
on pe.id_pensji=w.id_pensji
order by pe.kwota

-- zadanie 5j
select p.imie, p.nazwisko
from pracownicy p
join wynagrodzenie w
on p.id_pracownika=w.id_pracownika
join pensja pe
on pe.id_pensji=w.id_pensji
join premia pr
on pr.id_premii=w.id_premii
order by pe.kwota DESC, pr.kwota DESC

--zadanie 5k
select stanowisko, count(*) as liczba_pracownikow
from pensja
group by stanowisko

-- zadanie 5l
select avg(kwota) as srednia, min(kwota) as minimalna, max(kwota) as maksymalna
from pensja
where stanowisko= 'Analityk'

-- zadanie 5m
select sum(kwota) as suma_wynagrodzen
from pensja

-- zadanie 5o
select stanowisko, sum(kwota) as kwota_stanowisko
from pensja
group by (stanowisko)

--zadanie 5p
select stanowisko, count(pr.id_premii) as liczba_premii
from pensja pe
join wynagrodzenie w
on pe.id_pensji=w.id_pensji
join premia pr
on pr.id_premii=w.id_premii
where (pr.kwota > 0.00)
group by (pe.stanowisko)

-- zadanie 5r
-- najpierw trzeba usunac rekordy powiazane w tabeli wynagrodzenia, a potem pracownikow

delete wynagrodzenie
from wynagrodzenie w
inner join pensja pe
on w.id_pensji=pe.id_pensji
where pe.kwota < 5000

--insert into wynagrodzenie values
--('w11', '2025-10-04', 9, 'g9', 'pe9', 'pr8'),
--('w13', '2025-10-04', 10, 'g10', 'pe10', 'pr9');
--select * from wynagrodzenie

delete p
from pracownicy p
where not exists 
(select 1 
from wynagrodzenie w
where w.id_pracownika=p.id_pracownika)

select * from pracownicy

