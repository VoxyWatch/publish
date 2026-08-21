# Flash Call Detection

VoxyWatch Flash Call Intelligence detects signaling patterns commonly associated
with missed-call authentication and similar automated call-verification traffic.
It is a passive early-warning feature: it observes SIP metadata, explains why a
pattern looks automated and can notify operators. It never blocks, rejects,
reroutes or modifies a call, and it never controls the SBC.

## What the detector looks for

The detector evaluates recent calls in groups scoped by trunk and originating
source. A group is considered only when the originating side repeatedly sends
`CANCEL` after `INVITE`. It then combines the following deterministic signals:

- repeated `INVITE` to `CANCEL` timing inside the configured range;
- a high percentage of calls cancelled by the originating side;
- `487 Request Terminated` evidence following cancellation;
- no answer and no RTP/RTCP media;
- low timing dispersion, measured with median absolute deviation (MAD);
- high destination fan-out instead of repeated calls to one destination.

The result is a score from 0 to 100 with the supporting measurements. Detection
and scoring run locally and do not use an LLM or consume AI tokens.

VoxyWatch identifies an automation pattern; it does not assert the application
owner's intent. Operators should confirm commercial and contractual context
before treating the traffic as an OTP or authentication service.

## Prerequisites

VoxyWatch must see the relevant SIP dialog through HEP, SIPREC or the supported
capture path. For the strongest result it should receive:

1. the original `INVITE`;
2. provisional responses when present;
3. the originator's `CANCEL`;
4. the corresponding `487`;
5. enough recent traffic to satisfy the minimum sample.

NAT, topology hiding or a B2BUA may change visible source addresses. VoxyWatch
groups by the source it can observe and hashes that source before exposing it to
the AI/MCP layer. Missing `487` or media evidence lowers confidence but does not
invent evidence.

## Modes

Open **Fraud → Flash Call Intelligence → Configuration**.

| Mode | Behavior |
|---|---|
| **Shadow** | Default. Calculates and displays findings without opening incidents or sending notifications. |
| **Alerting** | Opens a deduplicated incident only after the score remains above the alert threshold for the configured number of consecutive windows. |

Changing from Shadow to Alerting starts the sustain counter from zero. Shadow
observations never count toward an alert. When a previously active pattern is
absent for the configured recovery windows, its incident is recovered.

The release ships with the detector enabled in Shadow. The UI mode selector
offers Shadow and Alerting; an administrator-managed `enabled: false` setting
turns the detector off, clears its counters and recovers its open incidents.

## Default configuration

The mode, economic assumptions, window, minimum calls, alert score, sustain and
recovery values are editable in the UI. The remaining detector gates below are
conservative runtime defaults managed through the validated settings contract;
they are documented for interpretation and controlled deployments. Advanced UI
settings are collapsed by default.

| Setting | Default | Meaning |
|---|---:|---|
| Evaluation window | 15 min | Recent activity interval evaluated every 60 seconds |
| Minimum calls | 30 | Smallest group that can produce a finding |
| CANCEL timing range | 1–15 s | Accepted `INVITE` to originator `CANCEL` interval |
| Minimum origin-cancel ratio | 80% | Hard gate: share cancelled by the originating side |
| Dominant timing-bucket ratio | 70% | Share concentrated near the repeated timing |
| Maximum timing MAD | 1 s | Maximum robust timing dispersion |
| Minimum unique-destination ratio | 75% | Required destination fan-out |
| Alert score | 70 | Minimum score eligible for an incident |
| Critical score | 90 | Score classified as critical |
| Sustain windows | 2 | Consecutive Alerting windows required before opening |
| Recovery windows | 3 | Consecutive missing windows required before recovery |
| A2P unit revenue | 0 | Optional displaced-value estimate per probable call |
| Substitution percentage | 0% | Estimated share replacing billable A2P verification |
| Currency | USD | ISO 4217 display currency for the estimate |

The economic values are operator-provided estimates, not billing records. A
zero value disables the monetary estimate without changing detection.

## Reading a finding

- **Probable calls:** calls in the group that satisfy the core pattern.
- **Observed calls:** all calls considered for that trunk/source group.
- **Score:** deterministic confidence in the pattern, not a fraud probability.
- **Dominant timing:** repeated delay between `INVITE` and `CANCEL`.
- **MAD:** timing consistency; lower values indicate more automation-like timing.
- **Origin-cancel ratio:** percentage cancelled by the same side that originated
  the call.
- **Destination fan-out:** unique destinations divided by probable calls.
- **Signals:** the exact gates and supporting observations that contributed.
- **Estimated displaced revenue:** probable calls × configured unit revenue ×
  substitution percentage.

The source identifier shown to agents and MCP clients is a short installation-
local hash. Raw source IPs and telephone numbers are not returned by the Flash
Call specialist.

## Safe validation

Use **Test detector** in the Flash Call Intelligence panel. The test generates a
bounded synthetic group in memory and returns a finding. It:

- does not originate a call;
- does not insert CDRs;
- does not create or modify incidents;
- does not alter the live detector snapshot;
- does not call an AI provider;
- does not change the SBC or firewall.

Run the synthetic test first, leave the feature in Shadow long enough to observe
the customer's normal traffic, review timing/fan-out distributions, and only
then enable Alerting.

## False positives and tuning

Automated monitoring, callback services, predictive dialers and some legitimate
high-fan-out applications can resemble flash calls. Before lowering thresholds:

1. identify the trunk and time range;
2. verify that the originating side sends the `CANCEL`;
3. inspect representative SIP ladders;
4. confirm whether the repeated delay belongs to a known application;
5. prefer increasing `minimum calls` or `sustain windows` over weakening the
   origin-cancel hard gate;
6. keep Shadow enabled after major routing or SBC topology changes.

If no findings appear, confirm that VoxyWatch sees `CANCEL`, direction is
attributed correctly, the window contains enough calls and the visible source is
stable. If findings are noisy, increase the minimum sample, fan-out requirement,
dominant timing ratio or sustain windows.

## Incidents and notifications

Alerting uses the existing VoxyWatch incident engine and notification channels.
One fingerprint exists per trunk/source pattern, preventing repeated alert
storms. Restart recovery seeds active detector incidents from the database so
the lifecycle remains consistent after a portal restart.

The factory runbook is evidence-first: validate the SIP pattern, identify the
commercial owner and estimate impact. Any blocking or carrier action remains a
human decision performed outside VoxyWatch.

## Privacy and retention

The detector works on the bounded in-memory call working set. The Flash Call
snapshot stores aggregate findings only and is capped at 100 groups. It does not
retain raw SIP bodies, audio, RTP payloads or DTMF. Incidents retain the
deterministic aggregate evidence required for audit and recovery.

The optional `get_flash_call_overview` MCP/agent tool is read-only, requires
`mcp:read`, returns at most 25 findings and replaces the visible source with a
hash. See [MCP Server](MCP_SERVER.md) for remote-access controls.
