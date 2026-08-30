-- посчитали общее количество покупателей из таблицы customers
SELECT
COUNT(DISTINCT Customer_ID) AS customers_count
FROM Customers;

-- нашли десятку лучших продавцов, у которых больше всех суммарная выручка с проданных товаров 
SELECT
CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
COUNT(sales.sales_id) AS operations,
round(SUM(sales.quantity * products.price)) AS income
FROM employees
INNER JOIN sales ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON products.product_id = sales.product_id
GROUP BY employees.first_name, employees.last_name
ORDER BY income desc
limit 10;

-- определили список сотрудников отдела продаж, чей средний чек ниже среднего чека по всей компании
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ROUND(ss.avg_deal_size) AS average_income
FROM (
    SELECT
        s.sales_person_id,
        SUM(s.quantity * p.price) / COUNT(*) AS avg_deal_size
    FROM sales s
    INNER JOIN products p ON p.product_id = s.product_id
    GROUP BY s.sales_person_id
) ss
INNER JOIN employees e ON e.employee_id = ss.sales_person_id
CROSS JOIN (
    SELECT AVG(avg_deal_size) AS overall_avg
    FROM (
        SELECT
            s.sales_person_id,
            SUM(s.quantity * p.price) / COUNT(*) AS avg_deal_size
        FROM sales s
        INNER JOIN products p ON p.product_id = s.product_id
        GROUP BY s.sales_person_id
    ) inner_stats
) ga
WHERE ss.avg_deal_size < ga.overall_avg
ORDER BY ss.avg_deal_size ASC;

-- определили количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+, отсортировали по возрастным группам
SELECT 
age_category, 
SUM(age_count) AS age_count
FROM (
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
        END
) grouped_data
GROUP BY age_category;

-- нашли количество  уникальных покупателей, принесших выручку, разбитую по месяцам
SELECT 
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    round(SUM(sales.quantity * products.price)) AS income
FROM sales
JOIN products ON products.product_id  = sales.product_id  -- связь заказа с позициями
WHERE sales.sale_date IS NOT NULL -- исключаем заказы без даты
GROUP BY selling_month
ORDER BY selling_month ASC;

-- Собрали данные по чекам, отфильтровали данные, отсекли платные покупки
SELECT DISTINCT ON (c.customer_id)
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    s.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
LEFT JOIN employees e ON s.sales_person_id = e.employee_id
GROUP BY 
    c.customer_id, 
    s.sale_date, 
    s.sales_id, 
    e.first_name, 
    e.last_name,
    c.first_name, 
    c.last_name
HAVING SUM(p.price * s.quantity) = 0
ORDER BY 
    c.customer_id,         
    s.sale_date ASC,       
    s.sales_id ASC;  