# Runbook: Capture Loss

## Symptoms

- Capture percentage drops.
- Last packet age grows.
- HEP sources disappear.
- Calls are missing or incomplete.

## First Checks

- Operational health capture component.
- Sniffer service status.
- Queue drops and kernel drops.
- Disk availability.
- Recent source count.

## Likely Domains

- `integration-source`: SBC/probe stopped sending or changed HEP/RTP behavior.
- `deployment-os`: network, firewall, kernel buffers, disk or service issue.
- `product-code`: reproducible parser or ingestion bug.

## Validation

Capture is healthy when recent packets arrive, queue drops stay at zero, database writes continue and source count matches the expected deployment.
