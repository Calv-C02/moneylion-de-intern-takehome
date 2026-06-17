-- Freshness checks using max(updated_at).

with source_max as (
  select max(updated_at) as max_source_updated_at
  from SOURCE_DB.TRANSACTION
),
raw_max as (
  select max(updated_at) as max_raw_updated_at
  from RAW.TRANSACTION_RAW
  where coalesce(_is_deleted, false) = false
)
select
  s.max_source_updated_at,
  r.max_raw_updated_at,
  datediff('minute', r.max_raw_updated_at, s.max_source_updated_at) as lag_minutes
from source_max s
cross join raw_max r;
