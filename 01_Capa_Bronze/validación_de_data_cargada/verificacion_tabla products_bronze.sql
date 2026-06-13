USE data_bronze;

-- 1° Validacion nulos: 
SELECT 
SUM( -- No hay nulos en la columna PK
    CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos PK id product',
-- Cada columna tiene 2 productos registrados con especificacion nula
SUM(
    CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos columna peso',
SUM(
    CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos columna largo',
SUM(
    CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos columna alto',
SUM(
    CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos columna ancho'
FROM products_dataset;

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(product_id) AS 'Cantidad PK duplicadas'
FROM products_dataset
GROUP BY product_id
HAVING COUNT(product_id) > 1;

-- 3° Validar longitud del codigo: 
-- Para product_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(product_id)) AS 'Longitud del codigo id de producto'
FROM products_dataset;
