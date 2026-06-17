-- Star schema DDL examples for MART layer.

create schema if not exists MART;

create or replace table MART.DIM_DATE (
  date_key number primary key,
  calendar_date date,
  day_of_month number,
  month number,
  month_name string,
  quarter number,
  year number
);

create or replace table MART.DIM_USER (
  user_key number autoincrement start 1 increment 1 primary key,
  user_id number not null,
  full_name string,
  user_created_at timestamp_ntz,
  user_updated_at timestamp_ntz,
  is_current boolean default true
);

create or replace table MART.DIM_ACCOUNT (
  account_key number autoincrement start 1 increment 1 primary key,
  account_id number not null,
  user_id number not null,
  account_type string,
  account_status string,
  account_created_at timestamp_ntz,
  account_updated_at timestamp_ntz,
  is_current boolean default true
);

create or replace table MART.DIM_PRODUCT (
  product_key number autoincrement start 1 increment 1 primary key,
  product_type string,
  product_id number
);

create or replace table MART.DIM_MEMBERSHIP (
  membership_key number autoincrement start 1 increment 1 primary key,
  membership_id number not null,
  membership_name string,
  membership_code string,
  billing_period string,
  membership_status string
);

create or replace table MART.FACT_TRANSACTIONS (
  transaction_id number,
  transaction_date_key number,
  user_key number,
  account_key number,
  product_key number,
  transaction_status string,
  country_code string,
  postal_code string,
  merchant_code string,
  supplier_code string,
  transaction_amount float,
  transaction_count number default 1
);

create or replace table MART.FACT_MEMBERSHIP_BILLING (
  membership_billing_id number autoincrement start 1 increment 1,
  billing_date_key number,
  user_key number,
  account_key number,
  membership_key number,
  membership_revenue_amount float,
  membership_billing_count number default 1
);
