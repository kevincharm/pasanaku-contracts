import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

export default buildModule("Pasanaku", (m) => {
  const pasanaku = m.contract("Pasanaku", [
    m.getParameter("name", "Pasanaku"),
    m.getParameter("hub", "0xc12C1E50ABB450d6205Ea2C3Fa861b3B834d13e8"),
    m.getParameter("group", "0xFd37f4625CA5816157D55a5b3F7Dd8DD5F8a0C2F"),
    m.getParameter("roundInterval", 60),
    m.getParameter("depositAmount", parseEther("0.001")),
  ]);

  return {
    pasanaku,
  };
});
