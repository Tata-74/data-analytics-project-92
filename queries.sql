-- посчитали общее количество покупателей из таблицы customers
SELECT
COUNT(DISTINCT Customer_ID) AS customers_count
FROM Customers;

-- нашли десятку лучших продавцов, у которых больше всех суммарная выручка с проданных товаров 
SELECT
CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
COUNT(sales.sales_id) AS operations,
FLOOR(SUM(sales.quantity * products.price)) AS income
FROM employees
INNER JOIN sales ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON products.product_id = sales.product_id
GROUP BY employees.first_name, employees.last_name
ORDER BY income desc
limit 10;

-- определили список сотрудников отдела продаж, чей средний чек ниже среднего чека по всей компании
SELECT 
    e.first_name || ' ' || e.last_name AS seller,
    FLOOR(s.avg_income_per_sale) AS average_income
FROM (
    SELECT 
        sales_person_id,
        AVG(quantity * price) AS avg_income_per_sale
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY sales_person_id
) s
JOIN employees e ON e.employee_id = s.sales_person_id
WHERE s.avg_income_per_sale < (
    SELECT AVG(avg_income_per_sale) OVER () 
    FROM (
        SELECT AVG(quantity * p.price) AS avg_income_per_sale
        FROM sales s2
        JOIN products p ON s2.product_id = p.product_id
        GROUP BY sales_person_id
    ) sub
    LIMIT 1 
)
ORDER BY s.avg_income_per_sale ASC;

-- определили количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+, отсортировали по возрастным группам
SELECT 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'            
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
WHERE age IS NOT NULL -- исключаем пустые значения возраста
GROUP BY 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'      
    END;

-- нашли количество  уникальных покупателей, принесших выручку, разбитую по месяцам
SELECT 
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(sales.quantity * products.price)) AS income
FROM sales
LEFT JOIN products ON products.product_id  = sales.product_id  -- связь заказа с позициями
WHERE sales.sale_date IS NOT NULL -- исключаем заказы без даты
GROUP BY selling_month
ORDER BY selling_month ASC;

-- cобрали данные по чекам, отфильтровали данные, отсекли платные покупки
SELECT DISTINCT ON (c.customer_id)
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    s.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id AND p.price = 0
LEFT JOIN employees e ON s.sales_person_id = e.employee_id
ORDER BY 
    c.customer_id,         
    s.sale_date ASC,       
    s.sales_id ASC;  

-- находим выручку по дням недели для каждого продавца
WITH daily_revenue AS (
    SELECT 
        employees.first_name || ' ' || employees.last_name AS seller,
        set_config('lc_time', 'en_US', true),
        TO_CHAR(sales.sale_date, 'fmday') AS day_of_week_full,
        SUM(sales.quantity * products.price) AS raw_income,
        EXTRACT(ISODOW FROM sales.sale_date)::INTEGER AS iso_day_num
    FROM employees 
    INNER JOIN sales ON sales.sales_person_id = employees.employee_id
    INNER JOIN products ON products.product_id = sales.product_id
    GROUP BY 
        employees.first_name, 
        employees.last_name,
        "day_of_week_full",
        "iso_day_num"
)
SELECT 
    seller,
    day_of_week_full AS day_of_week,
    FLOOR(raw_income)::INTEGER AS income
FROM daily_revenue
ORDER BY 
    iso_day_num, 
    seller;