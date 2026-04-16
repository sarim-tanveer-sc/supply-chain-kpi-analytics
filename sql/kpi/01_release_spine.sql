-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 1 of 7: Release Spine
-- Grain: Order level
-- Dependencies: fact_order_line, fact_release_event
-- Output: order_id, dc_id, channel, 
--         release_ot_flag, release_if_flag
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
)
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
    ot.channel;
