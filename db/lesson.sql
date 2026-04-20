SELECT * FROM client;

-- to view schema of the columns
describe address;

-- to get gist details of columns
SUMMARIZE claim;
-- e.g. "If I SUMMARIZE the claim table and see a max(claim_amt) that is 10x higher than the average, what does that tell you about our insurance risk?"


-- A. JOINs — Linking Tables Together
-- Example: Combine claim data with car details
SELECT cl.id, cl.claim_amt, c.car_type
FROM claim cl
INNER JOIN car c ON cl.car_id = c.id;


-- B. Window Functions — Row-Level Analytics Without Collapsing
-- Running total of travel_time per car
-- Unlike GROUP BY (which collapses rows into groups), window functions add a calculated column to each row while keeping all rows visible.
-- PARTITION BY = "do this calculation separately for each group" ORDER BY inside OVER() = "in what order to accumulate"
SELECT id, car_id, travel_time,
    SUM(travel_time) OVER (PARTITION BY car_id ORDER BY id) AS running_total
FROM claim;


-- C. CTEs — Breaking Complex Queries into Steps
-- A Common Table Expression (CTE) is a named, temporary result set you define at the top of a query and reference like a table. It makes complex logic readable.
WITH avg_resale AS 
(
    SELECT car_use, AVG(resale_value) AS avg_val
    FROM car
    GROUP BY car_use
)
SELECT  car.id, car.resale_value, car.car_use
FROM    car
JOIN    avg_resale ON car.car_use = avg_resale.car_use
WHERE   car.resale_value < avg_resale.avg_val
;


SELECT count(*) FROM claim; -- 1468 rows
SELECT count(*) FROM car; -- 1000 rows

-- Returns only the rows that match in both tables.
SELECT * 
FROM claim
inner join car
on claim.car_id = car.id
;

SELECT count(*) -- 1468 rows
FROM claim 
inner join car
on claim.car_id = car.id
;

-- Returns all rows from the left table, and the matching rows from the right table.
SELECT * 
FROM claim
LEFT join car ON claim.car_id = car.id
;

SELECT count(*)
FROM claim
LEFT JOIN car ON claim.car_id = car.id
;

-- Returns all rows from the right table, and the matching rows from the left table.
SELECT * 
FROM claim
RIGHT join car ON claim.car_id = car.id
;

SELECT count(*) -- -- 1707 rows
FROM claim
RIGHT JOIN car ON claim.car_id = car.id
;

-- Returns all rows from both tables.
SELECT *
FROM claim
FULL JOIN car ON claim.car_id = car.id
;

SELECT count(*) -- 1707 rows
FROM claim
FULL JOIN car ON claim.car_id = car.id
;


-- UNION removes duplicate rows. Use UNION ALL to keep duplicates.
-- Example syntax (not for this database)
--SELECT * FROM employees
--UNION
--SELECT * FROM contractors;


-- Exercise : Create a master report of every claim. Include the client's name, their car type, and the city they live in.
SELECT *
FROM claim
inner join client ON client.id = claim.client_id
inner join car ON car.id = claim.car_id
inner join address ON address.id = client.address_id
;


-- WINDOW functions (SUM)
-- Running total is a cumulative sum: each row shows the sum of all rows from the start up to that row, in a defined order.
SELECT
  id, claim_amt,
  SUM(claim_amt) OVER (ORDER BY id) AS running_total
FROM claim
;

-- partition by car
SELECT id, car_id, claim_amt, SUM(claim_amt) OVER (PARTITION BY car_id ORDER BY id) AS running_total
FROM claim
ORDER BY car_id
;

-- Exercise : Calculate a running total of insurance payouts over time (ordered by claim_date).
SELECT id, claim_date, claim_amt, sum(claim_amt) over (ORDER BY cast(claim_date as date)) as running_total
FROM claim
ORDER BY claim_date
;


-- WINDOW functions (RANK)
SELECT id, car_id, claim_amt, RANK() OVER (PARTITION BY car_id ORDER BY claim_amt DESC) AS rank
FROM claim;


-- WINDOW functions (QUALIFY)
SELECT claim.id, car.car_type, claim.claim_amt, car.id
FROM claim
JOIN car ON claim.car_id = car.id
-- check only car.id = 999
WHERE car.id = 999
;

SELECT claim.id, car.car_type, claim.claim_amt, car.id, RANK() over (partition by car_type ORDER BY claim_amt DESC) AS rank
FROM claim
JOIN car ON claim.car_id = car.id
QUALIFY rank = 1
ORDER BY claim.claim_amt DESC
;


-- Nested Logic / Subqueries
-- A subquery is a query nested inside another query.
-- Exercise : To find the cars that have been involved in a claim:

SELECT count(*) FROM car; -- 1000 unique cars
SELECT count(*) FROM claim; -- 1468 unique claims
SELECT DISTINCT car_id FROM claim; -- 761 cars with claims. so pass this as subquery to a main query to fetch only the columns i want to see 

SELECT id, car_type
FROM car
WHERE id in (SELECT DISTINCT car_id FROM claim)
;

-- Correlated Subquery — the inner query references the outer query:
-- Exercise : To find the cars that have been involved in a claim, and the claim amount is greater than 10% of the car's resale value:

SELECT id, resale_value, car_type
FROM car
WHERE id IN 
(
  -- internal query on claim
  SELECT DISTINCT car_id
  FROM claim
  WHERE claim_amt > 0.1 * car.resale_value
  )
;

-- EXISTS operator: - to check if a subquery returns any rows. returns 'Yes' the moment there is data, so this commands lets the script run faster!
-- Exercise : To find the cars that have been involved in a claim:
SELECT id, resale_value, car_type
FROM car
WHERE EXISTS 
(
  SELECT DISTINCT car_id
  FROM claim
  WHERE claim.car_id = car.id
)
;


-- Exercise : to list down the cars, which have average claims, higher than the overall average claim amount
SELECT car_id, avg_claim_amt
FROM 
(
    -- inner query finding average claim amt for every single car in the claims table, and naming it 'avg_claims'
  SELECT car_id, AVG(claim_amt) AS avg_claim_amt
  FROM claim
  GROUP BY car_id
) 
AS avg_claims
    -- global claim average amount
WHERE avg_claim_amt > 
(
  SELECT AVG(claim_amt)
  FROM claim
)
;


-- Common Table Expressions (CTEs)
-- A CTE is a temporary named result set created within a query. Use CTEs when you need to reference the same query multiple times, or to improve readability.

WITH avg_claims AS 
(
    -- this is basically the same inner query as above, but writing it using WITH and putting it ontop
  SELECT car_id, AVG(claim_amt) AS avg_claim_amt
  FROM claim
  GROUP BY car_id
)
    -- followed by the main query
SELECT car_id, avg_claim_amt
FROM avg_claims
WHERE avg_claim_amt > (SELECT AVG(claim_amt) FROM claim)
;


-- Exercise : Create a CTE that finds the total claim amount for each car. Then use this CTE to find the cars with a total claim amount greater than the average.
WITH total_claims AS 
(
    -- CTE that finds the total claim amount for each car
    SELECT car_id, sum(claim_amt) AS total_claim_amt_percar
    FROM claim
    GROUP BY car_id
)
SELECT car_id, total_claim_amt_percar
FROM total_claims
WHERE total_claim_amt_percar > 
    -- cars with a total claim amount greater than the average claim
    (SELECT avg(total_claim_amt_percar) FROM total_claims)
ORDER BY total_claim_amt_percar DESC
;


-- Exercise : Create a report that shows each claim, the client's name, the car type, and the city. 
--          Additionally, include a column showing the rank of each claim by claim amount for each car type. 
--          Filter to show only the top 3 claims for each car type.

-- table that shows each claim, the client's name, the car type, and the city
SELECT 
    claim.id,
    claim.claim_amt,
    client.first_name,
    client.last_name,
    car.car_type,
    address.city
FROM    claim
join    car on car.id = claim.car_id
join    client on client.id = claim.client_id
join    address on address.id = client.address_id
;

SELECT 
    claim.id,
    claim.claim_amt,
    client.first_name,
    client.last_name,
    car.car_type,
    address.city,
    -- this is creating column showing the rank of each claim by claim amount for each car type.
    rank() over (partition by car.car_type ORDER BY claim.claim_amt DESC) as ranking
FROM    claim
join    car on car.id = claim.car_id
join    client on client.id = claim.client_id
join    address on address.id = client.address_id
ORDER   BY  
    car_type, 
    ranking
;

WITH ranked as --< put the alias here into CTE, use WITH, then move the SELECT below within the CTE
(
    SELECT
    claim.id,
    claim.claim_amt,
    client.first_name,
    client.last_name,
    car.car_type,
    address.city,
    -- this is creating column showing the rank of each claim by claim amount for each car type.
    rank() over (partition by car.car_type ORDER BY claim.claim_amt DESC) as ranking
FROM    claim
join    car on car.id = claim.car_id
join    client on client.id = claim.client_id
join    address on address.id = client.address_id
ORDER   BY  
    car_type, 
    ranking
)
SELECT  *
FROM    ranked --< then to filer, wrap all the above into an alias
WHERE   ranking <= 3
ORDER BY
    car_type,
    ranking
;