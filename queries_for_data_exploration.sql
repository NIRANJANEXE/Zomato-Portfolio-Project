-- TOTAL AMOUNT SPENT BY EACH USER 

SELECT s.userid, sum(p.price) as price_spent_by_each_user
FROM sales s JOIN product p ON s.product_id = p.product_id
GROUP BY s.userid
ORDER BY s.userid;

-- HOW MANY DAYS EACH CUSTOMER VISITED ZOMATO

SELECT s.userid, count(s.created_date) as total_visit_days
FROM sales s
GROUP BY s.userid
ORDER BY userid;

-- WHAT WAS THE FIRST PRODUCT PURCHASED BY EACH OF THE CUSTOMER 

select * from(SELECT *, rank() over(partition by userid order by created_date) as rnk
FROM sales) s
WHERE rnk = 1;

-- WHAT IS THE MOST PURCHASED ITEM ON THE MENU AND HOW MANY TIMES WAS IT PURCHASED BY THE CUSTOMER

SELECT * FROM(SELECT product_id, count(product_id) as total_orders
FROM sales
GROUP BY product_id) b
ORDER BY total_orders DESC LIMIT 1;

select userid, count(product_id) as cnt from sales where product_id =
(SELECT product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid;

-- WHICH ITEM WAS MOST POPULAR FOR EACH OF THE CUSTOMER

select * from
(SELECT *, rank() over(partition by userid order by cnt desc) as rnk from 
(SELECT s.userid, p.product_id, count(p.product_id) as cnt
from sales s join product p on s.product_id = p.product_id
group by s.userid, p.product_id) c) d
where rnk = 1;

-- WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMERS AFTER THEY BECAME A GOLD MEMBER?

select * from
 (select a.*, rank() over(partition by userid order by created_date) as rnk from
(select gs.userid, s.created_date, s.product_id, gs.gold_signup_date
from goldusers_signup gs JOIN sales s ON gs.userid = s.userid
WHERE s.created_date >= gs.gold_signup_date) a) b where rnk = 1;

-- WHICH ITEM WAS PURCHASED BY JUST BEFORE THE CUSTOMER BECAME A GOLD MEMBER

select * from
 (select a.*, rank() over(partition by userid order by created_date DESC) as rnk from
(select gs.userid, s.created_date, s.product_id, gs.gold_signup_date
from goldusers_signup gs JOIN sales s ON gs.userid = s.userid
WHERE s.created_date <= gs.gold_signup_date) a) b where rnk = 1;

-- WHAT ARE THE TOTAL ORDERS AND AMOUNT SPENT BY EACH CUSTOMER BEFORE THEY BECAME A MEMBER

select userid, count(created_date) as order_purchased, sum(price) as total_amount from
(select a.*, p.price from
(select s.userid, s.created_date, s.product_id, gs.gold_signup_date
from sales s inner join goldusers_signup gs on s.userid = gs.userid
and s.created_date <= gs.gold_signup_date) a inner join product p on a.product_id = p.product_id) b
group by userid;

-- IF BUYING EACH PRODUCT GENERATES POINTS, FOR EG 5RS = 2 ZOMATO POINT AND EACH PRODUCT HAS DIFFERENT PURCHASING POINTS, FOR EG
-- FOR p1, 5RS = 1 ZOMATO POINT, FOR p2, 10RS = 5 ZOMATO POINTS AND FOR p3, 5RS = 1 ZOMATO POINT.
-- CALCULATE THE POINTS COLLECTED BY EACH CUSTOMER.

SELECT userid, sum(total_points)*2.5 as total_money_per_user from
(SELECT c.*, round(total_price/points, 0) as total_points from
(SELECT b.*, CASE
WHEN product_id = 1 THEN 5
WHEN product_id = 2 THEN 2
WHEN product_id = 3 THEN 5 ELSE 0
END as points FROM
	(SELECT a.userid, a.product_id, sum(price) as total_price from
	(SELECT s.*, p.price FROM sales s INNER JOIN product p ON s.product_id = p.product_id) a
	group by userid, product_id) b) c) d
    GROUP BY userid
    order by userid;
    
-- IN THE FIRST ONE YEAR AFTER A CUSTOMER JOINS THE GOLD PROGRAM (INCLUDING THEIR JOIN DATE) IRRESPECTIVE OF WHAT THE CUSTOMER 
-- HAS PURCHASED THEY EARN 5 ZOMATO POINTS FOR EVERY 10 RS SPENT WHO EARNED MORE 1 OR 3 AND WHAT WAS THEIR POINTS EARNING 
-- IN THE FIRST YEAR 

SELECT b.*, price*0.5 AS total_zomato_points FROM
(SELECT a.*, p.price from
(SELECT DISTINCT s.userid, s.created_date, s.product_id, gs.gold_signup_date from sales s inner join goldusers_signup gs 
on s.userid = gs.userid	where created_date >= gold_signup_date and created_date <= date_add(gold_signup_date, interval 1 year)) a
inner join product p on a.product_id = p.product_id
ORDER BY userid) b;

-- RANK ALL THE TRANSACTIONS OF THE CUSTOMERS

SELECT *, rank() over(partition by userid order by created_date) as rnk from sales;

-- RANK ALL THE TRANSACTIONS FOR EACH MEMBER WHENEVER THEY ARE A ZOMATO GOLD MEMBER FOR EVERY NON GOLD MEMBER MARK na.

SELECT b.*, CASE
WHEN gold_signup_date IS NOT NULL THEN rnk
ELSE 'na'
END AS rnk_final FROM
(SELECT a.*, rank() over(partition by userid order by created_date desc) as rnk from
(SELECT distinct s.userid, s.created_date, s.product_id, gs.gold_signup_date from 
sales s left join goldusers_signup gs on s.userid = gs.userid and created_date >= gold_signup_date) a) b