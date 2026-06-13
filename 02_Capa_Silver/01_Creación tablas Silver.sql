USE data_silver;

CREATE TABLE customers_dataset_silver
(
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(50),
    customer_city VARCHAR(50),
    customer_state VARCHAR(50),

    CONSTRAINT PK_customers_dataset_silver PRIMARY KEY (customer_id)
);


CREATE TABLE sellers_dataset_silver
(
    seller_id VARCHAR(50) NOT NULL,
    seller_zip_code_prefix VARCHAR(50),
    seller_city VARCHAR(50),
    seller_state VARCHAR(50),

    CONSTRAINT PK_sellers_dataset_silver PRIMARY KEY (seller_id)
);


CREATE TABLE products_dataset_silver
(
    product_id VARCHAR(50) NOT NULL,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,

    CONSTRAINT PK_products_dataset_silver PRIMARY KEY (product_id)
);


CREATE TABLE orders_dataset_silver
(
    order_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    CONSTRAINT PK_orders_dataset_silver PRIMARY KEY (order_id),

    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id) REFERENCES customers_dataset_silver(customer_id)
);


CREATE TABLE items_dataset_silver
(
    order_id VARCHAR(50),
    order_item_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(18,10),
    freight_value DECIMAL(18,10),

    CONSTRAINT FK_items_orders FOREIGN KEY (order_id) REFERENCES orders_dataset_silver(order_id),
    CONSTRAINT FK_items_productos FOREIGN KEY (product_id) REFERENCES products_dataset_silver(product_id),
    CONSTRAINT FK_items_sellers FOREIGN KEY (seller_id) REFERENCES sellers_dataset_silver(seller_id)
);


CREATE TABLE reviews_dataset_silver
(
    review_id VARCHAR (50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(50),
    review_comment_message VARCHAR(MAX),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,

    CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES orders_dataset_silver(order_id)
)
