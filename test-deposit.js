import { ethers } from "ethers";

const CHAIN1_BRIDGE = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const RPC_URL = "http://localhost:8545";

const BRIDGE_ABI = [
    "function deposit(bytes32 depositId, uint256 amount, uint256 toChainId, address to) external",
    "function token() external view returns (address)"
];
const TOKEN_ABI = [
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function balanceOf(address) external view returns (uint256)"
];

async function testDeposit() {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

    const bridge = new ethers.Contract(CHAIN1_BRIDGE, BRIDGE_ABI, wallet);
    const tokenAddress = await bridge.token();
    const token = new ethers.Contract(tokenAddress, TOKEN_ABI, wallet);

    const depositId = ethers.keccak256(ethers.toUtf8Bytes("test-" + Date.now()));
    const amount = ethers.parseEther("100");
    const toChainId = 2;
    const toAddress = wallet.address;

    console.log("Starting test deposit");
    console.log("Account:", wallet.address);
    console.log("Receiving on chain 2: ", toAddress);
    console.log("Amount: ", ethers.formatEther(amount));

    const balance = await token.balanceOf(wallet.address);
    console.log("Current balance: ", ethers.formatEther(balance));

    if (balance < amount) {
        console.log("Not enough balance.");
        return;
    }

    const approveTx = await token.approve(CHAIN1_BRIDGE, amount);
    await approveTx.wait();
    console.log("Approved");

    const depositTx = await bridge.deposit(depositId, amount, toChainId, toAddress);
    const receipt = await depositTx.wait();

    console.log("Deposit completed");
    console.log("Deposit ID: ", depositId);
    console.log("Tx Hash: ", depositTx.hash);
    console.log("Block: ", receipt.blockNumber);

    const finalBalance = await token.balanceOf(wallet.address);
    console.log("Balance on Chain 1: ", ethers.formatEther(finalBalance));
}

testDeposit().catch(console.error);