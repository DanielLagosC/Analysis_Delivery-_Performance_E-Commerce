USE data_silver;

-- ALCANCE: Considerando que el análisis se realiza a nivel de 'state', y que además debido al alto esfuerzo y bajo retorno de inversión 
--          que iba a tener limpiar y estandarizar las columnas de ciudad respectivas a la tabla customers y seller, se eligió seguir
--          adelante solo uniformizando mayusculas, quitando espacios extras y quitando comillas, en lo demás es posible encontrar
--          duplicaciones causadas por errores de encoding y tildes


-- Carga de datos estandarizados a la tabla customers
INSERT INTO customers_dataset_silver(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT -- Se cargaron 99441 filas
UPPER(TRIM(REPLACE(customer_id, '"', ''))) AS customer_id,
UPPER(TRIM(REPLACE(customer_unique_id, '"', ''))) AS customer_unique_id,
UPPER(TRIM(REPLACE(customer_zip_code_prefix, '"', ''))) AS customer_zip_code_prefix,
UPPER(TRIM(REPLACE(customer_city, '"', ''))) AS customer_city,
UPPER(TRIM(REPLACE(customer_state, '"', ''))) AS customer_state
FROM data_bronze.dbo.customers_dataset;

-- Carga de datos estandarizados a la tabla sellers
INSERT INTO sellers_dataset_silver(seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT -- Se cargaron 3095 filas
UPPER(TRIM(REPLACE(seller_id, '"', ''))) AS seller_id,
UPPER(TRIM(REPLACE(seller_zip_code_prefix, '"', ''))) AS seller_zip_code_prefix,
UPPER(TRIM(REPLACE(seller_city, '"', ''))) AS seller_city,
UPPER(TRIM(REPLACE(seller_state, '"', ''))) AS seller_state
FROM data_bronze.dbo.sellers_dataset;

-- Carga de datos estandarizados a la tabla products
INSERT INTO products_dataset_silver(product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SELECT -- Se cargaron 32951 filas
UPPER(TRIM(REPLACE(product_id, '"', ''))) AS product_id,
UPPER(TRIM(REPLACE(product_category_name, '"', ''))) AS product_category_name,
CAST(product_name_length AS INT) AS product_name_length,
CAST(product_description_length AS INT) AS product_description_length,
CAST(product_photos_qty AS INT) AS product_photos_qty,
CAST(product_weight_g AS INT) AS product_weight_g,
CAST(product_length_cm AS INT) AS product_length_cm,
CAST(product_height_cm AS INT)AS product_height_cm,
CAST(product_width_cm AS INT) AS product_width_cm
FROM data_bronze.dbo.products_dataset;

-- Carga de datos estandarizados a la tabla orders
INSERT INTO orders_dataset_silver(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
SELECT -- Se cargaron 99441 filas
UPPER(TRIM(REPLACE(order_id, '"', ''))) AS order_id,
UPPER(TRIM(REPLACE(customer_id, '"', ''))) AS customer_id,
UPPER(TRIM(REPLACE(order_status, '"', ''))) AS order_status,
CAST(order_purchase_timestamp AS DATETIME) AS order_purchase_timestamp,
CAST(order_approved_at AS DATETIME) AS order_approved_at,
CAST(order_delivered_carrier_date AS DATETIME) AS order_delivered_carrier_date,
CAST(order_delivered_customer_date  AS DATETIME) AS order_delivered_customer_date,
CAST(order_estimated_delivery_date AS DATETIME) AS order_estimated_delivery_date
FROM data_bronze.dbo.orders_dataset;

-- Carga de datos estandarizados a la tabla items
INSERT INTO items_dataset_silver(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
SELECT -- Se cargaron 112650 filas
UPPER(TRIM(REPLACE(order_id, '"', ''))) AS order_id,
UPPER(TRIM(REPLACE(order_item_id, '"', ''))) AS order_item_id,
UPPER(TRIM(REPLACE(product_id, '"', ''))) AS product_id,
UPPER(TRIM(REPLACE(seller_id, '"', ''))) AS seller_id,
CAST(shipping_limit_date AS datetime) AS shipping_limit_date,
CAST(price AS DECIMAL(18,10)) AS price,
CAST(freight_value AS DECIMAL(18,10)) AS freight_value
FROM data_bronze.dbo.items_dataset

-- Carga de datos estandarizados a la tabla reviews 
INSERT INTO reviews_dataset_silver(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
SELECT 
UPPER(TRIM(REPLACE(review_id, '"', ''))) AS review_id,
UPPER(TRIM(REPLACE(order_id, '"', ''))) AS order_id,
CAST(review_score AS INT) AS review_score,
UPPER(TRIM(REPLACE(review_comment_title, '"', ''))) AS review_comment_title,
UPPER(TRIM(REPLACE(review_comment_message, '"', ''))) AS review_comment_message,
CAST(review_creation_date AS DATETIME) AS review_creation_date,
CAST(REPLACE(review_answer_timestamp, CHAR(13), '') AS DATETIME) AS review_answer_timestamps
FROM data_bronze.dbo.reviews_dataset