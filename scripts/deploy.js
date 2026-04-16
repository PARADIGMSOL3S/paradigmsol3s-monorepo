const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const hre = require("hardhat");

function assertEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

async function main() {
  const BASE_URI = assertEnv("BASE_URI");
  const ROYALTY_RECEIVER = assertEnv("ROYALTY_RECEIVER");
  const TREASURY = assertEnv("TREASURY");
  const OPERATOR = assertEnv("OPERATOR");
  const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS || "";
  const FOUNDING_ROOT = process.env.FOUNDING_ROOT || "";
  const CLUB_ROOT = process.env.CLUB_ROOT || "";

  if (BASE_URI.includes("PLACEHOLDER")) {
    throw new Error("BASE_URI still contains PLACEHOLDER. Set a production URI before deploying.");
  }

  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  if (chainId === 43114) {
    console.log("Mainnet deployment detected. Abort within 10 seconds if this is not intentional (Ctrl+C).");
    await new Promise((resolve) => setTimeout(resolve, 10_000));
  }

  const factory = await hre.ethers.getContractFactory("AetherCertificate");
  const admin = ADMIN_ADDRESS || deployer.address;
  const contract = await factory.deploy(admin, OPERATOR, TREASURY, ROYALTY_RECEIVER, BASE_URI);
  await contract.waitForDeployment();

  if (FOUNDING_ROOT) {
    const tx = await contract.setMerkleRoot(1, FOUNDING_ROOT);
    await tx.wait();
  }
  if (CLUB_ROOT) {
    const tx = await contract.setMerkleRoot(2, CLUB_ROOT);
    await tx.wait();
  }

  const address = await contract.getAddress();
  const block = await hre.ethers.provider.getBlock("latest");

  const artifactPath = path.resolve("artifacts/contracts/AetherCertificate.sol/AetherCertificate.json");
  const artifactRaw = fs.existsSync(artifactPath) ? fs.readFileSync(artifactPath) : Buffer.from("{}");
  const artifactSha256 = crypto.createHash("sha256").update(artifactRaw).digest("hex");

  const manifest = {
    deployedAt: new Date().toISOString(),
    network: hre.network.name,
    chainId,
    blockNumber: block ? block.number : null,
    deployer: deployer.address,
    admin,
    contractAddress: address,
    treasury: TREASURY,
    royaltyReceiver: ROYALTY_RECEIVER,
    baseUri: BASE_URI,
    artifactSha256,
    wormholeConfigured: Boolean(process.env.WORMHOLE_RELAYER && process.env.WORMHOLE_CHAIN_ID),
    rootsConfigured: {
      founding: Boolean(FOUNDING_ROOT),
      club: Boolean(CLUB_ROOT),
    },
  };

  fs.mkdirSync(path.resolve("release"), { recursive: true });
  const manifestFile = path.resolve("release", `aether-release-${chainId}.json`);
  fs.writeFileSync(manifestFile, JSON.stringify(manifest, null, 2));

  console.log("Deployment complete:", manifest);
  console.log(`Manifest written to: ${manifestFile}`);
  console.log(
    `Snowtrace verify: npx hardhat verify --network ${hre.network.name} ${address} ${admin} ${OPERATOR} ${TREASURY} ${ROYALTY_RECEIVER} ${JSON.stringify(BASE_URI)}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
