# End-to-End Supply Chain Performance & KPI Analytics  
**Downstream Execution Visibility | SQL + Python | Operational Diagnostics**

📌 **Project Documentation (Notion):**  
https://www.notion.so/End-to-End-Supply-Chain-Performance-KPI-Analytics-2db28a109f5280049b79ecefcc9521fe

---

## Project Overview
This project simulates a real-world downstream supply chain environment for a mid-size US consumer goods company and builds a structured KPI framework to diagnose service and cost performance issues.

The objective is to design a clean operational data model, generate realistic execution data, and compute end-to-end service KPIs using **SQL** — without relying on forecasting, machine learning, or optimization models.

This project focuses purely on **descriptive and diagnostic analytics**.

---

## Business Context
**Company:** NorthRiver Consumer Goods (NCG)  
**Industry:** Consumer Packaged Goods (CPG)  
**Revenue Scale:** ~$480M  
**Orders per Year:** ~1.8M  
**SKUs:** ~650  
**Channels:** Retail, E-commerce, B2B  

---

## Operating Model
NCG:
- Owns product design and SKU definitions  
- Uses contract manufacturers  
- Operates 3 distribution centers (**West, Central, East**)  
- Uses 3PL overflow during peak  
- Works with ~20 transportation carriers  
- Competes on availability (high-volume, low-margin SKUs)  

---

## Problem Statement
Over two quarters:
- OTIF declined from **~94% → ~87%**
- Logistics cost increased by **~12%**
- Customer complaints increased
- No unified cross-functional performance visibility exists

The leadership team lacks a single source of truth across:
- Order processing  
- Warehouse execution  
- Transportation performance  

This project builds that visibility framework.

---

## Project Scope

### Included
- Downstream execution (Order → Release → Ship → Deliver)
- KPI framework and hierarchy
- Data modeling and schema design
- Mock operational data generation
- SQL-based KPI calculations
- Diagnostic drill-down logic

### Excluded
- Upstream sourcing/manufacturing
- Forecasting
- Machine Learning
- Network optimization
- Prescriptive modeling

---

## KPI Framework

### Tier 1
- OTIF  
- Logistics Cost to Revenue  
- Lead Time  

### Tier 2 (Service Decomposition)
- Released On Time  
- Released In Full  
- Shipped On Time  
- Shipped In Full  
- Delivered On Time  
- Delivered In Full  

Each KPI definition includes:
- Evaluation grain  
- Reporting grain  
- Time anchors  
- Failure conditions  
- Ownership boundaries (Warehouse vs Carrier vs Order Management)

---

## Data Model

### Fact Tables
- `fact_order_line`  
- `fact_release_event`  
- `fact_shipment_line`  
- `fact_delivery_event`  

### Design Principles
- Grain consistency  
- Event lifecycle mapping  
- Clean dependency chain (release → shipment → delivery)  
- No mixed-grain KPIs  
- Realistic operational distributions  

---

## Mock Data Design
The project includes a controlled mock data generator simulating:
- 16-week rolling execution horizon  
- 200 → 20,000 order scalability  
- ~10% non-ATP order lines  
- ~20% split shipments  
- ~10–15% short shipments  
- ~8–12% late deliveries  
- Lost & damaged shipments  
- Multi-attempt deliveries  
- Channel-specific SLAs  

This allows KPI logic to be tested under realistic operational variability.

---

## Technical Stack
- **SQLite** (database)  
- **SQL** (CTEs, aggregations, rollups, pass/fail KPI logic)  
- **Python** (mock data generation + integration)  
- **GitHub** (version control)  
- **Notion** (documentation & KPI definitions)  

---

## Skills Demonstrated
- Operational data modeling  
- KPI architecture design  
- Grain-aware analytics  
- Event-based process modeling  
- SQL-based diagnostics  
- Data integrity validation  
- Realistic scenario simulation  

---

## Why This Project Matters
This project demonstrates the ability to:
- Translate business problems into structured analytical models  
- Separate execution layers (warehouse vs transportation)  
- Design KPI logic with correct grain and failure propagation  
- Perform diagnostic thinking beyond dashboarding  
- Own performance visibility rather than owning operations  

It simulates the type of analytical responsibility expected from a **Supply Chain Analyst embedded within operations**.

---

## Status
✅ Data model created  
✅ Mock data generator built  
✅ Sanity validation framework complete  
🟡 KPI SQL logic in progress  
