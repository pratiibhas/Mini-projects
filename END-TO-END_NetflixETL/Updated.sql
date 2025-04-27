USE practice;
SELECT * FROM netflix_titles;
DESCRIBE netflix_titles;

-- While converting df_to sql , it chooses maximum length possible to avoid any missed data 
/* and now the schema is overkill (like VARCHAR(1000) when you maybe only needed VARCHAR(100) 
and BIGINT when INT would’ve done). 
This can definitely hurt performance in terms of storage, index efficiency, and even query optimization.

HENCE, UPDATED COLUMNS
*/
ALTER TABLE netflix_titles
MODIFY COLUMN show_id VARCHAR(10),
MODIFY COLUMN type ENUM('Movie', 'TV Show'),
MODIFY COLUMN title VARCHAR(200),
MODIFY COLUMN director VARCHAR(250),
MODIFY COLUMN cast VARCHAR(1000),
MODIFY COLUMN country VARCHAR(150),
MODIFY COLUMN date_added VARCHAR(20) ,
MODIFY COLUMN release_year YEAR,
MODIFY COLUMN rating VARCHAR(10),
MODIFY COLUMN duration VARCHAR(10),
MODIFY COLUMN listed_in VARCHAR(100),
MODIFY COLUMN description VARCHAR(500);


