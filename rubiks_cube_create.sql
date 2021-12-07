DROP DATABASE IF EXISTS cubes3;
CREATE DATABASE cubes3;
USE cubes3;

-- The cube type entity
CREATE TABLE cube_types
(
	`cube_id`	INT		PRIMARY KEY 	auto_increment,
    `name`		VARCHAR(100)
);

-- The user entity
CREATE TABLE users
(
	`user_id`	INT 	PRIMARY KEY		auto_increment,
    `username`	VARCHAR(100)	NOT NULL	unique,
    `num_friends` INT	DEFAULT 0
);

-- The session entity
CREATE TABLE sessions
(
	`session_id` INT	PRIMARY KEY		auto_increment,
    `session_name`	VARCHAR(100)		UNIQUE,
    `cube_id`		INT,
    CONSTRAINT session_fk_cube
    FOREIGN KEY (cube_id)
    REFERENCES cube_types (cube_id) -- put in session instead
    ON UPDATE CASCADE ON DELETE SET NULL
);

-- The round entity
CREATE TABLE rounds
(
	`round_id`	INT		PRIMARY KEY		auto_increment,
    `scramble`	VARCHAR(250) 	NOT NULL,
    `session_id`	INT,
    CONSTRAINT round_fk_session
    FOREIGN KEY (session_id)
    REFERENCES sessions (session_id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

-- The solve entity
CREATE TABLE solves
(
	`solve_id`	INT		PRIMARY KEY		auto_increment,
    `time`		FLOAT NOT NULL,
    `penalty`	VARCHAR(32),
	`user_id`  	INT NOT NULL,
    `round_id`  INT NOT NULL,
    CONSTRAINT solves_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT solves_fk_rounds
    FOREIGN KEY (round_id)
    REFERENCES rounds (round_id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

-- The relationship between users
CREATE TABLE friends
(
	`user_1_id`		INT		NOT NULL,
    `user_2_id`		INT		NOT NULL,
    CONSTRAINT friends_fk_1
    FOREIGN KEY (user_1_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT friends_fk_2
    FOREIGN KEY (user_2_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT friends_pk
    PRIMARY KEY (user_1_id, user_2_id)
);

-- The note entity
CREATE TABLE notes
(
	`note_id`	INT		PRIMARY KEY 	auto_increment,
	`user_id`	INT,
    `text`		VARCHAR(256),
    CONSTRAINT notes_fk_user
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- Trigger to update num_friends when a friend is added
DROP TRIGGER IF EXISTS update_friends;
DELIMITER //
CREATE TRIGGER update_friends AFTER INSERT ON friends
FOR EACH ROW 
BEGIN
	DECLARE friend_1 INT;
    DECLARE friend_2 INT;
    SELECT NEW.user_1_id INTO friend_1;
    SELECT NEW.user_2_id INTO friend_2;
	UPDATE users SET num_friends = num_friends + 1 WHERE user_id = friend_1;
	UPDATE users SET num_friends = num_friends + 1 WHERE user_id = friend_2;
END//
DELIMITER ;

-- Trigger to update num_friends when a friend is deleted
DROP TRIGGER IF EXISTS update_friends_on_delete;
DELIMITER //
CREATE TRIGGER update_friends_on_delete BEFORE DELETE ON friends
FOR EACH ROW 
BEGIN
	DECLARE friend_1 INT;
    DECLARE friend_2 INT;
    SELECT OLD.user_1_id INTO friend_1;
    SELECT OLD.user_2_id INTO friend_2;
	UPDATE users SET num_friends = num_friends - 1 WHERE user_id = friend_1;
	UPDATE users SET num_friends = num_friends - 1 WHERE user_id = friend_2;
END//
DELIMITER ;

INSERT INTO `users` (`username`) VALUES ('audrey');
INSERT INTO `users` (`username`) VALUES ('graham');
INSERT INTO `users` (`username`) VALUES ('brooke');
INSERT INTO `users` (`username`) VALUES ('chirag');

INSERT INTO `cube_types` (`name`) VALUES ('3x3');
INSERT INTO `cube_types` (`name`) VALUES ('4x4');
INSERT INTO `cube_types` (`name`) VALUES ('Pyraminx');

INSERT INTO `sessions` (`session_name`, `cube_id`) VALUES ('session_1', 1);

INSERT INTO `rounds` (`scramble`, `session_id`) VALUES ("D' R2 U2 D2 B' U F D L2 B2 F' D F' B' R2 L B D L' B2 L U' D' B L2", 1);
INSERT INTO `rounds` (`scramble`, `session_id`) VALUES ("R D B2 U' R2 F' D U2 F' L B L F D R2 D U' B' R' F2 R B' L U L", 1);

INSERT INTO `solves` (`time`, `penalty`, `user_id`, `round_id`) VALUES (34.5, "DNF", 1, 1);
INSERT INTO `solves` (`time`, `user_id`, `round_id`) VALUES (50.1, 2, 1);
INSERT INTO `solves` (`time`, `user_id`, `round_id`) VALUES (100.4, 3, 1);
INSERT INTO `solves` (`time`, `penalty`, `user_id`, `round_id`) VALUES (73.0, "+2", 1, 2);
INSERT INTO `solves` (`time`, `user_id`, `round_id`) VALUES (30.4, 3, 2);
INSERT INTO `solves` (`time`, `user_id`, `round_id`) VALUES (90.9, 4, 2);

INSERT INTO `friends` (`user_1_id`, `user_2_id`) VALUES (1, 2);
INSERT INTO `friends` (`user_1_id`, `user_2_id`) VALUES (1, 3);
INSERT INTO `friends` (`user_1_id`, `user_2_id`) VALUES (1, 4);

INSERT INTO `notes` (`user_id`, `text`) VALUES (2, "I won today!");
INSERT INTO `notes` (`user_id`, `text`) VALUES (1, "Practice on 4x4");