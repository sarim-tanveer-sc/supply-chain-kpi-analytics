-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 2 of 7: Delivery Spine
-- Grain: Order level
-- Dependencies: fact_shipment_line, 
--               fact_delivery_event, 
--               fact_order_line
-- Output: order_id, dc_id, channel,
--         delivered_ot_flag, delivered_if_flag
-- ============================================

WITH fact_order_pdt AS (
    SELECT sh.shipment_id, sh.order_id, sh.order_line_id, 
           o.promised_delivery_date, o.channel, o.dc_id
    FROM fact_shipment_line AS sh
    INNER JOIN fact_order_line AS o
    ON sh.order_id = o.order_id AND sh.order_line_id = o.order_line_id
),
fact_del_ot_flag AS (
    SELECT o.shipment_id, o.order_id, o.order_line_id, o.dc_id, o.channel, 
           o.promised_delivery_date, de.delivered_ts,
    CASE WHEN de.delivered_ts IS NULL THEN 0
         WHEN date(de.delivered_ts) <= o.promised_delivery_date THEN 1 ELSE 0 
    END AS delot_flag_shipment
    FROM fact_order_pdt AS o
    INNER JOIN fact_delivery_event AS de
    ON o.shipment_id = de.shipment_id
),
fact_del_if_flag AS (
    SELECT sh.shipment_id, sh.order_id, sh.order_line_id, sh.dc_id,
    CASE WHEN de.damage_flag = 1 THEN 0
         WHEN de.loss_flag = 1 THEN 0 ELSE 1 
    END AS delif_flag_shipment
    FROM fact_shipment_line AS sh
    INNER JOIN fact_delivery_event AS de
    ON sh.shipment_id = de.shipment_id
)
SELECT dot.order_id, dot.dc_id, dot.channel,
    MIN(dot.delot_flag_shipment) AS delivered_ot_flag,
    MIN(dif.delif_flag_shipment) AS delivered_if_flag
FROM fact_del_ot_flag AS dot
INNER JOIN fact_del_if_flag AS dif
ON dot.shipment_id = dif.shipment_id
GROUP BY dot.order_id, dot.dc_id, dot.channel;
