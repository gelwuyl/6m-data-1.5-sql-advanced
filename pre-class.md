# 📚 Pre-Class: Advanced SQL

**Estimated Time:** 30 minutes
**Prerequisites:** Lesson 1.4 — SQL DML

> In Lesson 1.4 you queried, filtered, and aggregated data with `SELECT`, `WHERE`, and `GROUP BY`. This lesson introduces the techniques that unlock *analytical* questions — the kind that can't be answered with a single simple query.

---

## Step 1 — Watch the Video (8 min)

🎬 [Advanced SQL Detective Kit](https://youtu.be/mJGjUi_XvXc)

An overview of how advanced SQL moves from "show me the data" to "show me the insight" — covering joins, window functions, and CTEs.

---

## Step 2 — Read the Core Concepts (15 min)

### What Makes SQL "Advanced"?

Basic SQL answers simple questions: *"Show me all claims."*
Advanced SQL answers analytical questions: *"For each client, show me their total claims compared to the average for their car type, ranked within their state."*

Three techniques make this possible:

### A. JOINs — Linking Tables Together

Data in real databases is spread across multiple tables. A JOIN combines rows from two tables based on a shared key.

| Join Type | What it returns |
|---|---|
| `INNER JOIN` | Only rows that match in **both** tables |
| `LEFT JOIN` | All rows from the left table + matching rows from the right (unmatched = NULL) |

```sql
-- Example: Combine claim data with car details
SELECT cl.id, cl.claim_amt, c.car_type
FROM claim cl
INNER JOIN car c ON cl.car_id = c.id;
```

### B. Window Functions — Row-Level Analytics Without Collapsing

Unlike `GROUP BY` (which collapses rows into groups), window functions add a calculated column *to each row* while keeping all rows visible.

```sql
-- Running total of travel_time per car
SELECT id, car_id, travel_time,
    SUM(travel_time) OVER (PARTITION BY car_id ORDER BY id) AS running_total
FROM claim;
```

`PARTITION BY` = "do this calculation separately for each group"
`ORDER BY` inside `OVER()` = "in what order to accumulate"

Also useful: `RANK()`, `ROW_NUMBER()`, `AVG() OVER()`

### C. CTEs — Breaking Complex Queries into Steps

A **Common Table Expression (CTE)** is a named, temporary result set you define at the top of a query and reference like a table. It makes complex logic readable.

```sql
WITH avg_resale AS (
    SELECT car_use, AVG(resale_value) AS avg_val
    FROM car
    GROUP BY car_use
)
SELECT c.id, c.resale_value, c.car_use
FROM car c
JOIN avg_resale a ON c.car_use = a.car_use
WHERE c.resale_value < a.avg_val;
```

Think of a CTE like defining a sub-step in plain English before writing the final query.

---

## Step 3 — Tool Setup (5 min)

1. Ensure **DbGate** is installed (from Lesson 1.3)
2. Download `unit-1-5.db` from the course repository
3. Open DbGate → New DuckDB connection → point to `unit-1-5.db`
4. Verify your setup:

```sql
SELECT * FROM client LIMIT 5;
```

You should see 5 rows of client data. Post in **#questions** on Discord if you hit any issues.

---

## Step 4 — Check Your Understanding

Try to answer these before class, then check below.

1. You have a `Customers` table and an `Orders` table. Some customers have never placed an order. Which join type keeps *all* customers in the result?
2. What is the key difference between `GROUP BY` and a window function with `PARTITION BY`?
3. In a CTE, once you define `WITH my_cte AS (...)`, how do you use it?

<details>
<summary>Suggested answers</summary>

**Q1:** `LEFT JOIN` (with `Customers` as the left table). An `INNER JOIN` would drop customers with no orders because there's no matching row in `Orders`.

**Q2:** `GROUP BY` collapses all rows in a group into one summary row — you lose the individual row detail. A window function with `PARTITION BY` adds a calculated value to every row while keeping all rows intact. Use `GROUP BY` when you want a summary table; use window functions when you want the summary *alongside* the detail.

**Q3:** You reference it by name exactly like a regular table: `SELECT * FROM my_cte` or `JOIN my_cte ON ...`. The CTE only exists for the duration of that single query.

</details>
