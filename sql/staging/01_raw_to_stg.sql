-- Example staging transformations from RAW to STG layer.

create schema if not exists STG;

create or replace transient table STG.STG_USER as
select
  id as user_id,
  full_name,
  created_at,
  updated_at,
  email,
  ssn,
  addresses_json,
  _ingested_at,
  _batch_id
from RAW.USER_RAW
qualify row_number() over (partition by id order by updated_at desc, _ingested_at desc) = 1;

create or replace transient table STG.STG_ACCOUNT as
select
  id as account_id,
  user_id,
  status,
  account_type,
  balance,
  created_at,
  updated_at,
  _ingested_at,
  _batch_id
from RAW.ACCOUNT_RAW
where coalesce(_is_deleted, false) = false
qualify row_number() over (partition by id order by updated_at desc, _ingested_at desc) = 1;

create or replace transient table STG.STG_TRANSACTION as
select
  id as transaction_id,
  account_id,
  product_type,
  product_id,
  supplier_code,
  amount,
  country_code,
  postal_code,
  status as transaction_status,
  merchant_code,
  transaction_date,
  updated_at,
  _ingested_at,
  _batch_id
from RAW.TRANSACTION_RAW
where coalesce(_is_deleted, false) = false;
