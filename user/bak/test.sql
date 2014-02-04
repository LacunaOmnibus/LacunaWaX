PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE AppPrefsKeystore (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(64) NOT NULL,
  value varchar(64)
);
INSERT INTO "AppPrefsKeystore" VALUES(1,'MainWindowX','927');
INSERT INTO "AppPrefsKeystore" VALUES(2,'MainWindowY','39');
INSERT INTO "AppPrefsKeystore" VALUES(3,'MainWindowW','900');
INSERT INTO "AppPrefsKeystore" VALUES(4,'MainWindowH','800');
INSERT INTO "AppPrefsKeystore" VALUES(5,'AppVersion','1.20');
INSERT INTO "AppPrefsKeystore" VALUES(6,'DbVersion','0.1');
CREATE TABLE ArchMinPrefs (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  body_id integer NOT NULL,
  glyph_home_id integer,
  reserve_glyphs integer NOT NULL DEFAULT 0,
  pusher_ship_name varchar(32),
  auto_search_for varchar(32)
);
INSERT INTO "ArchMinPrefs" VALUES(1,1,360565,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(2,1,844994,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(3,1,184926,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(4,1,478857,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(5,1,483187,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(6,1,473071,157231,5,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(7,1,470140,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(8,1,470141,157231,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(9,1,604255,110203,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(10,1,108756,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(11,1,144484,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(12,1,110199,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(13,1,110201,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(14,1,217046,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(15,1,110203,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(16,1,82651,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(17,1,76901,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(18,1,84292,111653,0,'Smuggler Ship',NULL);
INSERT INTO "ArchMinPrefs" VALUES(19,1,157231,NULL,0,NULL,NULL);
CREATE TABLE BodyTypes (
  id INTEGER PRIMARY KEY NOT NULL,
  body_id integer NOT NULL,
  server_id integer,
  type_general varchar(16)
);
INSERT INTO "BodyTypes" VALUES(1,71423,1,'space station');
INSERT INTO "BodyTypes" VALUES(2,11971,1,'space station');
INSERT INTO "BodyTypes" VALUES(3,596628,1,'space station');
INSERT INTO "BodyTypes" VALUES(4,578020,1,'space station');
INSERT INTO "BodyTypes" VALUES(5,288617,1,'space station');
INSERT INTO "BodyTypes" VALUES(6,471875,1,'space station');
INSERT INTO "BodyTypes" VALUES(7,468709,1,'space station');
INSERT INTO "BodyTypes" VALUES(8,110204,1,'space station');
INSERT INTO "BodyTypes" VALUES(9,359715,1,'space station');
INSERT INTO "BodyTypes" VALUES(10,215640,1,'space station');
INSERT INTO "BodyTypes" VALUES(11,754487,1,'space station');
INSERT INTO "BodyTypes" VALUES(12,285952,1,'space station');
INSERT INTO "BodyTypes" VALUES(13,463023,1,'space station');
INSERT INTO "BodyTypes" VALUES(14,491837,1,'space station');
INSERT INTO "BodyTypes" VALUES(15,645488,1,'space station');
INSERT INTO "BodyTypes" VALUES(16,71377,1,'space station');
INSERT INTO "BodyTypes" VALUES(17,82971,1,'space station');
INSERT INTO "BodyTypes" VALUES(18,80082,1,'space station');
INSERT INTO "BodyTypes" VALUES(19,98819,1,'space station');
INSERT INTO "BodyTypes" VALUES(20,59842,1,'space station');
INSERT INTO "BodyTypes" VALUES(21,72782,1,'space station');
INSERT INTO "BodyTypes" VALUES(22,144584,1,'space station');
INSERT INTO "BodyTypes" VALUES(23,299393,1,'space station');
INSERT INTO "BodyTypes" VALUES(24,86085,1,'space station');
INSERT INTO "BodyTypes" VALUES(25,289142,1,'space station');
INSERT INTO "BodyTypes" VALUES(26,370033,1,'space station');
INSERT INTO "BodyTypes" VALUES(27,360612,1,'space station');
INSERT INTO "BodyTypes" VALUES(28,144971,1,'space station');
INSERT INTO "BodyTypes" VALUES(29,593205,1,'space station');
INSERT INTO "BodyTypes" VALUES(30,61303,1,'space station');
INSERT INTO "BodyTypes" VALUES(31,451704,1,'space station');
INSERT INTO "BodyTypes" VALUES(32,401175,1,'space station');
INSERT INTO "BodyTypes" VALUES(33,370819,1,'space station');
INSERT INTO "BodyTypes" VALUES(34,373714,1,'space station');
INSERT INTO "BodyTypes" VALUES(35,372199,1,'space station');
INSERT INTO "BodyTypes" VALUES(36,434194,1,'space station');
INSERT INTO "BodyTypes" VALUES(37,291773,1,'space station');
INSERT INTO "BodyTypes" VALUES(38,355132,1,'space station');
INSERT INTO "BodyTypes" VALUES(39,360983,1,'space station');
CREATE TABLE LotteryPrefs (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  body_id integer NOT NULL,
  count integer
);
CREATE TABLE SSAlerts (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  station_id integer NOT NULL,
  enabled integer NOT NULL DEFAULT 0,
  min_res bigint NOT NULL DEFAULT 0
);
CREATE TABLE ScheduleAutovote (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  proposed_by varchar(16) NOT NULL DEFAULT 'all'
);
CREATE TABLE Servers (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(32) NOT NULL,
  url varchar(64) NOT NULL,
  protocol varchar(8) DEFAULT 'http'
);
INSERT INTO "Servers" VALUES(1,'US1','us1.lacunaexpanse.com','https');
INSERT INTO "Servers" VALUES(2,'PT','pt.lacunaexpanse.com','http');
CREATE TABLE SitterPasswords (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer,
  player_id integer,
  player_name varchar(64),
  sitter varchar(64)
);
CREATE TABLE SpyTrainPrefs (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  spy_id integer NOT NULL,
  train varchar(32)
);
CREATE TABLE ServerAccounts (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  username varchar(64),
  password varchar(64),
  default_for_server integer,
  FOREIGN KEY (server_id) REFERENCES Servers(id)
);
INSERT INTO "ServerAccounts" VALUES(1,1,'tmtowtdi','plastic remote knife',1);
CREATE INDEX ArchMinPrefs_server_id ON ArchMinPrefs (server_id);
CREATE INDEX ArchMinPrefs_body_id ON ArchMinPrefs (body_id);
CREATE UNIQUE INDEX one_per_body ON ArchMinPrefs (server_id, body_id);
CREATE INDEX BodyTypes_body_id ON BodyTypes (body_id);
CREATE INDEX BodyTypes_type_general ON BodyTypes (type_general);
CREATE UNIQUE INDEX one_per_server ON BodyTypes (body_id, server_id);
CREATE UNIQUE INDEX LotteryPrefs_body ON LotteryPrefs (body_id, server_id);
CREATE INDEX SSAlerts_station_id ON SSAlerts (server_id, station_id);
CREATE UNIQUE INDEX one_alert_per_station ON SSAlerts (server_id, station_id);
CREATE UNIQUE INDEX unique_by_name ON Servers (name);
CREATE UNIQUE INDEX one_player_per_server ON SitterPasswords (server_id, player_id);
CREATE INDEX SpyTrainPrefs_spy_id ON SpyTrainPrefs (spy_id);
CREATE INDEX SpyTrainPrefs_train ON SpyTrainPrefs (train);
CREATE UNIQUE INDEX unique_server_spy ON SpyTrainPrefs (server_id, spy_id);
CREATE INDEX ServerAccounts_idx_server_id ON ServerAccounts (server_id);
COMMIT;
