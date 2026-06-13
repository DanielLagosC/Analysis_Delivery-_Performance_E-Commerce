USE data_bronze;

-- 1° Validacion nulos:
SELECT -- No hay nulos ni en la columna PK
SUM( -- No hay nulos ni en la columna PK
    CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos PK id customer',
SUM( -- No hay nulos en la columna id natural
    CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos id natural de cliente',
SUM( -- No hay nulos en la columna customer_state
    CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos customer_state',
SUM( -- No hay nulos en la columna zipcie
    CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos zipcode'
FROM customers_dataset;

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(customer_id) AS 'Cantidad PK duplicadas'
FROM customers_dataset
GROUP BY customer_id
HAVING COUNT(customer_id) > 1;

-- 3° Validar longitud del codigo
-- Para customer_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(customer_id)) AS 'Longitud del codigo de id de customer'
FROM customers_dataset
-- Para customer_unique id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(customer_unique_id)) AS 'Longitud del codigo de identificador de cliente natural'
FROM customers_dataset

