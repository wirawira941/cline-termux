// cline-termux preload — forces @opentui/core to use our Android-built libopentui.so
// This runs via `node --import` before Cline's own imports, so the module cache
// already has the correct library path when Cline loads @opentui/core.
import { setRenderLibPath } from "@opentui/core";

const libDir = new URL(".", import.meta.url).pathname;
setRenderLibPath(libDir + "libopentui.so");
