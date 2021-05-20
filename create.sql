DROP DATABASE IF EXIST db;
CREATE DATABASE cb;
USE db

CREATE TABLE Boards
(
	title VARCHAR(128) NOT NULL,
	short VARCHAR(4) NOT NULL,
	subtitle VARCHAR(128)
);

CREATE TABLE Posts
(
	id INT PRIMARY KEY AUTO_INCREMENT,
	board VARCHAR(128) NOT NULL,
	op BOOLEAN NOT NULL,
	nickname VARCHAR(32);
	title VARCHAR(128),
	content VARCHAR(2048) NOT NULL;
	image LONGBLOB,
);