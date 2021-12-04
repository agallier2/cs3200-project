DROP DATABASE IF EXISTS cubes;
CREATE DATABASE cubes;
USE cubes;

-- The user entity
CREATE TABLE users
(
	`user_id`	INT 	PRIMARY KEY		auto_increment,
    `username`	VARCHAR(100)	NOT NULL
);

-- The session entity
CREATE TABLE sessions
(
	`session_id` INT	PRIMARY KEY		auto_increment,
    `session_name`	VARCHAR(100),
    `start_time` 	DATETIME
);

-- The solve entity
CREATE TABLE solves
(
	`solve_id`	INT		PRIMARY KEY		auto_increment,
    `time`		FLOAT
);

-- The cube type entity
CREATE TABLE cube_types
(
	`cube_id`	INT		PRIMARY KEY 	auto_increment,
    `cube_shape`	VARCHAR(100),
	`cube_size`		INT,
    `name`		VARCHAR(100)
);

-- The round entity
CREATE TABLE rounds
(
	`round_id`	INT		PRIMARY KEY		auto_increment,
    `scramble`	VARCHAR(250) 	NOT NULL,
    `session_id`	INT,
    `cube_id`	INT,
    CONSTRAINT round_fk_session
    FOREIGN KEY (session_id)
    REFERENCES sessions (session_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT round_fk_cube
    FOREIGN KEY (cube_id)
    REFERENCES cube_types (cube_id)
    ON UPDATE CASCADE ON DELETE SET NULL
);

-- The complex relationship
-- Can change later
CREATE TABLE solve_logs
(
	`solve_id`	INT 	NOT NULL,
    `user_id`	INT		NOT NULL,
    `round_id`	INT		NOT NULL,
    CONSTRAINT logs_fk_solve
    FOREIGN KEY (solve_id)
    REFERENCES solves (solve_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT logs_fk_user
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT logs_fk_round
    FOREIGN KEY (round_id)
    REFERENCES rounds (round_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT logs_pk
    PRIMARY KEY (user_id, round_id)
);

-- The relationship between users
CREATE TABLE friends
(
	`id_1`		INT		NOT NULL,
    `id_2`		INT		NOT NULL,
    CONSTRAINT friends_fk_1
    FOREIGN KEY (id_1)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT friends_fk_2
    FOREIGN KEY (id_2)
    REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT friends_pk
    PRIMARY KEY (id_1, id_2)
);

INSERT INTO `users` (`username`) VALUES ('audrey');
INSERT INTO `users` (`username`) VALUES ('graham');
INSERT INTO `users` (`username`) VALUES ('brooke');

INSERT INTO `cube_types` (`cube_shape`, `cube_size`, `name`) VALUES ('cube', 3, 'standard');
INSERT INTO `cube_types` (`cube_shape`, `cube_size`, `name`) VALUES ('cube', 4, '4 by 4');

INSERT INTO `solves` (`time`) VALUES (34.5);
INSERT INTO `solves` (`time`) VALUES (50.1);
INSERT INTO `solves` (`time`) VALUES (100.4);
INSERT INTO `solves` (`time`) VALUES (73.0);
INSERT INTO `solves` (`time`) VALUES (30.4);

INSERT INTO `sessions` (`session_name`, `start_time`) VALUES ('session_1', '2021-12-04 13:23:44');

INSERT INTO `rounds` (`scramble`, `session_id`, `cube_id`) VALUES ("D' R2 U2 D2 B' U F D L2 B2 F' D F' B' R2 L B D L' B2 L U' D' B L2", 1, 1);
INSERT INTO `rounds` (`scramble`, `session_id`, `cube_id`) VALUES ("R D B2 U' R2 F' D U2 F' L B L F D R2 D U' B' R' F2 R B' L U L", 1, 2);

INSERT INTO `solve_logs` (`solve_id`, `user_id`, `round_id`) VALUES (1, 1, 1);
INSERT INTO `solve_logs` (`solve_id`, `user_id`, `round_id`) VALUES (2, 2, 1);
INSERT INTO `solve_logs` (`solve_id`, `user_id`, `round_id`) VALUES (3, 3, 1);
INSERT INTO `solve_logs` (`solve_id`, `user_id`, `round_id`) VALUES (4, 1, 2);
INSERT INTO `solve_logs` (`solve_id`, `user_id`, `round_id`) VALUES (5, 3, 2);

INSERT INTO `friends` (`id_1`, `id_2`) VALUES (1, 2);
INSERT INTO `friends` (`id_1`, `id_2`) VALUES (1, 3);