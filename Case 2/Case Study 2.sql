/* --------------------
   Case Study Questions
   --------------------*/
Check data type columns 

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = ‘TABLE NAME'

-- Change data type in column 

alter table pizza_names
alter column pizza_name type varchar;

Customer_orders table

-- create a new table from the customer_orders table, split the commas of the old table and insert it in the new table, drop the old table

create table n_customer_orders as (select order_id, customer_id, pizza_id, nullif(split_part(exclusions,',',1),NULL) ex1,nullif(split_part(exclusions,',',2),NULL) ex2, nullif(split_part(extras,',',1),NULL) ext1,nullif(split_part(extras,',',2),NULL) ext2, order_time 
from customer_orders);

drop table customer_orders;

-- Update all the 'null' values in the table to NULL

update n_customer_orders
set ex1=null
where ex1 in ('') OR ex1='null';

update n_customer_orders
set ex2=null
where ex2 in ('') or ext1='null';

update n_customer_orders
set ext1=null
where ext1 in ('') or ext1='null';

update n_customer_orders
set ext2=null
where ext2 in ('') or ext1='null';

-- Identify duplicates

-- select order_id,pizza_id,ex1,ex2,ext1,ext2,order_time,count(order_id)
-- from n_customer_orders group by order_id,pizza_id,ex1,ex2,ext1,ext2,order_time
-- having count(order_id)>1

-- Rank the duplicate and exclude them

create table customer_orders as (select *,rank() over(partition by customer_id,order_id,pizza_id,ex1,ex2,ext1,ext2,order_time) r1
from n_customer_orders group by customer_id, order_id,pizza_id,ex1,ex2,ext1,ext2,order_time);

-- drop the rank column and change data type of ex1, ex2, ext1, ext2 to integer

alter table customer_orders drop column r1,
alter column ex1 type int
using ex1::int,
alter column ex2 type int
using ex2::int,
alter column ext1 type int
using ext1::int,
alter column ext2 type int
using ext2::int;


-- extract numbers https://blogs.lessthandot.com/index.php/datamgmt/datadesign/extracting-numbers-with-sql-server/

Runner_orders table

-- Remove the strings from the columns distance and duration

update runner_orders
set distance = replace(replace(distance,'km',''),' ',''),
duration = replace(replace(replace(replace(duration,'minute',''),'mins',''),'s',''),' ','');

-- Replace all the 'null' with NULL and fill empty cells with NULL

update runner_orders
set distance=NULL,duration=null,pickup_time=null
where distance in ('null') OR duration in ('null') OR pickup_time in ('null');

update runner_orders
set cancellation=null
where cancellation='null';

-- Change column type pickup_time to timestamp, distance to float, duration to int and added NULLs where empty spaces in cancellation

create table n_runner_orders as (
select order_id,runner_id,pickup_time::timestamp, distance::float,duration::int,nullif(cancellation,'') cancellation from runner_orders);

-- Confirm new data type

-- sELECT *
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'runner_orders'

-- check for duplicates

-- select order_id,runner_id,pickup_time,distance,duration,cancellation,count(order_id)
-- from runner_orders group by order_id,runner_id,pickup_time,distance,duration,cancellation
-- having count(order_id)>1;


Pizza_recipes table

-- create new table and split in multiple rows

create table n_pizza_recipes as (
SELECT pizza_id, unnest(string_to_array(toppings,',')) n_toppings
FROM pizza_recipes);
                                        
-- change data type of toppings to int from varchar

alter table n_pizza_recipes
alter column n_toppings type int
using n_toppings::int;


Pizza_names table

-- Update the entry Meatlovers to Meat Lovers in the table pizza_names
                        
update pizza_names
set pizza_name='Meat Lovers'
where pizza_id=1;


Pizza_toppinngs table

-- create primary key for topping_id and reference the table pizza_recipes to it

alter table pizza_toppings add primary key (topping_id);

ALTER TABLE n_pizza_recipes 
add constraint fk_n_toppings
FOREIGN KEY (n_toppings) 
references pizza_toppings(topping_id);

-- At this point I use the following tables
-- customer_orders = customer_orders
-- n_runner_orders = runner_orders
-- n_pizza_recipes = pizza_recipes
-- runners = runners
-- pizza_names = pizza_names
-- n_pizza_recipes = pizza_recipes
-- pizza_toppings = pizza_toppings

-- All data is clean and ready to start analysis



-- Pizza Metrics
	1. How many pizzas were ordered?
	2. How many unique customer orders were made?
	3. How many successful orders were delivered by each runner?
	4. How many of each type of pizza was delivered?
	5. How many Vegetarian and Meatlovers were ordered by each customer?
	6. What was the maximum number of pizzas delivered in a single order?
	7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
	8. How many pizzas were delivered that had both exclusions and extras?
	9. What was the total volume of pizzas ordered for each hour of the day?
	10. What was the volume of orders for each day of the week?

-- 1. How many pizzas were ordered?

select count(*) "Total Ordered Pizzas" from customer_orders

-- 2. How many unique customer orders were made?

select count(distinct(customer_id)) "Unique Customers" from customer_orders

-- 3. How many successful orders were delivered by each runner?

select runner_id "Runner",count(*) "Succesful Deliveries"
from n_runner_orders
where cancellation is null
group by runner_id

-- 4. What was the average distance travelled for each customer?

select customer_id "Customer",round(avg(distance)) "Average Distance Travelled for Each Customer"
from n_runner_orders nro,customer_orders co
where nro.order_id=co.order_id
group by customer_id

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id "Customer",pizza_name "Pizza Type",count(*) "Total Ordered Pizzas"
from customer_orders co,pizza_names pn
where co.pizza_id=pn.pizza_id
group by customer_id,pizza_name
order by customer_id

-- 6. What was the maximum number of pizzas delivered in a single order?

select count(order_id) "Maximum Ordered Pizzas in One Order"
from customer_orders
group by order_id
order by "Maximum Ordered Pizzas in One Order" desc
limit 1

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?                 

select customer_id,count(distinct(order_id)) from customer_orders
                        where ex1 is not null or ex2 is not null or ext1 is not null or ext2 is not null
                                  group by customer_id
                                   
select customer_id, count(distinct(order_id)) order_with_no_change
from customer_orders
where ex1 is null and ex2 is null and ext1 is null and ext2 is null
group by customer_id;  

-- Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
                        
select extract(week from registration_date) week_number,count(*) from runners group by week_number

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
                        
select runner_id,round(avg(extract(minute from pickup_time)::numeric),2) from n_runner_orders
group by runner_id order by runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- No correlation what so ever between amount of pizzas ordered and how long it takes to prepare the pizzas.
                        
with relationship_amount_time(order_id,total_pizza,difference_time) as(
select co.order_id,count(*),extract(EPOCH from (pickup_time-order_time)/60) time_of_of_preparation_to_pickup_min
from customer_orders co,n_runner_orders nro
where co.order_id=nro.order_id                      
group by co.order_id,order_time,pickup_time
order by co.order_id)

select order_id,corr(total_pizza,difference_time)
from relationship_amount_time
group by order_id

-- 4. What was the average distance travelled for each customer?
                        
select customer_id,round(avg(distance)::numeric,2) average_time_travelled_in_min
from customer_orders co,n_runner_orders nro
where co.order_id=nro.order_id
group by customer_id

-- 5. What was the difference between the longest and shortest delivery times for all orders?
                        
select max(duration)-min(duration) from n_runner_orders

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
                        
select order_id,runner_id,round(avg(distance/(duration/60.0))::numeric,2) delivery_speed from n_runner_orders
group by order_id,runner_id
order by runner_id

-- 7. What is the successful delivery percentage for each runner?
                        
with total as (runner_total,total_am) as (select runner_id,count(*)
from n_runner_orders
group by runner_id),

success (runner_succ,total_succ) as (select runner_id,count(*)
from n_runner_orders
group by runner_id,cancellation
having cancellation is null)
                        
select runner_total runner_id,round(total_succ/sum(total_am) over (partition by runner_total),2)*100 delivery_success
from success,total
where runner_succ=runner_total


-- Ingredient Optimisation
                        
-- 1. What are the standard ingredients for each pizza?
                        
select pizza_id,string_agg(topping_name,', ' order by pizza_id) from n_pizza_recipes,pizza_toppings where n_toppings=topping_id
group by pizza_id;

-- 2. What was the most commonly added extra?
                        
-- Most common extra added was Bacon. Ordered 4 times.
                        
select topping_name,count(*)
from customer_orders,pizza_toppings
where ext1=topping_id                        
group by topping_name;
                        
select topping_name,count(*)
from customer_orders,pizza_toppings
where ext2=topping_id    
group by topping_name;
                        

-- 3. What was the most common exclusion?
                        
-- Most common exclusion was Cheese. Excluded 3 times.
                        
select topping_name,count(*)
from customer_orders,pizza_toppings
where ex1=topping_id                        
group by topping_name;
                        
select topping_name,count(*)
from customer_orders,pizza_toppings
where ex2=topping_id    
group by topping_name;






Working on
-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- *Meat Lovers
-- *Meat Lovers - Exclude Beef
-- *Meat Lovers - Extra Bacon
-- *Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
                        
with pizza_record as (select co.order_id,case
when co.pizza_id=pn.pizza_id then pn.pizza_name                        
else null end pizza_ordered,
case when ex1=topping_id then topping_name else null end toppings_ex1,
case when ex2=topping_id then topping_name else null end toppings_ex2,
case when ext1=topping_id then topping_name else null end toppings_extra1,
case when ext2=topping_id then topping_name else null end toppings_extra2
from customer_orders co,pizza_names pn,n_pizza_recipes pr, pizza_toppings pt
where co.pizza_id=pr.pizza_id
AND co.pizza_id=pn.pizza_id
AND n_toppings=topping_id)

                        
select order_id,
case when toppings_ex1=null and toppings_ex2=null and toppings_extra1=null and toppings_extra2=null then null 
when toppings_ex1!=null or toppings_ex2!=null and toppings_extra1=null and toppings_extra2=null then null then (pizza_ordered || '' || '-' || '' || 'Extra' )                
                        
                        
 else pizza_ordered                       end pizza
from pizza_record
group by order_id,pizza_ordered,toppings_ex1,toppings_ex2,toppings_extra1,toppings_extra2




-- Pricing and Ratings


-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?
                        
select '$' || sum(case when pizza_name='Vegetarian' then 10 else 12 end) revenue
from customer_orders co,n_runner_orders ro,pizza_names pr
where co.pizza_id=pr.pizza_id
and co.order_id=ro.order_id
and cancellation is null

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
                        
select '$' || sum(case when pizza_name='Vegetarian' then 10 else 12 
end)+
sum(case when ext1=4 or ext2=4 then 1 else 0 end) revenue                    
from customer_orders co,n_runner_orders ro,pizza_names pn
where co.pizza_id=pn.pizza_id
and co.order_id=ro.order_id
and cancellation is null
                        

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

drop table if exists runners_rating;
create table runners_rating (
runner_id integer references runners(runner_id),
order_id integer references customer_orders(order_id),
rating integer);


Which one works better and how to solve the issue with the unique matching constraints?
ALTER TABLE runners_rating 
add constraint fk_runner_id
FOREIGN KEY (runner_id) 
references runners(runner_id);

ALTER TABLE runners_rating 
add constraint fk_order_id
FOREIGN KEY (order_id) 
references customer_orders(order_id);




