use practice;
select * from df_orders;

-- find top 10 highest reveue generating products
select  product_id, sum(sell_price) as sell_price from df_orders
group by product_id
order by 2 desc
limit 10;

-- find top 5 highest selling products in each region

WITH ranked_products AS (
  SELECT
    product_id,
    region,
    SUM(sell_price) AS sell_price,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sell_price) DESC) AS rn
  FROM df_orders
  GROUP BY product_id, region
)

SELECT rn as sno,
  max(CASE WHEN region = 'East' THEN product_id END )AS East_top_products,
  max(CASE WHEN region = 'West' THEN product_id END) AS West_top_products,
  max(CASE WHEN region = 'Central' THEN product_id END) AS North_top_products,
  max(CASE WHEN region = 'South' THEN product_id END) AS South_top_products
FROM ranked_products
WHERE rn <= 5
GROUP BY rn
ORDER BY rn;


-- find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023 
with cte as (
select year(order_date) as order_year,month(order_date) as order_month,
sum(sell_price) as sales
from df_orders
group by year(order_date),month(order_date))

select order_month
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by order_month
order by order_month;
-- for each category which month had highest sales 
with cte as(
select category , month(order_date) as mn, sum(sell_price) as amt
from df_orders 
group by 1,2)
select category , month from(
select category, mn as month, amt as amount ,rank() over(partition by category order by amt desc) as rn 
from cte) a where rn=1;

-- which sub category had highest growth by profit in 2023 compare to 2022
with cte as(
select sub_category, sum(sell_price) as sales, month(order_date) as order_month, year(order_date) as order_year
from df_orders
group by 1 ,3,4)
select sub_category ,
sum(case when order_year=2023 then sales else 0 end) - 
sum(case when order_year=2022 then sales else 0 end) as growth
from cte 
group by 1
order by 2 desc;
