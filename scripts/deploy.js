const { ethers, Wallet, ContractFactory } = require('ethers');
const fs = require('fs');
require('dotenv').config();

const tokenArtifact = './artifacts/contracts/Token.sol/Token.json';
// const guildBankArtifiact = './artifacts/contracts/GuildBank.sol/GuildBank.json';
const molochArtifact = './artifacts/contracts/Moloch.sol/Moloch.json';
// const poolArtifact = './artifacts/contracts/Pool.sol/MolochPool.json';

// let token, guildBank, moloch, pool;
let token, moloch;

let provider, wallet, connectedWallet;

if (process.env.NETWORK == 'testnet') {
  provider = ethers.getDefaultProvider(
    'https://data-seed-prebsc-1-s1.binance.org:8545/'
  );
  token = '0x38d28227815af0281de9184919C09193898296b5';
  moloch = '0xD485ce0E2c7132211Ac66EEad4309f0a7eA8a436';
  // guildBank = '0x7DAe8e949896Eb20BB53ee5181aB6382fBdbceBE';
  // pool = '0xFFFeFCdA48AC6fABb9d0791e529DAbd7B7408805';
}

wallet = Wallet.fromMnemonic(process.env.MNEMONIC);
connectedWallet = wallet.connect(provider);

const unpackArtifact = artifactPath => {
  let contractData = JSON.parse(fs.readFileSync(artifactPath));

  const contractBytecode = contractData['bytecode'];
  const contractABI = contractData['abi'];
  const constructorArgs = contractABI.filter(itm => {
    return itm.type == 'constructor';
  });

  let constructorStr;
  if (constructorArgs.length < 1) {
    constructorStr = ' -- No constructor arguments -- ';
  } else {
    constructorJSON = constructorArgs[0].inputs;
    constructorStr = JSON.stringify(
      constructorJSON.map(c => {
        return {
          name: c.name,
          type: c.type,
        };
      })
    );
  }

  return {
    abi: contractABI,
    bytecode: contractBytecode,
    contractName: contractData.contractName,
    constructor: constructorStr,
  };
};

const deployContract = async (
  contractABI,
  contractBytecode,
  wallet,
  provider,
  args = []
) => {
  const factory = new ContractFactory(
    contractABI,
    contractBytecode,
    wallet.connect(provider)
  );
  return await factory.deploy(...args);
};

const deploy = async (artifactPath, args) => {
  try {
    let tokenUnpacked = unpackArtifact(artifactPath);
    console.log(
      `${tokenUnpacked.contractName} \n Constructor: ${tokenUnpacked.constructor}`
    );
    const token = await deployContract(
      tokenUnpacked.abi,
      tokenUnpacked.bytecode,
      wallet,
      provider,
      args
    );
    console.log(`⌛ Deploying ${tokenUnpacked.contractName}...`);

    await connectedWallet.provider.waitForTransaction(
      token.deployTransaction.hash
    );
    console.log(
      `✅ Deployed ${tokenUnpacked.contractName} to ${token.address}`
    );
    return token.address;
  } catch (err) {
    console.log('deploy ======>', err);
  }
};

const deployAll = async () => {
  if (!token) {
    try {
      token = await deploy(tokenArtifact, ['100000000000000000000000000']);
    } catch (e) {
      return;
    }
  }

  // if (!guildBank) {
  //   try {
  //     guildBank = await deploy(guildBankArtifiact, [token]);
  //   } catch (e) {
  //     return;
  //   }
  // }

  if (!moloch) {
    const periodDuration = 300; // default = 600 = 10 minutes in seconds (5 periods per day)
    const votingPeriodLength = 1; // default = 1 period (10 minutes)
    const gracePeriodLength = 1; // default = 1 period (10 minutes)
    const abortWindow = 1; // default = 1 period (10 minutes)
    const dilutionBound = 3; // default = 3 - maximum multiplier a YES voter will be obligated to pay in case of mass ragequit

    try {
      moloch = await deploy(molochArtifact, [
        wallet.address,
        token,
        periodDuration,
        votingPeriodLength,
        gracePeriodLength,
        abortWindow,
        dilutionBound,
      ]);
    } catch (e) {
      return;
    }
  }

  // if (!pool) {
  //   try {
  //     pool = await deploy(poolArtifact, [moloch]);
  //   } catch (e) {
  //     return;
  //   }
  // }
};

deployAll();
