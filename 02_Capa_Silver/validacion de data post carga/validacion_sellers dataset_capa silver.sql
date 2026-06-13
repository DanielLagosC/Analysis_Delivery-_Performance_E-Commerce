USE data_silver;

-- 1° Validacion nulos:
SELECT 
SUM( -- No hay nulos en la PK
    CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos PK id sellers',
SUM( -- No hay nulos en columna sellers_state
    CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos sellers_state'
FROM sellers_dataset_silver

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(seller_id) AS 'Cantidad PK duplicadas'
FROM sellers_dataset_silver
GROUP BY seller_id
HAVING COUNT(seller_id) > 1

-- 3° Validar longitud del codigo
-- Para seller_id se mantiene un unico formato de 32 caracteres para el id del vendedor
SELECT DISTINCT(LEN(seller_id)) AS 'Longitud del codigo id de seller'
FROM sellers_dataset_silver