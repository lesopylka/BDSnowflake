BEGIN;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM public.mock_data) <> 10000 THEN
        RAISE EXCEPTION 'Недостаточно строк';
    END IF;
END;
$$;

TRUNCATE TABLE star.fact_sales RESTART IDENTITY;

CREATE TEMP TABLE source_data ON COMMIT DROP AS
SELECT
    m.*,
    MD5(
        JSONB_BUILD_ARRAY(
            NULLIF(TRIM(product_name), ''),
            NULLIF(TRIM(product_category), ''),
            NULLIF(TRIM(product_price), '')::NUMERIC,
            NULLIF(TRIM(product_quantity), '')::INTEGER,
            NULLIF(TRIM(pet_category), ''),
            NULLIF(TRIM(product_weight), '')::NUMERIC,
            NULLIF(TRIM(product_color), ''),
            NULLIF(TRIM(product_size), ''),
            NULLIF(TRIM(product_brand), ''),
            NULLIF(TRIM(product_material), ''),
            NULLIF(TRIM(product_description), ''),
            NULLIF(TRIM(product_rating), '')::NUMERIC,
            NULLIF(TRIM(product_reviews), '')::INTEGER,
            TO_DATE(NULLIF(TRIM(product_release_date), ''), 'MM/DD/YYYY'),
            TO_DATE(NULLIF(TRIM(product_expiry_date), ''), 'MM/DD/YYYY'),
            NULLIF(TRIM(supplier_email), '')
        )::TEXT
    ) AS product_nk
FROM public.mock_data m;

INSERT INTO star.dim_country (country_name)
SELECT DISTINCT TRIM(country_name)
FROM (
    SELECT customer_country AS country_name FROM source_data
    UNION ALL
    SELECT seller_country FROM source_data
    UNION ALL
    SELECT store_country FROM source_data
    UNION ALL
    SELECT supplier_country FROM source_data
) countries
WHERE NULLIF(TRIM(country_name), '') IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO star.dim_pet_type (pet_type_name)
SELECT DISTINCT TRIM(customer_pet_type)
FROM source_data
WHERE NULLIF(TRIM(customer_pet_type), '') IS NOT NULL
ON CONFLICT (pet_type_name) DO NOTHING;

INSERT INTO star.dim_pet_breed (breed_name)
SELECT DISTINCT TRIM(customer_pet_breed)
FROM source_data
WHERE NULLIF(TRIM(customer_pet_breed), '') IS NOT NULL
ON CONFLICT (breed_name) DO NOTHING;

INSERT INTO star.dim_product_category (category_name)
SELECT DISTINCT TRIM(product_category)
FROM source_data
WHERE NULLIF(TRIM(product_category), '') IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO star.dim_pet_category (pet_category_name)
SELECT DISTINCT TRIM(pet_category)
FROM source_data
WHERE NULLIF(TRIM(pet_category), '') IS NOT NULL
ON CONFLICT (pet_category_name) DO NOTHING;

INSERT INTO star.dim_brand (brand_name)
SELECT DISTINCT TRIM(product_brand)
FROM source_data
WHERE NULLIF(TRIM(product_brand), '') IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;

INSERT INTO star.dim_color (color_name)
SELECT DISTINCT TRIM(product_color)
FROM source_data
WHERE NULLIF(TRIM(product_color), '') IS NOT NULL
ON CONFLICT (color_name) DO NOTHING;

INSERT INTO star.dim_size (size_name)
SELECT DISTINCT TRIM(product_size)
FROM source_data
WHERE NULLIF(TRIM(product_size), '') IS NOT NULL
ON CONFLICT (size_name) DO NOTHING;

INSERT INTO star.dim_material (material_name)
SELECT DISTINCT TRIM(product_material)
FROM source_data
WHERE NULLIF(TRIM(product_material), '') IS NOT NULL
ON CONFLICT (material_name) DO NOTHING;

INSERT INTO star.dim_date (
    full_date,
    year_num,
    quarter_num,
    month_num,
    day_num,
    month_name
)
SELECT
    full_date,
    EXTRACT(YEAR FROM full_date)::INTEGER,
    EXTRACT(QUARTER FROM full_date)::INTEGER,
    EXTRACT(MONTH FROM full_date)::INTEGER,
    EXTRACT(DAY FROM full_date)::INTEGER,
    TO_CHAR(full_date, 'FMMonth')
FROM (
    SELECT DISTINCT
        TO_DATE(TRIM(sale_date), 'MM/DD/YYYY') AS full_date
    FROM source_data
    WHERE NULLIF(TRIM(sale_date), '') IS NOT NULL
) dates
ON CONFLICT (full_date) DO NOTHING;

INSERT INTO star.dim_city (city_name, country_id)
SELECT DISTINCT
    TRIM(cities.city_name),
    country.country_id
FROM (
    SELECT
        store_city AS city_name,
        store_country AS country_name
    FROM source_data
    UNION ALL
    SELECT
        supplier_city,
        supplier_country
    FROM source_data
) cities
JOIN star.dim_country country
    ON country.country_name = TRIM(cities.country_name)
WHERE NULLIF(TRIM(cities.city_name), '') IS NOT NULL
ON CONFLICT (city_name, country_id) DO NOTHING;

INSERT INTO star.dim_supplier (
    supplier_name,
    contact_name,
    email,
    phone,
    address,
    city_id
)
SELECT DISTINCT ON (TRIM(m.supplier_email))
    NULLIF(TRIM(m.supplier_name), ''),
    NULLIF(TRIM(m.supplier_contact), ''),
    TRIM(m.supplier_email),
    NULLIF(TRIM(m.supplier_phone), ''),
    NULLIF(TRIM(m.supplier_address), ''),
    city.city_id
FROM source_data m
LEFT JOIN star.dim_country country
    ON country.country_name = TRIM(m.supplier_country)
LEFT JOIN star.dim_city city
    ON city.city_name = TRIM(m.supplier_city)
    AND city.country_id = country.country_id
WHERE NULLIF(TRIM(m.supplier_email), '') IS NOT NULL
ORDER BY TRIM(m.supplier_email), TO_JSONB(m)::TEXT
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_customer (
    first_name,
    last_name,
    age,
    email,
    postal_code,
    country_id,
    pet_type_id,
    pet_breed_id,
    pet_name
)
SELECT DISTINCT ON (TRIM(m.customer_email))
    NULLIF(TRIM(m.customer_first_name), ''),
    NULLIF(TRIM(m.customer_last_name), ''),
    NULLIF(TRIM(m.customer_age), '')::INTEGER,
    TRIM(m.customer_email),
    NULLIF(TRIM(m.customer_postal_code), ''),
    country.country_id,
    pet_type.pet_type_id,
    breed.pet_breed_id,
    NULLIF(TRIM(m.customer_pet_name), '')
FROM source_data m
LEFT JOIN star.dim_country country
    ON country.country_name = TRIM(m.customer_country)
LEFT JOIN star.dim_pet_type pet_type
    ON pet_type.pet_type_name = TRIM(m.customer_pet_type)
LEFT JOIN star.dim_pet_breed breed
    ON breed.breed_name = TRIM(m.customer_pet_breed)
WHERE NULLIF(TRIM(m.customer_email), '') IS NOT NULL
ORDER BY TRIM(m.customer_email), TO_JSONB(m)::TEXT
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_seller (
    first_name,
    last_name,
    email,
    postal_code,
    country_id
)
SELECT DISTINCT ON (TRIM(m.seller_email))
    NULLIF(TRIM(m.seller_first_name), ''),
    NULLIF(TRIM(m.seller_last_name), ''),
    TRIM(m.seller_email),
    NULLIF(TRIM(m.seller_postal_code), ''),
    country.country_id
FROM source_data m
LEFT JOIN star.dim_country country
    ON country.country_name = TRIM(m.seller_country)
WHERE NULLIF(TRIM(m.seller_email), '') IS NOT NULL
ORDER BY TRIM(m.seller_email), TO_JSONB(m)::TEXT
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_store (
    store_name,
    location,
    state_name,
    phone,
    email,
    city_id
)
SELECT DISTINCT ON (TRIM(m.store_email))
    NULLIF(TRIM(m.store_name), ''),
    NULLIF(TRIM(m.store_location), ''),
    NULLIF(TRIM(m.store_state), ''),
    NULLIF(TRIM(m.store_phone), ''),
    TRIM(m.store_email),
    city.city_id
FROM source_data m
LEFT JOIN star.dim_country country
    ON country.country_name = TRIM(m.store_country)
LEFT JOIN star.dim_city city
    ON city.city_name = TRIM(m.store_city)
    AND city.country_id = country.country_id
WHERE NULLIF(TRIM(m.store_email), '') IS NOT NULL
ORDER BY TRIM(m.store_email), TO_JSONB(m)::TEXT
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_product (
    product_name,
    price,
    stock_quantity,
    weight,
    rating,
    reviews,
    description,
    release_date,
    expiry_date,
    category_id,
    pet_category_id,
    brand_id,
    color_id,
    size_id,
    material_id,
    supplier_id,
    product_nk
)
SELECT DISTINCT ON (m.product_nk)
    NULLIF(TRIM(m.product_name), ''),
    NULLIF(TRIM(m.product_price), '')::NUMERIC(12, 2),
    NULLIF(TRIM(m.product_quantity), '')::INTEGER,
    NULLIF(TRIM(m.product_weight), '')::NUMERIC(12, 2),
    NULLIF(TRIM(m.product_rating), '')::NUMERIC(4, 2),
    NULLIF(TRIM(m.product_reviews), '')::INTEGER,
    NULLIF(TRIM(m.product_description), ''),
    TO_DATE(NULLIF(TRIM(m.product_release_date), ''), 'MM/DD/YYYY'),
    TO_DATE(NULLIF(TRIM(m.product_expiry_date), ''), 'MM/DD/YYYY'),
    category.category_id,
    pet_category.pet_category_id,
    brand.brand_id,
    color.color_id,
    product_size.size_id,
    material.material_id,
    supplier.supplier_id,
    m.product_nk
FROM source_data m
LEFT JOIN star.dim_product_category category
    ON category.category_name = TRIM(m.product_category)
LEFT JOIN star.dim_pet_category pet_category
    ON pet_category.pet_category_name = TRIM(m.pet_category)
LEFT JOIN star.dim_brand brand
    ON brand.brand_name = TRIM(m.product_brand)
LEFT JOIN star.dim_color color
    ON color.color_name = TRIM(m.product_color)
LEFT JOIN star.dim_size product_size
    ON product_size.size_name = TRIM(m.product_size)
LEFT JOIN star.dim_material material
    ON material.material_name = TRIM(m.product_material)
LEFT JOIN star.dim_supplier supplier
    ON supplier.email = TRIM(m.supplier_email)
ORDER BY m.product_nk, TO_JSONB(m)::TEXT
ON CONFLICT (product_nk) DO NOTHING;

INSERT INTO star.fact_sales (
    sale_date_id,
    customer_id,
    seller_id,
    product_id,
    store_id,
    sale_quantity,
    sale_total_price
)
SELECT
    date_dim.date_id,
    customer.customer_id,
    seller.seller_id,
    product.product_id,
    store.store_id,
    NULLIF(TRIM(m.sale_quantity), '')::INTEGER,
    NULLIF(TRIM(m.sale_total_price), '')::NUMERIC(14, 2)
FROM source_data m
LEFT JOIN star.dim_date date_dim
    ON date_dim.full_date =
        TO_DATE(NULLIF(TRIM(m.sale_date), ''), 'MM/DD/YYYY')
LEFT JOIN star.dim_customer customer
    ON customer.email = TRIM(m.customer_email)
LEFT JOIN star.dim_seller seller
    ON seller.email = TRIM(m.seller_email)
LEFT JOIN star.dim_product product
    ON product.product_nk = m.product_nk
LEFT JOIN star.dim_store store
    ON store.email = TRIM(m.store_email);

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM star.fact_sales)
        <> (SELECT COUNT(*) FROM source_data) THEN
        RAISE EXCEPTION 'Количество продаж не совпадает с количеством исходных строк';
    END IF;
END;
$$;

COMMIT;

SELECT
    (SELECT COUNT(*) FROM public.mock_data) AS source_rows,
    (SELECT COUNT(*) FROM star.fact_sales) AS loaded_sales;