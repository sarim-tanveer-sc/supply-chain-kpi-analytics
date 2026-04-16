# ============================================
# NCG Supply Chain KPI Analytics
# Phase 4 | Step 2 of 2: Mock Data Generation
# Purpose: Generates 50,000 order lines with
#          realistic failure injection across
#          16-week horizon
# Dependencies: setup_db.py (run first)
# Output: ncg.db populated with mock data
# ============================================

import sqlite3
import random
from datetime import datetime, timedelta

DB_NAME = "ncg.db"

NUM_ORDER_LINES = 50000
START_DATE = datetime(2024, 1, 1)

# Locked channel names and release lead times
CHANNEL_SLA_DAYS = {
    "Retail": 3,
    "B2B": 2,
    "E-commerce": 1
}

# Carrier tiers and freight multipliers
CARRIERS = {
    "CARR_PREMIUM_1": ("PREMIUM", 1.40),
    "CARR_PREMIUM_2": ("PREMIUM", 1.40),
    "CARR_STD_1":     ("STANDARD", 1.00),
    "CARR_STD_2":     ("STANDARD", 1.00),
    "CARR_BUDGET_1":  ("BUDGET", 0.75),
    "CARR_BUDGET_2":  ("BUDGET", 0.75)
}

SKU_POOL = [f"SKU_{i}" for i in range(1, 51)]
DC_POOL  = [f"DC_{i}"  for i in range(1, 5)]

random.seed(42)


def connect():
    return sqlite3.connect(DB_NAME)


def random_date():
    # 16 weeks = 112 days
    return START_DATE + timedelta(days=random.randint(0, 111))


def choose_channel():
    r = random.random()
    if r < 0.45:
        return "Retail"
    elif r < 0.80:
        return "E-commerce"
    return "B2B"


def get_week_band(order_created_dt):
    days_from_start = (order_created_dt.date() - START_DATE.date()).days
    week_num = days_from_start // 7 + 1
    if week_num <= 5:
        return "stable"
    elif week_num <= 11:
        return "early_decline"
    return "late_decline"


def get_band_params(band):
    """
    Failure rates are applied DIRECTLY to control on-time flags.
    release_late_rate  → probability that a line is marked late at release
    ship_late_rate     → probability that a shipment line is marked late
    release_fail_rate  → probability that release_qty = 0 (release In Full failure)
    ship_short_rate    → probability of short ship on a shipment line
    delivery_late_rate → probability that a DELIVERED shipment is late
    """
    if band == "stable":
        return {
            "release_fail_rate":  0.02,   # Release In Full ~98%
            "release_late_rate":  0.03,   # Release On Time ~97%
            "ship_short_rate":    0.02,   # Shipped In Full ~98%
            "ship_late_rate":     0.03,   # Shipped On Time ~97%
            "delivery_late_rate": 0.02    # Delivered On Time ~98%
        }
    elif band == "early_decline":
        return {
            "release_fail_rate":  0.04,   # Release In Full ~96%
            "release_late_rate":  0.06,   # Release On Time ~94%
            "ship_short_rate":    0.04,   # Shipped In Full ~96%
            "ship_late_rate":     0.06,   # Shipped On Time ~94%
            "delivery_late_rate": 0.03    # Delivered On Time ~97%
        }
    else:  # late_decline
        return {
            "release_fail_rate":  0.07,   # Release In Full ~93%
            "release_late_rate":  0.10,   # Release On Time ~90%
            "ship_short_rate":    0.07,   # Shipped In Full ~93%
            "ship_late_rate":     0.09,   # Shipped On Time ~91%
            "delivery_late_rate": 0.05    # Delivered On Time ~95%
        }


def generate():
    order_lines     = []
    release_events  = []
    shipment_lines  = []
    delivery_events = []

    release_event_counter = 1
    shipment_counter      = 1
    order_counter         = 1
    line_count            = 0

    while line_count < NUM_ORDER_LINES:
        order_id = f"ORD_{order_counter}"
        order_counter += 1

        num_lines = random.choices([1, 2, 3, 4], weights=[15, 40, 35, 10], k=1)[0]

        channel  = choose_channel()
        dc_id    = random.choice(DC_POOL)

        order_created   = random_date()
        # FIX: extend confirmation window so SLA date is always reachable
        order_confirmed = order_created + timedelta(hours=random.randint(1, 6))

        band   = get_week_band(order_created)
        params = get_band_params(band)

        for line_id in range(1, num_lines + 1):
            if line_count >= NUM_ORDER_LINES:
                break
            line_count += 1

            sku_id      = random.choice(SKU_POOL)
            ordered_qty = random.randint(5, 100)
            atp_qty     = ordered_qty
            unit_price  = round(random.uniform(10, 50), 2)

            # FIX: widen planned_ship_date window so SLA date sits
            # comfortably ahead of order_confirmed for all channels.
            # Minimum days to ship = channel SLA days + 2 buffer days.
            min_ship_days = CHANNEL_SLA_DAYS[channel] + 2
            max_ship_days = min_ship_days + 6
            planned_ship_date       = (order_confirmed + timedelta(days=random.randint(min_ship_days, max_ship_days))).date()
            promised_delivery_date  = planned_ship_date + timedelta(days=random.randint(2, 5))
            release_sla_date        = planned_ship_date - timedelta(days=CHANNEL_SLA_DAYS[channel])

            order_lines.append((
                order_id,
                line_id,
                sku_id,
                dc_id,
                channel,
                order_created.strftime("%Y-%m-%d %H:%M:%S"),
                order_confirmed.strftime("%Y-%m-%d %H:%M:%S"),
                promised_delivery_date.strftime("%Y-%m-%d"),
                planned_ship_date.strftime("%Y-%m-%d"),
                ordered_qty,
                atp_qty,
                unit_price,
                release_sla_date.strftime("%Y-%m-%d")
            ))

            # ----------------------------------------------------------------
            # RELEASE EVENT
            # FIX: determine on_time flag FIRST from band probability,
            # then generate a timestamp consistent with that decision.
            # This decouples timing logic from the flag outcome.
            # ----------------------------------------------------------------
            release_failed = random.random() < params["release_fail_rate"]
            release_qty    = 0 if release_failed else ordered_qty

            is_release_late = random.random() < params["release_late_rate"]

            # Window: order_confirmed + 2 hours → release_sla_date 23:59
            # This window is always valid because of the widened ship date above.
            earliest_on_time = order_confirmed + timedelta(hours=2)
            latest_on_time   = datetime.combine(release_sla_date, datetime.min.time()) + timedelta(hours=23, minutes=59)

            if is_release_late:
                # Release 1-3 days after SLA date
                release_ts = datetime.combine(release_sla_date, datetime.min.time()) + timedelta(
                    days=random.randint(1, 3),
                    hours=random.randint(1, 18),
                    minutes=random.randint(0, 59)
                )
            else:
                # On-time release anywhere within the valid window
                total_seconds = int((latest_on_time - earliest_on_time).total_seconds())
                offset        = random.randint(0, max(total_seconds, 0))
                release_ts    = earliest_on_time + timedelta(seconds=offset)

            released_on_time_flag = 1 if release_ts.date() <= release_sla_date else 0

            release_events.append((
                f"REL_{release_event_counter}",
                order_id,
                line_id,
                release_ts.strftime("%Y-%m-%d %H:%M:%S"),
                release_qty,
                released_on_time_flag
            ))
            release_event_counter += 1

            if release_qty == 0:
                continue

            # ----------------------------------------------------------------
            # SHIPMENT LINES
            # ----------------------------------------------------------------
            remaining_qty = release_qty

            num_shipments = 1
            if random.random() < 0.16 and release_qty > 1:
                num_shipments = random.randint(2, 3)

            for ship_seq in range(1, num_shipments + 1):
                if ship_seq == num_shipments or remaining_qty <= 1:
                    shipped_qty = remaining_qty
                else:
                    shipped_qty = random.randint(1, remaining_qty - 1)

                remaining_qty -= shipped_qty

                # Short ship (Shipped In Full failure) on non-last segments
                if ship_seq < num_shipments:
                    if random.random() < params["ship_short_rate"] and shipped_qty > 1:
                        shipped_qty -= random.randint(1, min(3, shipped_qty - 1))

                shipped_qty = max(0, min(shipped_qty, release_qty))

                shipment_id  = f"SHP_{shipment_counter}"
                shipment_counter += 1

                carrier_id                    = random.choice(list(CARRIERS.keys()))
                carrier_tier, carrier_mult    = CARRIERS[carrier_id]

                # FIX: determine shipped_on_time_flag first, then generate timestamp
                is_ship_late = random.random() < params["ship_late_rate"]

                if is_ship_late:
                    ship_ts = datetime.combine(planned_ship_date, datetime.min.time()) + timedelta(
                        days=random.randint(1, 2),
                        hours=random.randint(6, 18),
                        minutes=random.randint(0, 59)
                    )
                else:
                    ship_ts = datetime.combine(planned_ship_date, datetime.min.time()) + timedelta(
                        days=random.choice([-1, 0]),
                        hours=random.randint(6, 18),
                        minutes=random.randint(0, 59)
                    )

                shipped_on_time_flag = 1 if ship_ts.date() <= planned_ship_date else 0

                base_rate    = random.uniform(2.50, 4.00)
                noise        = random.uniform(0.90, 1.10)
                freight_cost = round(base_rate * shipped_qty * carrier_mult * noise, 2)

                shipment_lines.append((
                    shipment_id,
                    ship_seq,
                    order_id,
                    line_id,
                    sku_id,
                    dc_id,
                    carrier_id,
                    ship_ts.strftime("%Y-%m-%d %H:%M:%S"),
                    shipped_qty,
                    shipped_on_time_flag,
                    freight_cost
                ))

                # ----------------------------------------------------------------
                # DELIVERY EVENT
                # Carrier failure rates stable across all weeks (by design)
                # Budget > Standard > Premium failure rates
                # ----------------------------------------------------------------
                if carrier_tier == "BUDGET":
                    lost_prob    = 0.018
                    damaged_prob = 0.035
                elif carrier_tier == "STANDARD":
                    lost_prob    = 0.008
                    damaged_prob = 0.018
                else:  # PREMIUM
                    lost_prob    = 0.004
                    damaged_prob = 0.008

                r = random.random()

                if r < lost_prob:
                    delivery_status = "LOST"
                    delivered_ts    = None
                    damage_flag     = 0
                    loss_flag       = 1

                elif r < lost_prob + damaged_prob:
                    delivery_status = "DAMAGED"
                    delivered_ts    = datetime.combine(promised_delivery_date, datetime.min.time()) + timedelta(
                        days=random.randint(0, 2),
                        hours=random.randint(6, 18),
                        minutes=random.randint(0, 59)
                    )
                    damage_flag = 1
                    loss_flag   = 0

                else:
                    delivery_status = "DELIVERED"
                    # FIX: determine delivery on-time flag first, then generate timestamp
                    is_delivery_late = random.random() < params["delivery_late_rate"]
                    delay_days       = random.randint(1, 2) if is_delivery_late else random.choice([-1, 0])
                    delivered_ts     = datetime.combine(promised_delivery_date, datetime.min.time()) + timedelta(
                        days=delay_days,
                        hours=random.randint(6, 18),
                        minutes=random.randint(0, 59)
                    )
                    damage_flag = 0
                    loss_flag   = 0

                carrier_delay_flag = 0
                if delivered_ts is not None and delivered_ts.date() > promised_delivery_date:
                    carrier_delay_flag = 1

                delivery_attempts = 1 if random.random() < 0.88 else random.randint(2, 3)

                delivery_events.append((
                    shipment_id,
                    delivered_ts.strftime("%Y-%m-%d %H:%M:%S") if delivered_ts else None,
                    delivery_status,
                    delivery_attempts,
                    carrier_delay_flag,
                    damage_flag,
                    loss_flag
                ))

    return order_lines, release_events, shipment_lines, delivery_events


def main():
    conn = connect()
    cur  = conn.cursor()

    cur.execute("DELETE FROM fact_delivery_event")
    cur.execute("DELETE FROM fact_shipment_line")
    cur.execute("DELETE FROM fact_release_event")
    cur.execute("DELETE FROM fact_order_line")
    conn.commit()

    order_lines, release_events, shipment_lines, delivery_events = generate()

    cur.executemany("""
        INSERT INTO fact_order_line (
            order_id, order_line_id, sku_id, dc_id, channel,
            order_created_ts, order_confirmed_ts,
            promised_delivery_date, planned_ship_date,
            ordered_qty, atp_qty, unit_price, release_SLA_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, order_lines)

    cur.executemany("""
        INSERT INTO fact_release_event (
            release_event_id, order_id, order_line_id,
            release_ts, release_qty, released_on_time_flag
        ) VALUES (?, ?, ?, ?, ?, ?)
    """, release_events)

    cur.executemany("""
        INSERT INTO fact_shipment_line (
            shipment_id, shipment_line_id,
            order_id, order_line_id, sku_id,
            dc_id, carrier_id,
            ship_ts, shipped_qty,
            shipped_on_time_flag, freight_cost
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, shipment_lines)

    cur.executemany("""
        INSERT INTO fact_delivery_event (
            shipment_id,
            delivered_ts,
            delivery_status,
            delivery_attempts,
            carrier_delay_flag,
            damage_flag,
            loss_flag
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    """, delivery_events)

    conn.commit()
    conn.close()

    print(f"Loaded order lines:     {len(order_lines)}")
    print(f"Loaded release events:  {len(release_events)}")
    print(f"Loaded shipment lines:  {len(shipment_lines)}")
    print(f"Loaded delivery events: {len(delivery_events)}")


if __name__ == "__main__":
    main()
