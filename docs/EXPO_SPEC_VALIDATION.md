# Validation of House of Soles Expo Page and Avalanche Contract Spec

## Scope
This validation covers the four dependency pillars used in the current Phase 0-A plan:
1. Ripple/XRPL + Wormhole bridge assumptions.
2. XRPL NFT metadata and mutability semantics.
3. Xaman signing model and operational security.
4. Avalanche scarcity enforcement and deploy toolchain constraints.

## Validated corrections incorporated

### 1) Bridge claims split into "announced" vs "product-supported"
- Treat June 26, 2025 Ripple/Wormhole announcement scope and current product support as separate statements.
- For production expo UX, lock the initial bridge surface to the exact supported product path (XRPL-EVM-first when Connect support is required).

### 2) Latency framing changed from fixed value to policy-dependent distribution
- Bridge latency must be measured route-by-route and finality-mode-by-finality-mode.
- Schedule gate should be accepted using p50/p95/p99 and failure-mode tracking, not a single "typical" time claim.

### 3) Scarcity wording tied to actual contract mint guards
- "Sold out" should only be driven by contract-enforced mint/claim boundaries and state-derived counters.
- Supply limits are enforced in mint/claim code paths; transfer hooks are extension points, not assumed cap guards.

### 4) Avalanche toolchain compatibility hardened
- Hardhat now pins `evmVersion: "cancun"` to align with Avalanche C-Chain/Subnet-EVM compatibility guidance.

### 5) XRPL metadata model clarified
- The 11-field Aether metadata is treated as off-ledger JSON.
- On-ledger XRPL NFT metadata remains a URI pointer model; mutability must be an explicit product choice.

### 6) Xaman integration boundary clarified
- xApp-native and web payload handoff models are treated as separate implementation modes.
- Signing payload issuance is a server-side responsibility with audit/security controls.

### 7) Dual-proof identity binding added as acceptance criterion
- Require both EVM and XRPL proof-of-control before allowlist insertion + provenance enrollment.

## Acceptance test gates

1. Bridge benchmark gate passes under chosen finality policy (p50/p95/p99 + error modes).
2. Scarcity gate passes: contract reverts at boundary and UI reflects chain state.
3. Metadata gate passes: URI constraints and provenance JSON anchoring are verifiable.
4. XRPL mutability policy is explicit (immutable default or governed mutable mode).
5. Xaman payload flow works end-to-end with no API secrets in client runtime.
6. Identity binding gate passes with dual-signature challenge proof.
