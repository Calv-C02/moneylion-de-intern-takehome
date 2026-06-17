-- Accuracy reconciliation for transaction amount and count by day/status.

with source_agg as (
  select
    cast(transaction_date as date) as dt,
    status,
    count(*) as source_txn_count,
    sum(amount) as source_total_amount
  from SOURCE_DB.TRANSACTION
  group by 1,2
),
raw_agg as (
  select
    cast(transaction_date as date) as dt,
    status,
    count(*) as raw_txn_count,
    sum(amount) as raw_total_amount
  from RAW.TRANSACTION_RAW
  where coalesce(_is_deleted, false) = false
  group by 1,2
)
select
  coalesce(s.dt, r.dt) as dt,
  coalesce(s.status, r.status) as status,
  s.source_txn_count,
  r.raw_txn_count,
  s.source_total_amount,
  r.raw_total_amount,
  coalesce(r.raw_txn_count, 0) - coalesce(s.source_txn_count, 0) as cnt_diff,
  coalesce(r.raw_total_amount, 0) - coalesce(s.source_total_amount, 0) as amt_diff
from source_agg s
full outer join raw_agg r
  on s.dt = r.dt
 and s.status = r.status
order by 1,2;
