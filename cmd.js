const fs = require("fs");
const { execSync } = require("child_process");
const path = require("path");
const os = require("os");

const ROOT = path.resolve(__dirname, "..");
const PYJS = "pyjs";
const XEUS_PYTHON = "xeus-python";
const CONTAINER_ROOT = "/home/mambauser";
function buildImage() {
  execSync(`rm -fr ${ROOT}/${PYJS}/build`);
  const userInfo = os.userInfo();
  const USER_ID = userInfo.uid ?? 1000;
  const GID = userInfo.gid ?? 1000;
  execSync(
    `docker build --tag xeus-stack --build-arg NEW_MAMBA_USER_ID=${USER_ID} --build-arg NEW_MAMBA_USER_GID=${GID} -f docker/dockerfile .`,
    {
      cwd: ROOT,
      stdio: "inherit",
    }
  );
}

function start() {
  const outDir = `${ROOT}/docker/jupyterlite`
  !fs.existsSync(outDir) && fs.mkdirSync(outDir);

  const mount = `-v "${outDir}":"${CONTAINER_ROOT}/_out"`;
  execSync(
    `docker run --name xeus-stack-container --rm -it xeus-stack:latest bash`,
    {
      cwd: ROOT,
      stdio: "inherit",
    }
  );
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const cmd = args[0];
  if (!cmd) {
    return;
  }
  if (cmd.toLowerCase() === "build") {
    buildImage();
    return;
  }

  if (cmd.toLowerCase() === "start") {
    start();
    return;
  }
}
