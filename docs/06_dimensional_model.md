# 6) Dimensional Model Design

## Objective

Design a dimensional model that supports reliable analytics on transactions and memberships while remaining easy for analysts to query.

## Business Questions Supported

1. Total transaction amount by month, product type, and transaction status.
2. Membership revenue by month and membership code.

## Approach

Use a Kimball-style star schema with conformed dimensions and two facts:

- `fact_transactions`
- `fact_membership_billing`

## Why This Approach (Reasoning and Trade-offs)

- The source schema is OLTP-style and normalized, which is good for writes but inconvenient for analytics joins.
- A star schema reduces join complexity and improves reporting usability for business users.
- Two facts are used because transaction events and membership billing events have different business processes and grains. Mixing them in one fact would blur semantics and increase query errors.
- Atomic grain is retained for `fact_transactions` so future analysis remains flexible.
- Summary tables can still be added later for performance, but they should not replace atomic history.

## Grain Definitions

- **`fact_transactions` grain:** one row per transaction event (`transaction.id`).
- **`fact_membership_billing` grain:** one row per membership billing event per billing cycle (derived from membership records and billing period logic).

## Dimension Tables

### `dim_date`

- Surrogate key: `date_key` (`yyyymmdd`)
- Attributes: calendar date, month, quarter, year, week, month_start, month_end.

### `dim_user`

- Surrogate key: `user_key`
- Natural key: `user_id`
- Attributes: `full_name` (optional), created date, user status flags.
- PII handling: expose masked or dropped sensitive attributes in analyst-facing schema.

### `dim_account`

- Surrogate key: `account_key`
- Natural key: `account_id`
- Attributes: `account_type`, `status`, created date, balance band.

### `dim_membership`

- Surrogate key: `membership_key`
- Natural key: `membership_id`
- Attributes: `membership_code`, `membership_name`, `billing_period`, `status`.

### `dim_product`

- Surrogate key: `product_key`
- Natural composite: (`product_type`, `product_id`)
- Attributes: product category/type descriptors.

### Optional `dim_merchant`

- Surrogate key: `merchant_key`
- Natural key: `merchant_code`

## Fact Tables and Measures

### `fact_transactions`

Foreign keys:
- `transaction_date_key` -> `dim_date`
- `user_key` -> `dim_user`
- `account_key` -> `dim_account`
- `product_key` -> `dim_product`
- optional `merchant_key` -> `dim_merchant`

Measures:
- `transaction_amount`
- `transaction_count` (always 1 per row)

Degenerate dimensions:
- `transaction_id`
- `transaction_status`
- `country_code`
- `postal_code`
- `supplier_code`

### `fact_membership_billing`

Foreign keys:
- `billing_date_key` -> `dim_date`
- `user_key` -> `dim_user`
- `account_key` -> `dim_account`
- `membership_key` -> `dim_membership`

Measures:
- `membership_revenue_amount`
- `membership_billing_count` (always 1 per row)

## Key Metric Definitions

- **Total transaction amount:** `sum(fact_transactions.transaction_amount)`.
- **Total transaction count:** `sum(fact_transactions.transaction_count)`.
- **Membership revenue:** `sum(fact_membership_billing.membership_revenue_amount)`.

## Validation and Gatekeeping Rules

Before publishing marts for analyst use:

1. Confirm each fact table adheres to declared grain (no mixed-grain records).
2. Confirm fact foreign keys resolve to corresponding conformed dimensions.
3. Confirm metric reconciliation against trusted staging totals (for example daily transaction sums).
4. Confirm business questions from prompt are answerable with straightforward SQL.

If any check fails, do not publish updated mart tables.

## Example Query: Transaction Amount by Month/Product/Status

```sql
select
  d.year,
  d.month,
  p.product_type,
  f.transaction_status,
  sum(f.transaction_amount) as total_transaction_amount
from mart.fact_transactions f
join mart.dim_date d on f.transaction_date_key = d.date_key
join mart.dim_product p on f.product_key = p.product_key
group by 1,2,3,4
order by 1,2,3,4;
```

## Example Query: Membership Revenue by Month/Code

```sql
select
  d.year,
  d.month,
  m.membership_code,
  sum(f.membership_revenue_amount) as membership_revenue
from mart.fact_membership_billing f
join mart.dim_date d on f.billing_date_key = d.date_key
join mart.dim_membership m on f.membership_key = m.membership_key
group by 1,2,3
order by 1,2,3;
```

## Assumptions

- Membership table represents subscription records but billing events may be modeled as derived periodic records.
- `account.balance` in source is current-state and not treated as a periodic fact without snapshots.
- SCD Type 2 can be added later for dimensions with historical attribute changes.
- Surrogate keys are generated in `MART` to stabilize joins and support future history tracking.

## AI Usage Note

AI helped me evaluate multiple model shapes (single wide fact versus multi-fact star). I rejected a single-fact design because it mixes business processes and makes grain ambiguous. My final model follows Kimball principles (declare grain first, then dimensions/facts) and explicitly maps to both required reporting questions from the assessment.
