DROP DATABASE IF EXISTS chan;
CREATE DATABASE chan DEFAULT CHARSET = utf8mb4 DEFAULT COLLATE = utf8mb4_unicode_ci;;
USE chan;

CREATE TABLE Boards
(
	short VARCHAR(4) PRIMARY KEY,
	title VARCHAR(128) NOT NULL,
	subtitle VARCHAR(128)
);

CREATE TABLE Posts
(
	board VARCHAR(128) NOT NULL,
	OPid INT,
	FOREIGN KEY (board) REFERENCES Boards(short),
	FOREIGN KEY (OPid) REFERENCES Posts(id),
	content VARCHAR(2048) NOT NULL,
	nickname VARCHAR(32),
	id INT PRIMARY KEY AUTO_INCREMENT
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO Boards VALUES("g", "technology", "be dumb, act smart");
INSERT INTO Boards VALUES("t", "test", "this is a test board");
INSERT INTO Posts VALUES("t", NULL, "this is a test post", "anon", NULL);
