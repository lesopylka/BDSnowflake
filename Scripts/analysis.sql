SELECT COUNT(*) AS total_rows
FROM public.mock_data;

SELECT
    product_category,
    COUNT(*) AS sales_count,
    SUM(sale_quantity::NUMERIC) AS units_sold,
    ROUND(SUM(sale_total_price::NUMERIC), 2) AS revenue
FROM public.mock_data
GROUP BY product_category
ORDER BY revenue DESC;

SELECT
    customer_country,
    COUNT(*) AS sales_count,
    ROUND(SUM(sale_total_price::NUMERIC), 2) AS total_spent
FROM public.mock_data
GROUP BY customer_country
ORDER BY total_spent DESC
LIMIT 10;

SELECT
    customer_pet_type,
    COUNT(*) AS sales_count,
    ROUND(AVG(sale_total_price::NUMERIC), 2) AS average_purchase
FROM public.mock_data
GROUP BY customer_pet_type
ORDER BY average_purchase DESC;

SELECT
    product_name,
    ROUND(AVG(sale_quantity::NUMERIC), 2) AS average_quantity,
    SUM(sale_quantity::NUMERIC) AS total_quantity
FROM public.mock_data
GROUP BY product_name
ORDER BY average_quantity DESC
LIMIT 10;

SELECT
    CASE
        WHEN customer_age IS NULL
            OR TRIM(customer_age::TEXT) = '' THEN 'Возраст не указан'
        WHEN customer_age::INTEGER < 25 THEN 'До 25'
        WHEN customer_age::INTEGER < 45 THEN '25–44'
        WHEN customer_age::INTEGER < 65 THEN '45–64'
        ELSE '65 и старше'
    END AS age_group,
    COUNT(*) AS sales_count,
    ROUND(AVG(sale_total_price::NUMERIC), 2) AS average_purchase
FROM public.mock_data
GROUP BY age_group
ORDER BY average_purchase DESC;

SELECT
    id,
    product_name,
    product_price,
    sale_quantity,
    sale_total_price,
    ROUND(
        product_price::NUMERIC * sale_quantity::NUMERIC, 2
    ) AS calculated_total
FROM public.mock_data
WHERE ROUND(sale_total_price::NUMERIC, 2)
    <> ROUND(product_price::NUMERIC * sale_quantity::NUMERIC, 2)
LIMIT 20;

SELECT
    id,
    COUNT(*) AS occurrences
FROM public.mock_data
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

SELECT
    sale_product_id,
    COUNT(DISTINCT product_name) AS different_names
FROM public.mock_data
GROUP BY sale_product_id
HAVING COUNT(DISTINCT product_name) > 1
ORDER BY different_names DESC
LIMIT 20;