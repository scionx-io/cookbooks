#!/usr/bin/env node
import 'dotenv/config';

const config = {
  tronscanApiKey: process.env.TRONSCAN_API_KEY,
};

/**
 * Get price information for a specific token
 * @param {string} token - Token abbreviation (default: 'trx')
 * @returns {Object|null} Token price information or null if error
 */
async function getTokenPrice(token = 'trx') {
  const url = `https://apilist.tronscanapi.com/api/token/price?token=${token}`;
  const headers = { accept: 'application/json' };
  if (config.tronscanApiKey) headers['TRON-PRO-API-KEY'] = config.tronscanApiKey;

  try {
    const response = await fetch(url, { headers });
    if (!response.ok) throw new Error(`API Error: ${response.status}`);
    const data = await response.json();
    
    // The API response structure might be different than expected
    // If the response contains price_usd or priceInUsd directly, return it
    // Otherwise, return the full response
    if (data.priceInUsd !== undefined) {
      return data;
    } else if (data.price_usd !== undefined) {
      return data;
    } else if (typeof data === 'object' && data !== null) {
      // Return the full response object for further processing
      return data;
    }
    return data;
  } catch (error) {
    console.warn(`Warning: Could not fetch price for ${token}: ${error.message}`);
    return null;
  }
}

/**
 * Get list of all tokens that have price information
 * @returns {Object|null} List of priced tokens or null if error
 */
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

/**
 * Get price in USD for a specific token
 * @param {string} token - Token symbol (e.g., 'trx', 'usdt', 'usdc')
 * @returns {number|null} Price in USD or null if not available
 */
async function getTokenPriceUSD(token) {
  const priceData = await getTokenPrice(token);
  if (priceData && priceData.price_in_usd !== undefined) {
    return parseFloat(priceData.price_in_usd);
  }
  return null;
}

/**
 * Calculate the dollar value of a token balance
 * @param {string|number} balance - Token balance amount
 * @param {string} token - Token symbol (e.g., 'trx', 'usdt', 'usdc')
 * @returns {number|null} Dollar value or null if price not available
 */
async function getTokenValueUSD(balance, token) {
  const price = await getTokenPriceUSD(token);
  if (price !== null) {
    const balanceNum = parseFloat(balance);
    return balanceNum * price;
  }
  return null;
}

/**
 * Get prices for multiple tokens
 * @param {string[]} tokens - Array of token symbols
 * @returns {Object} Object with token symbols as keys and prices as values
 */
async function getMultipleTokenPrices(tokens) {
  const prices = {};
  for (const token of tokens) {
    // Add a small delay between requests to avoid rate limiting
    if (tokens.indexOf(token) > 0) {
      await new Promise(resolve => setTimeout(resolve, 100)); // 100ms delay
    }
    prices[token] = await getTokenPriceUSD(token);
  }
  return prices;
}

/**
 * Format price with currency symbol
 * @param {number|null} price - Price value
 * @param {string} currency - Currency symbol (default: 'USD')
 * @returns {string} Formatted price
 */
function formatPrice(price, currency = 'USD') {
  if (price === null) return `(price unavailable)`;
  if (price < 0.0001) {
    return `${price.toFixed(8)} ${currency}`;
  } else if (price < 1) {
    return `${price.toFixed(6)} ${currency}`;
  } else {
    return `${price.toFixed(4)} ${currency}`;
  }
}

// CLI usage
if (import.meta.url === `file://${process.argv[1]}`) {
  const token = process.argv[2] || 'trx';
  
  console.log(`Getting price for ${token.toUpperCase()}...`);
  getTokenPrice(token)
    .then(priceData => {
      if (priceData) {
        console.log(`${token.toUpperCase()} Price Information:`);
        console.log(`Price in USD: ${priceData.price_in_usd ? parseFloat(priceData.price_in_usd).toFixed(4) : 'N/A'}`);
        console.log(`Price in BTC: ${priceData.price_btc ? parseFloat(priceData.price_btc).toFixed(8) : 'N/A'}`);
      } else {
        console.log(`Could not retrieve price for ${token}`);
      }
    })
    .catch(error => {
      console.error('Error:', error.message);
    });
}

export { 
  getTokenPrice, 
  getAllTokenPrices, 
  getTokenPriceUSD, 
  getTokenValueUSD,
  getMultipleTokenPrices,
  formatPrice
};