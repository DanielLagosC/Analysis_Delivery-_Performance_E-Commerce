# 📦 Delivery Performance Analysis — Olist E-Commerce

Análisis del desempeño logístico de la plataforma brasileña Olist usando arquitectura medallón en SQL Server. El proyecto evalúa el Order Cycle Time (OCT), la puntualidad de entrega, la satisfacción del cliente y el cumplimiento de los vendedores sobre un universo de **96,475 órdenes** con trazabilidad completa de fechas.

---

## 🔍 Hallazgos principales

| Métrica | Resultado |
|---|---|
| Órdenes analizadas | 96,475 |
| OCT promedio | 12.50 días |
| Entregas anticipadas | 91.89% |
| Entregas tardías | 6.77% |
| Satisfacción promedio (tardías) | 2.27 / 5 |
| Satisfacción promedio (anticipadas) | 4.30 / 5 |
| Región con peor OCT | RR — Roraima (29.34 días) |
| Única región con retraso promedio real | AL — Alagoas (+8.7 días vs estimado) |
| Pico histórico de OCT | Marzo 2018 (~15.7 días, promedio móvil) |

> El 91.89% de las órdenes llegó antes de la fecha estimada, lo que refleja una política conservadora de estimación de plazos por parte de Olist — en ocasiones de hasta 156 días para ciertas rutas — más que una eficiencia operativa extraordinaria.

---

## 🏗️ Arquitectura

El proyecto implementa una **arquitectura medallón de tres capas** sobre SQL Server:

```
CSV originales
     │
     ▼
┌─────────────┐
│   BRONZE    │  Ingesta cruda — BULK INSERT, sin transformaciones, todo VARCHAR
└─────────────┘
     │
     ▼
┌─────────────┐
│   SILVER    │  Tipado, estandarización (UPPER/TRIM), constraints, FKs
└─────────────┘
     │
     ▼
┌─────────────┐
│    GOLD     │  Views analíticas + análisis de negocio
└─────────────┘
```

---

## 📁 Estructura del repositorio

```
├── 01_Capa_Bronze/
│   ├── validacion_de_data_cargada/     # Verificación post BULK INSERT por tabla
│   ├── 01_Creacion de tablas Bronze.sql
│   └── 02_Carga de datos crudos (usando BULK INSERT).sql
│
├── 02_Capa_Silver/
│   ├── validacion de data post carga/  # Validación de integridad post transformación
│   ├── 01_Creación tablas Silver.sql
│   └── 02_Script Carga de datos a tablas Silver.sql
│
├── 03_Capa_Gold/
│   ├── 01_Creación de Views (Universo analítico).sql
│   ├── 02_Validación data de universo analítico.sql
│   ├── Data_Analisis_Delivery_Performance.sql
│   └── 04_Analisis_Paso_a_Paso.md      # Narrativa completa del análisis con outputs
│
└── README.md
```

---

## 🔧 Decisiones técnicas y metodológicas

### Capa Bronze 
Ingesta sin transformaciones mediante `BULK INSERT`. El archivo de reseñas requirió preprocesamiento previo (realizado con python pandas) a la carga por problemas de encoding en el CSV original.

### Capa Silver
- Estandarización de strings: `UPPER(TRIM(REPLACE(col, '"', '')))` en todas las columnas de texto
- Conversión de tipos: `VARCHAR → DATETIME, INT, DECIMAL(18,10)`
- Las columnas de ciudad no se normalizaron completamente por alto esfuerzo y bajo impacto en el análisis, que opera a nivel de estado (`customer_state`)
- Constraints: PKs en tablas maestras, FKs encadenadas para garantizar integridad referencial

### Capa Gold — Universo analítico
El universo analítico excluye órdenes con fechas incompletas (sin `order_delivered_customer_date` u otras fechas de trazabilidad). No se aplican filtros por valores extremos ya que representan operaciones reales registradas por Olist.

Se definen tres views:
- **`OCT_ordenes`** — universo base con OCT calculado y clasificación de puntualidad
- **`incidencias_sellers`** — flag binario de incumplimiento del vendedor vs `shipping_limit_date`
- **`reviews_cardinalidad_uno_a_uno`** — subconjunto con cardinalidad 1:1 estricta para evitar sesgos en el análisis de satisfacción

### Métrica central: media aritmética
Se utiliza la media sobre la mediana por las siguientes razones:
- OCT como métrica de proporción de cumplimiento se beneficia de la media ponderada
- Validación empírica: órdenes con OCT > 60 días representan el 0.31% del universo (298 órdenes sobre 96,475), con un impacto máximo de 0.99 días sobre el promedio mensual (2017-03, el mes con menor volumen)
- Los valores extremos se distribuyen de forma uniforme a lo largo del período — el mes con mayor concentración (2018-02) registra 54 casos sobre 6,556 órdenes (0.82%)

> Nota: Olist registra plazos estimados de hasta 156 días para ciertas rutas, por lo que un OCT alto no implica incumplimiento automático. El análisis de puntualidad se basa en la comparación relativa entre OCT real y OCT estimado, no en umbrales absolutos.

### Promedio móvil ponderado (MoM)
El análisis de tendencia mensual usa un promedio móvil de 3 meses calculado como `SUM(OCT) / SUM(órdenes)` sobre ventanas deslizantes, evitando el promedio de promedios que ignora el peso de cada mes.

### Análisis de vendedores
El ranking de incumplimiento se limita a órdenes gestionadas por un único vendedor (95,200 de 96,475) para evitar el sesgo de atribución en órdenes compartidas, donde no es posible determinar cuál vendedor incumplió el plazo de entrega al aliado logístico.

---

## 🛠️ Stack tecnológico

- **SQL Server** — almacenamiento y procesamiento en capas Bronze / Silver / Gold
- **T-SQL** — CTEs, Window Functions (`LAG`, `DENSE_RANK`, `PERCENTILE_CONT`, `SUM OVER`), agregación condicional, `BULK INSERT`

---

## 📂 Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle
