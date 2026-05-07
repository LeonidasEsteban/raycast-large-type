import { LaunchProps, environment, showHUD } from "@raycast/api";
import { spawn } from "node:child_process";
import { join } from "node:path";

type Args = { text: string };

export default async function Command(props: LaunchProps<{ arguments: Args }>) {
  const text = props.arguments.text?.trim();
  if (!text) {
    await showHUD("No text provided");
    return;
  }

  const helper = join(environment.assetsPath, "LargeType");
  const child = spawn(helper, [text], {
    detached: true,
    stdio: "ignore",
  });
  child.on("error", async (err) => {
    await showHUD(`Failed to launch helper: ${err.message}`);
  });
  child.unref();
}
