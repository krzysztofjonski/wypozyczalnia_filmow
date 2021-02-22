
USE [wypozyczalnia_filmow]
/*****TWORZENIE TABEL*****/
/*TABELA KLIENT*/
create table Klient
(
KlientID int identity (1, 1) primary key,
Punkty nvarchar(10) 
)

/*TABELA FILM*/
create table Film
(
FilmID int identity (1, 1) primary key,
TypID int NOT NULL,
Cena money NOT NULL,
KlientID int 
)

/*TABELA HW*/
create table HW
(
WypID int identity (1, 1) primary key,
KlientID int NOT NULL,
FilmID int NOT NULL,
IloscDniWyp int,
KwotaZaplaty money
)

/*TABELA TYPFILMU*/
create table TypFilmu
(
TypID int identity (1, 1) primary key,
TypFi nvarchar(10)
)

/*****WPROWADZANIE DANYCH DO TABEL*****/
/*TABELA KLIENT*/
insert into Klient (Punkty)
values ('0'),
	   ('0'),
	   ('0'),
	   ('0')

/*TABELA FILM*/
insert into Film (TypID, Cena)
values ('2', '30.00'), 
	   ('3', '30.00'),
	   ('1', '40.00'),
	   ('2', '30.00'),
	   ('1', '40.00'),
	   ('3', '30.00')

/*TABELA TYPFILMU*/
insert into TypFilmu (TypFi)
values ('nowy'),
	   ('zwyk³y'),
	   ('stary')

/*****TWORZENIE RELACJI ORAZ NADAWANIE UNIQUE*****/
/*ALTER HW*/
alter table HW
	add constraint FK_KlientID
		foreign key (KlientID) REFERENCES Klient(KlientID)

alter table HW
	add constraint FK_FilmID
		foreign key (FilmID) REFERENCES Film(FilmID)

/*ALTER FILM*/
alter table Film
	add constraint FK_TypID
		foreign key (TypID) REFERENCES TypFilmu(TypID)

alter table Film
	add constraint FK_Klient_ID
		foreign key (KlientID) REFERENCES Klient(KlientID)


/*****TWORZENIE FUNCJI*****/
/*Funkcja CenaZwr wylicza nam cene za film, 
-nowy - 40 zl * ilosc dni,
-zwykly - 30 zl za 3dni + 30zl za kazdy kolejny,
-stary - 30 zl za 5dni + 30zl za kazdy kolejny*/


create function CenaZwr (@FilmID int, @IloscDniWyp int)
returns money
begin
	declare @TypID INT;
	set @TypID = (select f.TypID from Film f left join Klient k
	on f.KlientID = k.KlientID where f.FilmID = @FilmID)
	
	declare @wynik money;
	if @TypID = 1
		set @wynik = @IloscDniWyp * 40.00

	if @TypID = 2 and @IloscDniWyp <= 3
		set @wynik = 30.00
	if @TypID = 2 and @IloscDniWyp > 3
		set @wynik = 30.00 + (@IloscDniWyp - 3) * 30.00

	if @TypID = 3 and @IloscDniWyp <= 5
		set @wynik = 30.00
	if @TypID = 3 and @IloscDniWyp > 5
		set @wynik = 30.00 + (@IloscDniWyp - 5) * 30.00
	return @wynik 

end

declare @koszt money
set @koszt = dbo.CenaZwr(2,10) 
print convert(nvarchar(7), @koszt) + ' zl'




/*****TWORZENIE PROCEDUR*****/
/*Procedura wypozyczFilm, wypozycza i dodaje punkty w zaleznosci od typu filmu, film nowy dodaje 2 pkt Klientowi, a pozostale po 1 pkt
dodatkowo podaje kwote kaucji oraz uzupelnia tabele HW */

create procedure wypozyczFilm(@KlientID int, @FilmID int)
as
begin
	if not exists (select 1 from Klient k where k.KlientID = @KlientID)
	begin
		print 'Klient nie isnieje, KlientID - ' + convert(nvarchar(5), @KlientID)
		return;
	end

	if not exists (select 1 from Film f where f.FilmID = @FilmID)
	begin
		print 'Film nie isnieje, FilmID - ' + convert(nvarchar(5), @FilmID)
		return;
	end

	declare @wypKlientID int;
	set @wypKlientID = (select top 1 f.KlientID FROM Film f where f.FilmID = @FilmID)

	if (@wypKlientID is not null)
	begin
		print 'Film o ID ' + convert(nvarchar(5), @FilmID) + ' zosta³ ju¿ wypo¿yczony !'
		return;
	end
	
	update Film set KlientID = @KlientID WHERE FilmID = @FilmID
	begin
	declare @TypID INT;
	set @TypID = (select f.TypID from Film f left join Klient k
	on f.KlientID = k.KlientID where f.FilmID = @FilmID)
	if @TypID = 1
		UPDATE Klient set punkty = Punkty + 2 where KlientID = @KlientID
	if @TypID = 2 
	 	UPDATE Klient set punkty = Punkty + 1 where KlientID = @KlientID 
	if @TypID = 3
	 	UPDATE Klient set punkty = Punkty + 1 where KlientID = @KlientID
	end
	print 'OK, film zosta³ przez Ciebie wypo¿yczony :)'
	 
    insert into HW(KlientID, FilmID) values (@KlientID, @FilmID) 	
	print 'Klient o ID ' + convert(nvarchar(5), @KlientID) + ' ma do zap³aty kaucje 30.00 zl' 

end

/*Procedura zwrocFilm zwraca film, robi update HW oraz wypisuje ile zostalo do zaplaty*/
create procedure zwrocFilm(@KlientID int, @FilmID int, @IloscDniWyp int)
as
begin
	if not exists (select 1 from Klient k where k.KlientID = @KlientID)
	begin
		print 'Klient nie isnieje, KlientID - ' + convert(nvarchar(5), @KlientID)
		return;
	end

	if not exists (select 1 from Film f where f.FilmID = @FilmID)
	begin
		print 'Film nie isnieje, FilmID - ' + convert(nvarchar(5), @FilmID)
		return;
	end

	if exists (select f.FilmID FROM Film f where f.FilmID = @FilmID and KlientID is null)
	begin
		print 'Film o ID - ' + convert(nvarchar(5), @FilmID) + ' nie mo¿e zostaæ zwrócony, gdy¿ nie zosta³ wypo¿yczony !'
		return;
	end 
	
	update Film set KlientID = NULL WHERE FilmID = @FilmID

	print 'Ok, Film o ID ' + convert(nvarchar(5), @FilmID) + ' zosta³ zwrócony :)'
	update HW set IloscDniWyp = @IloscDniWyp where (KlientID = @KlientID and FilmID = @FilmID and IloscDniWyp is NULL)
	update HW set KwotaZaplaty = dbo.CenaZwr (FilmID, IloscDniWyp)
	declare @koszt money
	set @koszt = dbo.CenaZwr (@FilmID, @IloscDniWyp)
	declare @nowacena money
	declare @kaucja money
	set @kaucja = 30.00
	set @nowacena = @koszt - @kaucja
	print 'Klient o ID ' + convert(nvarchar(5), @KlientID) + ' ma do zap³aty ' + convert(nvarchar(7), @koszt) + ' z³ minus 30.00 z³ kaucji' 
	print 'Razem do zap³aty ' + convert(nvarchar(7), @nowacena)
end

EXEC wypozyczFilm 1 , 1
exec zwrocFilm 1 , 1, 6

select * from Klient

