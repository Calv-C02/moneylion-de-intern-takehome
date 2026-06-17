# 4) Access Governance and Sensitive Data Protection

## Objective

Enable cross-team analytics while preventing unauthorized access to sensitive user data (`email`, `ssn`, `addresses_json`).

## Approach

Use layered governance in Snowflake:

1. Role-based access control (RBAC) for least-privilege entitlement.
2. PII segmentation between restricted raw data and analyst-safe marts.
3. Dynamic masking and secure views for policy enforcement.
4. Audit and classification tags to prove controls are working.

## Why This Approach (Reasoning and Trade-offs)

- RBAC alone is not enough; users can still accidentally query sensitive columns if raw tables are exposed widely.
- Secure views and masking policies reduce accidental exposure while still enabling analysis.
- Some teams need business-level attributes but not direct identifiers; masked views balance data utility and privacy.
- Row access policies are optional initially because the prompt focuses on column sensitivity; they can be added when team-based row restrictions are required.

## 1) Role-Based Access Control (RBAC)

- Create layered roles:
  - `ROLE_DATA_ENGINEER` (full engineering access)
  - `ROLE_ANALYST` (mart read access, no raw PII)
  - `ROLE_FINANCE_ANALYST` (membership and transaction reporting views)
  - `ROLE_GOVERNANCE_ADMIN` (policy administration)

Grant least privilege by schema/object level.

## 2) PII Segmentation

- Keep raw PII in restricted schema/tables.
- Publish analyst-safe views in `MART` with PII removed or masked.
- Use secure views to enforce logic server-side.

## 3) Dynamic Data Masking

- Apply masking policy to `email`, `ssn`, and `addresses_json`.
- Unmask only for privileged roles.

## 4) Row Access (if needed)

- Add row access policies for team-specific scopes (example: regional access by `country_code`).

## 5) Classification and Auditing

- Tag sensitive columns (for example `DATA_CLASSIFICATION = 'PII'`).
- Monitor query access via Snowflake access history and audit logs.

## Validation and Gatekeeping Rules

Before promoting governance configuration to production:

1. Confirm `ROLE_ANALYST` cannot read raw `email`, `ssn`, `addresses_json`.
2. Confirm privileged roles can access unmasked fields only when required.
3. Confirm analyst queries still work against curated views.
4. Confirm access audit logs capture policy-protected object reads.

Any failed control test blocks release of permission changes.

## Example Masking Policy

```sql
create or replace masking policy mask_ssn as (val string) returns string ->
  case
    when current_role() in ('ROLE_DATA_ENGINEER', 'ROLE_GOVERNANCE_ADMIN') then val
    else '***-**-****'
  end;
```

## Assumptions

- Compliance requires masking for analysts by default.
- Some engineering roles still require controlled raw access for operations.
- Central data team owns role and policy lifecycle.

## AI Usage Note

AI suggested multiple governance frameworks, including options that would be too heavy for an intern assessment. I selected a Snowflake-native baseline (RBAC, secure views, masking, audit checks) that directly addresses the prompt's sensitive fields. I also added concrete pre-release validation tests so the proposal is operational, not just conceptual.
