-- Pedidos totales por estado del cliente
SELECT
    c.customer_state,
    COUNT(*) AS total_pedidos
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_pedidos DESC;


-- total gastado por cliente y ranking
SELECT
    c.customer_state,
    c.customer_id,
    SUM(oi.price) AS total_gastado,
    RANK() OVER (PARTITION BY c.customer_state ORDER BY SUM(oi.price) DESC) AS ranking_en_su_estado
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state, c.customer_id
ORDER BY c.customer_state, ranking_en_su_estado
LIMIT 50;


-- Top 3 clientes por gasto en cada estado.
-- Agrupo por customer_unique_id (no customer_id): en Olist cada pedido genera un customer_id nuevo.
WITH ranking_clientes AS (
    SELECT
        c.customer_state,
        c.customer_unique_id,
        SUM(oi.price) AS total_gastado,
        RANK() OVER (PARTITION BY c.customer_state ORDER BY SUM(oi.price) DESC) AS ranking_en_su_estado
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_state, c.customer_unique_id
)
SELECT *
FROM ranking_clientes
WHERE ranking_en_su_estado <= 3
ORDER BY customer_state, ranking_en_su_estado;


-- Ingresos por mes y crecimiento % vs mes anterior.
-- Solo meses completos (ene-2017 a ago-2018): antes y después hay datos parciales que distorsionan el %.
WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
        SUM(oi.price) AS ingresos
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'canceled'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    mes,
    ingresos,
    LAG(ingresos) OVER (ORDER BY mes) AS ingresos_mes_anterior,
    ROUND(100.0 * (ingresos - LAG(ingresos) OVER (ORDER BY mes))
          / LAG(ingresos) OVER (ORDER BY mes), 1) AS crecimiento_pct
FROM ventas_mensuales
ORDER BY mes;



-- Hallazgo: el % de atrasos depende más del colchón en la fecha estimada que de la velocidad real.
-- AL promete 32 días y entrega en 24 (23.9% tardíos); AM/AP/RR/AC son lentos pero casi no se atrasan.

-- Tiempo de entrega real vs estimado por estado del cliente.
-- Solo pedidos entregados con fecha de entrega registrada.
SELECT
    c.customer_state,
    COUNT(*) AS pedidos,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400)::numeric, 1) AS dias_reales,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400)::numeric, 1) AS dias_estimados,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) / COUNT(*), 1) AS pct_tardios
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY pct_tardios DESC;



-- Menos del 1% de los clientes de cada cohorte vuelve a comprar en los 3 meses siguientes; el crecimiento de Olist depende de captar clientes nuevos, no de recompra.

-- Retención por cohorte: clientes (customer_unique_id) según su mes de primera compra
-- y cuántos compran de nuevo hasta 3 meses después. Cohortes de 2017.
WITH compras AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS mes_compra
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'canceled'
),
primera_compra AS (
    SELECT customer_unique_id, MIN(mes_compra) AS mes_cohorte
    FROM compras
    GROUP BY customer_unique_id
)
SELECT
    p.mes_cohorte,
    (EXTRACT(YEAR FROM AGE(c.mes_compra, p.mes_cohorte)) * 12
     + EXTRACT(MONTH FROM AGE(c.mes_compra, p.mes_cohorte)))::int AS meses_desde_primera,
    COUNT(DISTINCT c.customer_unique_id) AS clientes_que_compraron
FROM compras c
JOIN primera_compra p ON c.customer_unique_id = p.customer_unique_id
WHERE p.mes_cohorte BETWEEN '2017-01-01' AND '2017-12-01'
  AND c.mes_compra <= p.mes_cohorte + INTERVAL '3 months'
GROUP BY p.mes_cohorte, meses_desde_primera
ORDER BY p.mes_cohorte, meses_desde_primera;