# SQL_StarSchema_Project

This project demonstrates how to transform raw transactional sales data into a clean star schema using SQL — ideal for BI tools like Power BI or Tableau.

---

## Goal

Design a **star schema** from the cleaned cafe sales dataset to support efficient reporting and time-based analysis.

---

## Skills Used

- SQL Joins & Aggregation  
- Star Schema Design (Fact + 4 Dimensions)  
- Date Dimension Generation  
- Handling Nulls in Dimensions  
- Indexing for Performance  
- ETL Logic  
- Business KPIs Readiness

---

## Star Schema Overview

**Fact Table**: `fact_sales`  
**Dimensions**: `dim_product`, `dim_payment_method`, `dim_location`, `dim_date`

### `fact_sales`
| Column | Description |
|--------|-------------|
| `transaction_id` | Degenerate dimension |
| `date_id` | FK to `dim_date` |
| `product_id` | FK to `dim_product` |
| `payment_method_id` | FK to `dim_payment_method` |
| `location_id` | FK to `dim_location` |
| `quantity` | Sales quantity measure |
| `total_spent` | Revenue measure |

---

## ETL Summary

1. **Cleaned `cafe_sales_cleaned`**: Handled nulls in `item`, `location`, `payment_method`
2. **Created Dimension Tables**:
   - `dim_product`: Normalized with unique `product_name + price`
   - `dim_date`: Full calendar of 2023 generated with SQL "With help of GEN-AI"
   - `dim_location`, `dim_payment_method`: Cleaned and normalized
3. **Joined + Loaded into `fact_sales`** with full FK integrity
4. **Indexed** for BI use:
   ```sql
   CREATE INDEX idx_fact_date ON fact_sales(date_id);
   CREATE INDEX idx_fact_product ON fact_sales(product_id);
   CREATE INDEX idx_fact_payment_method ON fact_sales(payment_method_id);

---
## Example of Vizualizations
<img width="1517" height="768" alt="image" src="https://github.com/user-attachments/assets/985df245-6b0d-4ccc-8cb2-a42db4c493a4" />


<img width="1543" height="766" alt="image" src="https://github.com/user-attachments/assets/a697e6af-b21c-45e0-8b22-53b7fe233560" />


<img width="1566" height="767" alt="image" src="https://github.com/user-attachments/assets/31fa3d98-30b0-4c6e-af27-33bc0648b146" />


