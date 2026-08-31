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
WITH seller_stats AS (
    SELECT
        s.sales_person_id,
         FLOOR(AVG(s.quantity * p.price)) AS avg_deal_size
    FROM sales s
    INNER JOIN products p ON p.product_id = s.product_id
    GROUP BY s.sales_person_id
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ROUND(ss.avg_deal_size) AS average_income
FROM seller_stats ss
INNER JOIN employees e ON e.employee_id = ss.sales_person_id
CROSS JOIN (
    SELECT FLOOR(AVG(avg_deal_size)) AS overall_avg FROM seller_stats
) ga
WHERE ss.avg_deal_size < ga.overall_avg
ORDER BY ss.avg_deal_size ASC;

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
        -- Полное название дня недели на английском (monday, tuesday...)
        -- Если СУБД вернет русский язык, выполнить перед запросом: SET lc_time TO 'en_US';
        TO_CHAR(sales.sale_date, 'fmday') AS day_of_week,
        SUM(sales.quantity * products.price) AS raw_income
    FROM employees 
    INNER JOIN sales ON sales.sales_person_id = employees.employee_id
    INNER JOIN products ON products.product_id = sales.product_id
    GROUP BY 
        employees.first_name, 
        employees.last_name,
        "day_of_week" -- Группируемся по вычисленному английскому названию
)
SELECT 
    seller,
    day_of_week,
    FLOOR(raw_income)::INTEGER AS income -- Округляем до целого числа в меньшую сторону
FROM daily_revenue
ORDER BY 
    CASE day_of_week 
        WHEN 'monday' THEN 1
        WHEN 'tuesday' THEN 2
        WHEN 'wednesday' THEN 3
        WHEN 'thursday' THEN 4
        WHEN 'friday' THEN 5
        WHEN 'saturday' THEN 6
        WHEN 'sunday' THEN 7
    END, 
    seller;