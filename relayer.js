import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

const CHAIN1_RPC = "http://localhost:8545";
const CHAIN2_RPC = "http://localhost:8545";

const CHAIN1_BRIDGE = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const CHAIN2_BRIDGE = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
const PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const BRIDGE_ABI = [
    "event Deposit(bytes32 indexed depositId, address indexed from, uint256 amount, uint256 indexed toChainId, address to)",
    "function redeem(bytes32 depositId, address to, uint256 amount, uint256 fromChainId) external",
    "function processed(bytes32) external view returns (bool)"
];

async function main() {
    const provider1 = new ethers.JsonRpcProvider(CHAIN1_RPC);
    const provider2 = new ethers.JsonRpcProvider(CHAIN2_RPC);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider2);

    const bridge1 = new ethers.Contract(CHAIN1_BRIDGE, BRIDGE_ABI, provider1);
    const bridge2 = new ethers.Contract(CHAIN2_BRIDGE, BRIDGE_ABI, wallet);

    console.log("Relayer started...");
    console.log("Chain 1 Bridge: ", CHAIN1_BRIDGE);
    console.log("Chain 2 Bridge: ", CHAIN2_BRIDGE);

    bridge1.on("Deposit", async (depositId, from, amount, toChainId, to, event) => {
        console.log("Deposit ID: ", depositId);
        console.log("From: ", from);
        console.log("Amount: ", ethers.formatEther(amount));
        console.log("To Chain ID: ", toChainId.toString());
        console.log("To Address: ", to);
        console.log("Tx Hash: ", event.transactionHash);

        try {
            const isProcessed = await bridge2.processed(depositId);
            if (isProcessed) {
                console.log("Deposit already processed");
                return;
            }

            console.log("Processing redeem on Chain 2");

            const tx = await bridge2.redeem(depositId, to, amount, 1);
            console.log("Redeem transaction sent: ", tx.hash);

            const receipt = await tx.wait();
            console.log("Redeem confirmed in block: ", receipt.blockNumber);
            console.log("Tokens minted to: ", to);
        } catch (err) {
            console.error("Redeem error: ", err.message);
        }
    });

    process.on('SIGINT', () => {
        console.log("\nRelayer stopped");
        process.exit();
    });
}

main().catch(console.error);