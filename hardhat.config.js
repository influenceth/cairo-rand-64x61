require('@shardlabs/starknet-hardhat-plugin');

module.exports = {
  mocha: {
    bail: true,
    timeout: 600_000
  },
  networks: {
    dockerStark: {
      url: 'http://localhost:9000'
    },
    dockerEth: {
      url: 'http://ethereum:8545'
    },
    integratedDevnet: {
      url: "http://127.0.0.1:5050",
      dockerizedVersion: "0.3.1"
    }
  },
  paths: {
    cairoPaths: [
      './node_modules',
      './node_modules/influenceth__cairo_math_64x61/contracts'
    ]
  },
  starknet: {
    network: 'dockerStark',
    venv: 'active',
    wallets: {
      MyWallet: {
        accountName: 'OpenZeppelin',
        modulePath: 'starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount',
        accountPath: '~/.starknet_accounts'
      }
    }
  }
};