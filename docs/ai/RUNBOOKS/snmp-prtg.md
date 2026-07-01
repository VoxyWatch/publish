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

- Private OIDs under `1.3.6.1.4.1.65985`.
- Selected standard aliases for generic NMS tools.

## Likely Domains

- `configuration`: bind, allowlist, community, SNMPv3 settings or wrong sensor type.
- `deployment-os`: firewall or network path.
- `product-code`: missing alias or incorrect SNMP response type.
