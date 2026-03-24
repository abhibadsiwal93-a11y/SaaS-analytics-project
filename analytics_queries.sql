SELECT DATABASE();
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50),
    acquisition_channel VARCHAR(50)
);
SELECT COUNT(*) FROM users;
SELECT * FROM users LIMIT 10;
TRUNCATE TABLE users;
SELECT COUNT(*) FROM users;
DESCRIBE users;
TRUNCATE TABLE users;
SELECT COUNT(*) FROM users;
-- Country wise users 
SELECT country, COUNT(*) AS total_users
FROM users
GROUP BY country
ORDER BY total_users DESC;
-- Acquisition channel performance
SELECT acquisition_channel, COUNT(*) AS total_users
FROM users
GROUP BY acquisition_channel
ORDER BY total_users DESC; 
-- Monthly signup Trend
SELECT 
    DATE_FORMAT(signup_date, '%Y-%m') AS month,
    COUNT(*) AS total_users
FROM users
GROUP BY month
ORDER BY month;
CREATE TABLE sessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    session_date DATE,
    device VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);
TRUNCATE TABLE sessions;
SELECT COUNT(*) FROM sessions;
-- Total sessions
SELECT COUNT(*) AS total_sessions 
FROM sessions;
-- Active users (Overall)
SELECT COUNT(DISTINCT user_id) AS active_users
FROM sessions;
-- DAU (daily active users)
SELECT 
    session_date,
    COUNT(DISTINCT user_id) AS DAU
FROM sessions
GROUP BY session_date
ORDER BY session_date;
-- MAU (monthly active users)
SELECT 
    DATE_FORMAT(session_date, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS MAU
FROM sessions
GROUP BY month
ORDER BY month;
-- Device Usage Analysis
SELECT 
    device,
    COUNT(*) AS total_sessions
FROM sessions
GROUP BY device
ORDER BY total_sessions DESC;
-- Country + Sessions(join with users)
SELECT 
    u.country,
    COUNT(s.session_id) AS total_sessions
FROM sessions s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.country
ORDER BY total_sessions DESC;
-- Avg Sessions Per User
SELECT 
    COUNT(*) / COUNT(DISTINCT user_id) AS avg_sessions_per_user
FROM sessions;
-- Reetention Simulation
SELECT 
    user_id,
    COUNT(*) AS total_sessions
FROM sessions
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY total_sessions DESC;
CREATE TABLE events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    session_id INT,
    event_type VARCHAR(100),
    event_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (session_id) REFERENCES sessions(session_id)
);
SELECT MIN(user_id), MAX(user_id) FROM users;
SELECT COUNT(*) FROM events;
SELECT COUNT(*) AS total_events FROM events;
SELECT event_type, COUNT(*) AS total
FROM events
GROUP BY event_type
ORDER BY total DESC;
SELECT user_id, COUNT(*) AS total_events
FROM events
GROUP BY user_id
ORDER BY total_events DESC;
SELECT COUNT(*) 
FROM events 
WHERE user_id IS NULL;
TRUNCATE TABLE events;
SELECT COUNT(*) 
FROM events;
SELECT user_id, COUNT(*) 
FROM events
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 10;
SELECT user_id, COUNT(*) AS total_events
FROM events
GROUP BY user_id
ORDER BY total_events DESC;
SELECT session_id, COUNT(*) AS total_events
FROM events
GROUP BY session_id
ORDER BY total_events DESC;
SELECT COUNT(*) 
FROM events
WHERE event_type = 'purchase';
SELECT COUNT(DISTINCT user_id) AS active_users
FROM events;
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    session_id INT,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(20),
    payment_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (session_id) REFERENCES sessions(session_id)
);
TRUNCATE TABLE payments;
SELECT COUNT(*) FROM payments;
SELECT status, COUNT(*) 
FROM payments 
GROUP BY status;
SELECT SUM(amount) 
FROM payments 
WHERE status = 'Success';
SELECT status, COUNT(*) AS total
FROM payments
GROUP BY status;
SELECT payment_method, SUM(amount) AS revenue
FROM payments
WHERE status = 'Success'
GROUP BY payment_method
ORDER BY revenue DESC;
SELECT user_id, SUM(amount) AS total_spent
FROM payments
WHERE status = 'Success'
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 5;
SELECT COUNT(DISTINCT user_id) AS paying_users
FROM payments
WHERE status = 'Success';
SELECT DATE(payment_time) AS payment_date,
       SUM(amount) AS daily_revenue
FROM payments
WHERE status = 'Success'
GROUP BY DATE(payment_time)
ORDER BY payment_date;
SELECT u.country, SUM(p.amount) AS revenue
FROM payments p
JOIN users u ON p.user_id = u.user_id
WHERE p.status = 'Success'
GROUP BY u.country;
SELECT COUNT(DISTINCT user_id) 
FROM events;
SELECT COUNT(DISTINCT user_id) 
FROM payments
WHERE status = 'Success';
SELECT 
    (155.0 / 479) * 100 AS conversion_rate_percent;
SELECT COUNT(*) AS churned_users
FROM users u
LEFT JOIN payments p 
    ON u.user_id = p.user_id 
    AND p.status = 'Success'
WHERE p.user_id IS NULL;
SELECT 
    ((SELECT COUNT(*) FROM users) - 
     (SELECT COUNT(DISTINCT user_id) 
      FROM payments 
      WHERE status = 'Success')) * 100.0
    / (SELECT COUNT(*) FROM users) AS churn_rate;
    SELECT 
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN p.status = 'Success' THEN u.user_id END) AS paying_users
FROM users u
LEFT JOIN payments p ON u.user_id = p.user_id;
SELECT user_id, MAX(event_time) AS last_activity
FROM events
GROUP BY user_id;
SELECT COUNT(*) AS churned_users
FROM (
    SELECT user_id, MAX(event_time) AS last_activity
    FROM events
    GROUP BY user_id
) AS user_activity
WHERE last_activity < NOW() - INTERVAL 7 DAY;
SELECT 
(
    SELECT COUNT(*)
    FROM (
        SELECT user_id, MAX(event_time) AS last_activity
        FROM events
        GROUP BY user_id
    ) AS ua
    WHERE last_activity < 
          (SELECT MAX(event_time) FROM events) - INTERVAL 7 DAY
) * 100.0 
/
(SELECT COUNT(*) FROM users) AS churn_rate_percent;
SELECT u.user_id, SUM(p.amount) AS total_spent
FROM users u
JOIN payments p ON u.user_id = p.user_id
WHERE p.status = 'Success'
GROUP BY u.user_id
HAVING u.user_id IN (
    SELECT user_id
    FROM (
        SELECT user_id, MAX(event_time) AS last_activity
        FROM events
        GROUP BY user_id
    ) AS ua
    WHERE last_activity < 
          (SELECT MAX(event_time) FROM events) - INTERVAL 7 DAY
)
ORDER BY total_spent DESC;
SELECT 
    MIN(event_time) AS first_event,
    MAX(event_time) AS last_event
FROM events;
INSERT INTO events (user_id, session_id, event_type, event_time)
SELECT 
    user_id,
    session_id,
    event_type,
    DATE_ADD(event_time, INTERVAL 1 MONTH)
FROM events;
INSERT INTO events (user_id, session_id, event_type, event_time)
SELECT 
    user_id,
    session_id,
    event_type,
    DATE_ADD(event_time, INTERVAL 2 MONTH)
FROM events;
SELECT 
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    COUNT(*)
FROM events
GROUP BY month
ORDER BY month;
INSERT INTO payments (user_id, session_id, amount, payment_method, status, payment_time)
SELECT 
    user_id,
    session_id,
    amount,
    payment_method,
    status,
    DATE_ADD(payment_time, INTERVAL 1 MONTH)
FROM payments
WHERE payment_time BETWEEN '2026-02-01' AND '2026-02-12';
INSERT INTO payments (user_id, session_id, amount, payment_method, status, payment_time)
SELECT 
    user_id,
    session_id,
    amount,
    payment_method,
    status,
    DATE_ADD(payment_time, INTERVAL 2 MONTH)
FROM payments
WHERE payment_time BETWEEN '2026-02-01' AND '2026-02-12';
SELECT 
    DATE_FORMAT(payment_time, '%Y-%m') AS month,
    COUNT(*),
    SUM(amount)
FROM payments
GROUP BY month
ORDER BY month;
SELECT COUNT(*) FROM users;
INSERT INTO users (created_at)
SELECT DATE_ADD(created_at, INTERVAL 1 MONTH)
FROM users
LIMIT 500;
DESCRIBE users;
ALTER TABLE users
ADD COLUMN created_at DATETIME;
UPDATE users
SET created_at = '2026-02-01 10:00:00'
WHERE created_at IS NULL;
SET SQL_SAFE_UPDATES = 0;
UPDATE users
SET created_at = '2026-02-01 10:00:00';
SET SQL_SAFE_UPDATES = 1;
SELECT COUNT(*)
FROM users
WHERE created_at = '2026-02-01 10:00:00';
INSERT INTO users (created_at)
SELECT DATE_ADD(created_at, INTERVAL 1 MONTH)
FROM users
WHERE created_at = '2026-02-01 10:00:00'
LIMIT 500;
DESCRIBE users;
ALTER TABLE users
MODIFY user_id INT AUTO_INCREMENT;
ALTER TABLE sessions
DROP FOREIGN KEY sessions_ibfk_1;
ALTER TABLE events
DROP FOREIGN KEY events_ibfk_1;
ALTER TABLE payments
DROP FOREIGN KEY payments_ibfk_1;
ALTER TABLE users
MODIFY COLUMN user_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE sessions
ADD CONSTRAINT sessions_ibfk_1
FOREIGN KEY (user_id)
REFERENCES users(user_id);
ALTER TABLE events
ADD CONSTRAINT events_ibfk_1
FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE payments
ADD CONSTRAINT payments_ibfk_1
FOREIGN KEY (user_id) REFERENCES users(user_id);
INSERT INTO users (created_at)
SELECT DATE_ADD(created_at, INTERVAL 1 MONTH)
FROM users
WHERE created_at = '2026-02-01 10:00:00'
LIMIT 500;
INSERT INTO events (user_id, session_id, event_type, event_time)
SELECT 
    user_id,
    user_id + 1000,   -- unique integer session_id
    'login',
    created_at
FROM users
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2026-03';
-- Cohort check
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') AS cohort_month,
    COUNT(*) AS total_users
FROM users
GROUP BY cohort_month
ORDER BY cohort_month;

-- MAU check
SELECT 
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS active_users
FROM events
GROUP BY month
ORDER BY month;
INSERT INTO users (created_at)
SELECT DATE_ADD(created_at, INTERVAL 2 MONTH)
FROM users
WHERE created_at = '2026-02-01 10:00:00'
LIMIT 440;
INSERT INTO events (user_id, session_id, event_type, event_time)
SELECT 
    user_id,
    user_id + 1000,
    'login',
    created_at
FROM users
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2026-04';
SELECT 
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS active_users
FROM events
GROUP BY month
ORDER BY month;
INSERT INTO users (created_at)
SELECT DATE_ADD(created_at, INTERVAL 3 MONTH)
FROM users
WHERE created_at = '2026-02-01 10:00:00'
LIMIT 416;
INSERT INTO events (user_id, session_id, event_type, event_time)
SELECT 
    user_id,
    user_id + 1000,   -- unique integer session_id
    'login',
    created_at
FROM users
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2026-05';
-- Cohort check
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') AS cohort_month,
    COUNT(*) AS total_users
FROM users
GROUP BY cohort_month
ORDER BY cohort_month;
-- MAU check
SELECT 
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS active_users
FROM events
GROUP BY month
ORDER BY month;
-- Cohort-wise monthly retention
SELECT 
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    DATE_FORMAT(e.event_time, '%Y-%m') AS event_month,
    COUNT(DISTINCT e.user_id) AS active_users
FROM users u
LEFT JOIN events e
    ON u.user_id = e.user_id
GROUP BY cohort_month, event_month
ORDER BY cohort_month, event_month;
-- Month-wise churn: 1 - (current_month_active / previous_month_active)
WITH monthly_active AS (
    SELECT 
        DATE_FORMAT(event_time, '%Y-%m') AS month,
        COUNT(DISTINCT user_id) AS active_users
    FROM events
    GROUP BY month
)
SELECT 
    month,
    active_users,
    LAG(active_users) OVER (ORDER BY month) AS prev_month_users,
    ROUND((LAG(active_users) OVER (ORDER BY month) - active_users) / LAG(active_users) OVER (ORDER BY month) * 100, 2) AS churn_percentage
FROM monthly_active;
DESCRIBE payments;
-- Cohort-wise LTV (Lifetime Value) per signup month
SELECT 
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT p.user_id) AS paying_users,
    SUM(p.amount) AS total_revenue,
    ROUND(SUM(p.amount)/COUNT(DISTINCT p.user_id), 2) AS ARPU
FROM users u
LEFT JOIN payments p
    ON u.user_id = p.user_id
GROUP BY cohort_month
ORDER BY cohort_month;
INSERT INTO payments (user_id, session_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    s.session_id,
    240.00,
    'card',
    'paid',
    u.created_at
FROM users u
JOIN sessions s ON s.user_id = u.user_id
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-03';
INSERT INTO payments (user_id, session_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    s.session_id,
    300.00,          
    'upi',           
    'paid',
    u.created_at
FROM users u
JOIN sessions s ON s.user_id = u.user_id
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-04';
INSERT INTO payments (user_id, session_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    s.session_id,
    280.00,          
    'netbanking',    
    'paid',
    u.created_at
FROM users u
JOIN sessions s ON s.user_id = u.user_id
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-05';
SELECT 
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT p.user_id) AS paying_users,
    SUM(p.amount) AS total_revenue,
    ROUND(SUM(p.amount)/COUNT(DISTINCT p.user_id), 2) AS ARPU
FROM users u
LEFT JOIN payments p
    ON u.user_id = p.user_id
GROUP BY cohort_month
ORDER BY cohort_month;
SELECT DATE_FORMAT(payment_time, '%Y-%m') AS month,
       COUNT(*) AS total_payments,
       COUNT(DISTINCT user_id) AS paying_users
FROM payments
GROUP BY month;
SELECT 
    cohort_month,
    COUNT(DISTINCT paying_user_id) AS paying_users,
    SUM(total_paid) AS total_revenue,
    ROUND(SUM(total_paid)/COUNT(DISTINCT paying_user_id), 2) AS ARPU
FROM (
    SELECT 
        u.user_id AS paying_user_id,
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        SUM(p.amount) AS total_paid
    FROM users u
    LEFT JOIN payments p ON u.user_id = p.user_id
    GROUP BY u.user_id, cohort_month
) t
GROUP BY cohort_month
ORDER BY cohort_month;
SELECT user_id, COUNT(*) AS total_payments, SUM(amount) AS total_amount
FROM payments
GROUP BY user_id
ORDER BY total_amount DESC
LIMIT 10;
SELECT 
    DATE_FORMAT(payment_time, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS paying_users,
    SUM(amount) AS total_revenue,
    ROUND(SUM(amount)/COUNT(DISTINCT user_id),2) AS ARPU
FROM payments
GROUP BY month
ORDER BY month;
-- Step: Cohort-wise lifetime value & ARPU calculation
SELECT 
    cohort_month,
    COUNT(DISTINCT user_id) AS paying_users,
    COALESCE(SUM(total_paid),0) AS total_revenue,
    COALESCE(ROUND(SUM(total_paid)/COUNT(DISTINCT user_id),2),0) AS ARPU
FROM (
    -- Step: Calculate total payment per user
    SELECT 
        u.user_id,
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        SUM(p.amount) AS total_paid
    FROM users u
    LEFT JOIN payments p ON u.user_id = p.user_id
    GROUP BY u.user_id
) t
GROUP BY cohort_month
ORDER BY cohort_month;
SELECT 
    cohort_month,
    COUNT(DISTINCT user_id) AS paying_users,
    COALESCE(SUM(total_paid),0) AS total_revenue,
    COALESCE(ROUND(SUM(total_paid)/COUNT(DISTINCT user_id),2),0) AS ARPU
FROM (
    SELECT 
        u.user_id,
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        COALESCE(SUM(p.amount),0) AS total_paid
    FROM users u
    LEFT JOIN payments p ON u.user_id = p.user_id
    GROUP BY u.user_id
) t
GROUP BY cohort_month
ORDER BY cohort_month;
INSERT INTO payments (user_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    ROUND(100 + (RAND()*200), 2) AS amount, 
    CASE 
        WHEN RAND() < 0.5 THEN 'card'
        ELSE 'upi'
    END AS payment_method,
    'completed' AS status,
    CONCAT('2026-03-', LPAD(FLOOR(1 + RAND()*28),2,'0'), ' ', 
           LPAD(FLOOR(RAND()*24),2,'0'), ':', LPAD(FLOOR(RAND()*60),2,'0'), ':00') AS payment_time
FROM users u
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-03'
ORDER BY RAND()
LIMIT 500;
INSERT INTO payments (user_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    ROUND(100 + (RAND()*200), 2) AS amount, 
    CASE 
        WHEN RAND() < 0.5 THEN 'card'
        ELSE 'upi'
    END AS payment_method,
    'completed' AS status,
    CONCAT('2026-04-', LPAD(FLOOR(1 + RAND()*28),2,'0'), ' ', 
           LPAD(FLOOR(RAND()*24),2,'0'), ':', LPAD(FLOOR(RAND()*60),2,'0'), ':00') AS payment_time
FROM users u
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-04'
ORDER BY RAND()
LIMIT 440; 
INSERT INTO payments (user_id, amount, payment_method, status, payment_time)
SELECT 
    u.user_id,
    ROUND(100 + (RAND()*200), 2) AS amount, 
    CASE 
        WHEN RAND() < 0.5 THEN 'card'
        ELSE 'upi'
    END AS payment_method,
    'completed' AS status,
    CONCAT('2026-05-', LPAD(FLOOR(1 + RAND()*28),2,'0'), ' ', 
           LPAD(FLOOR(RAND()*24),2,'0'), ':', LPAD(FLOOR(RAND()*60),2,'0'), ':00') AS payment_time
FROM users u
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2026-05'
ORDER BY RAND()
LIMIT 416;
SELECT DATE_FORMAT(payment_time, '%Y-%m') AS payment_month,
       COUNT(DISTINCT user_id) AS paying_users,
       SUM(amount) AS total_revenue,
       ROUND(SUM(amount)/COUNT(DISTINCT user_id),2) AS ARPU
FROM payments
GROUP BY payment_month
ORDER BY payment_month;
SELECT
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    DATE_FORMAT(e.event_time, '%Y-%m') AS event_month,
    COUNT(DISTINCT e.user_id) AS active_users
FROM users u
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY cohort_month, event_month
ORDER BY cohort_month, event_month;
-- =========================================
-- 1️⃣ Month-wise Revenue Trend + Growth %
-- =========================================
WITH revenue_trend AS (
    SELECT
        DATE_FORMAT(payment_time,'%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM payments
    GROUP BY month
),
revenue_growth AS (
    SELECT
        month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue,
        ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
              / LAG(total_revenue) OVER (ORDER BY month) * 100,2) AS growth_pct
    FROM revenue_trend
)

-- =========================================
-- 2️⃣ Cohort-wise LTV / ARPU
-- =========================================
, cohort_ltv AS (
    SELECT 
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        COUNT(DISTINCT u.user_id) AS total_users,
        COUNT(DISTINCT p.user_id) AS paying_users,
        COALESCE(SUM(p.amount),0) AS total_revenue,
        COALESCE(ROUND(SUM(p.amount)/COUNT(DISTINCT p.user_id),2),0) AS ARPU
    FROM users u
    LEFT JOIN payments p ON u.user_id = p.user_id
    GROUP BY cohort_month
)

-- =========================================
-- 3️⃣ Cohort-wise Month-by-Month Retention
-- =========================================
, retention AS (
    SELECT
        DATE_FORMAT(u.created_at,'%Y-%m') AS cohort_month,
        DATE_FORMAT(e.event_time,'%Y-%m') AS event_month,
        COUNT(DISTINCT e.user_id) AS active_users
    FROM users u
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY cohort_month, event_month
)

-- =========================================
-- 4️⃣ Churn Rate per cohort
-- =========================================
, churn AS (
    SELECT
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        COUNT(DISTINCT u.user_id) AS total_users,
        COUNT(DISTINCT p.user_id) AS paying_users,
        COUNT(DISTINCT u.user_id) - COUNT(DISTINCT p.user_id) AS churned_users,
        ROUND((COUNT(DISTINCT u.user_id) - COUNT(DISTINCT p.user_id)) 
              / COUNT(DISTINCT u.user_id)*100,2) AS churn_rate_pct
    FROM users u
    LEFT JOIN payments p ON u.user_id = p.user_id
    GROUP BY cohort_month
)

-- =========================================
-- 5️⃣ Final Output – Combine Everything
-- =========================================
SELECT 
    r.month AS month,
    rg.total_revenue,
    rg.growth_pct,
    c.cohort_month,
    c.total_users,
    c.paying_users,
    c.total_revenue AS cohort_total_revenue,
    c.ARPU,
    COALESCE(ret.active_users,0) AS active_users_in_month,
    ch.churned_users,
    ch.churn_rate_pct
FROM revenue_trend r
LEFT JOIN revenue_growth rg ON r.month = rg.month
LEFT JOIN cohort_ltv c ON r.month = c.cohort_month
LEFT JOIN retention ret ON c.cohort_month = ret.cohort_month AND r.month = ret.event_month
LEFT JOIN churn ch ON c.cohort_month = ch.cohort_month
ORDER BY r.month, c.cohort_month;