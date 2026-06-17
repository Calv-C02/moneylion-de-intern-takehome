# 5) Snowflake Cost Governance

## Objective

Identify key cost drivers after dashboard/report growth, tune expensive queries, and enforce controls for predictable compute spend.

## Approach

Treat cost governance as a continuous cycle:

1. Measure where credits are being spent.
2. Identify and tune highest-cost query patterns.
3. Enforce platform guardrails.
4. Review regularly and adjust.

## Why This Approach (Reasoning and Trade-offs)

- Warehouse-level metrics show where spend happens, but query-level analysis explains why it happens.
- Tuning every query is low ROI; prioritizing top-cost queries usually captures most savings.
- Aggressive guardrails (timeouts, strict caps) can reduce waste but may interrupt legitimate heavy jobs, so controls should be tiered by workload criticality.
- Isolating ETL, BI, and ad hoc usage improves both predictability and accountability.

## Investigate Cost Drivers

1. Analyze warehouse credits by hour/day from `WAREHOUSE_METERING_HISTORY`.
2. Attribute cost-heavy periods to query patterns from `QUERY_HISTORY`.
3. Break down by workload type:
   - ETL batch
   - BI dashboards
   - ad hoc analyst queries

## Tune Expensive Workloads

- Optimize top 10 most expensive queries by bytes scanned and elapsed time.
- Reduce repeated full-table scans with aggregate tables and query pruning.
- Isolate noisy ad hoc workloads onto separate smaller warehouse(s).

## Cost Controls

- Set `AUTO_SUSPEND` (e.g., 60 seconds) and `AUTO_RESUME = TRUE`.
- Apply resource monitors with credit quotas and alert thresholds.
- Define budget guardrails by environment/team (dev/stage/prod).
- Set query timeout and statement queuing policies for runaway workloads.

## Validation and Gatekeeping Rules

Cost governance changes are accepted only when:

1. Monthly credit variance stays inside target band.
2. No critical scheduled report misses SLA due to new limits.
3. Top recurring expensive queries show measurable improvement.

If controls create reliability regressions, roll back the control and redesign (for example, separate warehouse or adjust timeout policy).

## Operating Cadence

- Weekly cost review:
  - cost by warehouse
  - top expensive queries
  - optimization backlog
- Monthly governance review:
  - monitor thresholds
  - warehouse right-sizing
  - dashboard usage cleanup

## Example Monitoring SQL

```sql
select
  warehouse_name,
  date_trunc('day', start_time) as usage_day,
  sum(credits_used_compute) as credits_compute
from snowflake.account_usage.warehouse_metering_history
where start_time >= dateadd(day, -30, current_timestamp())
group by 1,2
order by usage_day desc, credits_compute desc;
```

## Assumptions

- Workload growth is primarily dashboard-driven.
- Teams can support a lightweight weekly optimization cadence.
- Tagging or naming conventions are available to classify workloads.

## AI Usage Note

AI helped brainstorm possible cost controls. I rejected controls that were too broad or difficult to operate for this scope, and kept a practical governance loop: identify top spenders, tune high-impact queries, and enforce predictable guardrails. I added explicit success/failure criteria to show how I would judge whether controls are effective without hurting business reporting.
