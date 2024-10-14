import createDebug from "debug";

export const debug = createDebug("paymaster");
export const error = createDebug("paymaster");

// Pipe debug output to stdout instead of stderr
debug.log = console.debug.bind(console);

// Pipe error output to stderr
error.log = console.error.bind(console);
