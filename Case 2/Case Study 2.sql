/* --------------------
   Case Study Questions
   --------------------
   
 In this particular case study much data standarization and cleaning had to be done before running a proper SQL sentence.
 This cleaning has been represented below. Afterwards the questions are answered.

 A. Pizza Metrics
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

 B. Runner and Customer Experience
  1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
  2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
  3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
  4. What was the average distance travelled for each customer?
  5. What was the difference between the longest and shortest delivery times for all orders?
  6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
  7. What is the successful delivery percentage for each runner?

 C. Ingredient Optimisation
  1. What are the standard ingredients for each pizza?
  2. What was the most commonly added extra?
  3. What was the most common exclusion?
  4. Generate an order item for each record in the customers_orders table in the format of one of the following:
  	*Meat Lovers
	*Meat Lovers - Exclude Beef
	*Meat Lovers - Extra Bacon
	*Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

 D. Pricing and Ratings
  1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
     how much money has Pizza Runner made so far if there are no delivery fees?
  2. What if there was an additional $1 charge for any pizza extras?
     Add cheese is $1 extra */

-- Check data type columns 

SELECT 
  * 
FROM 
  INFORMATION_SCHEMA.COLUMNS 
WHERE 
  TABLE_NAME = 'TABLE NAME';

-- Change data type in column 

ALTER TABLE pizza_names ALTER COLUMN pizza_name TYPE varchar;

-- Customer_orders table

-- Create a new table from the customer_orders table, split the commas of the old table and insert it in the new table, drop the old table

CREATE TABLE n_customer_orders AS
  (SELECT order_id,
          customer_id,
          pizza_id,
          NULLIF(Split_part(exclusions, ',', 1), NULL) ex1,
          NULLIF(Split_part(exclusions, ',', 2), NULL) ex2,
          NULLIF(Split_part(extras, ',', 1), NULL)     ext1,
          NULLIF(Split_part(extras, ',', 2), NULL)     ext2,
          order_time
   FROM   customer_orders);

DROP TABLE customer_orders;

-- Update all the 'null' values in the table to NULL

UPDATE n_customer_orders
SET    ex1 = NULL
WHERE  ex1 IN ( '' )
        OR ex1 = 'null';

UPDATE n_customer_orders
SET    ex2 = NULL
WHERE  ex2 IN ( '' )
        OR ext1 = 'null';

UPDATE n_customer_orders
SET    ext1 = NULL
WHERE  ext1 IN ( '' )
        OR ext1 = 'null';

UPDATE n_customer_orders
SET    ext2 = NULL
WHERE  ext2 IN ( '' )
        OR ext1 = 'null'; 

-- Identify duplicates

/* SELECT order_id,
       pizza_id,
       ex1,
       ex2,
       ext1,
       ext2,
       order_time,
       Count(order_id)
FROM   n_customer_orders
GROUP  BY order_id,
          pizza_id,
          ex1,
          ex2,
          ext1,
          ext2,
          order_time
HAVING Count(order_id) > 1 */

-- Rank the duplicate and exclude them

CREATE TABLE customer_orders AS
  (SELECT *,
          Rank()
            OVER(
              partition BY customer_id, order_id, pizza_id, ex1, ex2, ext1, ext2
            ,
            order_time) r1
   FROM   n_customer_orders
   GROUP  BY customer_id,
             order_id,
             pizza_id,
             ex1,
             ex2,
             ext1,
             ext2,
             order_time); 

-- Drop the rank column and change data type of ex1, ex2, ext1, ext2 to integer

ALTER TABLE customer_orders DROP COLUMN r1,
            alter column ex1 type  int
using       ex1::                  int,
            ALTER COLUMN ex2 type  int
using       ex2::                  int,
            ALTER COLUMN ext1 type int
using       ext1::                 int,
            ALTER COLUMN ext2 type int
using       ext2::                 int;

-- Runner_orders table

-- Remove the strings from the columns distance and duration

UPDATE runner_orders
SET    distance = Replace(Replace(distance, 'km', ''), ' ', ''),
       duration = Replace(Replace(Replace(Replace(duration, 'minute', ''),
                                  'mins', ''),
                          's', ''),
                             ' ', ''); 

-- Replace all the 'null' with NULL and fill empty cells with NULL

UPDATE runner_orders
SET    distance = NULL,
       duration = NULL,
       pickup_time = NULL
WHERE  distance IN ( 'null' )
        OR duration IN ( 'null' )
        OR pickup_time IN ( 'null' );

UPDATE runner_orders
SET    cancellation = NULL
WHERE  cancellation = 'null'; 

-- Change column type pickup_time to timestamp, distance to float, duration to int and added NULLs where empty spaces in cancellation

CREATE TABLE n_runner_orders AS
  (SELECT order_id,
          runner_id,
          pickup_time :: timestamp,
          distance :: FLOAT,
          duration :: INT,
          Nullif(cancellation, '') cancellation
   FROM   runner_orders); 

-- Confirm new data type

/* SELECT *
FROM   information_schema.columns
WHERE  table_name = 'runner_orders' 

Check for duplicates

SELECT order_id,
       runner_id,
       pickup_time,
       distance,
       duration,
       cancellation,
       Count(order_id)
FROM   runner_orders
GROUP  BY order_id,
          runner_id,
          pickup_time,
          distance,
          duration,
          cancellation
HAVING Count(order_id) > 1; */

-- Pizza_recipes table

-- Create new table and split in multiple rows

CREATE TABLE n_pizza_recipes AS
  (SELECT pizza_id,
          Unnest(String_to_array(toppings, ',')) n_toppings
   FROM   pizza_recipes); 
                                        
-- Change data type of toppings to int from varchar

ALTER TABLE n_pizza_recipes ALTER COLUMN n_toppings TYPE int
using       n_toppings::                                 int;

-- Pizza_names table

-- Update the entry Meatlovers to Meat Lovers in the table pizza_names
                        
UPDATE pizza_names
SET    pizza_name = 'Meat Lovers'
WHERE  pizza_id = 1; 

-- Pizza_toppinngs table

-- Create primary key for topping_id and reference the table pizza_recipes to it

ALTER TABLE pizza_toppings
  ADD PRIMARY KEY (topping_id);

ALTER TABLE n_pizza_recipes
  ADD CONSTRAINT fk_n_toppings FOREIGN KEY (n_toppings) REFERENCES
  pizza_toppings(topping_id); 

/* Following tables have been created
customer_orders = customer_orders
n_runner_orders = runner_orders
n_pizza_recipes = pizza_recipes
runners = runners
pizza_names = pizza_names
n_pizza_recipes = pizza_recipes
pizza_toppings = pizza_toppings

All data is clean and ready to start analysis

A. Pizza Metrics
1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week? */

-- 1. How many pizzas were ordered?

SELECT Count(*) "Total Ordered Pizzas"
FROM   customer_orders;

-- 2. How many unique customer orders were made?

SELECT Count(DISTINCT( customer_id )) "Unique Customers"
FROM   customer_orders;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id "Runner",
       Count(*)  "Succesful Deliveries"
FROM   n_runner_orders
WHERE  cancellation IS NULL
GROUP  BY runner_id;

-- 4. What was the average distance travelled for each customer?

SELECT customer_id          "Customer",
       Round(Avg(distance)) "Average Distance Travelled for Each Customer"
FROM   n_runner_orders nro,
       customer_orders co
WHERE  nro.order_id = co.order_id
GROUP  BY customer_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id "Customer",
       pizza_name  "Pizza Type",
       Count(*)    "Total Ordered Pizzas"
FROM   customer_orders co,
       pizza_names pn
WHERE  co.pizza_id = pn.pizza_id
GROUP  BY customer_id,
          pizza_name
ORDER  BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT Count(order_id) "Maximum Ordered Pizzas in One Order"
FROM   customer_orders
GROUP  BY order_id
ORDER  BY "maximum ordered pizzas in one order" DESC
LIMIT  1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?                 

SELECT customer_id,
       Count(DISTINCT( order_id ))
FROM   customer_orders
WHERE  ex1 IS NOT NULL
        OR ex2 IS NOT NULL
        OR ext1 IS NOT NULL
        OR ext2 IS NOT NULL
GROUP  BY customer_id;

SELECT customer_id,
       Count(DISTINCT( order_id )) order_with_no_change
FROM   customer_orders
WHERE  ex1 IS NULL
       AND ex2 IS NULL
       AND ext1 IS NULL
       AND ext2 IS NULL
GROUP  BY customer_id; 

-- B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
                        
SELECT Extract(week FROM registration_date) week_number,
       Count(*)
FROM   runners
GROUP  BY week_number;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
                        
SELECT runner_id,
       Round(Avg(Extract(minute FROM pickup_time) :: NUMERIC), 2)
FROM   n_runner_orders
GROUP  BY runner_id
ORDER  BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- No correlation what so ever between amount of pizzas ordered and how long it takes to prepare the pizzas.
                        
WITH relationship_amount_time(order_id, total_pizza, difference_time)
     AS (SELECT co.order_id,
                Count(*),
                Extract(epoch FROM ( pickup_time - order_time ) / 60)
                time_of_of_preparation_to_pickup_min
         FROM   customer_orders co,
                n_runner_orders nro
         WHERE  co.order_id = nro.order_id
         GROUP  BY co.order_id,
                   order_time,
                   pickup_time
         ORDER  BY co.order_id);
	 
SELECT order_id,
       Corr(total_pizza, difference_time)
FROM   relationship_amount_time
GROUP  BY order_id;

-- 4. What was the average distance travelled for each customer?
                        
SELECT customer_id,
       Round(Avg(distance) :: NUMERIC, 2) average_time_travelled_in_min
FROM   customer_orders co,
       n_runner_orders nro
WHERE  co.order_id = nro.order_id
GROUP  BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
                        
SELECT Max(duration) - Min(duration)
FROM   n_runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
                        
SELECT order_id,
       runner_id,
       Round(Avg(distance / ( duration / 60.0 )) :: NUMERIC, 2) delivery_speed
FROM   n_runner_orders
GROUP  BY order_id,
          runner_id
ORDER  BY runner_id;

-- 7. What is the successful delivery percentage for each runner?
                        
WITH total AS (runner_total,total_am) AS
(
         SELECT   runner_id,
                  count(*)
         FROM     n_runner_orders
         GROUP BY runner_id), success (runner_succ,total_succ) AS
(
         SELECT   runner_id,
                  count(*)
         FROM     n_runner_orders
         GROUP BY runner_id,
                  cancellation
         HAVING   cancellation IS NULL);
	 
SELECT runner_total                                                           runner_id,
       round(total_succ/sum(total_am) OVER (partition BY runner_total),2)*100 delivery_success
FROM   success,
       total
WHERE  runner_succ=runner_total;

-- C. Ingredient Optimisation
                        
-- 1. What are the standard ingredients for each pizza?
                        
SELECT   pizza_id,
         string_agg(topping_name,', ' order BY pizza_id)
FROM     n_pizza_recipes,
         pizza_toppings
WHERE    n_toppings=topping_id
GROUP BY pizza_id;

-- 2. What was the most commonly added extra?
                        
-- Most common extra added was Bacon. Ordered 4 times.
                        
SELECT topping_name,
       Count(*)
FROM   customer_orders,
       pizza_toppings
WHERE  ext1 = topping_id
GROUP  BY topping_name;

SELECT topping_name,
       Count(*)
FROM   customer_orders,
       pizza_toppings
WHERE  ext2 = topping_id
GROUP  BY topping_name; 
                        
-- 3. What was the most common exclusion?
                        
-- Most common exclusion was Cheese. Excluded 3 times.
                        
SELECT topping_name,
       Count(*)
FROM   customer_orders,
       pizza_toppings
WHERE  ex1 = topping_id
GROUP  BY topping_name;

SELECT topping_name,
       Count(*)
FROM   customer_orders,
       pizza_toppings
WHERE  ex2 = topping_id
GROUP  BY topping_name; 

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- *Meat Lovers
-- *Meat Lovers - Exclude Beef
-- *Meat Lovers - Extra Bacon
-- *Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
                        
WITH pizza_record AS
(
       SELECT co.order_id,
              CASE
                     WHEN co.pizza_id=pn.pizza_id THEN pn.pizza_name
                     ELSE NULL
              END pizza_ordered,
              CASE
                     WHEN ex1=topping_id THEN topping_name
                     ELSE NULL
              END toppings_ex1,
              CASE
                     WHEN ex2=topping_id THEN topping_name
                     ELSE NULL
              END toppings_ex2,
              CASE
                     WHEN ext1=topping_id THEN topping_name
                     ELSE NULL
              END toppings_extra1,
              CASE
                     WHEN ext2=topping_id THEN topping_name
                     ELSE NULL
              END toppings_extra2
       FROM   customer_orders co,
              pizza_names pn,
              n_pizza_recipes pr,
              pizza_toppings pt
       WHERE  co.pizza_id=pr.pizza_id
       AND    co.pizza_id=pn.pizza_id
       AND    n_toppings=topping_id);
       
SELECT   order_id,
         CASE
                  WHEN toppings_ex1=NULL
                  AND      toppings_ex2=NULL
                  AND      toppings_extra1=NULL
                  AND      toppings_extra2=NULL THEN NULL
                  WHEN toppings_ex1!=NULL
                  OR       toppings_ex2!=NULL
                  AND      toppings_extra1=NULL
                  AND      toppings_extra2=NULL THEN NULL then (pizza_ordered
                                    || ''
                                    || '-'
                                    || ''
                                    || 'Extra' )
                  ELSE pizza_ordered
         END pizza
FROM     pizza_record
GROUP BY order_id,
         pizza_ordered,
         toppings_ex1,
         toppings_ex2,
         toppings_extra1,
         toppings_extra2;

-- D. Pricing and Ratings

--  1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
--      how much money has Pizza Runner made so far if there are no delivery fees?
                        
SELECT '$'
       || Sum(CASE
                WHEN pizza_name = 'Vegetarian' THEN 10
                ELSE 12
              END) revenue
FROM   customer_orders co,
       n_runner_orders ro,
       pizza_names pr
WHERE  co.pizza_id = pr.pizza_id
       AND co.order_id = ro.order_id
       AND cancellation IS NULL;

-- 2. What if there was an additional $1 charge for any pizza extras?
--      Add cheese is $1 extra
                        
SELECT '$'
       || Sum(CASE WHEN pizza_name='Vegetarian' THEN 10 ELSE 12 END) + Sum(CASE
          WHEN
          ext1=
          4 OR ext2=4 THEN 1 ELSE 0 END) revenue
FROM   customer_orders co,
       n_runner_orders ro,
       pizza_names pn
WHERE  co.pizza_id = pn.pizza_id
       AND co.order_id = ro.order_id
       AND cancellation IS NULL;
                    



  
  




