USE data_silver;

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
FROM items_dataset_silver

-- 2° 
-- Validacion duplicacion: no hay duplicados en la tabla
SELECT order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, COUNT(*)
FROM items_dataset_silver
GROUP BY order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value
HAVING COUNT(*) > 1

-- 3° Validas fechas:
SELECT 
MONTH(shipping_limit_date) AS 'mes',
-- Todos los dias respetan su limite cronologico
MAX(DAY(shipping_limit_date)) AS 'max_dia', MIN(DAY(shipping_limit_date)) AS 'min_dia',
MAX(YEAR(shipping_limit_date)) AS 'max_año', MIN(YEAR(shipping_limit_date)) AS 'min_año'
FROM items_dataset_silver
GROUP BY MONTH(shipping_limit_date)
ORDER BY 'mes' ASC

-- 4° Validar longitud del codigo
-- La columna FK order_id respeta el estandar de 32 caracteres para el codigo
SELECT DISTINCT(LEN(order_id)) AS 'Longitud del codigo id de orden'
FROM items_dataset_silver;
-- La columna FK product_id respeta el estandar de 32 caracteres para el codigo
SELECT DISTINCT(LEN(product_id)) AS 'Longitud del codigo id de producto'
FROM items_dataset_silver;
-- La columna FK seller_id respeta el estandar de 32 caracteres para el codigo
SELECT DISTINCT(LEN(seller_id)) AS 'Longitud del codigo id de seller'
FROM items_dataset_silver;