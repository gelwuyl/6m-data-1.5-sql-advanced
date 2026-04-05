# Assignment

## Brief

Write the SQL statements for the following questions.

## Instructions

Write your SQL answers in the code blocks below each question. Check your work against the solution key at the bottom. To share your work, post in **#peer-reviews** on Discord. For questions, post in **#questions**.

### Question 1

Using the `claim` and `car` tables, write a SQL query to return a table containing `id, claim_date, travel_time, claim_amt` from `claim`, and `car_type, car_use` from `car`. Use an appropriate join based on the `car_id`.

Answer:

```sql

```

### Question 2

Write a SQL query to compute the running total of the `travel_time` column for each `car_id` in the `claim` table. The resulting table should contain `id, car_id, travel_time, running_total`.

Answer:

```sql

```

### Question 3

Using a Common Table Expression (CTE), write a SQL query to return a table containing `id, resale_value, car_use` from `car`, where the car resale value is less than the average resale value for the car use.

Answer:

```sql

```

# **Level Up: The Insurance Auditor Project**

Scenario:  
You are the Lead Data Analyst for "SafeDrive Insurance". The CEO suspects that certain car types in specific cities are disproportionately expensive.  
Your Task:  
Create a comprehensive SQL report that answers the following in a single script (using CTEs):

1. **Market Comparison:** For every claim, show the claim\_amt alongside the **average claim amount for that specific car\_type**.  
2. **Risk Ranking:** Within each state, rank the clients by their total claim amounts.  
3. **Efficiency:** Only show the **top 2** highest-claiming clients per state.  
4. **Final Output:** The table should include: Client Name, State, Car Type, Total Claimed, State Rank.

**Submission:** Save your work as a `.sql` file with comments explaining your logic. Share in **#peer-reviews** on Discord, or keep it in your own notes if self-studying.

---

## **✅ Solutions**

*Attempt all questions before expanding the solutions below.*

<details>
<summary>Click to reveal — Questions 1–3 Solutions</summary>

### Question 1

```sql
SELECT 
    cl.id, 
    cl.claim_date, 
    cl.travel_time, 
    cl.claim_amt,
    c.car_type, 
    c.car_use 
FROM claim cl
INNER JOIN car c ON cl.car_id = c.id;
```

### Question 2

```sql
SELECT 
    id,
    car_id,
    travel_time,
    SUM(travel_time) OVER (PARTITION BY car_id ORDER BY id) AS running_total
FROM claim;
```

### Question 3

```sql
WITH AvgResale AS (
    SELECT 
        car_use,
        AVG(resale_value) AS avg_resale_value
    FROM car
    GROUP BY car_use
)
SELECT 
    c.id,
    c.resale_value,
    c.car_use
FROM car c
JOIN AvgResale a ON c.car_use = a.car_use
WHERE c.resale_value < a.avg_resale_value;
```

</details>

<details>
<summary>Click to reveal — Level Up: Insurance Auditor Project Solution</summary>

### Complete SQL Solution for Insurance Auditor Project

```sql
-- =============================================================================
-- SafeDrive Insurance: Comprehensive Claims Analysis Report
-- Lead Data Analyst: Insurance Auditor Project
-- Purpose: Identify high-risk clients by car type and state
-- =============================================================================

-- REQUIREMENT 1: Market Comparison
-- Calculate average claim amount for each car_type to establish market baseline
WITH market_comparison AS (
    SELECT 
        cl.id AS claim_id,
        cl.claim_amt,
        cl.car_id,
        cl.client_id,
        ca.car_type,
        -- Window function: Average claim amount per car type (Market Comparison)
        AVG(cl.claim_amt) OVER (PARTITION BY ca.car_type) AS avg_claim_by_car_type
    FROM claim cl
    INNER JOIN car ca ON cl.car_id = ca.id
),

-- REQUIREMENT 2: Aggregate total claims per client
-- Group claims by client to calculate total exposure per client
client_claim_totals AS (
    SELECT 
        mc.client_id,
        mc.car_type,
        -- Sum all claim amounts for each client
        SUM(mc.claim_amt) AS total_claimed
    FROM market_comparison mc
    GROUP BY mc.client_id, mc.car_type
),

-- Join client information to get name and state details
client_with_details AS (
    SELECT 
        c.id AS client_id,
        -- Concatenate first and last name for full client name
        c.first_name || ' ' || c.last_name AS client_name,
        a.state,
        cct.car_type,
        cct.total_claimed
    FROM client_claim_totals cct
    INNER JOIN client c ON cct.client_id = c.id
    INNER JOIN address a ON c.address_id = a.id
),

-- REQUIREMENT 2: Risk Ranking
-- Rank clients within each state by their total claim amounts
ranked_clients AS (
    SELECT 
        client_name,
        state,
        car_type,
        total_claimed,
        -- Window function: Rank clients within state (highest claims = rank 1)
        RANK() OVER (PARTITION BY state ORDER BY total_claimed DESC) AS state_rank
    FROM client_with_details
)

-- REQUIREMENT 3 & 4: Efficiency Filter + Final Output
-- Show only top 2 highest-claiming clients per state
SELECT 
    client_name AS "Client Name",
    state AS "State",
    car_type AS "Car Type",
    ROUND(total_claimed, 2) AS "Total Claimed",
    state_rank AS "State Rank"
FROM ranked_clients
-- Filter: Only top 2 clients per state (Efficiency requirement)
WHERE state_rank <= 2
ORDER BY state, state_rank;

-- =============================================================================
-- BUSINESS INSIGHTS FROM THIS QUERY:
-- 
-- 1. Market Comparison (CTE 1): Establishes baseline claim amounts by car type
--    to identify which vehicle categories are disproportionately expensive
-- 
-- 2. Risk Ranking (CTE 3 & 4): Identifies highest-risk clients within each 
--    state, enabling targeted investigation and risk management
-- 
-- 3. Efficiency (Final WHERE): Focuses executive attention on top 2 clients
--    per state, reducing noise and highlighting critical risk factors
-- 
-- 4. Geographic Analysis: State-level partitioning reveals regional patterns
--    that may indicate fraud, regional risk factors, or market anomalies
-- =============================================================================
```

## Technical Breakdown

### CTE Architecture 

The solution employs a four-stage CTE pipeline:

1. **market_comparison**: Implements the Market Comparison requirement by joining `claim` and `car` tables, calculating the average claim amount per car type using `AVG() OVER (PARTITION BY car_type)` 

2. **client_claim_totals**: Aggregates total claims per client using `GROUP BY client_id, car_type` to prepare for ranking analysis 

3. **client_with_details**: Joins client and address tables to retrieve full names and state information, concatenating first and last names for readability 

4. **ranked_clients**: Implements Risk Ranking using `RANK() OVER (PARTITION BY state ORDER BY total_claimed DESC)` to identify highest-risk clients within each state 

### Key SQL Techniques Used

**Window Functions**: 
- `AVG() OVER (PARTITION BY car_type)`: Calculates market baseline without collapsing rows
- `RANK() OVER (PARTITION BY state ORDER BY total_claimed DESC)`: Assigns rankings within state groups, allowing ties with gap numbering

**Join Strategy**:
- `INNER JOIN` used throughout to ensure only clients with actual claims and complete address information are included
- Four-table join path: `claim → car`, `claim → client → address`

**Efficiency Filter**: 
- `WHERE state_rank <= 2` restricts output to top 2 clients per state
- Final `ORDER BY state, state_rank` ensures logical presentation for executive review

## Expected Output Format 

| Client Name | State | Car Type | Total Claimed | State Rank |
|-------------|-------|----------|---------------|------------|
| John Smith  | CA    | Sedan    | 15000.00     | 1          |
| Jane Doe    | CA    | SUV      | 12500.00     | 2          |
| Bob Wilson  | NY    | Truck    | 18000.00     | 1          |
| Alice Brown | NY    | Sedan    | 14000.00     | 2          |

This solution directly addresses the CEO's concern about disproportionately expensive car types in specific cities by providing actionable insights into high-risk client profiles across geographic regions.

</details>
