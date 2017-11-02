import web3 from 'web3';

export const NETWORK_ETHEREUM         = 'ethereum'
export const NETWORK_ETHEREUM_ROPSTEN = 'ropsten'
export const NETWORK_ETHEREUM_MAINNET = 'mainnet'

export const networks = {
  [NETWORK_ETHEREUM_MAINNET]: {
    network: NETWORK_ETHEREUM,
    subnetwork: NETWORK_ETHEREUM_MAINNET
  },
  [NETWORK_ETHEREUM_ROPSTEN]: {
    network: NETWORK_ETHEREUM,
    subnetwork: NETWORK_ETHEREUM_ROPSTEN
  }
};

export default {

  [NETWORK_ETHEREUM]: {
    name: "Ethereum",
    subnetworks: {
      [NETWORK_ETHEREUM_MAINNET]: {
        rpc: `https://mainnet.infura.io/${process.env.REACT_APP_INFURA_TOKEN}`
      },
      [NETWORK_ETHEREUM_ROPSTEN]: {
        rpc: `https://ropsten.infura.io/${process.env.REACT_APP_INFURA_TOKEN}`
      }
    },
    lib: web3
  }

}