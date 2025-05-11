import hre from "hardhat";
import Pasanaku from "../ignition/modules/Pasanaku";

async function main() {
  const [deployer] = await hre.viem.getWalletClients();
}

main()
  .then(() => {
    console.log("Done");
  })
  .catch((error) => {
    console.error(error);
  });
