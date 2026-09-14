# DisplayBoost — Research Documentation

This directory holds the feasibility study behind DisplayBoost. **English is canonical here;
Turkish translations mirror it one-to-one in [`tr/`](tr/README.md).**

Every factual claim about an API, a version number, a licence or a performance figure is
sourced in [`07-references.md`](07-references.md). Claims that could not be sourced are
labelled as estimates in the text rather than presented as fact.

<div align="center">

**English** | [Türkçe](tr/README.md)

</div>

## Documents

| # | Document | What it answers |
|---|---|---|
| 00 | [Overview](00-overview.md) | What DisplayBoost is, the target architecture, design principles, non-goals, and the glossary |
| 01 | [Virtual display driver](01-virtual-display-driver.md) | How an IddCx indirect display driver works, which Windows versions support which IddCx version, which existing projects to learn from, and how a driver gets signed |
| 02 | [Capture and present](02-capture-and-present.md) | How to get frames out of the virtual display and onto the physical monitor with minimal latency |
| 03 | [Upscaling](03-upscaling.md) | Which upscalers are technically usable and legally shippable, and why the famous ones are not |
| 04 | [Prior art](04-prior-art.md) | Magpie, Lossless Scaling, Automatic Super Resolution, AMD RSR and what DisplayBoost does differently |
| 05 | [Risks and limitations](05-risks-and-limitations.md) | The risk register. **Read this before getting excited.** |
| 06 | [Roadmap](06-roadmap.md) | Phased plan with success criteria and a measurement methodology |
| 07 | [References](07-references.md) | Every source used, grouped by topic |

## Suggested reading order

**If you have five minutes:** [00 — Overview](00-overview.md), then the "The honest version"
section of it, then the top of [05 — Risks](05-risks-and-limitations.md).

**If you want to evaluate the idea:** 00 → 05 → 04. The feasibility verdict lives in 05 and the
competitive positioning in 04.

**If you want to build it:** 00 → 01 → 02 → 03, with 05 open in another tab. Then
[06 — Roadmap](06-roadmap.md) for where to start.

**If you are reviewing the sources:** [07 — References](07-references.md), then follow the links
back into whichever document made the claim.

## Conventions used in these documents

- **Confidence is stated.** Anything not backed by a primary source is marked as
  *estimated*, *unverified* or *anecdotal* in the text.
- **Sourced facts carry links.** Inline links point to the primary source, not to a blog post
  summarising it, wherever a primary source exists.
- **Measurement beats assertion.** Where this project has no numbers of its own, that is said
  explicitly. DisplayBoost's own benchmarks arrive with V1.
- **Technical identifiers stay in English** in both language trees — `IddCx`,
  `DXGI Desktop Duplication`, `swapchain`, `flip model`, `fill-rate`. Translating them makes the
  text harder to search and impossible to verify against vendor documentation.

## Contributing to the research

Corrections are the single most valuable contribution at this stage. See
[../CONTRIBUTING.md](../CONTRIBUTING.md) and the
[research correction issue template](https://github.com/raksix/DisplayBoost/issues/new?template=research_correction.yml).

If you edit an English document, update its Turkish counterpart in the same pull request — the
document pair list lives in [`../scripts/check-doc-parity.sh`](../scripts/check-doc-parity.sh)
and is enforced by CI.
