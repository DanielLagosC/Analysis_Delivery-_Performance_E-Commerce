USE data_bronze ;

-- Cargamos la data cruda a cada tabla

BULK INSERT customers_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_originales\olist_customers_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);


BULK INSERT sellers_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_originales\olist_sellers_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);


BULK INSERT products_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_originales\olist_products_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);


BULK INSERT orders_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_originales\olist_orders_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);


BULK INSERT items_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_originales\olist_order_items_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);


BULK INSERT reviews_dataset
FROM 'C:\Users\Daniel\OneDrive\Desktop\DANIEL\Análisis E - Commerce\00_archivos_csv\csv_modificados\olist_order_reviews_dataset_arreglo.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
