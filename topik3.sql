/* Задача 3
1.Проанализировать структуру БД vk, которую мы создали на занятии, 
  и внести предложения по усовершенствованию (если такие идеи есть). 
  Напишите пожалуйста, всё-ли понятно по структуре. Понятно.
2.Добавить необходимую таблицу/таблицы для того, чтобы можно было 
  использовать лайки для медиафайлов, постов и пользователей.
  --мне не понятно формулировка, сама таблица лайков не достаточно, или 
  имеется в виду, какая другая операция? для меня необходимость той или иной
  таблицы возникает когда я четко представляю конкретную операцию. 
  тут я ничего к сожалению не представляю 
3.Используя сервис http://filldb.info или другой по вашему желанию, 
  сгенерировать тестовые данные для всех таблиц, учитывая логику связей. 
  Для всех таблиц, где это имеет смысл, создать не менее 100 строк. 
  Создать локально БД vk и загрузить в неё тестовые данные.
*/
DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;
--пользователи
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамилья', 
    email VARCHAR(120) UNIQUE,
    phone BIGINT, 
    INDEX users_phone_idx(phone), -- как выбирать индексы? --индекс необходимо создавать для тех столбцов, к значениям которого часто будет присутствовать в условии WHERE 
    INDEX users_firstname_lastname_idx(firstname, lastname)
);
--профиль пользователя
DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles (
	user_id SERIAL PRIMARY KEY,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(id) -- что за зверь в целом? внешний ключ с таблицей users. обеспечивает согласованность
    	ON UPDATE CASCADE -- как это работает? Какие варианты? ON UPDATE CASCADE говорит о том, что в случае если кто-то решит изменить ID пользователя, все его потомки-таблицы, в данном случае профиль, получат новый, измененный ID. есть вариант RESTRICT - не дать изменить в родительской таблице данные, если есть соответствующие данные в дочках. SET nuul and SET DEFAULT and NO ACTION 
    	ON DELETE restrict -- как это работает? Какие варианты?
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);
--сообщения
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке
    INDEX messages_from_user_id (from_user_id),
    INDEX messages_to_user_id (to_user_id),
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);
--запросы дружбы
DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL PRIMARY KEY, -- изменили на композитный ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    -- status TINYINT UNSIGNED,
    status ENUM('requested', 'approved', 'unfriended', 'declined'),
    -- status TINYINT UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	confirmed_at DATETIME,
	
    PRIMARY KEY (initiator_user_id, target_user_id),
	INDEX (initiator_user_id), -- потому что обычно будем искать друзей конкретного пользователя
    INDEX (target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)
);
--сообщества
DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL PRIMARY KEY,
	name VARCHAR(150),

	INDEX communities_name_idx(name)
);
--сообщества пользователя
DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);
--типы постов: пост или заметка
DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

    -- записей мало, поэтому индекс будет лишним (замедлит работу)!
);
--пост/заметка пользователя
DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL PRIMARY KEY,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);
--лайки
DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  

    , FOREIGN KEY (user_id) REFERENCES users(id)
    , FOREIGN KEY (media_id) REFERENCES media(id)

);
--фотоальбомы
DROP TABLE IF EXISTS photo_albums;
CREATE TABLE photo_albums (
	id SERIAL,
	name varchar(255) DEFAULT NULL,
    user_id BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
  	PRIMARY KEY (id)
);
--фото(альбом) пользователя
DROP TABLE IF EXISTS photos;
CREATE TABLE photos (
	id SERIAL PRIMARY KEY,
	album_id BIGINT unsigned NOT NULL,
	media_id BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);
-- наполнение нужными данными
INSERT INTO users VALUES (1,'Keanu','Lesch','juliana.feil@example.org','3544127038'),
(2,'Reagan','Ledner','jaime52@example.org','0'),
(3,'Danial','Rempel','dcassin@example.net','182'),
(4,'Valentin','Reynolds','gladys55@example.com','7366559029'),
(5,'Ressie','Fahey','izaiah01@example.net','0'),
(6,'Lane','Herzog','thora65@example.com','908847'),
(7,'Keegan','Medhurst','vicky77@example.com','580'),
(8,'Pansy','Aufderhar','pietro.hodkiewicz@example.net','0'),
(9,'Hallie','Hills','mariah.lueilwitz@example.net','7700181392'),
(10,'Carleton','Pagac','elvis23@example.com',1),
(11,'Joaquin','Sporer','tillman.dakota@example.org','738127'),
(12,'Ethelyn','Grimes','buckridge.jaqueline@example.com','331'),
(13,'Alva','Russel','kihn.gennaro@example.net','0'),
(14,'Blaise','O\'Hara','casper.mozelle@example.com','122936'),
(15,'Heath','Hagenes','agustin20@example.org','725362'),
(16,'Estell','Ortiz','deckow.lilliana@example.net','0'),
(17,'Luella','Roob','rice.xander@example.com','0'),
(18,'Serenity','Treutel','bins.tobin@example.net',1),
(19,'Patricia','Koepp','marks.jadon@example.com','0'),
(20,'Eugenia','Daugherty','joy.mills@example.com',78),
(21,'Tyree','Harris','oauer@example.com','754537'),
(22,'Erling','Schiller','tiffany67@example.net','0'),
(23,'Amelie','Willms','damion47@example.com','441573'),
(24,'Tony','Torp','feeney.nolan@example.net','196633'),
(25,'Eric','Prohaska','leannon.torrance@example.com','874'),
(26,'Angeline','Wiza','o\'hara.novella@example.org','365478'),
(27,'Addison','Von','vbartoletti@example.com','742768'),
(28,'Delmer','Sawayn','mclaughlin.ignatius@example.com',1),
(29,'Stacy','Steuber','dibbert.katlyn@example.com',49),
(30,'Brianne','Turcotte','camylle.littel@example.net','7676247683'),
(31,'Marion','Durgan','eglover@example.net','0'),
(32,'Jude','Muller','beryl86@example.com','972395'),
(33,'Gerson','Hettinger','minnie.bernier@example.org','0'),
(34,'Dallin','Muller','samanta59@example.com','359462'),
(35,'Lavada','Kilback','judy.o\'conner@example.org','0'),
(36,'Benjamin','Cummerata','reichel.evan@example.net','0'),
(37,'Lee','Johnson','thalia51@example.net','288030'),
(38,'Shany','Purdy','hane.mckenna@example.com',1),
(39,'Jazlyn','Barton','nolan.mckayla@example.org','205'),
(40,'Allison','Shields','jacklyn.rogahn@example.net','255'),
(41,'Mathew','Nikolaus','schuster.omer@example.com','761'),
(42,'Destinee','Turcotte','kohler.alexzander@example.net',1),
(43,'Gayle','Sawayn','balistreri.magnolia@example.net','354214'),
(44,'Evalyn','Lakin','eichmann.raven@example.net','386'),
(45,'Kolby','Pacocha','schaefer.constance@example.com','1269094199'),
(46,'Kayla','Beier','joanie.walker@example.net','3039700114'),
(47,'Kaelyn','Harber','tosinski@example.org',8),
(48,'Victoria','Cronin','cummerata.jolie@example.org','0'),
(49,'Diana','Johnston','christa52@example.org','468404'),
(50,'Fredy','Ernser','graham.fanny@example.net','0'),
(51,'Reymundo','Shields','jrempel@example.org','423'),
(52,'Estrella','Ziemann','tressa13@example.com','588'),
(53,'Emelia','Boehm','ross.schmitt@example.com',17),
(54,'Everette','Harvey','minnie26@example.com','828691'),
(55,'Rene','Kuhic','wcruickshank@example.net',25),
(56,'Edna','Schneider','hhansen@example.com','857768'),
(57,'Nannie','Purdy','legros.willa@example.net','719'),
(58,'Amina','Runte','keebler.merl@example.com','855610'),
(59,'Shanny','Carroll','darian77@example.net','0'),
(60,'Albertha','Breitenberg','mable.balistreri@example.net',42),
(61,'Robb','Kihn','parker.hodkiewicz@example.org','260'),
(62,'Landen','Emmerich','koss.katlyn@example.org','0'),
(63,'Carson','Lakin','marlene31@example.com','240'),
(64,'Rosalyn','Strosin','laurianne.rowe@example.net','283'),
(65,'Dawn','Mayert','alejandra28@example.org',1),
(66,'Amber','Mayert','hayden17@example.net','1992792170'),
(67,'Dannie','Will','hollis.batz@example.org',80),
(68,'Amira','Bernier','isabel.becker@example.com','295929'),
(69,'Eino','Yost','willms.domenica@example.org','0'),
(70,'Keenan','Johns','cgusikowski@example.com','596341'),
(71,'Faye','Dibbert','coby.homenick@example.org','0'),
(72,'Linda','Muller','alisha.lebsack@example.com','62162626'),
(73,'Wyman','Wuckert','prosacco.edward@example.net','7926504175'),
(74,'Eleanora','Jacobi','anne55@example.com','0'),
(75,'Jessy','Sanford','dmaggio@example.org',81),
(76,'Tremaine','Klocko','xavier05@example.net','913876'),
(77,'Devon','Homenick','mariela.breitenberg@example.org','813347'),
(78,'Jesse','Brakus','tconroy@example.com','0'),
(79,'Fatima','Schaden','rachelle.hartmann@example.com','2641839573'),
(80,'Jovanny','Oberbrunner','krajcik.sherman@example.org',63),
(81,'Dedrick','McDermott','roberts.luther@example.com','44789'),
(82,'Mable','Goodwin','serena.wunsch@example.net',1),
(83,'Lamont','Deckow','anastasia83@example.org','889148'),
(84,'Gianni','Hodkiewicz','gerlach.kadin@example.com','807'),
(85,'Una','Reilly','mills.lazaro@example.org','6405363317'),
(86,'Garrison','Schaden','zkeeling@example.org','774773'),
(87,'Jamar','Torphy','ucrona@example.net','0'),
(88,'Adolfo','Reinger','wuckert.samir@example.org','0'),
(89,'Fanny','Kreiger','martina48@example.net',1),
(90,'Blanche','Jones','bonita49@example.org',1),
(91,'Jerod','Ankunding','wilderman.jalon@example.org',1),
(92,'Mable','Smitham','rberge@example.org',1),
(93,'Brennon','Quigley','hudson84@example.org',1),
(94,'Alessia','Murray','aaliyah.hilpert@example.org','0'),
(95,'Carmen','Mante','wintheiser.alan@example.net',75),
(96,'Dee','Brakus','batz.marilie@example.org',1),
(97,'Shayne','Medhurst','jerod92@example.com',1),
(98,'Cristobal','McLaughlin','rkshlerin@example.org','0'),
(99,'Claude','Johnson','madyson17@example.org','537284'),
(100,'Glennie','Ebert','rubye28@example.com','8865831836');

INSERT INTO profiles VALUES (1,'M','1992-01-03',NULL,'1978-11-22 14:53:59','Eloisaside'),
(2,'M','2001-03-18',NULL,'1985-02-28 22:39:46','Stephanystad'),
(3,'M','1996-10-04',NULL,'1992-09-01 00:23:33','West Edward'),
(4,'M','1986-07-23',NULL,'1983-04-08 07:38:14','Myahport'),
(5,'F','1987-04-02',NULL,'1978-02-21 00:03:43','New Berniceberg'),
(6,'M','2000-03-24',NULL,'2014-07-11 19:49:04','Moentown'),
(7,'M','1971-04-21',NULL,'2001-11-28 23:12:39','Lake Justonstad'),
(8,'F','1987-08-02',NULL,'1995-10-05 18:32:20','Mrazland'),
(9,'F','1983-12-16',NULL,'2007-12-16 01:56:57','Nigelbury'),
(10,'M','1974-05-09',NULL,'1993-02-20 06:19:47','North Dejaberg'),
(11,'M','2009-12-09',NULL,'2001-08-13 11:26:16','North Elmershire'),
(12,'F','2019-06-16',NULL,'2010-10-27 13:13:01','Towneside'),
(13,'M','2018-03-19',NULL,'1988-08-27 17:58:54','Easterville'),
(14,'M','2012-07-10',NULL,'1989-01-29 17:42:48','Zoeport'),
(15,'F','2004-10-19',NULL,'1972-03-14 23:05:22','Calistafurt'),
(16,'F','1985-10-23',NULL,'1995-07-18 09:18:13','Tevinburgh'),
(17,'M','1983-12-09',NULL,'2018-09-19 23:32:23','Corenefurt'),
(18,'M','2006-08-16',NULL,'2001-09-10 16:32:56','Reillyburgh'),
(19,'F','1997-02-11',NULL,'1978-05-07 12:33:50','West Elmo'),
(20,'M','1990-10-15',NULL,'2001-03-05 14:34:53','Martamouth'),
(21,'F','1978-12-07',NULL,'2006-08-29 13:17:07','West Jontown'),
(22,'F','2005-07-15',NULL,'1996-01-20 07:39:30','Daremouth'),
(23,'F','1986-10-14',NULL,'1970-07-21 18:14:02','North Mina'),
(24,'F','2007-03-29',NULL,'2000-12-26 11:46:20','North Raphael'),
(25,'F','1976-07-11',NULL,'1970-07-08 20:08:33','Winnifredfurt'),
(26,'M','2018-02-08',NULL,'2011-09-10 02:43:18','Sauershire'),
(27,'F','2000-01-19',NULL,'2010-05-26 18:59:34','Camrenhaven'),
(28,'F','1978-01-08',NULL,'1975-08-14 20:47:48','North Margaretthaven'),
(29,'M','1998-11-07',NULL,'1972-07-08 16:52:24','South Joshuah'),
(30,'M','2003-02-09',NULL,'1985-01-08 15:33:34','O\'Reillyland'),
(31,'F','1976-05-25',NULL,'2013-05-20 10:43:43','East Daphnee'),
(32,'F','2010-07-01',NULL,'1993-01-30 06:38:57','Skilesview'),
(33,'F','1999-03-12',NULL,'2006-06-03 05:26:18','Morarhaven'),
(34,'F','2010-02-04',NULL,'1999-09-15 16:26:24','Port Abagailmouth'),
(35,'F','1996-02-14',NULL,'2006-03-24 03:46:13','Port Jenifer'),
(36,'M','2006-10-20',NULL,'1981-05-03 12:28:57','Lake Alanisburgh'),
(37,'M','2016-06-11',NULL,'2016-10-19 15:26:25','Destinyfurt'),
(38,'F','1984-02-28',NULL,'1975-09-19 00:01:09','North Augustustown'),
(39,'F','1985-11-15',NULL,'1998-06-27 08:44:39','Lake Orpha'),
(40,'F','1974-03-24',NULL,'1999-12-09 19:06:44','Port Zitaton'),
(41,'M','1984-11-25',NULL,'1987-11-29 00:31:40','East Nobleburgh'),
(42,'M','1976-04-17',NULL,'2003-04-12 06:50:42','West Geoffreymouth'),
(43,'F','1980-02-24',NULL,'2014-06-05 18:15:58','North Ryderside'),
(44,'F','1987-07-13',NULL,'1973-11-24 10:07:29','South Reynaport'),
(45,'M','1979-06-22',NULL,'2018-05-19 01:02:31','Lebsackborough'),
(46,'F','1982-07-21',NULL,'1978-03-05 02:53:24','Port Normabury'),
(47,'F','2003-05-02',NULL,'2000-02-25 13:05:04','Adriennehaven'),
(48,'M','2010-07-23',NULL,'2014-11-16 05:14:10','East Dedrick'),
(49,'F','2012-04-09',NULL,'1975-11-09 11:07:34','Darestad'),
(50,'M','2012-06-01',NULL,'1971-07-08 16:27:21','Edashire'),
(51,'F','1977-12-06',NULL,'2017-11-23 22:01:36','Tamialand'),
(52,'F','2015-02-15',NULL,'1994-11-29 11:45:29','Lake Grantchester'),
(53,'F','2006-05-27',NULL,'1976-07-17 09:57:01','South Cloyd'),
(54,'F','2010-09-17',NULL,'1980-06-07 10:57:27','Jackiehaven'),
(55,'F','2000-01-14',NULL,'1979-10-28 12:16:51','West Marquis'),
(56,'F','2008-04-09',NULL,'1980-07-16 12:25:49','Ricehaven'),
(57,'F','2001-12-28',NULL,'1981-10-29 15:38:43','Merlmouth'),
(58,'F','2012-06-02',NULL,'2000-10-04 10:16:48','Porterville'),
(59,'M','2014-12-17',NULL,'2009-11-24 05:52:56','Lake Stantonside'),
(60,'F','1989-02-10',NULL,'2010-08-08 20:01:32','Bartellton'),
(61,'F','2003-03-08',NULL,'2011-02-18 10:01:47','Port Lexusfort'),
(62,'M','1976-01-18',NULL,'2017-04-28 20:46:56','Port Loriton'),
(63,'F','1979-02-27',NULL,'1995-04-11 09:06:53','Lake Laisha'),
(64,'F','1990-09-08',NULL,'2018-11-12 15:40:52','North Breana'),
(65,'M','2015-04-13',NULL,'2015-04-22 23:58:46','Dantown'),
(66,'F','1982-11-13',NULL,'1983-01-24 16:03:26','South Noemi'),
(67,'F','1986-05-21',NULL,'1983-05-09 00:31:33','New Lilly'),
(68,'F','1992-03-17',NULL,'1995-03-06 11:43:38','Beattyport'),
(69,'M','2008-05-24',NULL,'1984-09-12 21:22:54','North Reaganmouth'),
(70,'F','1995-05-09',NULL,'1971-08-02 12:32:45','Zacheryfurt'),
(71,'M','2001-02-05',NULL,'2009-05-29 18:04:36','Bartolettiport'),
(72,'F','1975-03-27',NULL,'1978-09-30 13:11:03','Elinorville'),
(73,'M','1985-10-08',NULL,'1990-07-23 12:18:39','New Javier'),
(74,'M','2012-10-30',NULL,'1999-02-24 14:22:39','Romagueraburgh'),
(75,'F','2009-09-26',NULL,'1977-04-16 06:18:31','Kaylaton'),
(76,'M','1995-07-26',NULL,'2008-10-11 02:09:00','Langoshberg'),
(77,'M','1996-05-04',NULL,'1986-09-30 07:06:05','Port Monserrate'),
(78,'M','1974-10-26',NULL,'1998-12-19 06:01:35','Stromanmouth'),
(79,'M','2008-09-05',NULL,'2011-07-17 09:24:39','Port Mackborough'),
(80,'F','1987-08-18',NULL,'1972-10-28 15:26:00','North Sadyechester'),
(81,'M','2004-04-23',NULL,'1998-03-15 17:55:33','Augustineview'),
(82,'M','1997-05-12',NULL,'2017-09-28 08:45:51','Heavenberg'),
(83,'M','1977-04-04',NULL,'1974-02-04 21:39:43','East Erick'),
(84,'M','1999-07-13',NULL,'2007-12-17 21:24:50','Cliffordfort'),
(85,'F','1989-03-23',NULL,'1989-03-09 05:47:00','South Cornelius'),
(86,'M','2002-03-18',NULL,'1980-10-11 19:47:30','East Blake'),
(87,'F','2009-08-08',NULL,'2015-09-28 00:14:58','Schuppehaven'),
(88,'M','1978-08-02',NULL,'1971-06-15 17:09:04','West King'),
(89,'F','1994-03-07',NULL,'2005-07-11 17:12:37','Antoniaside'),
(90,'F','1980-01-27',NULL,'1986-11-02 02:22:43','Port Abelville'),
(91,'M','1970-11-02',NULL,'1975-03-15 15:11:09','West Maverickborough'),
(92,'M','1990-11-05',NULL,'1981-08-16 04:02:26','New Micahshire'),
(93,'F','2005-05-12',NULL,'2012-11-30 22:37:44','Kirstinport'),
(94,'F','1975-02-15',NULL,'2010-11-02 02:05:53','Gleichnerport'),
(95,'F','2003-04-12',NULL,'1978-10-17 00:29:49','Noahbury'),
(96,'F','2014-04-05',NULL,'1981-01-26 05:11:12','Domenickshire'),
(97,'F','1975-06-23',NULL,'1970-09-16 16:55:53','Hudsonmouth'),
(98,'F','1999-11-07',NULL,'2004-03-03 05:22:54','Marshallport'),
(99,'M','1984-11-08',NULL,'1996-07-20 19:40:05','Alisonmouth'),
(100,'M','2012-08-16',NULL,'1979-08-09 19:30:21','Keyonchester'); 