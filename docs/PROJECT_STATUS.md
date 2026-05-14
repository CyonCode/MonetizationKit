# PROJECT_STATUS.md

## Project: MonetizationKit
## Type: Internal SDK (not an app)

---

## Current Phase: Phase 3 — Development

### Scope Lock (Phase 0 equivalent)
- **SDK type:** Native StoreKit 2 subscription management
- **Platform:** iOS 17+
- **Swift:** 5.9
- **Dependencies:** Zero (matches AttributionKit)
- **Join mechanism:** IDFV via appAccountToken → server-side join to AttributionKit.idfv
- **Server endpoint:** `POST /v1/webhook/appstore/<appId>` for ASSN V2

### Exit criteria
- [x] `swift build` exits 0
- [x] `swift test` — all tests pass
- [x] All `.swift` files have zero LSP errors (warnings only for Swift 6 strictness)
- [x] README complete with install, quick start, event reference
- [x] AGENTS.md documents module boundaries and design decisions
- [ ] Integrated by at least one consumer app

### Test status
- **Total tests:** 53
- **Pass:** 53
- **Fail:** 0

### File count
- **Source files:** 12
- **Test files:** 8
- **Doc files:** 5 (README, AGENTS, PROJECT_STATUS, .gitignore, PaywallIntegration example)

---

## Next steps
1. Integrate into a consumer app (Phase 3 of the app's own flow)
2. Validate sandbox purchase flow end-to-end
3. Verify ASSN V2 webhook server endpoint
4. Tag 1.0.0 release after consumer validation
