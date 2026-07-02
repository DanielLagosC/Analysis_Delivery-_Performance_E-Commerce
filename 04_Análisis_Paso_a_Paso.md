
I. Panorama general del desempeño logístico
-----------------------------------------------------------------------------------
#### 1. ¿Cuántas órdenes hay?
```sql
SELECT COUNT(*) AS [Ordenes totales]
FROM OCT_ordenes
```
<img width="208" height="65" alt="image" src="https://github.com/user-attachments/assets/a004d94c-21d8-4842-9686-6df263c96f58" />


#### 2. ¿Cuál es el Order Cycle Time (OCT) promedio entre todas las órdenes?
```sql
SELECT 
ROUND(AVG(OCT_de_la_orden), 2) AS [OCT promedio de las ordenes]
FROM OCT_ordenes
```
<img width="322" height="62" alt="image" src="https://github.com/user-attachments/assets/5a60e47f-b0a1-4750-9343-58ea51fa3010" />


#### 3. ¿Cuántas órdenes hay por su puntualidad a la hora de ser entregadas?
```sql
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
CROSS JOIN total_gral AS t
```
<img width="677" height="132" alt="image" src="https://github.com/user-attachments/assets/634bcc76-579a-4b32-b87d-75fbec435a6c" />


#### 4. ¿Como influye la puntualidad de entrega de la orden en la satisfaccion del cliente?, una aproximacion usando el review_score

**Primero validamos qué relación de órdenes y reseñas respetan una cardinalidad 1:1 (uno a uno)**, puesto que hay muchas órdenes que tienen dirigidas distintas reseñas (lo cual no tiene sentido si solo lo ha comprado una sola persona) y hay reseñas que están dirigadas a 
más de 1 orden (lo que tampoco tiene sentido ya que eso significaría que un cliente está opinando sobre órdenes de productos que no le corresponde o ni siquiera pidió) 
```sql
DECLARE @total_ordenes INT = (SELECT COUNT(*) FROM OCT_ordenes)

SELECT COUNT(*) AS ordenes_con_reviews,
       @total_ordenes - COUNT(*) AS [ordenes_sin_reviews]
FROM OCT_ordenes AS universo
WHERE EXISTS (
     SELECT 1
     FROM reviews_cardinalidad_uno_a_uno AS reviews
     WHERE universo.order_id = reviews.order_id
)
```
<img width="578" height="71" alt="image" src="https://github.com/user-attachments/assets/a7cf32dc-6b34-49c1-9216-bdea564e0e32" />


Con estos resultados en cuenta, sabemos que **estamos aplicando el análisis sobre el 97.89%** de nuestro universo de órdenes total, esto es aceptable sabiendo que lo restante son datos que alterarian y sesgarian completamente el análisis, contándose puntuaciones a ordenes 
con puntualidad de entrega que no le corresponden
```sql
SELECT puntualidad, COUNT(o.order_id) AS [Cantidad Ordenes], AVG(review_score*1.0) AS [satisfaccion_score_promedio]
FROM OCT_ordenes AS o   
INNER JOIN reviews_cardinalidad_uno_a_uno AS r
          ON o.order_id = r.order_id
GROUP BY puntualidad
```
<img width="743" height="137" alt="image" src="https://github.com/user-attachments/assets/97b28f54-58e0-45ef-9d05-5f444b5e3876" />

Se observa que la impuntualidad de la entrega está relacionada a una menor satisfacción de los clientes.







II. Delivery performance por región
------------------------------------------------------------------------------------------------------------------------
##### 1. ¿Cuáles son las 10 regiones con peor OCT?
```sql
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
WHERE ranking <= 10
```
<img width="552" height="356" alt="image" src="https://github.com/user-attachments/assets/8802dc91-ea0e-481c-a7af-a7ffd7e60f60" />


#### 2. ¿Cuáles son las 10 regiones con peor promedio de diferencia de días entre la fecha estimada y la fecha real de entrega?
```sql
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
WHERE ranking <= 10
```
<img width="582" height="361" alt="image" src="https://github.com/user-attachments/assets/74ba6d06-eb57-4f9d-aa4f-6d9d6fd229f0" />


III. Evolucion del OCT mes a mes (MoM)
-------------------------------------------------------------------------------------------------------------------------------------
ACLARACION: Para este análisis se consideraran los años 2017 a 2018, ya que el año 2016 solo presenta data de 3 meses y de forma descontinuada (Solo tiene registros de septiembre, octubre y diciembre), donde 2 de esos meses solo tiene 1 registro de orden

```sql
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
ORDER BY [year_] ASC, [month_] ASC
```
<img width="1105" height="690" alt="image" src="https://github.com/user-attachments/assets/a00845aa-f8d6-4c80-9e99-712ca197d006" />


Debido a que la variacion mes a mes presenta picos muy altos, se observara la tendencia con promedio movil

```sql
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
WHERE meses_ventana = 3
```
<img width="1262" height="620" alt="image" src="https://github.com/user-attachments/assets/0ec85c9f-457c-4c23-88f8-c163a1ccf1a9" />

A lo largo del tiempo se observan tendencias claras con respecto al desempeño de entrega: en el periodo que abarca desde mayo hasta septiembre del año 2017 se observa una leve pero continua disminución del Order Cycle Time (OCT) para que luego, en el periodo desde octubre del año 2017 hasta marzo del año 2018 se produzca una tendencia creciente (viéndose más acentuada de octubre a noviembre de año 2017) alcanzo un máximo histórico en el mes de marzo del 2018, teniendo el negocio un OCT de aproximadamente 15 días. Después de este pico, el resto de los meses se vuelve a observar otra tendencia decreciente mucho más marcada que la inicial.  


IV. Análisis de desempeño de los vendedores en el proceso logístitoc de las órdenes
-------------------------------------------------------------------------------------
#### 1. ¿Cuál es la tasa de órdenes cuyos vendedores incumplieron el plazo de entrega de los productos al proveedor logístico?
```sql
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
```
<img width="1157" height="132" alt="image" src="https://github.com/user-attachments/assets/bfc16fcb-636d-4435-be85-5f3aa498722b" />

Es interesante observar el hecho de que poco más de 1/4 de las órdenes con entregas tardías y con entregas a tiempo estén ligadas al incumplimiento de los plazos de entrega que tienen los vendedores a cargo de esas órdenes, esto permite formular dos visiones del desempeño por parte del vendedor y por parte del aliado logístico:  
1) Se podría teorizar que existen algunas órdenes cuya entrega tardía se debe más al incumplimento e irresponsabilidad con los plazos de entrega del prodcucto por parte de los vendedores que por la irresponsabilidad del servicio logístico del negocio.  
2) Se puede observar casos excepcionales de buen desempeño por parte del servicio logístico para que, pese a la demora por parte del vendedor con la entrega del producto, lograron gestionar bien sus operaciones para de todas maneras lograr cumplir con la fecha estimada de entrega indicada al cliente.


#### 2. ¿Cuáles son los vendedores con mayor incumplimientos en los plazos de entrega de sus productos?
ACLARACIÓN: Este análisis se limita a órdenes cuyos articulos pertencen a 1 solo vendedor por sesgo de recuento si se considera ordenes con articulos pertenecientes a 2 o mas vendedores, ya que no hay forma de diferenciar cuál falló demoró realmente con la entrega (debido a que 
comparten misma fecha de entrega al proveedor logistico). Debido a eso, es posible que vendedores con mas ventas se vean en la situacion de tener incidencias adjudicadas a pesar de que en realidad no haya sido su culpa, al compartir ordenes con otros vendedores que realmente 
incumplan su plazo de entrega con mayor frecuencia. Con la siguiente query observamos cuántas órdenes realmente cumplen esa regla

```sql
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
               HAVING COUNT(DISTINCT seller_id) = 1)
```
<img width="725" height="71" alt="image" src="https://github.com/user-attachments/assets/8400c949-f0c5-4538-bd6e-ebf6a0cae4db" />


Con esos resultados, sabremos que el ranking se hará en base al 98.67% del universo de órdenes
```sql
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
```
<img width="1140" height="812" alt="image" src="https://github.com/user-attachments/assets/9a614cb4-1d95-4e30-85f6-2eb94ad361ed" />

Estos resultados representan un llamado a la toma de medidas correctivas para bajar la tasa de incumplimiento de los vendedores con los plazos de la entrega de sus productos al servicio de delivery, ya que, con lo observado anteriormente, podría terminar en la entrega tardía del producto y por lo tanto con la insatisfacción del cliente con respecto a la calidad del servicio del negocio.
