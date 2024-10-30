update vars set value = 'http://{BASE_URL}' where name = 'absolutedir' limit 1;
update vars set value = 'https://{BASE_URL}' where name = 'absolutedir_secure' limit 1;
update vars set value = '{BASE_URL}' where name = 'basedomain' limit 1;
update vars set value = '//{BASE_URL}' where name = 'rootdir' limit 1;
update vars set value = '//{BASE_URL}/images' where name = 'imagedir' limit 1;
update vars set value = 'sphinx' where name = 'search_sphinx_host' limit 1;
update skins set url = REPLACE(url, '/soylentnews.org', '/{BASE_URL}') where url like 'https://soylentnews.org%';
update skins set cookiedomain = REPLACE(cookiedomain, '.soylentnews.org','.{BASE_URL}') where cookiedomain = '.soylentnews.org';
update skins set hostname = '{BASE_URL}' where skid = 1;
update blocks set block=REPLACE(block,'https://soylentnews.org','https://{BASE_URL}');
update blocks set url=REPLACE(url,'//soylentnews.org', '//{BASE_URL}');
update discussions set url=REPLACE(url,'//soylentnews.org', '//{BASE_URL}');
update blocks set rdf=REPLACE(rdf,'//soylentnews.org', '//{BASE_URL}');


CREATE TABLE IF NOT EXISTS sqlflags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    flag VARCHAR(255) UNIQUE
);

DROP PROCEDURE IF EXISTS create_indexes_if_needed;


-- Create a stored procedure to handle the index creation
DELIMITER //

CREATE PROCEDURE create_indexes_if_needed()
BEGIN
    DECLARE row_count INT;

    -- Check if the specific row exists
    SELECT COUNT(*) INTO row_count FROM sqlflags WHERE flag = 'indexes_created';

    -- If the row does not exist, create the indexes and insert the row
    IF row_count = 0 THEN
        CREATE INDEX idx_uid_ipid_ts ON moderatorlog (uid, ipid, ts);
        CREATE INDEX idx_uid_ipid_date ON comments (uid, ipid, date);
        CREATE INDEX idx_date ON comments (date);
        CREATE INDEX idx_moderatorlog_ts ON moderatorlog(ts);
        CREATE INDEX idx_comments_uid ON comments(uid);

        -- Insert a row into the sqlflags table to mark that the indexes have been created
        INSERT INTO sqlflags (flag) VALUES ('indexes_created');
    END IF;
END //

DELIMITER ;

-- Call the stored procedure

CALL create_indexes_if_needed();
