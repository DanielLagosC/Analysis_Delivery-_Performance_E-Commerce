USE data_bronze;

-- 1° Validacion nulos:
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
FROM orders_dataset;

-- 2° 
-- Validacion duplicacion PK: no hay duplicados
SELECT 
COUNT(order_id) AS 'Cantidad PK duplicadas'
FROM orders_dataset
GROUP BY order_id
HAVING COUNT(order_id) > 1;
-- Validacion duplicacion FK: no hay duplicados, se respeta la relacion 1:1 entre order_id y customer_id
SELECT 
COUNT(customer_id) AS 'Cantidad fk duplicadas'
FROM orders_dataset
GROUP BY order_id
HAVING COUNT(customer_id) > 1;
-- Validacion duplicacion sin depender de PK ni FK (para detectar ordenes iguales que hayan sido registradas con distintos PK),
-- no hay duplicados
SELECT 
order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
order_estimated_delivery_date, COUNT(*)
FROM orders_dataset
GROUP BY customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
         order_estimated_delivery_date
HAVING COUNT(*) > 1;


--  3° 
-- Validacion de longitud del campo fecha, debido a que el dato se encuentra como tipo string
-- Todos los campos tienen uniformizado su longitud (19 caracteres), lo que brinda una idea de que las fechas mantienen el mismo 
-- formato en todas las columnas

-- Para order_purchase_timestamp
SELECT DISTINCT(LEN(order_purchase_timestamp)) AS 'Longitud_order_purchase_timestamp'
FROM orders_dataset;
-- Para order_delivered_customer_date
SELECT DISTINCT(LEN(order_delivered_carrier_date)) AS 'Longitud_order_delivered_customer_date'
FROM orders_dataset;
-- Para order_delivered_customer_date
SELECT DISTINCT(LEN(order_delivered_customer_date)) AS 'Longitud_order_delivered_customer_date'
FROM orders_dataset;
-- Para order_estimated_delivery_date
SELECT DISTINCT(LEN(order_estimated_delivery_date)) AS 'Longitud_order_estimated_delivery_date'
FROM orders_dataset;


-- 4° Validar reglas de estandarizacion en codigos
-- Para order_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(order_id)) AS 'Longitud codigo'
FROM orders_dataset
-- Para customer_id hay distintos tipos de longitud (32 y 34), lo que indica que la data no está estandarizada
SELECT DISTINCT(LEN(customer_id)) AS 'Longitud codigo'
FROM orders_dataset