-- Scenario: You are the Lead Data Analyst for "SafeDrive Insurance". The CEO suspects that certain car types in specific cities are disproportionately expensive.
-- Your Task: Create a comprehensive SQL report that answers the following in a single script (using CTEs):
--    Market Comparison: For every claim, show the claim_amt alongside the average claim amount for that specific car_type.
--    Risk Ranking: Within each state, rank the clients by their total claim amounts.
--    Efficiency: Only show the top 2 highest-claiming clients per state.
--    Final Output: The table should include: Client Name, State, Car Type, Total Claimed, State Rank.


-- REQUIREMENT 1: Market Comparison
-- Calculate average claim amount for each car_type to establish market baseline

--  SELECT
--      claim.id,
--      claim.claim_amt,
--      claim.car_id,
--      claim.client_id,
--      car.car_type,
        -- use window function to find average claim amount
--      avg(claim.claim_amt) over (partition by car.car_type) AS avg_claim_by_car_type
--  FROM claim
--  join car on car.id = claim.car_id
--  ;

-- because use CTE, so encompass this script using WITH

WITH market_comparison AS 
(
    SELECT
        claim.id,
        claim.claim_amt,
        claim.car_id,
        claim.client_id,
        car.car_type,
        -- use window function to find average claim amount
        avg(claim.claim_amt) over (partition by car.car_type) AS avg_claim_by_car_type
    FROM claim
    join car on car.id = claim.car_id
),

-- REQUIREMENT 2: Aggregate total claims per client
-- Aggregates total claims per client using GROUP BY client_id, car_type to prepare for ranking analysis
client_claim_total AS 
(
    SELECT
        mc.client_id,
        mc.car_type,
        -- to get sum of claim amounts for each client
        sum(mc.claim_amt) as total_claim
    FROM market_comparison mc
    GROUP BY
        mc.client_id,
        mc.car_type
),

-- Joins client and address tables to retrieve full names and state, concatenating first and last names for readability
client_with_details AS 
(
    SELECT
        client.id,
        client.first_name ||''|| client.last_name as client_name,
        address.state,
        cct.car_type,
        cct.total_claim
    FROM client_claim_total cct
    join client on client.id = cct.client_id
    join address on address.id = client.address_id
),

-- Rank clients within each state by their total claim amounts
ranked_clients AS 
(
    SELECT
        client_name,
        state,
        car_type,
        total_claim,
        -- window function to rank (highest claim = rank 1)
        rank () over (partition by state ORDER by total_claim DESC) as state_rank
    FROM client_with_details cwd
)

-- REQUIREMENT 3 & 4: Efficiency Filter + Final Output
-- Show only top 2 highest-claiming clients per state
SELECT
    client_name,
    state,
    car_type,
    state_rank,
    total_claim
FROM ranked_clients
-- filter to restrict output to top 2 clients per state
WHERE state_rank <= 2
-- ensures logical presentation for executive review
ORDER BY state, state_rank
;
-- This solution directly addresses the CEO's concern about disproportionately expensive car types in specific cities by providing actionable insights into high-risk client profiles across geographic regions.