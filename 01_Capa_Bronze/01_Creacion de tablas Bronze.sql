USE data_bronze ;

-- Se crearan específicamente las tablas de las cuales se hagan uso en el análisis

CREATE TABLE customers_dataset
(
    customer_id VARCHAR(100),
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix VARCHAR(100),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100)
);

CREATE TABLE sellers_dataset
(
    seller_id VARCHAR(100),
    seller_zip_code_prefix VARCHAR(100),
    seller_city VARCHAR(100),
    seller_state VARCHAR(100)
);

CREATE TABLE products_dataset
(
    product_id VARCHAR(100),
    product_category_name VARCHAR(100),
    product_name_length VARCHAR(100),
    product_description_length VARCHAR(100),
    product_photos_qty VARCHAR(100),
    product_weight_g VARCHAR(100),
    product_length_cm VARCHAR(100),
    product_height_cm VARCHAR(100),
    product_width_cm VARCHAR(100)
);

CREATE TABLE orders_dataset
(
    order_id VARCHAR(100),
    customer_id VARCHAR(100),
    order_status VARCHAR(100),
    order_purchase_timestamp VARCHAR(100),
    order_approved_at VARCHAR(100),
    order_delivered_carrier_date VARCHAR(100),
    order_delivered_customer_date VARCHAR(100),
    order_estimated_delivery_date VARCHAR(100)
);

CREATE TABLE items_dataset
(
    order_id VARCHAR(100),
    order_item_id VARCHAR(100),
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    shipping_limit_date VARCHAR(100),
    price VARCHAR(100),
    freight_value VARCHAR(100)
);


CREATE TABLE reviews_dataset
(
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score VARCHAR(50),
    review_comment_title VARCHAR(100),
    review_comment_message VARCHAR(MAX),
    review_creation_date VARCHAR(50),
    review_answer_timestamp VARCHAR(50)
);
