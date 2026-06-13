USE data_silver;

-- 1° Validacion nulos:
-- En las columnas que son necesarias para el analisis:
-- Se tiene una incidencia del 0% de registros nulos en la columna Primary Key
-- Se tiene una incidencia del 0% de registros nulos en la columna Foreign Key
-- Se tiene una incidencia del 0% de registros nulos en la columna order_purchase_timestamp
-- Se tiene una incidencia del 1.80% de registros nulos en la columna order_delivered_carrier_date
-- Se tiene una incidencia del 2.98% de registros nulos en la columna order_delivered_customer_date
-- Se tiene una incidencia del 0% de registros nulos en la columna order_estimated_delivery_date
/* 
CONCLUSION: La presencia de nulos en las fechas de entrega representa una proporcion baja del total de registros. Dado que el 
analisis de OCT requiere trazabilidad temporal completa, estos registros seran documentados y excluidos unicamente cuando impidan 
calcular las metricas principales. La baja incidencia observada permite continuar con el analisis sin comprometer la 
representatividad general del dataset. 
*/
SELECT 
SUM( -- No hay nulos en la PK
    CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos PK id orden',
SUM( -- No hay nulos en la FK
    CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos FK id customer',
SUM( -- No hay nulos en la fecha de compra
    CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos fecha compra',
SUM( -- Hay 1783 nulos en la fecha entrega a aliado logistico
    CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos fecha entrega aliado',
SUM( -- Hay 2965 nulos en la fecha entrega a cliente
    CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos fecha entrega',
SUM( -- No hay nulos en la fecha estimada
    CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS 'Cantidad nulos fecha estimada'
FROM orders_dataset_silver;


-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(order_id) AS 'Cantidad PK duplicadas'
FROM orders_dataset_silver
GROUP BY order_id
HAVING COUNT(order_id) > 1
-- Validacion duplicacion FK: no hay duplicados, se respeta la relacion 1:1 entre order_id y customer_id
SELECT 
COUNT(customer_id) AS 'Cantidad fk duplicadas'
FROM orders_dataset_silver
GROUP BY order_id
HAVING COUNT(customer_id) > 1
-- Validacion duplicacion sin depender de PK ni FK (para detectar ordenes iguales que hayan sido registradas con distintos PK)
SELECT 
order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
order_estimated_delivery_date, COUNT(*)
FROM orders_dataset_silver
GROUP BY customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
         order_estimated_delivery_date
HAVING COUNT(*) > 1

-- 3° Validar Fechas
-- Para order_purchase_timestamp: no hay fechas rotas, OJO: esta columna es la que si o si tiene que respetar los años que indican
-- sucedieron las ordenes en el origen del dataset: desde 2016 a 2018
SELECT 
MONTH(order_purchase_timestamp) AS 'mes',
-- Todos los dias respetan los limites cronologicos de cada mes
MAX(DAY(order_purchase_timestamp)) AS 'max_dia', MIN(DAY(order_purchase_timestamp)) AS 'min_dia',
-- Los años si se encuentran dentro del rango delimitado por el diccionario de datos: de 2016 a 2018
MAX(YEAR(order_purchase_timestamp)) AS 'max_año', MIN(YEAR(order_purchase_timestamp)) AS 'min_año'
FROM orders_dataset_silver
GROUP BY MONTH(order_purchase_timestamp)
ORDER BY 'mes' ASC;

-- Para order_delivered_carrier_date: no hay fechas rotas
SELECT 
MONTH(order_delivered_carrier_date) AS 'mes',
-- Todos los dias respetan los limites cronologicos de cada mes
MAX(DAY(order_delivered_carrier_date)) AS 'max_dia', MIN(DAY(order_delivered_carrier_date)) AS 'min_dia',
MAX(YEAR(order_delivered_carrier_date)) AS 'max_año', MIN(YEAR(order_delivered_carrier_date)) AS 'min_año'
FROM orders_dataset_silver
GROUP BY MONTH(order_delivered_carrier_date)
ORDER BY 'mes' ASC;

-- Para order_delivered_customer_date: no hay fechas rotas
SELECT 
MONTH(order_delivered_customer_date) AS 'mes',
-- Todos los dias respetan los limites cronologicos de cada mes
MAX(DAY(order_delivered_customer_date)) AS 'max_dia', MIN(DAY(order_delivered_customer_date)) AS 'min_dia',
MAX(YEAR(order_delivered_customer_date)) AS 'max_año', MIN(YEAR(order_delivered_customer_date)) AS 'min_año'
FROM orders_dataset_silver
GROUP BY MONTH(order_delivered_customer_date)
ORDER BY 'mes' ASC;

-- Para order_estimated_delivery_date
SELECT 
MONTH(order_estimated_delivery_date) AS 'mes',
-- Todos los dias respetan los limites cronologicos de cada mes
MAX(DAY(order_estimated_delivery_date)) AS 'max_dia', MIN(DAY(order_estimated_delivery_date)) AS 'min_dia',
MAX(YEAR(order_estimated_delivery_date)) AS 'max_año', MIN(YEAR(order_estimated_delivery_date)) AS 'min_año'
FROM orders_dataset_silver
GROUP BY MONTH(order_estimated_delivery_date)
ORDER BY 'mes' ASC;


-- 4° Validar reglas de estandarizacion en codigos
-- Para order_id se mantiene un unico formato de 32 caracteres para el id de la orden
SELECT DISTINCT(LEN(order_id)) AS 'Longitud codigo'
FROM orders_dataset_silver
-- Para customer_id se mantiene un unico formato de 32 caracteres para el id del customer
SELECT DISTINCT(LEN(customer_id)) AS 'Longitud codigo'
FROM orders_dataset_silver