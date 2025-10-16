
import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

import('dotenv').then(dotenv => dotenv.config({ path: path.resolve(__dirname, '.env') }));

import { getTrxBalance, getAllTrc20Balances } from './index.js';

async function getWalletBalance(address) {
  if (!address || !address.startsWith('T')) {
    throw new Error('Invalid TRON address.');
  }

  const trxBalance = await getTrxBalance(address);
  const trc20Balances = await getAllTrc20Balances(address);

  return {
    address: address,
    trxBalance: trxBalance,
    trc20Tokens: trc20Balances,
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const walletAddress = process.argv[2];
  if (!walletAddress) {
    console.error('Error: No wallet address provided.');
    console.log('Usage: node balance-service.js <TRON_WALLET_ADDRESS>');
    process.exit(1);
  }

  getWalletBalance(walletAddress)
    .then(balances => {
      console.log(JSON.stringify(balances, null, 2));
    })
    .catch(error => {
      console.error('Error:', error);
    });
}

export { getWalletBalance };
