-- Monday Coffee -- Data Analysis

select * from city;
select * from products;
select * from customers;
select * from sales;

-- Reports and Analysis

-- Q1) Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does

 Select 
	 city_name,
	 round((population * 0.25)/1000000,2) as coffee_conusmers_in_millions,
	 city_rank
 from city
 order  by 2 desc


 --Q2) Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

Select *,
	extract (year from sale_date) as year,
	extract (quarter from sale_date) as qtr
from sales
where 
	extract( year from sale_date) = 2023
	and extract (quarter from sale_date) = 4

Select 
	ci.city_name,
	sum(total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where 
	extract( year from s.sale_date) = 2023
	and 
	extract (quarter from s.sale_date) = 4
group by 1
order by 2 desc

--Q3) Sales Count for Each Product
--How many units of each coffee product have been sold?

Select 
p.product_name,
count(s.sale_id) as total_orders
from products as p
left join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc


-- Q4) Average Sales Amount per City
--What is the average sales amount per customer in each city?

 -- City and Total sales
 -- No of customers in each of the city

 Select 
	ci.city_name,
	sum(total) as total_revenue,
	count(distinct s.customer_id) as total_cx,
	round(sum(s.total):: numeric/count(distinct s.customer_id) :: numeric,2) as avg_sale_pr_cx
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc


--Q5) City Population and Coffee Consumers (25%)
--Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table AS (
    SELECT
        city_name,
        ROUND((population * 0.25 / 1000000), 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT
    ct.city_name,
    ct.coffee_consumers AS coffee_consumer_in_millions,
    cst.unique_cx
FROM city_table AS ct
JOIN customers_table AS cst
    ON ct.city_name = cst.city_name;

--Q6) Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
select *
from-- table
(select 
	Ci.city_name,
	p.product_name,
	count(s.sale_id) as total_orders,
	dense_rank () over(partition by ci.city_name order by count(s.sale_id)  desc) as rank
 From sales as s
 join products as p
 on s.product_id = p.product_id
 join customers as c
 on c.customer_id = s.customer_id
 join city as ci
 on ci.city_id = c.city_id
 group by 1,2
 --order by 1, 3 Desc
 ) as t1
where rank <= 3

 --Q7) Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

select * from products

select
	ci.city_name,
	count(distinct c.customer_id) as unique_cx
from city as ci
left join
customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where 
 s.product_id in(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1


--q8) Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

-- Conclusions
WITH city_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric,
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent
    FROM city
)
SELECT
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx ,
    ct.avg_sale_pr_cx,
	round( cr.estimated_rent::numeric/ ct.total_cx::numeric,2) as avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name;
ORDER BY 4 desc



--Q9)Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)  
-- by each city

with
monthly_sales
as
(
    SELECT
        ci.city_name,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, year, month
	order by 1,3,2
),
growth_ratio
as
(		    SELECT
		    city_name,
		    month,
		    year,
		    total_sale AS cr_month_sale,
		    LAG(total_sale, 1) OVER (
		        PARTITION BY city_name
		        ORDER BY year, month
		    ) AS last_month_sale
		FROM monthly_sales
)

select
city_name,
month,
year,
cr_month_sale,
last_month_sale,
round(
     (cr_month_sale - last_month_sale):: numeric/last_month_sale::numeric * 100,2) as growth_ratio


from growth_ratio
where last_month_Sale is not null


--Q10) Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consume

WITH city_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        SUM(s.total) AS total_revenue,
        ROUND(
            SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric,
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 5)
            AS estimated_coffee_consumers_in_millions
    FROM city
)
SELECT
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumers_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::numeric / ct.total_cx::numeric,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
--Recomendation
city 1: Pune
	1.Avg rent per cx is very less, 
	2.highest total revenue, 
	3.avg_sale per cx is also high

City 2: Delhi
	1.Highest estimated coffee consumer which is 7.7M
	2.Highest total cx which is 68
	3.avg rent per cx 330 (still under 500)

City 3: Jaipur
	1. Higest cx no which is 69
	2. avg rent per cx is very less 156
	3.avg_sale per cx is better which is at 11.6k
