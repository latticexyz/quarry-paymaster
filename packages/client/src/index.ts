import { stash } from "./stash";
import { sync } from "./sync";

async function main() {
  sync();
}

(window as any).stash = stash;
main();
