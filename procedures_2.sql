-- Procedure to find all solves for a user grouped by cube type and ordered by time
-- Returns round, time, penalty, and cube type
DROP PROCEDURE IF EXISTS find_solves_for_user;
DELIMITER //
CREATE PROCEDURE find_solves_for_user(IN uname VARCHAR(100))
BEGIN
SELECT round_id, time, penalty, name 
FROM (SELECT * FROM solves NATURAL JOIN solve_logs NATURAL JOIN rounds NATURAL JOIN
(SELECT round_id, name FROM rounds NATURAL JOIN (SELECT session_id, name FROM sessions NATURAL JOIN cube_types) AS t) AS t2) AS t3
WHERE user_id = (SELECT get_user_id(uname)) ORDER BY name, time ASC;
END // 
DELIMITER ;

CALL find_solves_for_user("audrey");

-- Procedure to calculate the current average of the last 5 time submitted by a user
-- If user does not have 5 yet, averages all the scores
DROP PROCEDURE IF EXISTS average_of_5;
DELIMITER //
CREATE PROCEDURE average_of_5(IN uname VARCHAR(100))
BEGIN
SELECT AVG(time) FROM solves NATURAL JOIN solve_logs 
WHERE user_id = (SELECT get_user_id(uname)) ORDER BY solve_id DESC LIMIT 5;
END //
DELIMITER ;

CALL average_of_5("audrey");

-- Procedure to update a username
DROP PROCEDURE IF EXISTS update_username;
DELIMITER //
CREATE PROCEDURE update_username(IN old_name VARCHAR(100), IN new_name VARCHAR(100))
BEGIN
UPDATE users SET username = new_name WHERE user_id = (SELECT get_user_id(old_name));
END //
DELIMITER ;

CALL update_username("graham", "audreys_partner");

-- Prodecure to delete a session--should also delete rounds and solve log entries
DROP PROCEDURE IF EXISTS delete_session;
DELIMITER //
CREATE PROCEDURE delete_session(IN session_name VARCHAR(100))
BEGIN
DELETE FROM sessions WHERE session_id = (SELECT get_session_id(session_name));
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