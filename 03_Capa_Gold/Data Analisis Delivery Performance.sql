USE data_gold
GO

--============================================================
-- ANÁLISIS DE DELIVERY PERFORMANCE - E COMMERCE
--============================================================
-- Universo analítico: órdenes con trazabilidad completa de fechas(order_purchase_timestamp, 
-- order_delivered_carrier_date y order_delivered_customer_date no nulas).
-- No se aplican filtros por valores extremos ya que representan operaciones reales registradas por Olist.
-- Métrica central: media aritmética. Robustez validada en archivo '02_Validación data de universo analítico'
--============================================================

-- Cantidad de Ordenes del Universo Analitico
--------------------------------------------------------------------------
SELECT COUNT(*) AS [Ordenes totales]
FROM OCT_ordenes


-- OCT promedio del dataset
--------------------------------------------------------------------------
SELECT 
ROUND(AVG(OCT_de_la_orden), 2) AS [OCT promedio de las ordenes]
FROM OCT_ordenes;


-- % de puntualidad
--------------------------------------------------------------------------
WITH total_gral AS(
SELECT COUNT(*)*1.0 AS total
FROM OCT_ordenes
),
agregacion AS(
SELECT puntualidad, COUNT(*)*1.0 AS [cantidad_ordenes]
FROM OCT_ordenes
GROUP BY puntualidad
)
SELECT 
a.puntualidad, [cantidad_ordenes], CAST( ( ([cantidad_ordenes]*100)/total ) AS DECIMAL(5,2)) AS [% respecto al total]
FROM agregacion AS a    
CROSS JOIN total_gral AS t;


-- ¿Como influye la puntualidad de entrega de la orden en la satisfaccion del cliente?, una aproximacion usando el review_score
---------------------------------------------------------------------------------------------------------------------------------
DECLARE @total_ordenes INT = (SELECT COUNT(*) FROM OCT_ordenes)

SELECT COUNT(*) AS ordenes_con_reviews,
       @total_ordenes - COUNT(*) AS [ordenes_sin_reviews]
FROM OCT_ordenes AS universo
WHERE EXISTS (
     SELECT 1
     FROM reviews_cardinalidad_uno_a_uno AS reviews
     WHERE universo.order_id = reviews.order_id
);

-- (Analisis realizado en base al 97.89% de la poblacion de ordenes)
SELECT puntualidad, COUNT(o.order_id) AS [Cantidad Ordenes], AVG(review_score*1.0) AS [satisfaccion_score_promedio]
FROM OCT_ordenes AS o   
INNER JOIN reviews_cardinalidad_uno_a_uno AS r
          ON o.order_id = r.order_id
GROUP BY puntualidad;


-- PERFORMANCE POR REGION
------------------------------------------------------------------------------------------------------------------------
-- Top 10 regiones con peor OCT
WITH ranking AS(
SELECT 
customer_state,
CAST(AVG(OCT_de_la_orden) AS DECIMAL(5,2)) AS OCT_promedio,
DENSE_RANK() OVER (ORDER BY AVG(OCT_de_la_orden) DESC) AS ranking
FROM OCT_ordenes AS oct
JOIN data_silver.dbo.customers_dataset_silver AS cus
     ON oct.customer_id = cus.customer_id
GROUP BY customer_state)
SELECT *
FROM ranking
WHERE ranking <= 10;

-- Top 10 regiones con peor promedio de diferencia entre fecha estimada y fecha real de entrega
WITH ranking AS(
SELECT 
customer_state,
AVG(DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)*1.0) AS dias_diferencia,
DENSE_RANK() OVER (ORDER BY AVG(DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)*1.0) DESC) AS ranking
FROM OCT_ordenes AS oct
JOIN data_silver.dbo.customers_dataset_silver AS cus
     ON oct.customer_id = cus.customer_id
GROUP BY customer_state
)
SELECT *
FROM ranking
WHERE ranking <= 10;


-- Evolucion mes a mes (MoM)
-- ACLARACION: Para este análisis se consideraran los años 2017 a 2018, ya que el año 2016 solo presenta data de 3 meses
--             y de forma descontinuada (Solo tiene registros de septiembre, octubre y diciembre), donde 2 de esos meses 
--             solo tiene 1 registro de orden
-------------------------------------------------------------------------------------------------------------------------------------
WITH calculo_mes_a_mes AS(
SELECT
YEAR(order_purchase_timestamp) AS [year_],
MONTH(order_purchase_timestamp) AS [month_],
COUNT(order_id) AS [cantidad_ordenes],
AVG(OCT_de_la_orden) AS [OCT_de_ordenes_generadas_del_mes],
LAG(AVG(OCT_de_la_orden)) OVER (ORDER BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)) AS [OCT_mes_anterior]
FROM OCT_ordenes
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT
[year_], [month_], cantidad_ordenes,
[OCT_de_ordenes_generadas_del_mes],
( ([OCT_de_ordenes_generadas_del_mes] - [OCT_mes_anterior]) / [OCT_mes_anterior] )*100 AS [Variacion_MoM]
FROM calculo_mes_a_mes
ORDER BY [year_] ASC, [month_] ASC;


-- Debido a que la variacion mes a mes presenta picos muy altos, se observara la tendencia con promedio movil

-- Aclaración: el promedio de los promedios no refleja el resultado real, ya que no se tendria en cuenta
-- la cantidad de ordenes que tiene cada mes y mas bien se les trataria como si todas tuvieran el mismo peso cuando no es asi
-- Por ello, como la tabla esta a nivel de orden individual, primero hay que dejar el terreno de agregaciones matematicas a nivel
-- simple de ordenes, para luego recien hacer la formula de promedio = (suma total/cantidad) con windows functions para que sea movil
WITH data_para_promedio_movil AS(
SELECT
YEAR(order_purchase_timestamp) AS [year_], MONTH(order_purchase_timestamp) AS [month_],
SUM(OCT_de_la_orden) AS [suma_oct_mes], 
(COUNT(*)*1.0) AS [cantidad_ordenes],
COUNT(CASE WHEN OCT_de_la_orden > 60 THEN OCT_de_la_orden END) AS [cantidad_outliers]
FROM OCT_ordenes
WHERE YEAR(order_purchase_timestamp) IN (2017,2018)
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
),
promedio_movil AS(
SELECT 
[year_], [month_], [cantidad_ordenes], [cantidad_outliers],
(
--Aqui calculamos la suma de oct de 3 meses
SUM(suma_oct_mes) OVER (ORDER BY year_, month_ ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) 
/
--Aqui calculamos la suma de ordenes totales en esos 3 meses 
SUM(cantidad_ordenes) OVER (ORDER BY year_, month_ ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
) AS [promedio_movil_3_meses],
--Aqui colocamos la regla de filtro para descartar aquellos promedios que no usar la ventana de tiempo de 3 meses
COUNT(*) OVER (ORDER BY year_, month_ ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS meses_ventana
FROM data_para_promedio_movil
)
SELECT
year_,
month_,
cantidad_ordenes,
cantidad_outliers,
promedio_movil_3_meses,
((promedio_movil_3_meses - ( LAG(promedio_movil_3_meses) OVER (ORDER BY year_, month_) ))*100)
/
(LAG(promedio_movil_3_meses) OVER (ORDER BY year_, month_)) 
AS [variacion_MoM]
FROM promedio_movil
WHERE meses_ventana = 3;


--=============================================
-- ANALISIS DESEMPEÑO DE VENDEDORES
--=============================================
-- Tasa de incidencias de los vendedores por estado de puntualidad de la orden
WITH conteo_ordenes AS(
SELECT puntualidad, COUNT(*) AS cantidad_ordenes
FROM OCT_ordenes
GROUP BY puntualidad
),
data_incumplimiento AS(
SELECT order_id, puntualidad, SUM(incumplimiento_seller) AS suma_incidencias
FROM incidencias_sellers
GROUP BY order_id, puntualidad
HAVING SUM(incumplimiento_seller) > 0
),
agregacion_incumplimiento AS(
SELECT 
puntualidad, COUNT(*) AS [ordenes con incidencia seller]
FROM data_incumplimiento AS a
GROUP BY puntualidad
)
SELECT a.puntualidad, [ordenes con incidencia seller], cantidad_ordenes,
       ([ordenes con incidencia seller]*100.0)/(cantidad_ordenes*1.0) AS [% ordenes con incidencia seller]
FROM agregacion_incumplimiento AS a
JOIN conteo_ordenes AS c ON a.puntualidad = c.puntualidad
GO


-- Top sellers con mayor incumplimiento de plazos de entrega (limitado solo a ordenes cuya gestion recae en 1 solo vendedor)
-- Aclaracion con pruebas: se limita a ordenes cuyos articulos pertencen a 1 solo vendedor por sesgo de recuento si se considera
-- ordenes con articulos pertenecientes a 2 o mas vendedores, ya que no hay forma de diferenciar si es que 1 de ellos fue el que 
-- fallo o fueron los 2 en realidad (debido a que comparten misma fecha de entrega al aliado logistico, con exacto numero de minuto y 
-- segundos). Debido a eso, es posible que vendedores con mas ventas se vean en la situacion de tener incidencias adjudicadas a pesar 
-- de que no haya sido su culpa, al compartir ordenes con otros vendedores que realmente incumplan su plazo de entrega con mayor 
-- frecuencia. De todas formas, en la siguiente query se demuestra que la diferencia es significativa, hay 95200 ordenes que 
-- corresponden a 1 solo seller mientras que solo hay 1275 ordenes que estan conformadas por la participacion de 2 a mas vendedores.
DECLARE @total_ordenes INT = (SELECT COUNT(*) FROM OCT_ordenes)

SELECT
COUNT(DISTINCT order_id) AS total_ordenes_con_1_vendedor,
(@total_ordenes - COUNT(DISTINCT order_id)) AS total_ordenes_con_mas_1_vendedor
FROM incidencias_sellers AS i1
WHERE EXISTS (
               SELECT order_id, COUNT(DISTINCT seller_id)
               FROM incidencias_sellers AS i2
               WHERE i1.order_id = i2.order_id
               GROUP BY order_id
               HAVING COUNT(DISTINCT seller_id) = 1);

-- Dicho lo anterior, el top sellers con mayor frecuencia de incumplimiento de plazo de entregas son los siguientes:
-- (Ranking calculado en base al 98.67% de la poblacion de ordenes)
WITH encargo_individual AS(
SELECT 
order_id, 
seller_id, 
MAX(incumplimiento_seller) AS incumplimiento_seller -- Colapsa a nivel orden-seller; si existe al menos una incidencia, marca 1
FROM incidencias_sellers AS i1
WHERE EXISTS ( -- Para traer order_id que cumplan la regla de 1 solo vendedor
               SELECT order_id, COUNT(DISTINCT seller_id)
               FROM incidencias_sellers AS i2
               WHERE i1.order_id = i2.order_id -- Para indicar explicitamente que se quiere hacer la comparacion con order_id
               GROUP BY order_id
               HAVING COUNT(DISTINCT seller_id) = 1) -- Para filtrar ordenes que fueron gestionadas solo por 1 vendedor 
GROUP BY order_id, seller_id -- Evita duplicar órdenes por múltiples ítems del mismo seller
)
SELECT 
seller_id, 
SUM(incumplimiento_seller) AS [ordenes_con_incidencia_seller], -- Total de órdenes del seller con al menos una incidencia
COUNT(order_id) AS cantidad_ordenes, -- Para contar el total de ordenes 
((SUM(incumplimiento_seller)*1.0)*100)/(COUNT(order_id)*1.0) AS [% de incidencia] -- Para hacer el % de incidencias por seller
FROM encargo_individual
GROUP BY seller_id
ORDER BY [ordenes_con_incidencia_seller] DESC
