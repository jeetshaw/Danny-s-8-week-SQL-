#Each of the following case study questions can be answered using a single SQL statement:

#1 What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spend
FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

#2 How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS number_visits
FROM sales
GROUP BY customer_id;

#3 What was the first item from the menu purchased by each customer?

WITH cte AS
(SELECT s.customer_id, m.product_name, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
FROM sales s JOIN menu m ON s.product_id = m.product_id)
SELECT DISTINCT customer_id, product_name
FROM cte
WHERE rnk = 1;

#4 What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_id, COUNT(*) AS count
FROM sales
GROUP BY product_id
ORDER BY COUNT(*) DESC
LIMIT 1;

#5 Which item was the most popular for each customer?

WITH cte AS
(SELECT s.customer_id, m.product_name, COUNT(*) AS cnt, RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rnk
FROM sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)
SELECT customer_id, product_name
FROM cte
WHERE rnk = 1;

#6 Which item (product name) was purchased first by the customer after they became a member?

WITH cte AS
(SELECT s.customer_id, m.product_name, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
FROM sales s JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date >= mem.join_date)
SELECT customer_id, product_name
FROM cte
WHERE rnk = 1;

#7 Which item was purchased just before the customer became a member?

WITH cte AS
(SELECT s.customer_id, m.product_name, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
FROM sales s JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date)
SELECT customer_id, product_name
FROM cte
WHERE rnk = 1;

#8 What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) AS total_items, SUM(me.price) AS amount_spent
FROM sales s JOIN members m ON s.customer_id = m.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

#9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte AS
(SELECT product_id,
CASE 
WHEN product_id = 1 THEN price*2
ELSE price*1
END AS points
FROM menu)
SELECT customer_id, SUM(points) AS total_points
FROM sales s LEFT JOIN cte c ON s.product_id = c.product_id
GROUP BY customer_id;

#10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte AS
(SELECT s.customer_id,
CASE
WHEN s.order_date >= m.join_date AND s.order_date < DATE_ADD(m.join_date, INTERVAL 	7 DAY) THEN me.price*2
ELSE IF(s.product_id = 1, me.price*2, me.price)
END
AS points
FROM sales s JOIN members m ON s.customer_id = m.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE s.order_date <= '2021-01-31')
SELECT customer_id, SUM(points) AS total_pts
FROM cte
GROUP BY customer_id;

## BONUS QUESTION ##

#1 Join everything to show customer_id, order_date, product_name, price, they are member or not (Y/N)

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
WHEN s.order_date >= me.join_date THEN 'Y'
ELSE 'N'
END AS member
FROM sales s JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id;

#2 ranking for members

WITH cte AS
(SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
WHEN s.order_date >= me.join_date THEN 'Y'
ELSE 'N'
END AS member
FROM sales s JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id)
SELECT *,
CASE
WHEN member = 'N' THEN NULL
WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM cte;