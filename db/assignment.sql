-- Question 1 
-- Using the claim and car tables, write a SQL query to return a table containing id, claim_date, travel_time, claim_amt from claim, and car_type, car_use from car. Use an appropriate join based on the car_id.

SELECT
    claim.id,
    claim.claim_date,
    claim.travel_time,
    claim.claim_amt,
    car.car_type,
    car.car_use
FROM
    claim
join car on car.id = claim.car_id
;


-- Question 2
-- Write a SQL query to compute the running total of the travel_time column for each car_id in the claim table. The resulting table should contain id, car_id, travel_time, running_total.

SELECT
    id,
    car_id,
    travel_time,
    -- for each car_id, so use window fuction i.e. partition by
    sum (travel_time) over (partition by car_id) as running_total
FROM
    claim
;


-- Question 3
-- Using a Common Table Expression (CTE), write a SQL query to return a table containing id, resale_value, car_use from car, where the car resale value is less than the average resale value for the car use.

-- main return table
SELECT
    id,
    resale_value,
    car_use
FROM
    car

-- sub query
SELECT
    car_use,
    -- to get the average resale value
    avg(resale_value) as avg_resale_value
FROM
    car
GROUP BY
    car_use
    
-- now put them together in a CTE, so need to use WITH
WITH avgresale AS
    (
    SELECT
        car_use,
        -- to get the average resale value
        avg(resale_value) as avg_resale_value
    FROM car
    GROUP BY
        car_use
    )
SELECT
    car.id,
    car.resale_value,
    car.car_use
FROM car
-- now need to show only where the car resale value is less than the average resale value
join avgresale on avgresale.car_use = car.car_use
WHERE car.resale_value < avgresale.avg_resale_value
;