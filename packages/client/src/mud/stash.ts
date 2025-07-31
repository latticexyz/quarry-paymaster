import { createStash } from "@latticexyz/stash/internal";
import { tables } from "../common";

export const stash = createStash({ namespaces: { "": { tables } } });
