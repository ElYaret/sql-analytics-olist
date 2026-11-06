# Hallazgos — SQL Analytics sobre Olist

Dataset: ~99,000 pedidos de e-commerce brasileño (2016-2018), 8 tablas relacionales en PostgreSQL. Las queries están en [`sql/queries.sql`](./sql/queries.sql).

## Concentración geográfica
- São Paulo concentra 41,746 de los 99,441 pedidos (42%); le siguen Rio de Janeiro (12,852) y Minas Gerais (11,635).

## Clientes: agrupar por la clave correcta
- En Olist cada pedido genera un `customer_id` nuevo; la persona real se identifica con `customer_unique_id`.
- Rankear clientes por `customer_id` mide pedidos sueltos, no personas. Al corregirlo, el top 3 cambió en 5 de 27 estados (por ejemplo, el cliente que más gastó en RS pasó de £3,124 a £4,080 al sumar sus compras).
- En el resto de estados el resultado no cambió, porque casi todos los clientes compran una sola vez.

## Ingresos mensuales (ene 2017 – ago 2018)
- Se excluyeron los meses parciales del inicio (sep-dic 2016) y del final (sep 2018): generaban variaciones absurdas (+1,101,719%, -100%).
- Además, no hay pedidos en noviembre 2016, y `LAG()` compara con la fila anterior, no con el mes anterior.
- 2017 fue de crecimiento fuerte: de £120K en enero a £660K en octubre. Noviembre 2017 fue el pico (£1.0M, +52%); la hipótesis es Black Friday, pero el dataset no lo confirma.
- 2018 se estanca: los ingresos se mueven entre £0.85M y £1.0M sin tendencia de crecimiento.

## Entregas: prometido vs real
- El % de pedidos tardíos depende más del colchón en la fecha estimada que de la velocidad real. AL tiene la peor tasa (23.9%) con 24.5 días reales contra 32.6 prometidos; AM, AP, RR y AC son los más lentos (21 a 29 días) pero casi no se atrasan, porque se les promete 41 a 46 días.
- Los atrasos se concentran en el noreste (AL, MA, PI, CE, SE, BA: 14% a 24%).
- Por volumen, SP (~2,400 pedidos tardíos) y RJ (~1,670, tasa de 13.5%) pesan más que AL (~95).
- Limitaciones: RR, AP y AC tienen menos de 100 pedidos, y solo se incluyeron pedidos `delivered` con fecha de entrega, así que los atrasos reales probablemente son mayores.

## Retención por cohorte (2017)
- Menos del 1% de los clientes de cada cohorte vuelve a comprar al mes siguiente (entre 0.2% y 0.7%).
- El crecimiento de Olist depende de captar clientes nuevos, no de recompra: la cohorte de noviembre 2017 tiene 7,270 clientes nuevos y solo 40 repiten al mes siguiente.

## Optimización
- Filtrar `order_items` por `product_id` hacía un `Seq Scan` (112,641 filas descartadas, 104.9 ms). Con `idx_order_items_product_id` pasó a `Index Only Scan` en 0.07 ms (~1,400 veces más rápido).
- Los índices tienen costo (espacio y escrituras más lentas), por eso se crean solo para columnas que se filtran o unen con frecuencia.
