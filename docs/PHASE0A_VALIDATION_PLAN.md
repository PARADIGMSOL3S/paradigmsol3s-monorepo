# Plan: Validate and Deploy Phase 0-A Deliverables

## TL;DR
If you cannot install npm packages in the current environment, validate Phase 0-A from a machine with Node.js + npm access: compile, generate Merkle roots, deploy to testnet, run mint checks, then verify frontend integration before any mainnet action.

## Execution Steps

1. Open this workspace locally.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Compile contracts:
   ```bash
   npx hardhat compile
   ```
4. Prepare allowlists in `data/founding.json` and `data/club.json`.
5. Generate deterministic roots + proofs:
   ```bash
   node scripts/generateMerkle.js --founding data/founding.json --club data/club.json --version v1
   ```
6. Configure env vars (`.env`):
   - `ADMIN_ADDRESS`
   - `OPERATOR`
   - `TREASURY`
   - `ROYALTY_RECEIVER`
   - `BASE_URI`
   - `FOUNDING_ROOT` (optional, can be applied post-deploy)
   - `CLUB_ROOT` (optional, can be applied post-deploy)
7. Deploy to testnet first:
   ```bash
   npx hardhat run scripts/deploy.js --network fuji
   ```
8. Verify on explorer using printed command from `deploy.js`.
9. Test minting paths:
   - valid proof mints
   - invalid proof reverts
   - one-per-address enforced
   - phase gate enforced
10. Open frontend and validate integration:
    - open `houseofsoles-expo.html`
    - set contract address in settings
    - verify chain counter refresh, RSVP, export, and admin actions
11. Only after testnet sign-off, deploy to mainnet:
   ```bash
   npx hardhat run scripts/deploy.js --network avalanche
   ```

## Verification Checklist

- Contract compiles with Solidity `0.8.24`.
- Merkle outputs are deterministic for same input.
- Deployment writes release manifest and prints verify command.
- Frontend can read `saleStatus()` and render live values.
- Admin exports produce valid JSON/CSV/EVM-only files.

## Bridge and cross-chain schedule gate (required before mainnet)

- Lock bridge route explicitly (XRPL mainnet vs XRPL-EVM) for the exact Wormhole product path used in expo UX.
- Benchmark end-to-end delivery time with your ship-mode finality policy:
  - collect p50/p95/p99
  - capture failures (timeouts, delayed delivery, destination reverts, duplicate delivery attempts)
- Promote only when bridge benchmark SLOs pass under burst load.

## Identity and signing gate

- For each buyer, require dual proof-of-control before allowlist/provenance enrollment:
  - EVM challenge signature
  - XRPL/Xaman sign-request challenge
- Keep Xaman payload creation server-side and audit all payload issuance.
