USE data_silver;

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
FROM products_dataset_silver

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(product_id) AS 'Cantidad PK duplicadas'
FROM products_dataset_silver
GROUP BY product_id
HAVING COUNT(product_id) > 1
-- Para esta tabla especifica, es posible que coincidan especificaciones para distintos productos, por lo que se eligira confiar
-- en su SKU (osea su id), ademas, los productos no son el meollo del asunto, por eso se sigue con el analisis

-- 3° Validar longitud del codigo: 
-- Para product_id se mantiene un unico formato de 32 caracteres para el id del producto
SELECT DISTINCT(LEN(product_id)) AS 'Longitud del codigo id de producto'
FROM products_dataset_silver