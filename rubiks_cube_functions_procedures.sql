USE cubes;

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

-- Procedure to find all the friends of a user
DROP PROCEDURE IF EXISTS find_friends;
DELIMITER //
CREATE PROCEDURE find_friends(IN uname VARCHAR(100))
BEGIN
-- WITH id AS (SELECT get_user_id(username))
SELECT username FROM users JOIN
((SELECT user_1_id AS this_user, user_2_id AS friend FROM friends WHERE user_1_id = (SELECT get_user_id(uname)))
UNION (SELECT user_2_id AS this_user, user_1_id AS friend FROM friends WHERE user_2_id = (SELECT get_user_id(uname)))) AS friends
ON friend = users.user_id;
END //
DELIMITER ;

CALL find_friends('audrey');


SELECT get_user_id('graham');