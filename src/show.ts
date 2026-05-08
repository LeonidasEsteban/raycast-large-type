import { LaunchProps, environment, showHUD } from "@raycast/api";
import { spawn } from "node:child_process";
import { appendFileSync } from "node:fs";
import { join } from "node:path";

const LOG_PATH = "/tmp/raycast-large-type.log";

function log(label: string, data: unknown) {
  const line = `[${new Date().toISOString()}] ${label}: ${JSON.stringify(data, null, 2)}\n`;
  // eslint-disable-next-line no-console
  console.log(line);
  try {
    appendFileSync(LOG_PATH, line);
  } catch {
    // ignore log write errors
  }
}

export default async function Command(props: LaunchProps) {
  log("=== command invoked ===", { ts: Date.now() });
  log("props", {
    arguments: props.arguments,
    fallbackText: props.fallbackText,
    launchType: props.launchType,
    launchContext: props.launchContext,
  });
  log("environment", {
    commandName: environment.commandName,
    commandMode: environment.commandMode,
    extensionName: environment.extensionName,
    launchType: environment.launchType,
    raycastVersion: environment.raycastVersion,
    isDevelopment: environment.isDevelopment,
    assetsPath: environment.assetsPath,
  });
  log("argv", process.argv);

  const text = props.fallbackText?.trim();

  if (!text) {
    log("result", "no text — showing HUD");
    await showHUD(`No text. Check ${LOG_PATH} for debug info`);
    return;
  }

  log("result", { spawningHelper: true, text });

  const helper = join(environment.assetsPath, "LargeType");
  const child = spawn(helper, [text], {
    detached: true,
    stdio: "ignore",
  });
  child.on("error", async (err) => {
    log("spawn error", err.message);
    await showHUD(`Failed to launch helper: ${err.message}`);
  });
  child.unref();
}
