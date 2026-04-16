-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 4 of 7: OTIF Derivation
-- Grain: Order level
-- Dependencies: Release Spine, Shipment Spine,
--               Delivery Spine
-- Output: order_id, dc_id, channel,
--         otif_flag (dynamically derived)
-- ============================================

WITH fact_release_ot_flag_per_order_line AS (
    SELECT
        o.order_id,
        o.order_line_id,
        o.channel,
        o.dc_id,
        CASE WHEN date(re.release_ts) <= o.release_SLA_date THEN 1 ELSE 0
        END AS release_ot_flag_per_order_line
    FROM fact_order_line AS o
    INNER JOIN fact_release_event AS re
        ON o.order_id = re.order_id
        AND o.order_line_id = re.order_line_id
),
fact_release_if_flag_per_order_line AS (
    SELECT
        o.order_id,
        o.order_line_id,
        o.dc_id,
        o.channel,
        CASE WHEN re.release_qty = o.ordered_qty THEN 1 ELSE 0
        END AS release_if_flag_per_order_line
    FROM fact_order_line AS o
    INNER JOIN fact_release_event AS re
        ON o.order_id = re.order_id
        AND o.order_line_id = re.order_line_id
),
fact_released_flag AS (
    SELECT
        ot.order_id,
        ot.dc_id,
        ot.channel,
        MIN(ot.release_ot_flag_per_order_line) AS release_ot_flag,
        MIN(rif.release_if_flag_per_order_line) AS release_if_flag
    FROM fact_release_ot_flag_per_order_line AS ot
    INNER JOIN fact_release_if_flag_per_order_line AS rif
        ON ot.order_id = rif.order_id
        AND ot.dc_id = rif.dc_id
        AND ot.channel = rif.channel
    GROUP BY
        ot.order_id,
        ot.dc_id,
        ot.channel
),
fact_order_pdt AS (
    SELECT
        sh.shipment_id,
        sh.order_id,
        sh.order_line_id,
        o.promised_delivery_date,
        o.channel,
        o.dc_id
    FROM fact_shipment_line AS sh
    INNER JOIN fact_order_line AS o
        ON sh.order_id = o.order_id
        AND sh.order_line_id = o.order_line_id
),
fact_del_ot_flag AS (
    SELECT
        o.shipment_id,
        o.order_id,
        o.order_line_id,
        o.dc_id,
        o.channel,
        o.promised_delivery_date,
        de.delivered_ts,
        CASE WHEN de.delivered_ts IS NULL THEN 0
             WHEN date(de.delivered_ts) <= o.promised_delivery_date THEN 1 ELSE 0
        END AS delot_flag_shipment
    FROM fact_order_pdt AS o
    INNER JOIN fact_delivery_event AS de
        ON o.shipment_id = de.shipment_id
),
fact_del_if_flag AS (
    SELECT
        sh.shipment_id,
        sh.order_id,
        sh.order_line_id,
        sh.dc_id,
        CASE WHEN de.damage_flag = 1 THEN 0
             WHEN de.loss_flag = 1 THEN 0 ELSE 1
        END AS delif_flag_shipment
    FROM fact_shipment_line AS sh
    INNER JOIN fact_delivery_event AS de
        ON sh.shipment_id = de.shipment_id
),
fact_delivered_flag AS (
    SELECT
        dot.order_id,
        dot.dc_id,
        dot.channel,
        MIN(dot.delot_flag_shipment) AS delivered_ot_flag,
        MIN(dif.delif_flag_shipment) AS delivered_if_flag
    FROM fact_del_ot_flag AS dot
    INNER JOIN fact_del_if_flag AS dif
        ON dot.shipment_id = dif.shipment_id
    GROUP BY
        dot.order_id,
        dot.dc_id,
        dot.channel
),
fact_reol_plandt AS (
    SELECT
        re.order_id,
        re.order_line_id,
        o.dc_id,
        o.channel,
        o.planned_ship_date
    FROM fact_release_event AS re
    INNER JOIN fact_order_line AS o
        ON re.order_id = o.order_id
        AND re.order_line_id = o.order_line_id
),
fact_shipot_flag_shipment AS (
    SELECT
        sh.shipment_id,
        o.order_id,
        o.order_line_id,
        o.dc_id,
        o.channel,
        o.planned_ship_date,
        sh.ship_ts,
        CASE WHEN sh.ship_ts IS NULL THEN 0
             WHEN date(sh.ship_ts) <= o.planned_ship_date T
