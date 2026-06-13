USE data_gold
GO

-- Definimos el universo analitico, que contiene las ordenes que permiten trazabilidad contando aquellas que tienen la fecha de la
-- compra hasta la fecha de cuando la orden se entrega al cliente, permitiendo el calculo del OCT. Ademas, contienen las ordenes 
-- que tienen la fecha de cuando la orden fue entregada al aliado logistico para permitir la identificacion de los vendedores que 
-- cumplieron o no su plazo de entrega del articulo.

CREATE VIEW OCT_ordenes AS
SELECT
order_id,
customer_id,
order_purchase_timestamp,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date,
CASE -- La diferencia de datatype 'DATE' es para comparar dias y meses, no horas, que la fecha estimada solo tiene fecha.
    WHEN CAST(order_delivered_customer_date AS DATE) = CAST(order_estimated_delivery_date AS DATE) THEN 'A TIEMPO'
    WHEN CAST(order_delivered_customer_date AS DATE) > CAST(order_estimated_delivery_date AS DATE) THEN 'TARDIO'
    WHEN CAST(order_delivered_customer_date AS DATE) < CAST(order_estimated_delivery_date AS DATE) THEN 'ANTICIPADO'
END AS puntualidad,
DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)*1.0 AS OCT_de_la_orden
FROM data_silver.dbo.orders_dataset_silver
WHERE order_id IS NOT NULL AND
      customer_id IS NOT NULL AND
      order_purchase_timestamp IS NOT NULL AND
      order_delivered_carrier_date IS NOT NULL AND
      order_delivered_customer_date IS NOT NULL AND
      order_estimated_delivery_date IS NOT NULL
GO


CREATE VIEW incidencias_sellers AS
SELECT u.order_id AS order_id, 
       order_item_id, 
       product_id,
       seller_id, 
       shipping_limit_date, 
       order_delivered_carrier_date, 
       puntualidad, 
       CASE 
            WHEN order_delivered_carrier_date <= shipping_limit_date THEN 0 ELSE 1 
       END AS incumplimiento_seller
FROM data_gold.dbo.OCT_ordenes AS u
LEFT JOIN data_silver.dbo.items_dataset_silver AS i
           ON u.order_id = i.order_id
GO

-- Definimos una vista con la tabla reviews delimitada solo por el subconjunto conservador y metodológicamente más confiable para 
--analizar la relación entre desempeño logístico y satisfacción del cliente, aquellas ordenes y reseñas que tengan 
-- estrictamente cardinalidad 1:1. Las relaciones que incumplan esa regla no se consideran necesariamente erróneas, pero sí ambiguas 
-- para un análisis agregado a nivel orden.
CREATE VIEW reviews_cardinalidad_uno_a_uno AS
WITH filtro AS(
SELECT
review_id,
order_id,
review_score,
COUNT(*) OVER(PARTITION BY order_id) AS cantidad_reviews_dirigidas_a_una_orden,
COUNT(*) OVER(PARTITION BY review_id) AS cantidad_ordenes_relacionadas_a_una_review
FROM data_silver.dbo.reviews_dataset_silver
)
SELECT 
review_id,
order_id,
review_score
FROM filtro
WHERE cantidad_reviews_dirigidas_a_una_orden = 1
      AND cantidad_ordenes_relacionadas_a_una_review = 1
GO