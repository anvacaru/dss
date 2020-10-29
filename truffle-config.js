module.exports = {
    contracts_directory: "./src/",
    compilers:{
      solc: {
      version: "0.5.12",
      optimizer: {
          enabled: true,
          runs: 200
      }
   }
  },
    networks: {
      development: {
        host: "127.0.0.1",
        port: 8545,
        network_id: "*"
      }
    }
  };
