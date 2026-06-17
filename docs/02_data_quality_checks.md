# 2) Load Completeness, Freshness, and Accuracy

## Objective

Confirm Snowflake data is complete, fresh, and accurate before publishing reporting tables.

## Approach

Run data quality checks after ingestion and before `MART` publish, then persist all results in `AUDIT.DATA_QUALITY_RESULTS`.

## Validation Framework

Run validation in three layers after ingestion and before mart publish:

1. **Completeness:** source vs Snowflake row counts and key coverage.
2. **Freshness:** ingestion recency and `updated_at` lag checks.
3. **Accuracy:** metric reconciliation and record-level consistency checks.

Store all results in `AUDIT.DATA_QUALITY_RESULTS` and fail publish if critical checks fail.

## Why This Approach (Reasoning and Trade-offs)

- Splitting checks into three categories makes failures easier to triage:
  - completeness failures usually indicate ingestion gaps,
  - freshness failures usually indicate scheduler/SLA issues,
  - accuracy failures usually indicate transformation logic issues.
- I use aggregate reconciliation (count/sum by date/status/product) instead of full row-by-row comparison for daily operations because it is faster and still catches most financial-impacting errors.
- Record-level checks are still included for key constraints (null PKs, duplicate IDs) where correctness risk is high.

## 1. Completeness Checks

- Row counts by table and load window:
  - source `transaction` rows since last watermark vs `RAW.TRANSACTION_RAW`.
- Distinct key checks:
  - distinct `id` in source vs raw.
- Null checks on required fields:
  - `transaction.id`, `account.id`, `user.id`.

## 2. Freshness Checks

- Validate latest source `updated_at` is present in Snowflake within SLA threshold.
- Validate pipeline run completed before business cutoff.
- Example threshold: max lag <= 2 hours between source max `updated_at` and raw max `updated_at`.

## 3. Accuracy Checks

- Reconcile daily aggregate transaction amount by date/status between source and Snowflake.
- Reconcile record counts by `product_type`.
- Spot-check hash totals for critical columns.

## Validation and Gatekeeping Rules

Only publish to `MART` when:

- All critical checks pass.
- Any warnings are documented and approved.
- Audit logs include run ID, status, and timestamps.

If a critical check fails:

1. Mark pipeline run as `FAILED_DQ`.
2. Do not overwrite downstream mart tables.
3. Alert owner with failing check name, table, and variance value.

This protects Finance users from consuming partial or incorrect daily numbers.

## Example Check SQL

```sql
-- Freshness check for transaction table
select
  max(updated_at) as max_source_ts
from SOURCE_DB.TRANSACTION;

select
  max(updated_at) as max_raw_ts
from RAW.TRANSACTION_RAW
where _is_deleted = false;
```

```sql
-- Aggregate accuracy reconciliation example
select
  cast(transaction_date as date) as dt,
  status,
  sum(amount) as total_amt,
  count(*) as txn_cnt
from RAW.TRANSACTION_RAW
where _is_deleted = false
group by 1,2;
```

## Assumptions

- Temporary minor count drift can occur during active source writes; checks run after extract cutoff.
- Source access allows aggregate query comparisons.
- Thresholds are configurable by table criticality (for example, strict for `transaction`, softer for low-volume dimensions).

## AI Usage Note

AI suggested generic validation buckets and some heavy reconciliation ideas. I kept the core categories but rejected expensive daily row-level diffs for all tables because they are unnecessary for this scale and SLA. My final version emphasizes practical controls: aggregate reconciliation for financial confidence, strict blocking rules before publish, and explicit failure handling steps.
