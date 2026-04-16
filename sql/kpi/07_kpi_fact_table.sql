-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 7 of 7: KPI Fact Table
-- Grain: Order level
-- Dependencies: All spines (Release, Delivery,
--               Shipment, Cost to Revenue,
--               Lead Time)
-- Output: One row per order. Tier 2 flags,
--         OTIF (dynamic), cost_rev_pct,
--         lead_time_days
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
             WHEN date(sh.ship_ts) <= o.planned_ship_date THEN 1 ELSE 0
        END AS shipot_flag_shipment
    FROM fact_reol_plandt AS o
    LEFT JOIN fact_shipment_line AS sh
        ON o.order_id = sh.order_id
        AND o.order_line_id = sh.order_line_id
),
fact_shipped_ot_orderlevel AS (
    SELECT
        order_id,
        dc_id,
        channel,
        MIN(shipot_flag_shipment) AS shipped_ot_flag
    FROM fact_shipot_flag_shipment
    GROUP BY
        order_id,
        dc_id,
        channel
),
fact_ship_orderline AS (
    SELECT
        order_id,
        order_line_id,
        dc_id,
        SUM(shipped_qty) AS shipped_qty_orderline
    FROM fact_shipment_line
    GROUP BY
        order_id,
        order_line_id
),
fact_shif_flag_orderline AS (
    SELECT
        sh.order_id,
        sh.order_line_id,
        sh.dc_id,
        re.release_qty,
        sh.shipped_qty_orderline,
        CASE WHEN sh.shipped_qty_orderline IS NULL THEN 0
             WHEN sh.shipped_qty_orderline = re.release_qty THEN 1 ELSE 0
        END AS shif_flag_orderline
    FROM fact_release_event AS re
    LEFT JOIN fact_ship_orderline AS sh
        ON re.order_id = sh.order_id
        AND re.order_line_id = sh.order_line_id
),
fact_shipped_if_orderlevel AS (
    SELECT
        o.order_id,
        o.dc_id,
        o.channel,
        MIN(sh.shif_flag_orderline) AS shipped_if_flag
    FROM fact_order_line AS o
    INNER JOIN fact_shif_flag_orderline AS sh
        ON o.order_id = sh.order_id
        AND o.order_line_id = sh.order_line_id
    GROUP BY
        o.order_id,
        o.dc_id,
        o.channel
),
fact_shipped_flag AS (
    SELECT
        shot.order_id,
        shot.dc_id,
        shot.channel,
        shot.shipped_ot_flag,
        shif.shipped_if_flag
    FROM fact_shipped_ot_orderlevel AS shot
    INNER JOIN fact_shipped_if_orderlevel AS shif
        ON shot.order_id = shif.order_id
),
fact_rel_ship_join_flag AS (
    SELECT
        re.order_id,
        re.release_ot_flag,
        re.release_if_flag,
        sh.shipped_ot_flag,
        sh.shipped_if_flag
    FROM fact_released_flag AS re
    LEFT JOIN fact_shipped_flag AS sh
        ON re.order_id = sh.order_id
),
fact_reship_del_join_flag AS (
    SELECT
        re.order_id,
        re.release_ot_flag,
        re.release_if_flag,
        re.shipped_ot_flag,
        re.shipped_if_flag,
        del.delivered_ot_flag,
        del.delivered_if_flag
    FROM fact_rel_ship_join_flag AS re
    LEFT JOIN fact_delivered_flag AS del
        ON re.order_id = del.order_id
),
fact_tier2_kpi_flag AS (
    SELECT DISTINCT
        o.order_id,
        o.dc_id,
        o.channel,
        date(o.order_confirmed_ts) AS order_confirmed_dt,
        strftime('%W', o.order_created_ts) AS week_num,
        k.release_ot_flag,
        k.release_if_flag,
        k.shipped_ot_flag,
        k.shipped_if_flag,
        k.delivered_ot_flag,
        k.delivered_if_flag
    FROM fact_order_line AS o
    INNER JOIN fact_reship_del_join_flag AS k
        ON o.order_id = k.order_id
),
fact_shipment_orderline AS (
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
),
fact_log_cost_rev AS (
    SELECT
        order_id,
        dc_id,
        channel,
        week_num,
        SUM(freight_cost_orderline) AS freight_cost_order,
        SUM(unit_price * shipped_qty_orderline) AS revenue_order,
