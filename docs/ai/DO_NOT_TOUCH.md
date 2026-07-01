# Do Not Touch

These areas are high-risk. Do not change them casually.

## Never

- Do not access, configure or modify the customer SBC.
- Do not print, store or request secrets, API tokens, passwords, private keys or license contents.
- Do not paste raw SIP, audio, CDR samples with identifiers, IP lists, trunks or Call-IDs into external AI tools.
- Do not hand-patch production code.
- Do not delete customer data, database tables, RTP segments, audio, CDRs, releases or repositories.
- Do not force-push, reset hard or rewrite release history.

## Avoid Without Explicit Approval

- Restarting the sniffer or interrupting capture.
- Enabling a network-listening service.
- Changing retention/autopurge.
- Running broad database scans on high-volume installs.
- Changing incident thresholds globally.
- Turning on risky new behavior without an off flag.

## If Something Fails

Record:

- What failed.
- Concrete cause.
- What process would have caught it earlier.
- What guardrail was added: test, script, invariant, docs, checklist or runbook.
