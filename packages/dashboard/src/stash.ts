import { createStash } from "@latticexyz/stash/internal";
import config from "contracts/mud.config";
import worldConfig from "@latticexyz/world/mud.config";

export const stash = createStash({
  ...config,
  namespaces: {
    ...config.namespaces,
    world: {
      tables: {
        NamespaceOwner: worldConfig.namespaces.world.tables.NamespaceOwner,
      },
    },
  },
});

(window as any).stash = stash;
