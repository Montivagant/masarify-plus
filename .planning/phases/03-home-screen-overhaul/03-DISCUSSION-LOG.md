# Phase 3: Home Screen Overhaul - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-27
**Phase:** 03-home-screen-overhaul
**Areas discussed:** Balance & card design, Transaction list behavior, Swipe actions & deletion, Voice confirm screen

---

## Balance & Card Design

### Visual style for balance area

| Option | Description | Selected |
|--------|-------------|----------|
| Compact summary header | Replace carousel with fixed top: total balance, horizontal account chips. Like Wise/Revolut. | ✓ |
| Modernized carousel | Keep PageView, redesign cards smaller/sleeker. "All Accounts" gets distinct shape. | |
| Hybrid approach | Total balance always visible at top, individual accounts in compact horizontal scroll below. | |

**User's choice:** Compact summary header
**Notes:** User selected the Wise/Revolut-inspired approach with account chips showing mini-balances.

### "All Accounts" vs individual account distinction

| Option | Description | Selected |
|--------|-------------|----------|
| Chip highlighting | "All" chip filled primary, account chips show bank color when selected. Balance updates. | ✓ |
| Section header change | Header transforms to show selected account's name and icon. | |
| You decide | Claude picks best approach. | |

**User's choice:** Chip highlighting

### Month summary zone

| Option | Description | Selected |
|--------|-------------|----------|
| Inline under balance | Show income/expense/net as compact single-row directly under balance number. | ✓ |
| Keep as separate zone | MonthSummaryZone stays as own section, but more compact. | |
| Remove from home | Move to Analytics tab only. | |

**User's choice:** Inline under balance

### Insight cards placement

User interrupted the options to raise a critical point: **transaction entry count can be very large, scrolling is needed, and the entire layout needs rethinking for all states and cases.**

This led to a comprehensive research phase and full home screen architecture redesign.

## Transaction List Behavior (merged with Home Layout)

### Home screen architecture (post-research)

| Option | Description | Selected |
|--------|-------------|----------|
| Collapsing header + sticky filters | CustomScrollView: SliverAppBar collapses, insight cards scroll away, filter chips pinned, SliverList lazy-loads transactions. Like Revolut/Wise. | ✓ |
| Fixed header + scrollable body | Balance always visible (never collapses). Transactions scroll in remaining space. Simpler. | |
| Bottom sheet transactions | Balance + insights fill top half. Transactions in draggable bottom sheet. Like Google Maps. | |

**User's choice:** Collapsing header + sticky filters
**Notes:** User confirmed the architecture after reviewing an interactive HTML mockup (`.firecrawl/home-mockup.html`) showing all 7 states: expanded, scrolled, search, filtered, empty, swipe actions, dark RTL.

### Design system emphasis

**User feedback (critical):** "Don't forget the guidelines — I want it to follow the glass morphism theme, and apply across the app, modern, clean, sleek and visually appealing."

This was captured as D-23, D-24, D-25 in CONTEXT.md.

## Swipe Actions & Deletion

| Option | Description | Selected |
|--------|-------------|----------|
| As shown in mockup | Swipe-left reveals Edit (blue) + Delete (red). Single confirm for regular, 2-step for transfers. | |
| Swipe both directions | Swipe-left = Delete, Swipe-right = Edit. | |
| You decide | Claude picks cleanest approach with glassmorphism styling. | ✓ |

**User's choice:** You decide
**Notes:** Claude has discretion on swipe design — must be glassmorphic and minimal-effort.

## Voice Confirm Screen

### Main layout approach

| Option | Description | Selected |
|--------|-------------|----------|
| Full-screen form card | Single large GlassCard, all fields visible/editable. Amount prominent, colored by type. Everything tappable. | ✓ |
| Comparison layout | Left = raw transcript, right = parsed fields. More transparent, more space. | |
| Bottom sheet style | Draggable bottom sheet over home screen. Lighter feel. | |

**User's choice:** Full-screen form card
**Notes:** User wants confidence-inspiring layout with all parsed data visible.

### Multi-draft review

| Option | Description | Selected |
|--------|-------------|----------|
| Swipeable cards | Each draft a full-screen card, swipe between. Page indicator dots. | |
| Stacked list | All drafts in scrollable list, tap to expand. | |
| You decide | Claude picks best approach. | |

**User's choice:** (Custom) "Whichever takes less steps and effort, we're promoting ease of access and agile UX"
**Notes:** User's guiding principle is minimal taps/effort. Claude has discretion to pick the approach that minimizes steps.

## Claude's Discretion

- Swipe action visual design (direction, colors, icons, animation)
- Multi-draft voice review implementation
- SliverAppBar collapse animation specifics
- Loading skeleton design
- Error state handling
- Search debounce timing and match algorithm

## Deferred Ideas

None — discussion stayed within phase scope.

## Research Conducted

- **Web research**: Searched and scraped 6+ articles on banking app UX (2026), mobile filter patterns, neobank UI breakdowns (Revolut, Wise, N26, Monzo)
- **Key sources**: wavespace.agency (top 15 banking apps UX), Pencil & Paper (mobile filter UX patterns), Purrweb (banking app design 2026)
- **HTML mockup**: Created interactive prototype at `.firecrawl/home-mockup.html` showing 7 home screen states
- **Key finding**: All top finance apps follow the pattern: balance header → contextual nudges → sticky filter bar → lazy transaction list. Revolut uses smart personalized dashboards. N26 auto-groups transactions. Quick filters are critical for mobile.
