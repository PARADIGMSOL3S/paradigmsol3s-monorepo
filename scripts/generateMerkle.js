const fs = require("node:fs");
const path = require("node:path");
const { getAddress, keccak256, solidityPacked } = require("ethers");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

function argValue(flag, fallback = "") {
  const index = process.argv.indexOf(flag);
  if (index === -1 || !process.argv[index + 1]) return fallback;
  return process.argv[index + 1];
}

function usage() {
  console.log("Usage:");
  console.log("  node scripts/generateMerkle.js --phase founding --input data/founding.json --version v1");
  console.log("  node scripts/generateMerkle.js --founding data/founding.json --club data/club.json --version v1");
}

function normalizeAddresses(rawAddresses) {
  const checksummed = rawAddresses.map((x) => getAddress(x.trim()));
  const deduped = [...new Set(checksummed)];
  deduped.sort((a, b) => a.localeCompare(b));
  return deduped;
}

function leafForAddress(address) {
  return keccak256(solidityPacked(["address"], [address]));
}

function generateForPhase(phase, input, phaseVersion) {
  const raw = JSON.parse(fs.readFileSync(path.resolve(input), "utf8"));
  const addresses = Array.isArray(raw) ? raw : raw.addresses;

  if (!Array.isArray(addresses) || addresses.length === 0) {
    throw new Error("Input must be an array of addresses or an object with addresses[]");
  }

  const normalized = normalizeAddresses(addresses);
  const rows = normalized.map((addr) => [addr]);
  const tree = StandardMerkleTree.of(rows, ["address"]);

  const proofsAll = {};
  for (const [index, entry] of tree.entries()) {
    const account = entry[0];
    proofsAll[account] = {
      leaf: leafForAddress(account),
      proof: tree.getProof(index),
    };
  }

  const outDir = path.resolve("merkle");
  fs.mkdirSync(outDir, { recursive: true });

  fs.writeFileSync(path.join(outDir, `${phase}Root.txt`), `${tree.root}\n`);
  fs.writeFileSync(path.join(outDir, `${phase}ProofsAll.json`), JSON.stringify(proofsAll, null, 2));
  fs.writeFileSync(
    path.join(outDir, `${phase}Manifest.json`),
    JSON.stringify(
      {
        phase,
        phaseVersion,
        root: tree.root,
        addressCount: normalized.length,
        generatedAt: new Date().toISOString(),
      },
      null,
      2
    )
  );

  console.log(`Generated deterministic Merkle package for phase '${phase}' with root ${tree.root}`);
}

function main() {
  const phase = argValue("--phase");
  const input = argValue("--input");
  const founding = argValue("--founding");
  const club = argValue("--club");
  const phaseVersion = argValue("--version", "v1");

  if (phase && input) {
    generateForPhase(phase, input, phaseVersion);
    return;
  }

  if (founding || club) {
    if (founding) generateForPhase("founding", founding, phaseVersion);
    if (club) generateForPhase("club", club, phaseVersion);
    return;
  }

  usage();
  throw new Error("Missing required args. Use --phase/--input or --founding/--club.");
}

main();
