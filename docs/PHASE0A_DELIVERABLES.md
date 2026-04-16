# Complete Phase 0-A Deliverable Package

## File-by-file implementation

### 1) `contracts/AetherCertificate.sol`
Production certificate contract with the requested upgrades:
- `Phase` enum replaces boolean flags to avoid overlap.
- Mint counter uses `_totalMinted()` semantics (burn-safe for unit tracking).
- `processedDeliveries` mapping blocks Wormhole delivery replay.
- Hard cap at 300 enforced in mint path and transfer lifecycle hooks.
- `saleStatus()` returns frontend-ready phase + supply + roots + treasury/royalty routing.
- `treasury` and `royaltyReceiver` are explicitly separate addresses.

### 2) `scripts/deploy.js`
Deployment script with safety and release reporting:
- 10-second abort window on Avalanche mainnet.
- Throws if `ROYALTY_RECEIVER` is missing.
- Throws if `BASE_URI` still contains `PLACEHOLDER`.
- Writes release manifest JSON with `chainId`, `blockNumber`, `artifactSha256`, `wormholeConfigured`.
- Prints the Snowtrace verification command.

### 3) `scripts/generateMerkle.js`
Deterministic Merkle tooling:
- Normalizes addresses to checksum form.
- Deduplicates and lexicographically sorts before hashing.
- Outputs `<phase>Root.txt`, `<phase>ProofsAll.json`, `<phase>Manifest.json`.
- Includes `phaseVersion` in the manifest for stale-proof guardrails.

### 4) `token_template.json`
ERC-721 metadata template:
- Includes 11 Aether fields in the standard `attributes` array.
- `_aether_extended` block is marked `INTERNAL` and excluded from public tokenURI output.
- XRPL provenance text is set to: "off-ledger JSON referenced by NFT URI".

### 5) `houseofsoles-expo.html`
Complete frontend dashboard shell:
- Hero area with chain counter using ethers v6 `JsonRpcProvider` and 30-second refresh.
- Phase pills, countdown timer, and drop lineup status table.
- RSVP form with EVM validation and localStorage persistence.
- Certificate lookup panel.
- Toggle-activated live dashboard KPIs.
- Xaman QR placeholder and schedule timeline.
- Admin panel for RSVP approve/reject/export (JSON, CSV, EVM-only Merkle input).
- Settings panel for contract address, expo date, and Whatnot URL.

## Execution sequence

```bash
npm install
npx hardhat compile
node scripts/generateMerkle.js --founding data/founding.json --club data/club.json --version v1
npx hardhat run scripts/deploy.js --network fuji
# validate mint flow and frontend integration, then:
npx hardhat run scripts/deploy.js --network avalanche
```

See `docs/PHASE0A_VALIDATION_PLAN.md` for the full testnet-first validation checklist.
See `docs/EXPO_SPEC_VALIDATION.md` for bridge/XRPL/Xaman/scarcity claim validation notes.
