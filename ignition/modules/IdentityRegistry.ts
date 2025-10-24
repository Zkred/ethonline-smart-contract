import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("IdentityRegistryModule", (m) => {
  // First deploy DIDValidator
  const didValidator = m.contract("DIDValidator");

  // Then deploy IdentityRegistry with DIDValidator address and decimal=6
  const identityRegistry = m.contract("AgentRegistry", [didValidator, 6]);

  return { didValidator, identityRegistry };
});
