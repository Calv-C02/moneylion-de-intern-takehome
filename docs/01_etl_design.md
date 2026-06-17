# 1) Database to Snowflake ETL

## Objective

Refresh source data into Snowflake every morning before business hours in a way that is reliable, auditable, and simple enough to operate as a small data team.

## Approach

1. Extract data incrementally from source relational tables (`user`, `account`, `membership`, `transaction`).
2. Land extracted data in object storage first (acts as immutable replay layer).
3. Load landed data to Snowflake `RAW` tables with ingestion metadata.
4. Transform `RAW` to typed `STG` models.
5. Publish business-consumable `MART` models after data quality checks pass.

## Why This Approach (Reasoning and Trade-offs)

- A landing zone between source DB and Snowflake protects the source database and gives a recovery path if transforms fail.
- Incremental extraction is chosen over full refresh because transactions will grow quickly and full daily reloads become expensive.
- CDC is preferred because it captures updates/deletes explicitly, but high-watermark on `updated_at` is retained as a fallback for portability.
- Layering (`RAW` -> `STG` -> `MART`) keeps responsibilities clear:
  - `RAW` preserves source truth,
  - `STG` standardizes and deduplicates,
  - `MART` serves analytics with stable definitions.

## Snowflake Raw Layer Organization

Use one analytics database with schema separation:

- `RAW`: source-shaped append history with ingestion metadata.
- `STG`: typed and cleaned records.
- `MART`: reporting-ready dimensions and facts.
- `AUDIT`: run metadata, validation logs, and reconciliation outcomes.

### Raw Table Pattern

Each `RAW` table stores source columns plus:

- `_ingested_at` (load timestamp)
- `_batch_id` (idempotency key)
- `_source_system` (lineage)
- `_is_deleted` (for CDC delete handling)

## Validation and Gatekeeping Rules

Pipeline publish to `MART` is blocked unless:

1. All required source tables are loaded for the batch.
2. Freshness threshold is met before business cutoff.
3. Critical reconciliation checks pass (counts and key financial aggregates).
4. Run audit status is `SUCCESS` in control table.

This gate is important because Finance reports should fail closed (no publish) rather than silently serve stale or partial data.

## Scheduling and Operations

- Orchestrate daily run (for example 4:00 AM local time).
- Load independent tables in parallel, then run dependency-aware transforms.
- Retry transient failures with exponential backoff.
- Keep landed files for replay of failed windows.

## Example Snowflake DDL (Raw)

```sql
create schema if not exists RAW;

create table if not exists RAW.TRANSACTION_RAW (
  id number,
  account_id number,
  product_type string,
  product_id number,
  supplier_code string,
  amount float,
  country_code string,
  postal_code string,
  status string,
  merchant_code string,
  transaction_date timestamp_ntz,
  updated_at timestamp_ntz,
  _ingested_at timestamp_ntz default current_timestamp(),
  _batch_id string,
  _source_system string,
  _is_deleted boolean default false
);
```

## Assumptions

- Source tables have stable primary keys.
- `updated_at` is reliable if CDC is unavailable.
- Finance accepts daily batch refresh (not near-real-time).
- Membership remains optional per user in this simplified domain.

## AI Usage Note

AI helped me compare two extraction patterns (CDC-first versus pure high-watermark) and suggest common Snowflake layer designs. I rejected suggestions that introduced extra infrastructure not required by the prompt (for example, near-real-time streaming and complex event frameworks). My final design keeps daily batch reliability as the priority, adds a clear publish gate, and stays scoped to the given schema and intern-level implementation expectations.
