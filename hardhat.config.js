require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-truffle5');
require('@nomiclabs/hardhat-waffle');
require('./scripts/moloch-tasks');
require('./scripts/pool-tasks');

module.exports = {
  networks: {
    develop: {
      url: 'http://localhost:8545',
      deployedContracts: {
        moloch: '',
        pool: '',
      },
    },
    testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      gasPrice: 20000000000,
      accounts: { mnemonic: `${process.env.MNEMONIC}` },
    },
    mainnet: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      gasPrice: 20000000000,
      accounts: { mnemonic: `${process.env.MNEMONIC}` },
    },
  },
  solidity: {
    version: '0.6.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
};
