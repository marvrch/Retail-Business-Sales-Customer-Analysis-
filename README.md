# Retail Business Sales & Customer Analysis

## Background Problem

A national retailer runs many stores across several product categories. The data for sales, products, customers, and store attributes sits in separate tables, which makes it hard to build one trusted view of performance and customer behavior.

This project uses a competition dataset that simulates a real retailer. The goal is to define clear KPIs, prepare analysis tables with SQL, and present the results in an interactive Power BI dashboard to diagnose issues and recommend practical improvements.
Note: this repository contains only the SQL used for analysis and a three page PDF preview of the dashboard. The raw data is not published.

## Tools & Libraries

* **Microsoft SQL Server Management Studio (SSMS)** for data preparation, KPI logic, and RFM computation
* **Power BI** for interactive visualization and drill down views

## Insights

* **Promo driven volatility.** Sales expanded by about **450%** within the period, with sharp spikes that point to date based promotions rather than durable demand. This pattern increases forecasting and inventory risk and can weaken margins if left unmanaged.
* **Geographic concentration.** About 40% of sales come from Depok alone, so the business relies too much on one city. This raises risk if conditions change there, while other cities still have clear room to grow.
* **Loyalty risk.** **44%** of customers are marked **At Risk** by RFM, indicating a large group with low recent activity and a high probability of churn.

## Advices

* **Stabilize growth mechanics.** Shift the focus from short term date promotions to steady AOV lift and consistent up sell and cross sell. Track margin impact so that growth becomes robust rather than volatile.
* **Rebalance geography.** Run geo targeted marketing to build share beyond Depok. Localize assortment and budget, then scale what works based on city level performance.
* **Personalized retention.** Use RFM segments to prioritize At Risk customers with targeted win back offers, service outreach, and simple follow ups. Measure repeat rate and 90 day churn to confirm impact.
