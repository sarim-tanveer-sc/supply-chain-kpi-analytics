# End-to-End Supply Chain Performance & KPI Analytics
Downstream Execution Visibility | SQL + Python + Power BI | Operational Diagnostics

Project Documentation (Notion):
https://www.notion.so/End-to-End-Supply-Chain-Performance-KPI-Analytics-2db28a109f5280049b79ecefcc9521fe

---

## Project Overview

This project simulates a real-world downstream supply chain environment for a 
mid-size US consumer goods company and builds a structured KPI framework to 
diagnose service and cost performance issues.

The objective is to design a clean operational data model, generate realistic 
execution data, and compute end-to-end service KPIs using SQL — without relying 
on forecasting, machine learning, or optimization models.

This project focuses purely on descriptive and diagnostic analytics.

---

## Business Context

| Field | Detail |
|---|---|
| Company | NorthRiver Consumer Goods (NCG) |
| Industry | Consumer Packaged Goods (CPG) |
| Revenue Scale | ~$480M |
| Orders per Year | ~1.8M |
| SKUs | ~650 |
| Channels | Retail, E-commerce, B2B |

### Operating Model

NCG owns product design and SKU definitions, uses contract manufacturers, 
operates 3 owned distribution centers (West, Central, East), uses 3PL overflow 
during peak periods, and works with ~20 active transportation carriers across 
truckload, LTL, and parcel.

---

## Problem Statement

Over two consecutive quarters, NCG experienced:

- OTIF decline from ~94% to ~87%
- Logistics cost increase of ~12% without revenue growth
- Rising customer complaints
- No unified cross-functional performance visibility

Sales, warehousing, and transportation teams each attributed the decline to 
different causes. Leadership lacked a single source of truth. This project 
builds that visibility framework.

---

## Project Scope

**In Scope**
- Downstream execution: Order Confirmation → Release → Shipment → Delivery
- KPI framework and hierarchy design
- Operational data modeling and schema design
- Mock data generation with realistic failure injection
- SQL-based KPI computation and diagnostic logic

**Out of Scope**
- Upstream sourcing and manufacturing
- Forecasting and demand planning
- Machine learning
- Network design and optimisation
- Prescriptive modelling

---

## Project Roadmap

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Business Context & Problem Scope | ✅ Complete |
| Phase 2 | KPI Framework & Definition | ✅ Complete |
| Phase 3 | Data Architecture | ✅ Complete |
| Phase 4 | Data Generation | ✅ Complete |
| Phase 5 | KPI SQL Logic | 🟡 In Progress |
| Phase 6 | Diagnostic Analysis | 🔲 Not Started |
| Phase 7 | Executive Reporting | 🔲 Not Started |

---

## KPI Framework

### Tier 1 KPIs
| KPI | Description |
|---|---|
| OTIF | % of orders delivered on time and in full. Primary service metric. |
| Logistics Cost to Revenue | Freight cost as a % of shipped revenue. Efficiency metric. |
| Order Fulfilment Lead Time | Days from order confirmation to final delivery. |

### Tier 2 KPIs — Service Decomposition
| Stage | KPI | Evaluation Grain | Reporting Grain |
|---|---|---|---|
| Release | Released On Time | Order line | Order |
| Release | Released In Full | Order line | Order |
| Shipment | Shipped On Time | Shipment line | Order |
| Shipment | Shipped In Full | Order line | Order |
| Delivery | Delivered On Time | Shipment | Order |
| Delivery | Delivered In Full | Shipment | Order |

Each KPI is defined with evaluation grain, reporting grain, time anchors, 
failure conditions, and ownership boundaries across warehouse, carrier, 
and order management functions.

---

## Data Model

### Fact Tables
| Table | Grain | Key Columns |
|---|---|---|
| fact_order_line | One row per order line | order_id, order_line_id, channel, dc_id, planned_ship_date, promised_delivery_date |
| fact_release_event | One row per order line | order_id, order_line_id, release_ts, release_qty |
| fact_shipment_line | One row per shipment line | shipment_id, order_id, order_line_id, ship_ts, shipped_qty, freight_cost |
| fact_delivery_event | One row per shipment | shipment_id, delivered_ts, delivery_status |

### Design Principles
- Grain consistency across all fact tables
- Event lifecycle mapping: release → shipment → delivery
- Clean dependency chain enforced in KPI logic
- No mixed-grain KPIs

---

## Mock Dataset

| Metric | Value |
|---|---|
| Horizon | 16 weeks (2024-W01 to 2024-W16) |
| Order lines | 50,000 |
| Distinct orders | ~20,853 |
| Release events | 50,000 |
| Shipment lines | ~59,285 |
| Delivery events | ~59,285 |
| Split shipment rate | ~16% |
| Delivery status | ~97% delivered, ~2% damaged, ~1% lost |

Performance is injected across three bands to simulate a realistic declining 
trend over 16 weeks — enabling root cause diagnostic analysis across release, 
shipment, and delivery stages.

---

## Technical Stack

| Tool | Purpose |
|---|---|
| SQLite | Database — file-based, no server required |
| SQL | KPI computation, spine builds, aggregations |
| Python | Mock data generation (Stage 4), diagnostic analysis (Stage 6) |
| Power BI | Executive dashboard (Stage 7) |
| Notion | Project documentation and KPI definitions |
| GitHub | Version control and portfolio visibility |

---

## Skills Demonstrated

- Operational data modeling
- KPI framework
- Grain-aware analytics
- Event-based process modeling
- SQL-based diagnostic analysis
- Data integrity validation
- Realistic scenario simulation with controlled failure injection

## Why This Project Matters

This project demonstrates the ability to translate a real business problem into 
a structured analytical model — separating execution layers, designing KPI logic 
with correct grain and failure propagation, and producing diagnostic insight 
beyond surface-level dashboarding.

It simulates the type of analytical responsibility expected from a Supply Chain 
Analyst embedded within operations — owning performance visibility, not 
operations themselves.

---

## Repository Structure

```
supply-chain-kpi-analytics/
│
├── README.md
├── sql/
│   ├── ddl/
│   │   └── create_tables.sql
│   └── kpi/
│       ├── release_spine.sql
│       ├── delivery_spine.sql
│       ├── shipment_spine.sql
│       ├── otif_derivation.sql
│       ├── cost_to_revenue.sql
│       ├── lead_time.sql
│       └── kpi_fact_table.sql
└── python/
    └── data_gen/
        └── generate_mock_data.py
```

---

## Status

Phase 5 — KPI SQL Logic is nearing completion. All three execution spines 
(release, delivery, shipment) have been built and validated. OTIF derivation 
is complete. Cost to Revenue and Lead Time spines are validated. KPI Fact Table 
build is in progress.

Phase 6 (Python diagnostic analysis) and Phase 7 (Power BI dashboard) to follow.

























