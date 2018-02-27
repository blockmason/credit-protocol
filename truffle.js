module.exports = {
  networks: {
    testrpc: {
      host: "localhost",
      port: 8546,
      network_id: "*" // Match any network id
    },
    geth: {
      host: "localhost",
      port: 8548,
      network_id: "*" // Match any network id
    },
    ropsten: {
      host: "localhost",
      port: 8545,
      network_id: 3
    },
    ropstenNoData: {
      host: "localhost",
      port: 8545,
      network_id: 3
    },
    ropstenFidOnly: {
      host: "localhost",
      port: 8545,
      network_id: 3
    }
  },
  solc: {
    optimizer: {
      enabled: false,
      runs: 200
    }
  }
};
