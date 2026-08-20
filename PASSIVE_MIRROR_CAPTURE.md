# Passive Mirror Capture (Beta)

Passive Mirror Capture lets VoxyWatch ingest a read-only copy of SIP, RTP and
RTCP when the SBC cannot export HEP and SIPREC is unavailable. It never logs in
to, configures or changes the SBC. The feature is **OFF by default**.

## Architecture and safe defaults

```text
SBC/voice VLAN -> switch/cloud mirror -> dedicated VoxyWatch NIC
                                      -> voxywatch-probe
                                      -> HEPv3 127.0.0.1:9060
                                      -> existing sniffer/database/CDR pipeline
```

- The probe is an isolated service. Failure or overload does not stop native
  HEP or SIPREC.
- Local SPAN/RSPAN needs no listening port. ERSPAN is GRE (IP protocol 47), not
  TCP/UDP. AWS Traffic Mirroring delivers VXLAN on UDP 4789.
- The destination NIC should have no IP address and must not be the management
  interface. Never select `any` or loopback.
- Media authorization defaults to **SDP-learned**. Unrelated high-port UDP is
  rejected. SBC/voice CIDRs add a stronger first filter.
- Duplicate packets observed on both directions are suppressed for 1.5 s.
- The probe exposes bounded counters in `/run/voxywatch-probe/status.json`:
  kernel/interface/queue drops, duplicates, untrusted frames and HEP sends.
- SIP TLS, SRTP and IPsec remain encrypted. The probe can expose connection and
  quality metadata but cannot reconstruct encrypted audio.

## Settings

Open **Settings -> Capture Sources -> Passive Mirror Capture**.

1. Select the dedicated interface.
2. Choose Local SPAN, RSPAN, ERSPAN, AWS VXLAN or Auto detect.
3. Choose SIP + RTP + RTCP, SIP + RTCP, or SIP only.
4. Add SBC/voice CIDRs when known.
5. Keep SDP-learned media authorization unless a controlled validation proves
   heuristic mode is required. Heuristic mode cannot be enabled without CIDRs.
6. Apply. The portal starts only `voxywatch-probe.service` through its scoped
   service-control permission.

HEP, SIPREC and Passive Mirror are complementary sources, not an exclusive
radio selector. The local HEP collector remains the internal normalization bus.

## Network patterns

### Cisco

- SPAN: configure the SBC-facing port/VLAN as source and the dedicated
  VoxyWatch NIC as destination.
- RSPAN: carry the remote-span VLAN to the collector switch, then terminate it
  on the dedicated NIC.
- ERSPAN: send GRE to the VoxyWatch host and choose the ERSPAN input profile.
  Allow IP protocol 47 only from the configured mirror source.

### Huawei

Huawei uses **mirrored port** for the source and **observing port** for the
destination. Local port mirroring is preferred. For remote mirroring, terminate
the mirrored VLAN/tunnel on the dedicated VoxyWatch NIC.

### AWS

Create a VPC Traffic Mirroring session with the VoxyWatch collector ENI/NLB as
target. Permit UDP 4789 from the mirror sources. Choose the AWS VXLAN profile.
Cloud delivery can reorder or drop packets at documented PPS limits, so monitor
the probe and AWS target metrics.

### GCP and Azure

- GCP Packet Mirroring uses an internal passthrough Network Load Balancer and
  collector instances. Avoid selecting the same NIC as mirror source and
  collector; ingress and egress copies can duplicate packets.
- Azure Virtual Network TAP can stream traffic to a collector but availability
  is region/service dependent. Network Watcher packet capture is useful for
  short diagnostics, not continuous product ingestion.

### Juniper and Arista

Use analyzer/port-mirroring (Juniper) or monitor session (Arista) to a dedicated
collector port. If GRE encapsulation is used, select ERSPAN; if the delivery is
an untagged/tagged Ethernet copy, select SPAN/RSPAN.

Vendor syntax changes by platform and release. Validate the vendor configuration
against its official guide before applying it; VoxyWatch does not configure the
network device.

## Capacity and validation

- The mirror destination must carry the sum of mirrored ingress and egress.
  Use a 10 Gb/s collector path when a 1 Gb/s link can approach saturation.
- Preserve full snap length for SIP and media evidence.
- Start with one SBC, confirm both call directions, SDP, RTP/RTCP and zero drops,
  then expand the mirror sources.
- If kernel drops rise, reduce mirrored scope before increasing buffers. If
  queue drops rise, verify the local HEP receiver and CPU/storage health.
- Mirrored traffic contains personal communications. Apply retention, access,
  encryption and lawful-interception/privacy requirements before enabling it.

## Current Beta boundaries

UDP SIP/RTP/RTCP, VLAN/QinQ, VXLAN and ERSPAN II/III are supported. Complete SIP
message payloads over TCP are recognized; TLS cannot be decrypted. Fragmented IP
or TCP SIP reassembly remains a controlled follow-up and should be supplied by
native HEP when required. These limits do not affect the existing HEP or SIPREC
paths.
