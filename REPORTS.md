# Reports

VoxyWatch Reports works without an LLM. It uses canonical hourly network, external-trunk and internal-endpoint rollups, plus a bounded CDR-detail source.

Seven templates and the visual builder support periods, grouping, metrics, enabled-trunk filters, previous-period comparison, charts, tables, saved definitions and CSV export.

CDR columns are not hardcoded. VoxyWatch discovers scalar fields from the current canonical public CDR projection and revalidates every report when it runs. New fields can appear without a report-engine release; removed or complex fields are safely omitted.

Queries, formulas and exports are deterministic. Future AI assistance may draft the same validated ReportSpec or explain results, but cannot invent fields, SQL, calculations or evidence.
