USE data_bronze;

-- 1° Validacion nulos:
SELECT 
SUM( -- No hay nulos en la PK
    CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos PK id sellers',
SUM( -- No hay nulos en columna sellers_state
    CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos sellers_state'
FROM sellers_dataset;

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(seller_id) AS 'Cantidad PK duplicadas'
FROM sellers_dataset
GROUP BY seller_id
HAVING COUNT(seller_id) > 1;

-- 3° Validar longitud del codigo
-- Para seller_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(seller_id)) AS 'Longitud del codigo id de seller'
FROM sellers_dataset