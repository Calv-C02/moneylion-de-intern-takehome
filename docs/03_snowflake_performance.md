# 3) Snowflake Query Performance Optimization

## Objective

Keep analyst queries fast while controlling Snowflake compute cost as transaction volume and dashboard usage increase.

## Problem Context

Analysts frequently filter transactions by date, account, status, product type, country, and merchant. As volume grows, scan-heavy queries become slow and expensive.

## Approach

## Investigation Approach

1. Use `ACCOUNT_USAGE.QUERY_HISTORY` to identify slow and expensive dashboard queries.
2. Inspect scanned bytes, partitions scanned, and repeated query shapes.
3. Use `WAREHOUSE_METERING_HISTORY` to map cost spikes to workloads.

## Why This Approach (Reasoning and Trade-offs)

- I start with workload evidence (`QUERY_HISTORY`) before tuning so changes are based on measured pain, not assumptions.
- Clustering is targeted only on large frequently filtered facts; over-clustering small tables can add maintenance cost without performance gain.
- Materialized views are useful only for stable repeated patterns; if query patterns shift often, summary tables may be easier to control.
- Splitting ETL and BI warehouses prevents one workload from starving the other and makes chargeback/accountability clearer.

## Optimization Strategy

### Data Modeling and Physical Design

- Partition-friendly filtering pattern: always filter `transaction_date` first.
- Cluster large transaction fact by common predicate columns:
  - `(transaction_date, account_id, status, product_type)`.
- Use Search Optimization Service selectively for highly selective point lookups (e.g., `merchant_code`), only after cost-benefit review.

### Precomputation

- Create summary tables (daily/monthly aggregates) for heavily repeated dashboard metrics.
- Use materialized views only for stable, high-hit-rate query patterns.

### Query and Warehouse Tuning

- Rewrite broad `select *` queries to column-pruned projections.
- Separate BI/reporting workload from ETL workload warehouses.
- Right-size warehouse by workload class; enable auto-suspend and auto-resume.

## Validation and Gatekeeping Rules

Treat optimization changes as successful only when both conditions are met over a fixed observation window (for example, 1-2 weeks):

1. Median/95th percentile dashboard runtime improves.
2. Credits per dashboard run do not increase unexpectedly.

If runtime improves but cost rises sharply, revisit design (for example, remove low-ROI materialized view or resize warehouse).

## Example Cost/Performance Diagnostics

```sql
select
  query_id,
  user_name,
  warehouse_name,
  total_elapsed_time,
  bytes_scanned,
  rows_produced,
  query_text
from snowflake.account_usage.query_history
where start_time >= dateadd(day, -7, current_timestamp())
order by bytes_scanned desc
limit 50;
```

## Assumptions

- Dashboards generate repeated query templates, making summary precomputation effective.
- Most expensive scans come from transaction fact growth.
- Query tagging is available (or can be introduced) to attribute BI workloads more clearly.

## AI Usage Note

AI proposed many tuning tactics, including advanced features that may not always be cost-effective. I kept only options that have a clear measurement path for this assessment: query-history driven diagnosis, targeted clustering, selective pre-aggregation, and warehouse governance controls. I rejected broad "turn everything on" recommendations and added explicit success criteria to show how I would validate each optimization.
