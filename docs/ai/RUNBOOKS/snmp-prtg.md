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

Operational Health and the Support Bundle expose the SNMP component without
credentials or source addresses. Check `running`, `error_code`,
`last_error_at`, `requests_total` and `requests_rejected`. An
`authentication_failed` result means requests reached VoxyWatch but the NMS
community/USM configuration did not match; align both sides instead of weakening
the agent. Repeated failures are rate-limited in service logs.

`error_code` is a stable diagnostic category, not the raw library message:

- `authentication_failed`: community or SNMPv3 user/authentication mismatch.
- `source_not_allowed`: the source address is outside the configured NMS allowlist.
- `protocol_error`: the SNMP decoder rejected a malformed, unsupported or otherwise
  invalid datagram before normal request dispatch.
- `bind_failed`: the configured address/port could not be opened.
- `permission_denied`: the operating system refused the requested socket operation.
- `request_failed`: an agent error did not match a more specific category.

`requests_total` counts datagrams that reached the normal instrumented dispatcher.
`requests_rejected` also includes allowlist and protocol/decoder rejections that can
occur before that dispatcher. Therefore `requests_rejected` may increase while
`requests_total` remains unchanged; this is expected and does not indicate a broken
counter. Use `last_error_at` to correlate the most recent category with the NMS test.

## OID Surfaces

VoxyWatch exposes:

- Host/server metrics through standard MIB-II and HOST-RESOURCES-MIB OIDs:
  - identity and agent uptime: `1.3.6.1.2.1.1`
  - Linux host uptime: `1.3.6.1.2.1.25.1.1.0`
  - physical memory: `1.3.6.1.2.1.25.2.2.0` and `1.3.6.1.2.1.25.2.3.1`
  - root filesystem: row 3 of `1.3.6.1.2.1.25.2.3.1`
  - aggregate CPU load: `1.3.6.1.2.1.25.3.3.1.2.1`
- VoxyWatch service/capture/VoIP metrics under the private PEN `1.3.6.1.4.1.65985`.
- Portable host I/O extensions under `1.3.6.1.4.1.65985.4`: disk read/write MiB/s,
  read/write IOPS and counters; network RX/TX Mbit/s and counters; swap and exact root capacity.

PRTG should use standard SNMP System Uptime, Memory, Disk Free and CPU Load sensors for
the Linux host. Use SNMP Custom/Library sensors with `VOXYWATCH-MIB` only for portal,
sniffer, capture, HEP, VoIP, retention and VoxyWatch alarm state.

Use standard OIDs for generic uptime, CPU, RAM and filesystem occupancy. Use the VoxyWatch
resource OIDs for rates/counters that do not have a uniformly portable scalar across common NMS tools.
Rate OIDs ending in `X100` must be divided by 100; the generated exports carry that divisor.

## Downloads From Settings

Settings → Advanced → SNMP provides four generated exports. They all come from the same
runtime OID catalog, so names and numeric OIDs cannot drift independently:

- `VOXYWATCH-MIB.mib`: English SMIv2 MIB with module identity, object/notification groups and
  compliance declarations. In PRTG, convert it with Paessler MIB Importer and add an SNMP
  Library sensor. PRTG SNMP Custom v2 can also consume supported ASN.1 MIB folders.
- `voxywatch-snmp-oids.csv`: flat scalar list for PRTG Custom sensors, Nagios-compatible checks,
  spreadsheets and provisioning scripts. Every scalar already includes its `.0` instance.
- `voxywatch-zabbix-7.4-snmp.yaml`: importable Zabbix 7.4 template with 47 SNMP agent items.
  Configure the SNMP interface and credentials on the Zabbix host after importing it.
- `voxywatch-snmp-catalog.json`: versioned machine-readable catalog for automation and custom NMS adapters.

The MIB intentionally defines VoxyWatch enterprise objects only. Continue using the NMS vendor's
built-in SNMPv2-MIB and HOST-RESOURCES-MIB support for generic Linux uptime, CPU, RAM and storage.

The Base OID shown in Settings is informational and read-only. New installations use VoxyWatch's
assigned PEN; an older installation that already used another tree keeps it for sensor compatibility.

## Likely Domains

- `configuration`: bind, allowlist, community, SNMPv3 settings or wrong sensor type.
- `deployment-os`: firewall or network path.
- `product-code`: missing alias or incorrect SNMP response type.
