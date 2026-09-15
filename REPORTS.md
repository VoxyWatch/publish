# Reports

VoxyWatch Reports works without an LLM. It uses canonical hourly network, external-trunk and internal-endpoint rollups, plus a bounded CDR-detail source.

Seven templates and the visual builder support periods, grouping, metrics, enabled-trunk filters, previous-period comparison, charts, tables, saved definitions, read-only role sharing and CSV, Excel or HTML export. Exports use a fresh query and state clear limits instead of silently shortening results.

CDR columns are not hardcoded. VoxyWatch discovers scalar fields from the current canonical public CDR projection and revalidates every report when it runs. New fields can appear without a report-engine release; removed or complex fields are safely omitted.

Schedules start paused and use the chosen civil time zone. Their delivery history distinguishes acceptance by the configured mail service from proof that a recipient read a report. Queries, formulas and exports are deterministic. Optional AI assistance may draft the same validated report specification or explain results, but cannot invent fields, calculations or evidence.
