DROP DATABASE IF EXISTS final;
CREATE DATABASE final;
USE final;

CREATE TABLE teams(
team_id INT  PRIMARY KEY AUTO_INCREMENT,
team_name VARCHAR(100) NOT NULL,
founded_year YEAR NOT NULL, --
stadium VARCHAR(100) NOT NULL,
raking_position INT DEFAULT 0
);

CREATE TABLE coaches(
coach_id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(100) NOT NULL,
nationality VARCHAR(50) NOT NULL,
experience_years INT  DEFAULT 0,
team_id INT,
CONSTRAINT fk_coachs_team_id FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

CREATE TABLE players(
player_id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(100) NOT NULL,
jersey_number INT NOT NULL,
position VARCHAR(50) NOT NULL,
salary DECIMAL(12,2) NOT NULL,
team_id INT,
CONSTRAINT fk_player_team_id FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

CREATE TABLE matches(
match_id INT PRIMARY KEY AUTO_INCREMENT,
home_team_id INT,
away_team_id INT,
match_date DATETIME NOT NULL,
stadium VARCHAR(100) NOT NULL,
match_status VARCHAR(30) DEFAULT 'Scheduled',
CONSTRAINT fk_home_team_id FOREIGN KEY (home_team_id) REFERENCES teams(team_id),
CONSTRAINT fk_away_team_id FOREIGN KEY (away_team_id) REFERENCES teams(team_id)
);

CREATE TABLE player_statistics(
stat_id INT PRIMARY KEY AUTO_INCREMENT,
player_id INT,
match_id INT,
goals INT DEFAULT 0,
assists INT DEFAULT 0,
yellow_card INT DEFAULT 0,
rating_score DECIMAL(3,1) DEFAULT 0,
CONSTRAINT fk_player_statistics_id FOREIGN KEY (player_id) REFERENCES players(player_id),
CONSTRAINT fk_matchs_statistics_id FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

CREATE TABLE transfer_history (
    transfer_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT,
    old_team_id INT,
    new_team_id INT,
    transfer_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO teams(team_id,team_name,founded_year,stadium,raking_position) VALUES
(1,'Manchester City', 1880,'Etihad Stadium',1),
(2,'Real Madrid', 1902,'Santiago Bernabeu',2),
(3,'Hanoi Fc', 2006,'Hang Day Stadium',3),
(4,'Saigon United', 2015,'Thong Nhat Stadium',5),
(5,'Thép Xanh Nam Định', 1979,'Thiên Đường Stadium',10);

INSERT INTO coaches(coach_id,full_name,nationality,experience_years,team_id) VALUES
(1,'Pep Guardiola', 'Spanish', 15, 1),
(2,'Carlo Ancelotti', 'Italy', 25, 2),
(3,'Chu Đình Nghiêm', 'Vietnamese', 12, 3),
(4,'Alexsandre Polking', 'German-Brazillian', 10, 4),
(5,'Park Hang-seo', 'Korean', 30, 5);

INSERT INTO players(player_id, full_name, jersey_number, position, salary, team_id) VALUES
(1,'Erling Haaland',9,'Forward',450000000,1),
(2,'Kevin De Bruyne',17,'Midfielder',400000000,1),
(3,'Nguyễn Quang Hải',19,'Midfielder',60000000,3),
(4,'Kylian Mbappe',7,'Forward',500000000,2),
(5,'Nguyễn Văn Quyết',10,'Forward',55000000,3);

INSERT INTO matches(match_id,home_team_id,away_team_id,match_date,stadium,match_status) VALUES 
(1,1,2, '2026-05-10 19:00', 'Etihad Stadium','Finished'),
(2,3,4, '2026-05-12 18:30','Hang Day Stadium', 'Finished'),
(3,5,1, '2026-05-15 20:00','Thien Duong Stadium','Scheduled'),
(4,2,3, '2026-05-20 21:00', 'Santiago Bernabeu', 'Scheduled'),
(5,4,5, '2026-05-21 17:00', 'Thong Nhat Stadium','Scheduled');

INSERT INTO player_statistics(stat_id,player_id,match_id,goals,assists,yellow_card,rating_score) VALUES
(1,1,1,2,1,0,9.5),
(2,4,1,1,0,1,8.2),
(3,3,2,0,2,0,8.5),
(4,5,2,3,0,0,9.0),
(5,1,4,0,0,3,5.0);

-- cập nhật lương cầu thủ có vị trí là Forward và rating_score > 8
UPDATE players 
SET salary = salary * 1.15
WHERE position = 'Forward' 
AND player_id IN (SELECT player_id FROM player_statistics WHERE rating_score > 8.0);
-- xóa bản ghi có cầu thủ bị hơn 2 thẻ vàng
DELETE FROM player_statistics WHERE yellow_card > 2;

-- lấy dữ liêu từ players có lương lớn hơn 50000000 và position là Midfielder
SELECT full_name, jersey_number, position FROM players 
WHERE salary > 50000000 AND position = 'Midfielder';
-- lấy dữ liệu từ teams có vị trí từ thứ hạng từ 1 đến 5 và bắt đầu bằng S
SELECT team_name, stadium FROM teams 
WHERE raking_position BETWEEN 1 AND 5 AND team_name LIKE 'S%';

SELECT match_id, stadium, match_date FROM matches 
LIMIT 3 OFFSET 3;
-- liệt kê lấy số liêu từ hệ thống
SELECT 
    p.full_name,
    t.team_name,
    ps.goals,
    ps.assists 
FROM player_statistics ps
INNER JOIN players p ON p.player_id = ps.player_id
INNER JOIN teams t ON p.team_id = t.team_id;

-- liệt kê tên đội bóng và số bàn thắng của các cầu thủ thuộc đội đó , chỉ hiện thị những đội có tổng số bàn thắng lớn hưn 10
SELECT 
    t.team_name,
    SUM(ps.goals) AS total_goals
FROM teams t
INNER JOIN players p ON t.team_id = p.team_id
INNER JOIN player_statistics ps ON p.player_id = ps.player_id
GROUP BY t.team_id, t.team_name
HAVING SUM(ps.goals) > 10;

-- hiển thị mức lương của cầu thủ cao nhất hệ thống
SELECT player_id, full_name, salary 
FROM players 
WHERE salary = (SELECT MAX(salary) FROM players);
-- tạo index trên bảng players dựa trên position và salary 
CREATE INDEX players_position_salary ON players(position, salary);
-- tạo view hiển thị tên đội bóng, tổng số cầu thủ, tổng quỹ lương của đội bóng trong đó không tính các cầu thủ có mức lương bằng 0
CREATE VIEW view_team_salary AS
SELECT 
    t.team_name,
    COUNT(p.player_id) AS total_players,
    SUM(p.salary) AS total_salary_fund
FROM teams t
INNER JOIN players p ON t.team_id = p.team_id
WHERE p.salary > 0
GROUP BY t.team_id, t.team_name;
-- viêt một trigger sao cho khi thêm mới bản ghi vào player_statistics mà goals > 10 thì hệ thống tăng thêm 5%
DELIMITER //
CREATE TRIGGER insert_stats
AFTER INSERT ON player_statistics
FOR EACH ROW
BEGIN
    -- Nếu số bàn thắng mới thêm vào lớn hơn 10
    IF NEW.goals > 10 THEN
        UPDATE players 
        SET salary = salary * 1.05
        WHERE player_id = NEW.player_id;
    END IF;
END //
DELIMITER ;
-- viêt một trigger sao cho khi trạng thái của một trận đấu trong bảng matches được cập nhật sang finished thì hệ thống tự động thêm 1 ranking_position cho đội thắng trận.
DELIMITER //
CREATE TRIGGER update_match_status
AFTER UPDATE ON matches
FOR EACH ROW
BEGIN
    IF NEW.match_status = 'Finished' AND OLD.match_status <> 'Finished' THEN
        UPDATE teams 
        SET raking_position = raking_position + 1
        WHERE team_id = NEW.home_team_id;
    END IF;
END //
DELIMITER ;
-- viết một  stored procedure nhận vào mã cầu thủ và trả về thông báo Excellent nếu goals > 20, good nếu goals > từ 10 đén 20, Average nếu goals < 10
DELIMITER //
CREATE PROCEDURE alert_player(
    IN p_id INT
)
BEGIN
    DECLARE total_goals INT DEFAULT 0;
    DECLARE p_name VARCHAR(100);
    
    SELECT full_name INTO p_name FROM players WHERE player_id = p_id;
    
    SELECT SUM(goals) INTO total_goals 
    FROM player_statistics 
    WHERE player_id = p_id;
    
    IF total_goals > 20 THEN
        SELECT CONCAT('Cầu thủ: ', p_name, ' - Kết quả: Excellent') AS Message;
    ELSEIF total_goals >= 10 AND total_goals <= 20 THEN
        SELECT CONCAT('Cầu thủ: ', p_name, ' - Kết quả: Good') AS Message;
    ELSE
        SELECT CONCAT('Cầu thủ: ', p_name, ' - Kết quả: Average') AS Message;
    END IF;
END //
DELIMITER ;

-- viết một procedure để thực hiển chuyển đổi cầu thủ sang đội bóng mới
-- bước 1: bắt đầu transaction
-- bước 2 : cập nhật đội mới cho cầu thủ bằng bảng players
-- bước 3 : ghi log chuyển nhượng vào bảng mới có tên transfer_history
-- bước 4 : nếu thành công thì thì commit, nếu xảy ra lỗi ở bất kì bước nào thì rollback toàn bộ thao tácd
DROP PROCEDURE transfer_player;
DELIMITER //
CREATE PROCEDURE transfer_player(
    IN p_id INT,
    IN p_new_team_id INT
)
BEGIN
    DECLARE p_old_team_id INT;

    START TRANSACTION;
	SELECT team_id INTO p_old_team_id FROM players WHERE player_id = p_id;
	UPDATE players 
    SET team_id = p_new_team_id 
    WHERE player_id = p_id;
    INSERT INTO transfer_history (player_id, old_team_id, new_team_id)
    VALUES (p_id, p_old_team_id, p_new_team_id);
    COMMIT;
    
    SELECT 'Chuyển nhượng cầu thủ thành công' AS Result;

END //
DELIMITER ;

