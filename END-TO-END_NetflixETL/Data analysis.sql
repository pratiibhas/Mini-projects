use netflix;
select * from netflix_table;
-- ------------------ DATA ANALYSIS ----------------------------
/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */
select director ,COUNT(distinct case when type='Movie' then show_id end) as no_of_movies
,COUNT(distinct case when type='TV Show' then show_id end) as no_of_tvshow
from
(select d.show_id,director_1 as director, title,type from netflix_table nt
join directors d
on nt.show_id = d.show_id

union all
select d.show_id,director_2 as director,  title, type from netflix_table nt
join directors d
on nt.show_id = d.show_id

union all
select d.show_id,director_2 as director,  title, type from netflix_table nt
join directors d
on nt.show_id = d.show_id
) a
group by 1;

-- 2 which country has highest number of comedy movies
with cte as(
select c.show_id,country_1,country_2,country_3,title from country c
join netflix_table nt
on c.show_id = nt.show_id
join netflix_genres_list g
on g.show_id= c.show_id
where g.category_1='Comedies' or g.category_2='Comedies' or g.category_2='Comedies')

select country,count(*) as cnt from(
select country_1  as country from cte where country_1 is not null
union all
select country_2  as country from cte where country_1 is not null
union all 
select country_3  as country from cte where country_1 is not null)a
where country is not null
group by 1
order by 1
;

-- 3 for each year (as per date added to netflix), which director has maximum number of movies released

SELECT STR_TO_DATE(date_added, '%M %d, %Y') AS date_added FROM netflix_table;


with cte as (
select nd.director_1 as director,YEAR(date_added) AS date_added,count(n.show_id) as no_of_movies
from netflix_table n
inner join directors nd on n.show_id=nd.show_id
where type='Movie' and director_1 is not null
group by nd.director_1,YEAR(date_added)
union all 
select nd.director_2 as director,YEAR(date_added) AS date_added,count(n.show_id) as no_of_movies
from netflix_table n
inner join directors nd on n.show_id=nd.show_id
where type='Movie' and director_2 is not null
group by nd.director_2,YEAR(date_added)
union all
select nd.director_3 as director,YEAR(date_added) AS date_added,count(n.show_id) as no_of_movies
from netflix_table n
inner join directors nd on n.show_id=nd.show_id
where type='Movie' and director_3 is not null
group by nd.director_3,YEAR(date_added)

)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_added order by no_of_movies desc, director) as rn
from cte

)
select director, no_of_movies from cte2 where rn=1;
-- 4 what is average duration of movies in each genre
select ng.category_1 , avg(cast(REPLACE(duration,' min','') AS signed)) as avg_duration
from netflix n
inner join netflix_genres_list ng on n.show_id=ng.show_id
where type='Movie'
group by ng.category_1;

/*5  find the list of directors who have created horror and comedy movies both.
 display director names along with number of comedy and horror movies directed by them */
 select director, no_of_horrors,no_of_comedy from(
 select director_1  as director,
 sum(case when (ng.category_1 or ng.category_2 or ng.category_3) in ('Horror') then 1 else 0 end) as no_of_horrors,
 sum(case when (ng.category_1 or ng.category_2 or ng.category_3) in ('Comedies') then 1 else 0 end) as no_of_comedy
 from directors d
 join netflix_genres_list ng
 on d.show_id= ng.show_id
 where director_1 is not null
 group by 1) a 
 where no_of_horrors !=0  and no_of_comedy!=0
 