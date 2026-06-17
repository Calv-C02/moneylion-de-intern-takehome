-- Completeness checks: source-to-raw row count comparison.

with src as (
  select 'user' as table_name, count(*) as cnt from SOURCE_DB.USER
  union all
  select 'account' as table_name, count(*) as cnt from SOURCE_DB.ACCOUNT
  union all
  select 'membership' as table_name, count(*) as cnt from SOURCE_DB.MEMBERSHIP
  union all
  select 'transaction' as table_name, count(*) as cnt from SOURCE_DB.TRANSACTION
),
raw as (
  select 'user' as table_name, count(*) as cnt from RAW.USER_RAW where coalesce(_is_deleted, false) = false
  union all
  select 'account' as table_name, count(*) as cnt from RAW.ACCOUNT_RAW where coalesce(_is_deleted, false) = false
  union all
  select 'membership' as table_name, count(*) as cnt from RAW.MEMBERSHIP_RAW where coalesce(_is_deleted, false) = false
  union all
  select 'transaction' as table_name, count(*) as cnt from RAW.TRANSACTION_RAW where coalesce(_is_deleted, false) = false
)
select
  s.table_name,
  s.cnt as source_count,
  r.cnt as raw_count,
  (r.cnt - s.cnt) as diff
from src s
join raw r using (table_name)
order by 1;
