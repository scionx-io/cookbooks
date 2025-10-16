#!/usr/bin/env node
import 'dotenv/config';
import TronWeb from 'tronweb';

const config = {
  apiKey: process.env.TRONGRID_API_KEY,
  tronscanApiKey: process.env.TRONSCAN_API_KEY,
  walletAddress: process.env.TRON_WALLET_ADDRESS || process.argv[2] || '',
};

const tronWeb = new TronWeb({
  fullHost: 'https://api.trongrid.io',
  solidityNode: 'https://api.trongrid.io',
  eventServer: 'https://api.trongrid.io',
  headers: config.apiKey ? { 'TRON-PRO-API-KEY': config.apiKey } : undefined,
});

const formatBalance = (rawBalance, decimals) => {
  const balance = BigInt(rawBalance);
  const divisor = BigInt(10 ** decimals);
  const whole = balance / divisor;
  const fraction = balance % divisor;
  return `${whole}.${fraction.toString().padStart(decimals, '0')}`;
};

async function getTrxBalance(address) {
  console.log(`getTrxBalance address: ${address}`)
  const balance = await tronWeb.trx.getBalance(address);
  return formatBalance(balance, 6);
}

async function getAllTrc20Balances(address) {
  const url = `https://apilist.tronscanapi.com/api/account/wallet?address=${address}&asset_type=1`;
  const headers = { accept: 'application/json' };
  if (config.tronscanApiKey) headers['TRON-PRO-API-KEY'] = config.tronscanApiKey;

  const response = await fetch(url, { headers });
  if (!response.ok) throw new Error(`API Error: ${response.status}`);
  const data = await response.json();

  // Filter TRC20 tokens (token_type 20) with balance > 0
  return (data.data || [])
    .filter(token => token.token_type === 20 && parseFloat(token.balance) > 0)
    .map(token => ({
      symbol: token.token_abbr || token.token_name,
      name: token.token_name,
      balance: parseFloat(token.balance), // use API value directly
      decimals: token.token_decimal,
      address: token.token_id,
    }));
}


async function getAccountResources(address) {
  const resources = await tronWeb.trx.getAccountResources(address);
  return {
    bandwidth: (resources.freeNetLimit || 0) - (resources.freeNetUsed || 0),
    bandwidthLimit: resources.freeNetLimit || 0,
    energy: (resources.EnergyLimit || 0) - (resources.EnergyUsed || 0),
    energyLimit: resources.EnergyLimit || 0,
  };
}

async function getTokenPrice(token = 'trx') {
  const url = `https://apilist.tronscanapi.com/api/token/price?token=${token}`;
  const headers = { accept: 'application/json' };
  if (config.tronscanApiKey) headers['TRON-PRO-API-KEY'] = config.tronscanApiKey;

  try {
    const response = await fetch(url, { headers });
    if (!response.ok) throw new Error(`API Error: ${response.status}`);
    const data = await response.json();
    return data;
  } catch (error) {
    console.warn(`Warning: Could not fetch price for ${token}: ${error.message}`);
    return null;
  }
}

async function getAllTokenPrices() {
  const url = `https://apilist.tronscanapi.com/api/getAssetWithPriceList`;
  const headers = { accept: 'application/json' };
  if (config.tronscanApiKey) headers['TRON-PRO-API-KEY'] = config.tronscanApiKey;

  try {
    const response = await fetch(url, { headers });
    if (!response.ok) throw new Error(`API Error: ${response.status}`);
    const data = await response.json();
    return data;
  } catch (error) {
    console.warn(`Warning: Could not fetch token price list: ${error.message}`);
    return null;
  }
}

async function checkBalances(address) {
  if (!address || !address.startsWith('T')) throw new Error('Invalid TRON address.');

  tronWeb.setAddress(address);

  console.log('═'.repeat(60));
  console.log('TRON WALLET BALANCE CHECKER');
  console.log('═'.repeat(60));
  console.log(`Wallet: ${address}\n`);

  console.log('TRX Balance:');
  console.log(`  ${await getTrxBalance(address)} TRX\n`);

  console.log('TRC20 Token Balances:');
  const tokens = await getAllTrc20Balances(address);
  if (!tokens.length) console.log('  (No token balances found)');
  else tokens.forEach(t => console.log(`  ${t.symbol.padEnd(10)} ${t.balance.toFixed(t.decimals)}`));

  console.log('\nAccount Resources:');
  const res = await getAccountResources(address);
  console.log(`  Bandwidth: ${res.bandwidth.toLocaleString()} / ${res.bandwidthLimit.toLocaleString()}`);
  console.log(`  Energy:    ${res.energy.toLocaleString()} / ${res.energyLimit.toLocaleString()}`);
  console.log('═'.repeat(60));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  if (!config.walletAddress) {
    console.error('Error: No wallet address provided');
    process.exit(1);
  }
  checkBalances(config.walletAddress);
}

export { getTrxBalance, getAllTrc20Balances, getAccountResources, checkBalances, getTokenPrice, getAllTokenPrices, tronWeb };
