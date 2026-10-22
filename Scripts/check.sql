SELECT
    'source' AS data_source,
    COUNT(*) AS sales_count,
    SUM(sale_quantity::NUMERIC) AS total_quantity,
    SUM(sale_total_price::NUMERIC) AS total_amount
FROM public.mock_data

UNION ALL

SELECT
    'snowflake',
    COUNT(*),
    SUM(sale_quantity),
    SUM(sale_total_price)
FROM star.fact_sales;

SELECT COUNT(*) AS broken_links
FROM star.fact_sales f
LEFT JOIN star.dim_date d
    ON d.date_id = f.sale_date_id
LEFT JOIN star.dim_customer c
    ON c.customer_id = f.customer_id
LEFT JOIN star.dim_seller s
    ON s.seller_id = f.seller_id
LEFT JOIN star.dim_product p
    ON p.product_id = f.product_id
LEFT JOIN star.dim_store st
    ON st.store_id = f.store_id
WHERE d.date_id IS NULL
   OR c.customer_id IS NULL
   OR s.seller_id IS NULL
   OR p.product_id IS NULL
   OR st.store_id IS NULL;

SELECT
    f.sale_id,
    d.full_date,
    c.first_name,
    c.last_name,
    p.product_name,
    st.store_name,
    f.sale_quantity,
    f.sale_total_price
FROM star.fact_sales f
JOIN star.dim_date d
    ON d.date_id = f.sale_date_id
JOIN star.dim_customer c
    ON c.customer_id = f.customer_id
JOIN star.dim_product p
    ON p.product_id = f.product_id
JOIN star.dim_store st
    ON st.store_id = f.store_id
ORDER BY f.sale_id
LIMIT 20;