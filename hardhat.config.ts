import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    xdai: {
      url: process.env.XDAI_URL as string,
      accounts: [process.env.MAINNET_PK as string],
    },
  },
  etherscan: {
    apiKey: {
      xdai: process.env.GNOSISSCAN_API_KEY as string,
    },
  },
};

export default config;
