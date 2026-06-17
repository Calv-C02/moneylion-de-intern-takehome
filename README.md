# MoneyLion Data Engineering Intern Take-Home

This repository contains my complete submission for the MoneyLion Data Engineering Intern assessment.

## Executive Summary (What I Did and Why)

- Designed a daily batch ETL from source relational tables to Snowflake using a layered model (`RAW` -> `STG` -> `MART`) to keep ingestion reliable and analytics clean.
- Added a data quality validation gate (completeness, freshness, accuracy) so reporting tables are only published when checks pass.
- Proposed Snowflake performance tuning based on observed workload patterns, with cost-aware controls to avoid over-optimization.
- Designed access governance with RBAC, secure views, and masking to protect sensitive fields (`email`, `ssn`, `addresses_json`) while preserving analyst usability.
- Built a Kimball-style dimensional model with explicit grain and two fact tables to directly answer required business questions on transactions and membership revenue.
- Documented assumptions, trade-offs, SQL implementation sketches, and AI usage notes for each question.

## Approach Summary (How I Solved It)

1. Model data flow from source DB into Snowflake with incremental loading.
2. Preserve source fidelity in `RAW`, standardize in `STG`, and publish analyst-ready data in `MART`.
3. Add pre-publish validation checks and fail closed when critical checks fail.
4. Address performance and cost together using query history, warehouse metering, targeted tuning, and governance controls.
5. Use dimensional modeling best practices (declare grain first, then dimensions and facts) for robust analytics.

## Assessment Question Mapping

- **Database to Snowflake ETL (Q1):** `docs/01_etl_design.md`
- **Load validation before reporting (Q2):** `docs/02_data_quality_checks.md`
- **Performance optimization and cost control (Q3):** `docs/03_snowflake_performance.md`
- **Sensitive data access governance (Q4):** `docs/04_access_governance.md`
- **Snowflake cost governance (Q5):** `docs/05_cost_governance.md`
- **Dimensional modeling design (Q6):** `docs/06_dimensional_model.md`

## Repository Guide

- `docs/01_etl_design.md`: Source DB to Snowflake ingestion design and raw layer organization.
- `docs/02_data_quality_checks.md`: Validation strategy for completeness, freshness, and accuracy.
- `docs/03_snowflake_performance.md`: Query performance tuning and cost-conscious optimization.
- `docs/04_access_governance.md`: Snowflake access controls for PII protection and team access.
- `docs/05_cost_governance.md`: Cost-driver analysis and controls for predictable Snowflake spend.
- `docs/06_dimensional_model.md`: Dimensional model for users, accounts, memberships, and transactions.
- `docs/07_submission_checklist.md`: Final validation checklist, references, and interview prep notes.
- `sql/staging/`: Staging-layer SQL examples.
- `sql/quality_checks/`: Data quality and reconciliation SQL checks.
- `sql/marts/`: Star schema DDL and analytic model SQL examples.
- `diagrams/`: Architecture and star-schema diagrams.

## What Is In Each `docs/01-06` File

- `docs/01_etl_design.md`: Extraction approach, Snowflake raw-layer structure, orchestration, failure handling, and ETL trade-offs.
- `docs/02_data_quality_checks.md`: Validation framework, gatekeeping rules, check thresholds, and example reconciliation SQL.
- `docs/03_snowflake_performance.md`: Investigation method, tuning levers, and measurable performance/cost success criteria.
- `docs/04_access_governance.md`: Least-privilege design, masking strategy, secure access patterns, and governance validation steps.
- `docs/05_cost_governance.md`: Cost-driver diagnosis, optimization prioritization, budget controls, and operating cadence.
- `docs/06_dimensional_model.md`: Fact/dimension design, grain, keys, metric definitions, and example analytical queries.

## Assessment Assumptions (Summary)

- Source system is a production relational database with stable primary keys.
- Daily refresh is required before business hours, so a scheduled batch design is the default.
- Incremental extraction uses CDC when available; otherwise uses a high-watermark on `updated_at`.
- `membership` is optional per user (0 or 1 active membership record in this simplified model).
- Transaction records are append-only in source, but status may update post-ingestion.
- PII (`email`, `ssn`, `addresses_json`) must be restricted by policy and role.

## How To Review

1. Read each section in `docs/` in numeric order.
2. Use `sql/` files to see concrete implementation examples.
3. Review `diagrams/` for architecture and star schema context.

## References

- [Snowflake Documentation](https://docs.snowflake.com/)
- [Kimball Group Dimensional Modeling Techniques](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/)
- [Your Conceptual Guide to Building a Star Schema Data Warehouse](https://medium.com/@sarahryliegasparini/your-conceptual-guide-to-building-a-star-schema-data-warehouse-3ea25ccf0fce)
- [Kimball's Dimensional Data Modeling (Holistics)](https://www.holistics.io/books/setup-analytics/kimball-s-dimensional-data-modeling/)
- [Dimensional Modeling Design: Why Does It Matter? (Cube)](https://cube.dev/blog/dimensional-modeling-design-why-does-it-matter)
- [Back to the Future: Where Dimensional Modeling Enters the Modern Data Stack (YouTube)](https://www.youtube.com/watch?v=-yQa_DxEqaQ)

## AI Usage

AI was used to brainstorm initial solution structures and edge cases. I refined all proposals to fit the prompt constraints, simplified overly complex suggestions, and documented trade-offs and assumptions based on my own reasoning.
