USE data_gold
GO

-- Validacion de ordenes huerfanas
-- RESULTADO: Todas las ordenes del universo analitico se encuentran en la tabla de items
SELECT *
FROM OCT_ordenes AS universo
WHERE NOT EXISTS (
    SELECT 1
    FROM data_silver.dbo.items_dataset_silver AS items
    WHERE universo.order_id = items.order_id
);

-- RESULTADO: Hay 2040 que no tienen reseñas
-- Hay 94435 ordenes que si tienen reseña DEL UNIVERSO
-- Tiene sentido que si comparamos con la tabla reviews ya limpia de cardinalidad, aumente las ordenes que no están.
-- Ya que la tabla reviews limpia descarto a varias ordenes de por si
SELECT COUNT(*) AS [Cantidad de Ordenes que no tienen reseñas]
FROM OCT_ordenes AS universo
WHERE NOT EXISTS (
     SELECT 1
     FROM reviews_cardinalidad_uno_a_uno AS reviews
     WHERE universo.order_id = reviews.order_id
)


-- Verificacion outliers
------------------------------------------------------------------------------------------------------------------
-- Objetivo: cuantificar el peso de valores extremos de OCT sobre las métricas
-- de tendencia. No se descartan registros ya que representan operaciones reales. 
-- RESULTADO: órdenes con OCT > 60 días representan el 0.31% del universo, distribuidas a lo largo del período. 
-- El mes con mayor concentración (2018-02) registra 54 casos sobre 6,556 órdenes.

-- Olist registra plazos estimados de hasta 156 días para ciertas rutas,
-- por lo que OCT alto no implica incumplimiento automático. Sin embargo, a partir de 60 días
-- la frecuencia cae a menos del 0.31% del universo, lo que permite aislar casos atípicos
-- sin descartar operaciones con plazos legítimamente largos.


-- % de aparicion outliers en relacion a todo el dataset
WITH total_global AS( SELECT COUNT(*) AS total_ordenes FROM OCT_ordenes ),
total_outliers AS ( SELECT COUNT(*) AS cantidad_outliers_60 FROM OCT_ordenes WHERE OCT_de_la_orden > 60 )
SELECT cantidad_outliers_60, (cantidad_outliers_60*100.0)/(total_ordenes*1.0) AS [% de outliers > a 60 dias]
FROM total_outliers
CROSS JOIN total_global;

-- Distribucion de outliers a traves de año-mes
WITH distribucion_temporal AS(
SELECT
order_id, YEAR(order_purchase_timestamp) AS year_, MONTH(order_purchase_timestamp) AS month_, OCT_de_la_orden
FROM OCT_ordenes
WHERE OCT_de_la_orden > 60
)
SELECT 
year_, month_, 
COUNT(order_id) AS [cantidad_outliers], 
MAX(OCT_de_la_orden) AS [maximo OCT registrado]
FROM distribucion_temporal
WHERE year_ IN (2017, 2018)
GROUP BY year_, month_
ORDER BY year_, month_

-- Análisis de robustez de la media
--------------------------------------------------------------------------------------------
-- La diferencia entre el promedio con y sin valores extremos no supera 1 día en ningún mes del análisis
-- (máx. 0.99 días en 2017-03). La media es robusta como métrica central.
SELECT
    YEAR(order_purchase_timestamp) AS año,
    MONTH(order_purchase_timestamp) AS mes,
    COUNT(*) AS cantidad_ordenes,
    COUNT(CASE WHEN OCT_de_la_orden > 60 
             THEN OCT_de_la_orden END) AS cantidad_outliers,
    AVG(OCT_de_la_orden) AS OCT_con_outliers,
    AVG(CASE WHEN OCT_de_la_orden <= 60 
             THEN OCT_de_la_orden END) AS OCT_sin_outliers,
    AVG(OCT_de_la_orden) - 
    AVG(CASE WHEN OCT_de_la_orden <= 60 
             THEN OCT_de_la_orden END) AS diferencia
FROM OCT_ordenes
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY año, mes
