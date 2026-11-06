# 🗄️ SQL Analytics — Olist E-Commerce

## Problema de negocio
¿Dónde está el valor de un e-commerce y dónde se pierde? Este proyecto responde con SQL sobre un modelo relacional: concentración de pedidos por región, clientes de mayor gasto, evolución mensual de ingresos, cumplimiento de entregas y retención de clientes. Cierra con un ejercicio de optimización de consultas.

## Datos
- Fuente: [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- ~99,000 pedidos de 2016 a 2018, en 8 tablas relacionadas (clientes, pedidos, items, productos, vendedores, pagos, reseñas y traducción de categorías)
- Los CSV no se incluyen en el repositorio por su tamaño

## Contenido
- [`sql/schema.sql`](./sql/schema.sql): creación de las 8 tablas, con llaves primarias (algunas compuestas), llaves foráneas y un índice
- [`sql/queries.sql`](./sql/queries.sql): 7 consultas documentadas
- [`HALLAZGOS.md`](./HALLAZGOS.md): resultados e interpretación

## Técnicas SQL practicadas
`JOIN` de varias tablas, `GROUP BY`, window functions (`RANK()`, `LAG()`), CTEs encadenadas, `FILTER` en agregados, cálculo de cohortes de retención, `EXPLAIN ANALYZE` e índices.

## Hallazgos clave
Detalle completo en [HALLAZGOS.md](./HALLAZGOS.md). Resumen:
- Rankear clientes por `customer_id` mide pedidos, no personas; la clave correcta es `customer_unique_id` (cambió el top 3 en 5 de 27 estados)
- Los atrasos en entregas dependen más del margen de la fecha prometida que de la velocidad real
- Menos del 1% de los clientes vuelve a comprar al mes siguiente
- Un índice sobre `order_items(product_id)` redujo una consulta de ~105 ms a ~0.07 ms

## Tecnologías usadas
PostgreSQL 18, SQL, pgAdmin

## Cómo ejecutar este proyecto
1. Crea la base de datos y las tablas:
```bash
createdb olist_ecommerce
psql -d olist_ecommerce -f sql/schema.sql
```
2. Descarga el dataset desde el link de Kaggle y coloca los CSV en `data/`.
3. Carga los datos en este orden (respeta las llaves foráneas):
```bash
psql -d olist_ecommerce -c "\copy customers FROM 'data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy products FROM 'data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy sellers FROM 'data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy product_category_name_translation FROM 'data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy orders FROM 'data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy order_items FROM 'data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy order_payments FROM 'data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
psql -d olist_ecommerce -c "\copy order_reviews FROM 'data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
```
4. Abre `sql/queries.sql` y ejecuta las consultas desde psql o pgAdmin.
