# Runbook: SNMP And PRTG

## Symptoms

- PRTG connects but standard sensors do not find expected OIDs.
- Private VoxyWatch OIDs respond but standard aliases fail.
- SNMP works locally but not from NMS.

## First Checks

- SNMP enabled.
- Bind address and allowlist.
- SNMPv2c community or SNMPv3 credentials.
- Whether the NMS expects HOST-RESOURCES-MIB or VoxyWatch PEN OIDs.

## OID Surfaces

VoxyWatch exposes:

- Host/server metrics through standard MIB-II and HOST-RESOURCES-MIB OIDs:
  - identity and agent uptime: `1.3.6.1.2.1.1`
  - Linux host uptime: `1.3.6.1.2.1.25.1.1.0`
  - physical memory: `1.3.6.1.2.1.25.2.2.0` and `1.3.6.1.2.1.25.2.3.1`
  - root filesystem: row 3 of `1.3.6.1.2.1.25.2.3.1`
  - aggregate CPU load: `1.3.6.1.2.1.25.3.3.1.2.1`
- VoxyWatch service/capture/VoIP metrics under the private PEN `1.3.6.1.4.1.65985`.

PRTG should use standard SNMP System Uptime, Memory, Disk Free and CPU Load sensors for
the Linux host. Use SNMP Custom/Library sensors with `VOXYWATCH-MIB` only for portal,
sniffer, capture, HEP, VoIP, retention and VoxyWatch alarm state.

Private resource OIDs under the VoxyWatch PEN remain as backward-compatible aliases.
New NMS configurations should not use them for generic host monitoring.

## Likely Domains

- `configuration`: bind, allowlist, community, SNMPv3 settings or wrong sensor type.
- `deployment-os`: firewall or network path.
- `product-code`: missing alias or incorrect SNMP response type.
