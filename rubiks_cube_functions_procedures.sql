USE cubes3;

DROP FUNCTION IF EXISTS get_user_id;
DELIMITER //
 CREATE FUNCTION get_user_id(username_arg VARCHAR(100))
 RETURNS INT
 DETERMINISTIC
 READS SQL DATA
 BEGIN
	DECLARE result INT;
    SELECT user_id INTO result FROM (SELECT * FROM users WHERE username = username_arg) AS id;
    RETURN result;
 END//
DELIMITER ;

DROP FUNCTION IF EXISTS get_session_id;
DELIMITER //
 CREATE FUNCTION get_session_id(sname VARCHAR(100))
 RETURNS INT
 DETERMINISTIC
 READS SQL DATA
 BEGIN
	DECLARE result INT;
    SELECT session_id INTO result FROM (SELECT * FROM sessions WHERE session_name = sname) AS id;
    RETURN result;
 END//
DELIMITER ;

DROP FUNCTION IF EXISTS get_cube_id;
DELIMITER //
CREATE FUNCTION get_cube_id(cube_name VARCHAR(100))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE result INT;
    SELECT cube_id INTO result FROM cube_types WHERE name = cube_name;
    RETURN result;
END //
DELIMITER ;

-- Procedure to find all the friends of a user
DROP PROCEDURE IF EXISTS find_friends;
DELIMITER //
CREATE PROCEDURE find_friends(IN uname VARCHAR(100))
BEGIN
DECLARE uid INT DEFAULT 0;
SELECT get_user_id(uname) INTO uid;

SELECT username FROM users
JOIN (
	(SELECT user_1_id AS this_user, user_2_id AS friend FROM friends WHERE user_1_id = uid)
	UNION
	(SELECT user_2_id AS this_user, user_1_id AS friend FROM friends WHERE user_2_id = uid)
) as t
ON friend = users.user_id;
END //
DELIMITER ;

-- Prodecure to find out who won a round
DROP PROCEDURE IF EXISTS get_winner;
DELIMITER //
CREATE PROCEDURE get_winner(IN round INT)
BEGIN
SELECT username FROM users NATURAL JOIN
(SELECT * FROM solves WHERE (round_id = round AND (penalty IS NULL OR penalty != "DNF"))) AS logs ORDER BY time ASC LIMIT 1;
END //
DELIMITER ;

-- Procedure to find all the solves in a round. Lists username, time, and any penalties.
DROP PROCEDURE IF EXISTS get_solves;
DELIMITER //
CREATE PROCEDURE get_solves(IN round INT)
BEGIN
SELECT username, time, penalty FROM users NATURAL JOIN
(SELECT * FROM solves WHERE round_id = round) AS logs ORDER BY time ASC;
END //
DELIMITER ;

-- Procedure to change the session name
DROP PROCEDURE IF EXISTS change_session_name;
DELIMITER //
CREATE PROCEDURE change_session_name(IN old_id INT, IN new_name VARCHAR(100))
BEGIN
UPDATE sessions SET session_name = new_name WHERE session_id = old_id;
END //
DELIMITER ;

-- Prodecure to add a penalty to a user's solve for a round
DROP PROCEDURE IF EXISTS add_penalty;
DELIMITER //
CREATE PROCEDURE add_penalty(IN uname VARCHAR(100), IN roundid INT, IN pen VARCHAR(32))
BEGIN
UPDATE solves SET penalty = pen WHERE round_id = roundid AND user_id = (SELECT get_user_id(uname));
END //
DELIMITER ;

-- Procedure to delete a user
DROP PROCEDURE IF EXISTS remove_user;
DELIMITER //
CREATE PROCEDURE remove_user(IN uname VARCHAR(100))
BEGIN
DELETE FROM users WHERE username = uname;
END //
DELIMITER ;

-- Procedure to create a user
DROP PROCEDURE IF EXISTS create_user;
DELIMITER //
CREATE PROCEDURE create_user(IN uname VARCHAR(100))
BEGIN
INSERT INTO users (`username`) VALUES (uname);
END //
DELIMITER ;

-- Procedure to add a friend
DROP PROCEDURE IF EXISTS add_friend;
DELIMITER //
CREATE PROCEDURE add_friend(IN name_1 VARCHAR(100), IN name_2 VARCHAR(100))
BEGIN
INSERT INTO friends (`user_1_id`, `user_2_id`) VALUES ((SELECT get_user_id(name_1)), (SELECT get_user_id(name_2)));
END //
DELIMITER ;

-- Procedure to delete a friend
DROP PROCEDURE IF EXISTS remove_friend;
DELIMITER //
CREATE PROCEDURE remove_friend(IN name_1 VARCHAR(100), IN name_2 VARCHAR(100))
BEGIN
DELETE FROM friends WHERE (user_1_id = (SELECT get_user_id(name_1)) AND user_2_id = (SELECT get_user_id(name_2))
OR user_1_id = (SELECT get_user_id(name_2)) AND user_2_id = (SELECT get_user_id(name_1)));
END //
DELIMITER ;

-- Procedure to create a session
DROP PROCEDURE IF EXISTS create_session;
DELIMITER //
CREATE PROCEDURE create_session(IN session_name VARCHAR(100), cube_name VARCHAR(100))
BEGIN
DECLARE cube_id INT;
SELECT get_cube_id(cube_name) INTO cube_id;
INSERT INTO sessions (`session_name`, `cube_id`) VALUES (session_name, cube_id);
END //
DELIMITER ;

-- Procedure to list all sessions
DROP PROCEDURE IF EXISTS list_sessions;
DELIMITER //
CREATE PROCEDURE list_sessions()
BEGIN
SELECT * FROM sessions;
END //
DELIMITER ;

-- Procedure to add a round to a session
DROP PROCEDURE IF EXISTS add_round;
DELIMITER //
CREATE PROCEDURE add_round(IN scramble VARCHAR(250), session_id int)
BEGIN
INSERT INTO rounds (`scramble`, `session_id`) VALUES (scramble, session_id);
END //
DELIMITER ;

-- Procedure to list all rounds in a session
DROP PROCEDURE IF EXISTS list_rounds;
DELIMITER //
CREATE PROCEDURE list_rounds(IN sid int)
BEGIN
SELECT * FROM rounds WHERE session_id = sid;
END //
DELIMITER ;

-- Procedure to add a solve to a round
DROP PROCEDURE IF EXISTS add_solve;
DELIMITER //
CREATE PROCEDURE add_solve(IN user_id INT, round_id INT, time FLOAT, penalty VARCHAR(10))
BEGIN
INSERT INTO solves (`time`, `penalty`, `user_id`, `round_id`) VALUES (time, penalty, user_id, round_id);
END //
DELIMITER ;

-- Procedure to list all solves in a round
DROP PROCEDURE IF EXISTS list_solves;
DELIMITER //
CREATE PROCEDURE list_solves(IN rid INT)
BEGIN
SELECT * FROM solves WHERE round_id = rid;
END //
DELIMITER ;

-- Procedure to find all solves for a user grouped by cube type and ordered by time
-- Returns round, time, penalty, and cube type
DROP PROCEDURE IF EXISTS find_solves_for_user;
DELIMITER //
CREATE PROCEDURE find_solves_for_user(IN uname VARCHAR(100))
BEGIN
SELECT round_id, time, penalty, name
FROM (SELECT * FROM solves NATURAL JOIN rounds NATURAL JOIN
(SELECT round_id, name FROM rounds NATURAL JOIN (SELECT session_id, name FROM sessions NATURAL JOIN cube_types) AS t) AS t2) AS t3
WHERE user_id = (SELECT get_user_id(uname)) ORDER BY name, time ASC;
END //
DELIMITER ;

-- Procedure to calculate the current average of the last 5 time submitted by a user
-- If user does not have 5 yet, averages all the scores
DROP PROCEDURE IF EXISTS average_of_5;
DELIMITER //
CREATE PROCEDURE average_of_5(IN uname VARCHAR(100))
BEGIN
SELECT AVG(time) FROM solves
WHERE user_id = (SELECT get_user_id(uname)) ORDER BY solve_id DESC LIMIT 5;
END //
DELIMITER ;

-- Procedure to update a username
DROP PROCEDURE IF EXISTS update_username;
DELIMITER //
CREATE PROCEDURE update_username(IN old_name VARCHAR(100), IN new_name VARCHAR(100))
BEGIN
UPDATE users SET username = new_name WHERE user_id = (SELECT get_user_id(old_name));
END //
DELIMITER ;

-- Prodecure to delete a session--should also delete rounds and solve log entries
DROP PROCEDURE IF EXISTS delete_session;
DELIMITER //
CREATE PROCEDURE delete_session(IN sessionid INT)
BEGIN
DELETE FROM sessions WHERE session_id = sessionid;
END //
DELIMITER ;

-- Procedure to delete a round--all solve log entries from that round will also be deleted
DROP PROCEDURE IF EXISTS delete_round;
DELIMITER //
CREATE PROCEDURE delete_round(IN roundid INT)
BEGIN
	DELETE FROM rounds WHERE round_id = roundid;
END //
DELIMITER ;

-- Procedure to create a note
DROP PROCEDURE IF EXISTS create_note;
DELIMITER //
CREATE PROCEDURE create_note(IN userid INT, IN text VARCHAR(1000))
BEGIN
	INSERT INTO notes (`user_id`, `text`) VALUES (userid, text);
END //
DELIMITER ;

-- Procedure to list notes for a user
DROP PROCEDURE IF EXISTS list_notes;
DELIMITER //
CREATE PROCEDURE list_notes(IN userid INT)
BEGIN
	SELECT * FROM notes WHERE user_id = userid;
END //
DELIMITER ;

-- Procedure to update a note belonging to a user
DROP PROCEDURE IF EXISTS update_note;
DELIMITER //
CREATE PROCEDURE update_note(IN userid INT, IN noteid INT, IN new_text VARCHAR(1000))
BEGIN
	UPDATE notes SET text = new_text WHERE user_id = userid AND note_id = noteid;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_note;
DELIMITER //
CREATE PROCEDURE delete_note(IN userid INT, IN noteid INT)
BEGIN
	DELETE FROM notes WHERE user_id = userid and note_id = noteid;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS list_cube_types;
DELIMITER //
CREATE PROCEDURE list_cube_types()
BEGIN
	SELECT name from cube_types;
END //
DELIMITER ;
