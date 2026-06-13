USE data_bronze;

-- 1° Validacion nulos: 
SELECT 
SUM( -- No hay nulos en FKK order_id
    CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos order_id',
SUM( -- No hay nulos en FK product_id
    CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos product_id',
SUM( -- No hay nulos en seller_id
    CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS ' Cantidad nulos seller_id',
SUM( -- No hay nulos en fecha estimada
    CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos fecha estimada'
FROM items_dataset;

-- 2° 
-- Validacion duplicacion: no hay duplicados en la tabla
SELECT order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, COUNT(*)
FROM items_dataset
GROUP BY order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value
HAVING COUNT(*) > 1;

-- 3°
-- Validacion de longitud del campo fecha, debido a que el dato se encuentra como tipo string
-- Sí se tiene uniformizado su longitud (19 caracteres), lo que brinda una idea de que las fechas mantienen el mismo 
-- formato en toda la columna
SELECT DISTINCT(LEN(shipping_limit_date)) AS 'Longitud campo fecha'
FROM items_dataset


-- 4° Validar longitud del codigo
-- La columna FK order_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(order_id)) AS 'Longitud del codigo id de orden'
FROM items_dataset;
-- La columna FK product_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(product_id)) AS 'Longitud del codigo id de producto'
FROM items_dataset;
-- La columna FK seller_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(seller_id)) AS 'Longitud del codigo id de seller'
FROM items_dataset;