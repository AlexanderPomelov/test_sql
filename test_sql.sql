WITH ko AS (
    SELECT 1 AS id, 'Север' AS name UNION ALL
    SELECT 2, 'Запад' UNION ALL
    SELECT 3, 'Восток' UNION ALL
    SELECT 4, 'Юг'
),
ac AS (
    SELECT 1 AS ko, '2020-01-01'::date AS oper_date, 100 AS amount, 1 AS direction UNION ALL
    SELECT 1, '2020-01-11', 30, 0 UNION ALL
    SELECT 1, '2020-02-01', 230, 1 UNION ALL
    SELECT 1, '2020-02-11', 40, 0 UNION ALL
    SELECT 1, '2020-03-01', 90, 1 UNION ALL
    SELECT 1, '2020-03-11', 180, 0 UNION ALL
    SELECT 1, '2020-04-01', 400, 1 UNION ALL
    SELECT 1, '2020-04-11', 100, 0 UNION ALL
    SELECT 1, '2020-05-01', 120, 1 UNION ALL
    SELECT 1, '2020-05-11', 310, 0 UNION ALL
    SELECT 1, '2020-06-01', 100, 1 UNION ALL
    SELECT 1, '2020-06-11', 40, 0 UNION ALL
    SELECT 1, '2020-07-01', 90, 1 UNION ALL
    SELECT 1, '2020-07-11', 180, 0 UNION ALL
    SELECT 1, '2020-08-01', 400, 1 UNION ALL
    SELECT 1, '2020-08-11', 100, 0 UNION ALL
    SELECT 1, '2020-09-01', 120, 1 UNION ALL
    SELECT 2, '2020-02-01', 725, 1 UNION ALL
    SELECT 2, '2020-02-11', 40, 0 UNION ALL
    SELECT 2, '2020-03-01', 90, 1 UNION ALL
    SELECT 2, '2020-03-11', 180, 0 UNION ALL
    SELECT 2, '2020-04-01', 100, 1 UNION ALL
    SELECT 2, '2020-04-11', 380, 0 UNION ALL
    SELECT 2, '2020-05-01', 120, 1 UNION ALL
    SELECT 2, '2020-05-11', 480, 0 UNION ALL
    SELECT 2, '2020-06-01', 80, 1 UNION ALL
    SELECT 3, '2020-01-01', 125, 1 UNION ALL
    SELECT 3, '2020-02-11', 40, 0 UNION ALL
    SELECT 3, '2020-03-01', 90, 1 UNION ALL
    SELECT 3, '2020-03-11', 180, 0 UNION ALL
    SELECT 3, '2020-06-01', 100, 1 UNION ALL
    SELECT 3, '2020-06-11', 80, 0 UNION ALL
    SELECT 3, '2020-08-01', 120, 1 UNION ALL
    SELECT 3, '2020-08-11', 10, 0 UNION ALL
    SELECT 3, '2020-09-01', 80, 1 UNION ALL
    SELECT 4, '2020-02-01', 90, 0 UNION ALL
    SELECT 4, '2020-02-11', 180, 1 UNION ALL
    SELECT 4, '2020-05-01', 100, 0 UNION ALL
    SELECT 4, '2020-08-01', 120, 1 UNION ALL
    SELECT 4, '2020-08-11', 480, 1 UNION ALL
    SELECT 4, '2020-09-01', 80, 1
),
months AS (
    SELECT generate_series('2020-01-01'::date, '2020-09-01'::date, '1 month')::date AS month
),
all_combinations AS (
    SELECT
        ko.id,
        ko.name,
        months.month
    FROM
        ko
    CROSS JOIN months
),
monthly_operations AS (
    SELECT
        ko.id,
        ko.name,
        date_trunc('month', oper_date) AS month,
        SUM(CASE WHEN direction = 1 THEN amount ELSE -amount END) AS monthly_balance
    FROM
        ac
    JOIN ko ON ac.ko = ko.id
    GROUP BY
        ko.id, ko.name, date_trunc('month', oper_date)
),
cumulative_balances AS (
    SELECT
        ac.id,
        ac.name,
        ac.month,
        COALESCE(SUM(mo.monthly_balance) OVER (PARTITION BY ac.id ORDER BY ac.month), 0) AS balance
    FROM
        all_combinations ac
    LEFT JOIN monthly_operations mo ON ac.id = mo.id AND ac.month = mo.month
),
final_balances AS (
    SELECT
        name,
        month,
        balance
    FROM
        cumulative_balances
    WHERE
        month IN ('2020-04-01', '2020-05-01', '2020-06-01', '2020-07-01', '2020-08-01', '2020-09-01')
)
SELECT
    'Контрагент'::text AS "NAME",
    'апрель'::text AS "M5",
    'май'::text AS "M4",
    'июнь'::text AS "M3",
    'июль'::text AS "M2",
    'август'::text AS "M1",
    'сентябрь'::text AS "M0"
UNION ALL
SELECT
    name AS "NAME",
    COALESCE(SUM(CASE WHEN month = '2020-04-01' THEN balance END), 0)::text AS "M5",
    COALESCE(SUM(CASE WHEN month = '2020-05-01' THEN balance END), 0)::text AS "M4",
    COALESCE(SUM(CASE WHEN month = '2020-06-01' THEN balance END), 0)::text AS "M3",
    COALESCE(SUM(CASE WHEN month = '2020-07-01' THEN balance END), 0)::text AS "M2",
    COALESCE(SUM(CASE WHEN month = '2020-08-01' THEN balance END), 0)::text AS "M1",
    COALESCE(SUM(CASE WHEN month = '2020-09-01' THEN balance END), 0)::text AS "M0"
FROM
    final_balances
GROUP BY
    name
UNION ALL
SELECT
    'Итого:'::text,
    COALESCE(SUM(CASE WHEN month = '2020-04-01' THEN balance END), 0)::text,
    COALESCE(SUM(CASE WHEN month = '2020-05-01' THEN balance END), 0)::text,
    COALESCE(SUM(CASE WHEN month = '2020-06-01' THEN balance END), 0)::text,
    COALESCE(SUM(CASE WHEN month = '2020-07-01' THEN balance END), 0)::text,
    COALESCE(SUM(CASE WHEN month = '2020-08-01' THEN balance END), 0)::text,
    COALESCE(SUM(CASE WHEN month = '2020-09-01' THEN balance END), 0)::text
FROM
    final_balances;