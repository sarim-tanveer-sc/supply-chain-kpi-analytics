-- ============================================
-- NCG Supply Chain KPI Analytics
-- Phase 5 | Step 3 of 7: Shipment Spine
-- Grain: Order level
-- Dependencies: fact_order_line,
--               fact_release_event,
--               fact_shipment_line
-- Output: order_id, dc_id, channel,
--         shipped_ot_flag, shipped_if_flag
-- ============================================

WITH fact_reol_plandt AS (
		SELECT re.order_id, re.order_line_id, o.dc_id, o.channel, 
					 o.planned_ship_date
		FROM fact_release_event AS re
		INNER JOIN fact_order_line AS o
		ON re.order_id = o.order_id AND re.order_line_id = o.order_line_id
), 
fact_shipot_flag_shipment AS (
		SELECT sh.shipment_id, o.order_id, o.order_line_id, o.dc_id, o.channel,
					 o.planned_ship_date, sh.ship_ts,
		CASE WHEN sh.ship_ts IS NULL THEN 0
				 WHEN date(sh.ship_ts) <= o.planned_ship_date THEN 1 ELSE 0 
		END AS shipot_flag_shipment
		FROM fact_reol_plandt AS o
		LEFT JOIN fact_shipment_line AS sh
		ON o.order_id = sh.order_id AND o.order_line_id = sh.order_line_id
),
fact_shipped_ot_orderlevel AS (
		SELECT order_id, dc_id, channel,
		MIN (shipot_flag_shipment) AS shipped_ot_flag
		FROM fact_shipot_flag_shipment 
		GROUP BY order_id, dc_id, channel
),
fact_ship_orderline AS (
		SELECT order_id, order_line_id, dc_id, 
		SUM (shipped_qty) AS shipped_qty_orderline
		FROM fact_shipment_line
		GROUP BY order_line_id, order_id
),
fact_shif_flag_orderline AS (
		SELECT sh.order_id, sh.order_line_id, sh.dc_id, 
					 re.release_qty, sh.shipped_qty_orderline,
		CASE WHEN sh.shipped_qty_orderline IS NULL THEN 0
				 WHEN sh.shipped_qty_orderline = re.release_qty THEN 1 ELSE 0 END AS shif_flag_orderline
		FROM fact_release_event AS re
		LEFT JOIN fact_ship_orderline AS sh
		ON re.order_id = sh.order_id AND re.order_line_id = sh.order_line_id
),
fact_shipped_if_orderlevel AS (
		SELECT o.order_id, o.dc_id, o.channel,
		MIN (sh.shif_flag_orderline) AS shipped_if_flag
		FROM fact_order_line AS o
		INNER JOIN fact_shif_flag_orderline AS sh
		ON o.order_id = sh.order_id AND o.order_line_id = sh.order_line_id
		GROUP BY o.order_id, o.dc_id, o.channel
)
SELECT shot.order_id, shot.dc_id, shot.channel, 
			 shot.shipped_ot_flag, shif.shipped_if_flag
FROM fact_shipped_ot_orderlevel AS shot
INNER JOIN fact_shipped_if_orderlevel AS shif
ON shot.order_id = shif.order_id;
