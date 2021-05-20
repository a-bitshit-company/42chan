DROP DATABASE IF EXISTS chan;
CREATE DATABASE chan;
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
	title VARCHAR(128),
	image LONGBLOB,
	nickname VARCHAR(32),
	id INT PRIMARY KEY AUTO_INCREMENT
);

INSERT INTO Boards VALUES("g", "technology", "be dumb, act smart");
INSERT INTO Posts VALUES("g", NULL, "this is le test post on 42chan/g/", "test", NULL, "anon", NULL);
INSERT INTO Posts VALUES("g", 1, "this is test rebly :DDD", NULL, NULL, NULL, NULL);
