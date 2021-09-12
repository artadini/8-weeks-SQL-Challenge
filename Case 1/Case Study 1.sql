/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Bonus part 1, recreate the table displayed
-- Bonus part 2, recreate the table but rank all items


-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,
       sum(price)
FROM sales,
     menu
WHERE sales.product_id=menu.product_id
GROUP BY customer_id


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
       COUNT(DISTINCT(order_date))
FROM sales
GROUP BY customer_id


-- 3. What was the first item from the menu purchased by each customer?

WITH ranked AS
  (SELECT rank() over(PARTITION BY s.customer_id
                      ORDER BY order_date),
                 s.customer_id,
                 product_name
   FROM sales s,
        menu m
   WHERE s.product_id=m.product_id
   ORDER BY s.customer_id)
   
SELECT customer_id,
       product_name
FROM ranked
WHERE rank=1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name,
       count(s.product_id)
FROM sales s,
     menu m
WHERE s.product_id=m.product_id
GROUP BY product_name
ORDER BY COUNT DESC
LIMIT 1


-- 5. Which item was the most popular for each customer?

SELECT row_number() over(
                         ORDER BY count(s.product_id) DESC) AS ranking,
       customer_id,
       product_name,
       count(s.product_id)
FROM sales s,
     menu m
WHERE s.product_id=m.product_id
GROUP BY customer_id,
         product_name
ORDER BY ranking ASC
LIMIT 3


-- 6. Which item was purchased first by the customer after they became a member?

WITH ranked AS
  (SELECT rank() over(PARTITION BY s.customer_id
                      ORDER BY order_date) ranking,
                 s.customer_id,
                 product_name
   FROM sales s,
        menu m,
        members mem
   WHERE s.customer_id=mem.customer_id
     AND s.product_id=m.product_id
     AND extract(YEAR
                 FROM join_date)<=extract(YEAR
                                          FROM order_date)
     AND extract(MONTH
                 FROM join_date)<=extract(MONTH
                                          FROM order_date)
     AND extract(DAY
                 FROM join_date)<extract(DAY
                                         FROM order_date) )
SELECT customer_id,
       product_name
FROM ranked
WHERE ranking=1


-- 7. Which item was purchased just before the customer became a member?

WITH ranked AS
  (SELECT rank() over(PARTITION BY s.customer_id
                      ORDER BY order_date) AS ranking,
          s.customer_id,
          order_date,
          s.product_id,
          product_name,
          price
   FROM sales s,
        menu m,
        members mem
   WHERE s.customer_id=mem.customer_id
     AND s.product_id=m.product_id
     AND extract(YEAR
                 FROM join_date)>=extract(YEAR
                                          FROM order_date)
     AND extract(MONTH
                 FROM join_date)>=extract(MONTH
                                          FROM order_date)
     AND extract(DAY
                 FROM join_date)>extract(DAY
                                         FROM order_date) )
SELECT customer_id,
       order_date,
       product_name,
       price
FROM ranked
GROUP BY order_date,
         customer_id,
         product_name,
         price
LIMIT 2


-- 8. What is the total items and amount spent for each member before they became a member?

WITH ranked AS
  (SELECT rank() over(PARTITION BY s.customer_id
                      ORDER BY order_date) AS ranking,
          s.customer_id,
          order_date,
          s.product_id,
          product_name,
          price
   FROM sales s,
        menu m,
        members mem
   WHERE s.customer_id=mem.customer_id
     AND s.product_id=m.product_id
     AND extract(YEAR
                 FROM join_date)>=extract(YEAR
                                          FROM order_date)
     AND extract(MONTH
                 FROM join_date)>=extract(MONTH
                                          FROM order_date)
     AND extract(DAY
                 FROM join_date)>extract(DAY
                                         FROM order_date) )
SELECT customer_id,
       count(*),
       sum(price)
FROM ranked
GROUP BY customer_id
ORDER BY customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
       sum(CASE
               WHEN product_name='sushi' THEN price*10*2
               ELSE price*10
           END) AS points
FROM sales s,
     menu m
WHERE s.product_id=m.product_id
GROUP BY customer_id
ORDER BY points DESC


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH extra_points AS
  (SELECT customer_id,
          join_date,
          join_date+7 first_week
   FROM members),
     total_points AS
  (SELECT s.customer_id,
          (CASE
               WHEN extract(YEAR
                            FROM first_week)>=extract(YEAR
                                                      FROM join_date)
                    AND extract(MONTH
                                FROM first_week)>=extract(MONTH
                                                          FROM join_date)
                    AND extract(DAY
                                FROM first_week)>=extract(DAY
                                                          FROM join_date) THEN sum(price*2*10)
               ELSE sum(price*10)
           END) points
   FROM sales s,
        menu m,
        extra_points ep
   WHERE s.customer_id=ep.customer_id
     AND s.product_id=m.product_id
     AND join_date<=order_date
     AND order_date<'2021-01-31'
   GROUP BY s.customer_id,
            ep.join_date,
            s.order_date,
            ep.first_week,
            m.product_name
   ORDER BY s.customer_id)
   
SELECT customer_id,
       sum(points)
FROM total_points
GROUP BY customer_id


-- Bonus part 1, recreate the table displayed

WITH membership AS
  (SELECT s.customer_id,
          order_date,
          product_name,
          price,
          (CASE
               WHEN order_date>=join_date THEN 'Y'
               ELSE 'N'
           END) membership
   FROM sales s
   INNER JOIN menu m ON s.product_id=m.product_id
   LEFT JOIN members mem ON s.customer_id=mem.customer_id
   ORDER BY s.customer_id,
            order_date)
	    
SELECT *
FROM membership


-- Bonus part 2, recreate the table but rank all items

WITH membership AS
  (SELECT s.customer_id,
          order_date,
          product_name,
          price,
          (CASE
               WHEN order_date>=join_date THEN 'Y'
               ELSE 'N'
           END) membership
   FROM sales s
   INNER JOIN menu m ON s.product_id=m.product_id
   LEFT JOIN members mem ON s.customer_id=mem.customer_id
   ORDER BY s.customer_id,
            order_date)
SELECT *,
       CASE
           WHEN membership='Y' THEN rank() over(PARTITION BY customer_id, membership
                                                ORDER BY order_date)
           ELSE NULL
       END ranking
FROM membership

