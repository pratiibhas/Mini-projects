use demo;
-- Create employees table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(10) NOT NULL,
    join_date DATE NOT NULL,
    department VARCHAR(10) NOT NULL
);

-- Insert sample data
INSERT INTO employees (employee_id, name, join_date, department)
VALUES
    (1, 'Alice', '2018-06-15', 'IT'),
    (2, 'Bob', '2019-02-10', 'Finance'),
    (3, 'Charlie', '2017-09-20', 'HR'),
    (4, 'David', '2020-01-05', 'IT'),
    (5, 'Eve', '2016-07-30', 'Finance'),
    (6, 'Sumit', '2016-06-30', 'Finance');
 
-- Create salary_history table
CREATE TABLE salary_history (
    employee_id INT,
    change_date DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    promotion VARCHAR(3)
);

-- Insert sample data
INSERT INTO salary_history (employee_id, change_date, salary, promotion)
VALUES
    (1, '2018-06-15', 50000, 'No'),
    (1, '2019-08-20', 55000, 'No'),
    (1, '2021-02-10', 70000, 'Yes'),
    (2, '2019-02-10', 48000, 'No'),
    (2, '2020-05-15', 52000, 'Yes'),
    (2, '2023-01-25', 68000, 'Yes'),
    (3, '2017-09-20', 60000, 'No'),
    (3, '2019-12-10', 65000, 'No'),
    (3, '2022-06-30', 72000, 'Yes'),
    (4, '2020-01-05', 45000, 'No'),
    (4, '2021-07-18', 49000, 'No'),
    (5, '2016-07-30', 55000, 'No'),
    (5, '2018-11-22', 62000, 'Yes'),
    (5, '2021-09-10', 75000, 'Yes'),
    (6, '2016-06-30', 55000, 'No'),
    (6, '2017-11-22', 50000, 'No'),
    (6, '2018-11-22', 40000, 'No'),
    (6, '2021-09-10', 75000, 'Yes');
    
SELECT * FROM salary_history;
SELECT * FROM employees;

/* TASKS */
-- 1. Find the latest salary of the employees.
-- 2. Calculate the total number of promotions each employee have received.
-- 3. Identify employees whose salary never decreased.
-- 4. Find the average time(in months) between salary changes for each employee
-- 5. Determine the maximum salary hike percentage between any two consecutive salary changes for each employee.
-- 6. Rank employees by their salary rowth rate (from first to last recorded salary), breaking ties y earliest join date.
-- ALL IN A SINGLE TABLE


with cte as(select *, rank() over(partition by employee_id order by change_date desc) as rn,
rank() over(partition by employee_id order by change_date) as new_rn
from salary_history),

latest_sal as(
select * from cte where rn=1),

promotion_cte as(
select employee_id, count(*) as NoOfTimes from cte
where promotion ='Yes'
group by 1),

hike_pct as(
select c.employee_id, max(round((d.salary-c.salary)*100/c.salary,2)) as max_sal_growth from cte c
join cte d
on c.employee_id = d.employee_id and c.rn=d.rn+1 -- or use LEAD(salary,1) OVER (PARTITION BY change_date ORDER BY change_date DESC)
group by 1),

sal_dec as(
select d.employee_id,'N' as never_decreased from cte c
join cte d
on c.employee_id= d.employee_id
where c.rn=d.rn+1 and c.salary>d.salary
group by 1),

avg_month_between_change as
(select c.employee_id,round(avg(timestampdiff(month, c.change_date,d.change_date)),2) as avg_time from cte c
join cte d
on c.employee_id= d.employee_id
where c.rn = d.rn+1
group by 1
),
rank_by_gr as(select employee_id, 
max(case when rn=1 then salary end)as latest_sal,
max(case when new_rn=1 then salary end)as oldest_sal
from cte 
group by 1
),
ranked_growth as(
select c.employee_id,e.join_date,round((latest_sal- oldest_sal)*100/oldest_sal,2) as pct,
rank() over(order by round((latest_sal- oldest_sal)*100/oldest_sal,2) desc , join_date asc) as rank_by_growth
from rank_by_gr c
join employees e 
on e.employee_id = c.employee_id
order by pct desc, join_date asc)

select
e.employee_id,
l.salary as LatestSal,
coalesce(p.NoOfTimes,0) as No_of_promotions, 
coalesce(s.never_decreased,'Y') as Never_Decreased,
h.max_sal_growth as max_Hike_pct,
round(a.avg_time,0) as AverageTimebwPromotions,
r.rank_by_growth
from employees e
join latest_sal l
on e.employee_id = l.employee_id
left join promotion_cte p
on e.employee_id = p.employee_id
left join sal_dec s
on e.employee_id = s.employee_id
join hike_pct h
on e.employee_id = h.employee_id
join avg_month_between_change a
on e.employee_id = a.employee_id
join ranked_growth r
on e.employee_id = r.employee_id;

/* OPTIMISED VERSION To REDUCE LENGTH OF THE CODE BLOCK */
with cte as(select *, rank() over(partition by employee_id order by change_date desc) as rn,
rank() over(partition by employee_id order by change_date) as asc_rn,
lead(salary,1) over (partition by employee_id order by change_date desc) as prev_sal,
lag(change_date,1) over (partition by employee_id order by change_date) as prev_change_date
from salary_history)

select e.employee_id,
max(case when rn =1 then salary end) as latest_sal,
sum(case when promotion ='Yes' then 1 else 0 end) as NoOfPromotions,
(case when(max(case when salary<prev_sal then 1 else 0 end)) =1 then 'N' else 'Y' end) as NeverDecreased,
max(round((salary- prev_sal)*100/ prev_sal,2)) as MaxSalaryGrowth,
rank() over(order by (max(case when rn=1 then c.salary end) / max(case when asc_rn =1 then salary end))desc,e.join_date) as SalaryGrowthRanked,
round(avg(timestampdiff(month,prev_change_date, change_date)),0)as avgTimeBw
from cte c
join employees e
on e.employee_id = c.employee_id
group by 1;
