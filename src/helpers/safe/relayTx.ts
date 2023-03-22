/**
 * TODO: what this script does
 */

import { GelatoRelayAdapter } from "@safe-global/relay-kit";
import EthersAdapter from "@safe-global/safe-ethers-lib";
import SafeServiceClient from "@safe-global/safe-service-client";
import { ethers } from "ethers";

const config = {
  CHAIN_ID: 5, // mainnet: 1, goerli: 5
  RPC_URL: "https://goerli.infura.io/v3/0697ca1ac6d04ea7a86a146e53452fb9",
  BOT_PRIVATE_KEY: "0xa3bfde12b832ab44f303ecb8acfb5042190f357ec7712a8597c29ba1e1a31708",
  SAFE_ADDRESS: "0x839F2406464B98128c67c00dB9408F07bB9D4629",
  TX_SERVICE_URL: "https://safe-transaction-goerli.safe.global/", // Check https://docs.safe.global/backend/available-services
  DAI_ADDRESS: "0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844", // mainnet: 0x6B175474E89094C44Da98b954EedeAC495271d0F, goerli: 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844
};

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(config.RPC_URL);
  const signer = new ethers.Wallet(config.BOT_PRIVATE_KEY, provider);

  // create EthAdapter instance
  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: signer,
  });

  // Create Safe Service Client instance
  const service = new SafeServiceClient({
    txServiceUrl: config.TX_SERVICE_URL,
    ethAdapter,
  });

  // get pending txs
  const pendingTxs = await service.getPendingTransactions(config.SAFE_ADDRESS);
  if (pendingTxs.results.length > 0) {
    // get latest pending tx
    const latestPendingTx = pendingTxs.results[pendingTxs.results.length - 1];
    // if latest pending tx is signed by all parties
    if (latestPendingTx.confirmations?.length === latestPendingTx.confirmationsRequired) {
      // relay tx
      const relayAdapter = new GelatoRelayAdapter();
      const response = await relayAdapter.relayTransaction({
        target: config.SAFE_ADDRESS,
        encodedTransaction: String(latestPendingTx.data),
        chainId: config.CHAIN_ID,
        options: {
          gasLimit: ethers.BigNumber.from(120_000),
          gasToken: config.DAI_ADDRESS,
        },
      });
      console.log(`Check execution status here: https://relay.gelato.digital/tasks/status/${response.taskId}`);
    } else {
      console.log("Not enough signatures for latest pending transaction");
    }
  } else {
    console.log("There are no pending transactions");
  }
}

main();
