use netflix;
select * from netflix_titles
where show_id ='s5023';

-- DATA CLEANING
/* HANDLING   DUPLICATES*/
-- show duplicates
select show_id,count(*)
from netflix_titles
group by show_id
having count(*)>1; -- no duplicates with showid nut just to be sure let's check with title as well


select * 
from netflix_titles 
where upper(title) in 
(select title
      from (
           select upper(title) as title
           from netflix_titles
           group by title
           having count(*)>1)  as duplicated )
order by title ;
/* there exists a number of duplicates
same titles with different type should not be treated as a title here, 
but shows with same name which are being treated a different just becuase of their case are duplicates */

-- REMOVING DUPLICATES

select * 
from netflix_titles 
where concat(upper(title),type) in (
           select concat (upper(title),type) as title
           from netflix_titles
           group by title,type
           having count(*)>1)  
order by title ;
create table netflix_cleaned as 
with cte as(select * ,row_number() over(partition by title, type order by  show_id) as rn
from netflix_titles )
select * from cte where rn=1;


/* HANDLING   MULTIPLE DIRECTORS, CAST, GENRES, COUNTRY. */
-- NEW TABLES for listed in , genre, directors

-- For Directors
create table directors as 
select show_id,trim(substring_index (director,',',1))  as director_1,
case when director like '%,%' then 
nullif(trim(substring_index (substring_index (director,',',2), ',', -1)), '') else null end  as director_2,
case when director like '%,%,%' then 
nullif(trim(substring_index (substring_index (director,',',3), ',', -1)), '') else null end  as director_3
from netflix_cleaned;


-- For Listed_in 
create table netflix_genres_list as 
select show_id,trim(substring_index (listed_in,',',1))  as category_1,
case when listed_in like '%,%' then 
nullif(trim(substring_index (substring_index (listed_in,',',2), ',', -1)), '') else null end  as category_2,
case when listed_in like '%,%,%' then 
nullif(trim(substring_index (substring_index (listed_in,',',3), ',', -1)), '') else null end  as category_3

from netflix_cleaned;

-- For Country 
create table country as
select show_id,trim(substring_index (country,',',1))  as country_1,
case when country like '%,%' then 
nullif(trim(substring_index (substring_index (country,',',2), ',', -1)), '') else null end  as country_2,
case when country like '%,%,%' then 
nullif(trim(substring_index (substring_index (country,',',3), ',', -1)), '') else null end  as country_3

from netflix_cleaned;

-- For Cast
create table  cast as
select show_id,trim(substring_index (cast,',',1))  as cast_1,
case when cast like '%,%' then 
nullif(trim(substring_index (substring_index (cast,',',2), ',', -1)), '') else null end  as cast_2,
case when cast like '%,%,%' then 
nullif(trim(substring_index (substring_index (cast, ',', 3), ',', -1)), '') else null end  as cast_3,
case when cast like '%,%,%,%' then 
nullif(trim(substring_index (substring_index (cast, ',', 4), ',', -1)), '') else null end  as cast_4,
case when cast like '%,%,%,%,%' then 
nullif(trim(substring_index (substring_index (cast, ',', 5), ',', -1)), '') else null end  as cast_5,
case when cast like '%,%,%,%,%,%' then 
nullif(trim(substring_index (substring_index (cast, ',', 6), ',', -1)), '') else null end  as cast_6

from netflix_cleaned;

-- NOW that we ave added different tables for different columns we will reduce the table columns 
create table netflix as 
select show_id, type,title,date_added,release_year,rating,duration,description from netflix_cleaned ;

-- CHECKING DATATYPES OF EACH COLUMN
describe netflix_titles;
-- date_added should be of type datetime type release year also ratin should be float, duration should 


-- populate missing values in country, duration columns
insert into country
select n.show_id, country_1, null as country_2, null as country_3 from netflix_titles n
join (
select director_1, MIN(country_1) as country_1 from country c
join directors d
on c.show_id = d.show_id
group by 1) nt
on n.director= nt.director_1
where n.country is Null
;

-- analyzing some more columns
select * from netflix_cleaned where duration is null;

-- duration column is null and rating is given in minutes, hence there is some mismatch
create table netflix_table as 
select show_id, type,title,date_added,release_year,rating,
case when duration is null then rating else duration end as duration ,description
from netflix;