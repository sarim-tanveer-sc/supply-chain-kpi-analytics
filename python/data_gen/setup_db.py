# ============================================
# NCG Supply Chain KPI Analytics
# Phase 4 | Step 1 of 2: Database Setup
# Purpose: Creates SQLite database and all
#          four fact tables for NCG project
# Dependencies: None
# Output: ncg.db with empty fact tables
# ============================================

import sqlite3

# 1. Connect to SQLite database (creates file if it doesn't exist)
conn = sqlite3.connect("ncg.db")

# 2. Create cursor (used to execute SQL)
cursor = conn.cursor()

# 3. Create fact_order_line table
create_fact_order_line = """
CREATE TABLE IF NOT EXISTS fact_order_line (
    order_id TEXT NOT NULL,
    order_line_id INTEGER NOT NULL,
    sku_id TEXT NOT NULL,
    dc_id TEXT NOT NULL,
    channel TEXT NOT NULL,

    order_created_ts TEXT NOT NULL,
    order_confirmed_ts TEXT NOT NULL,

    promised_delivery_date TEXT NOT NULL,
    planned_ship_date TEXT NOT NULL,
    release_SLA_date TEXT NOT NULL,

    ordered_qty INTEGER NOT NULL,
    atp_qty INTEGER NOT NULL,

    unit_price REAL NOT NULL,

    PRIMARY KEY (order_id, order_line_id)
);
"""

cursor.execute(create_fact_order_line)

# 4. Create fact_release_event table
create_fact_release_event = """
CREATE TABLE IF NOT EXISTS fact_release_event (
    release_event_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL,
    order_line_id INTEGER NOT NULL,

    release_ts TEXT NOT NULL,
    release_qty INTEGER NOT NULL,

    released_on_time_flag INTEGER NOT NULL
);
"""

cursor.execute(create_fact_release_event)
# 5. Create fact_shipment_line table
create_fact_shipment_line = """
CREATE TABLE IF NOT EXISTS fact_shipment_line (
    shipment_id TEXT NOT NULL,
    shipment_line_id INTEGER NOT NULL,

    order_id TEXT NOT NULL,
    order_line_id INTEGER NOT NULL,
    sku_id TEXT NOT NULL,

    dc_id TEXT NOT NULL,
    carrier_id TEXT NOT NULL,

    ship_ts TEXT NOT NULL,
    shipped_qty INTEGER NOT NULL,
    freight_cost REAL NOT NULL,
    
    shipped_on_time_flag INTEGER NOT NULL,

    PRIMARY KEY (shipment_id, shipment_line_id)
);
"""
cursor.execute(create_fact_shipment_line)
# 6. Create fact_delivery_event table (one row per shipment)
create_fact_delivery_event = """
CREATE TABLE IF NOT EXISTS fact_delivery_event (
    shipment_id TEXT PRIMARY KEY,

    delivered_ts TEXT,                  -- NULL if lost
    delivery_status TEXT NOT NULL,      -- DELIVERED / LOST / DAMAGED
    delivery_attempts INTEGER NOT NULL,

    carrier_delay_flag INTEGER NOT NULL,
    damage_flag INTEGER NOT NULL,
    loss_flag INTEGER NOT NULL
);
"""
cursor.execute(create_fact_delivery_event)

# 5. Commit changes and close connection
conn.commit()
conn.close()

print("Database and core tables created successfully.")
