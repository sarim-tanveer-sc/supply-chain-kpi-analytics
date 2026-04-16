-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 5 of 7: Logistics Cost to Revenue
-- Grain: Order level
-- Dependencies: fact_order_line,
--               fact_shipment_line
-- Output: order_id, dc_id, channel, week_num,
--         freight_cost_order, revenue_order,
--         logistics_cost_rev_pct
-- ============================================

WITH fact_shipment_orderline AS (
    SELECT
        order_id,
        order_line_id,
        SUM(shipped_qty) AS shipped_qty_orderline,
        SUM(freight_cost) AS freight_cost_orderline
    FROM fact_shipment_line
    GROUP BY
        order_id,
        order_line_id
),
fact_ship_rev_orderline AS (
    SELECT
        sh.order_id,
        sh.order_line_id,
        sh.shipped_qty_orderline,
        sh.freight_cost_orderline,
        o.dc_id,
        o.channel,
        o.unit_price,
        strftime('%W', o.order_created_ts) AS week_num
    FROM fact_order_line AS o
    INNER JOIN fact_shipment_orderline AS sh
        ON o.order_id = sh.order_id
        AND o.order_line_id = sh.order_line_id
)
SELECT
    order_id,
    dc_id,
    channel,
    week_num,
    SUM(freight_cost_orderline) AS freight_cost_order,
    SUM(unit_price * shipped_qty_orderline) AS revenue_order,
    ROUND(
        (SUM(freight_cost_orderline) / SUM(unit_price * shipped_qty_orderline)) * 100.00,
        2
    ) AS logistics_cost_rev_pct
FROM fact_ship_rev_orderline
GROUP BY
    order_id,
    dc_id,
    channel,
    week_num;
