-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 6 of 7: Lead Time
-- Grain: Order level
-- Dependencies: fact_order_line,
--               fact_shipment_line,
--               fact_delivery_event
-- Output: order_id, dc_id, channel, week_num,
--         lead_time_days
-- ============================================

WITH fact_delivery_notnull AS (
    SELECT
        shipment_id,
        delivered_ts
    FROM fact_delivery_event
    WHERE delivered_ts IS NOT NULL
),
fact_ship_del_shipment AS (
    SELECT
        sh.shipment_id,
        sh.shipment_line_id,
        sh.order_id,
        sh.order_line_id,
        de.delivered_ts
    FROM fact_shipment_line AS sh
    INNER JOIN fact_delivery_notnull AS de
        ON sh.shipment_id = de.shipment_id
),
fact_ship_del_orderline AS (
    SELECT
        order_id,
        order_line_id,
        MAX(delivered_ts) AS delivered_dt
    FROM fact_ship_del_shipment
    GROUP BY
        order_id,
        order_line_id
),
fact_order_del_dt AS (
    SELECT
        o.order_id,
        o.order_line_id,
        o.dc_id,
        o.channel,
        strftime('%W', o.order_created_ts) AS week_num,
        o.order_confirmed_ts,
        de.delivered_dt
    FROM fact_order_line AS o
    INNER JOIN fact_ship_del_orderline AS de
        ON o.order_id = de.order_id
        AND o.order_line_id = de.order_line_id
)
SELECT
    order_id,
    dc_id,
    channel,
    week_num,
    julianday(MAX(date(delivered_dt))) - julianday(date(order_confirmed_ts)) AS lead_time
FROM fact_order_del_dt
GROUP BY
    order_id,
    dc_id,
    channel,
    week_num;
