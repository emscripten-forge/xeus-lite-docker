const fs = require("fs");
const { execSync } = require("child_process");
const path = require("path");
const os = require("os");
require("dotenv").config();

const ROOT = path.resolve(__dirname, "..");

const PYJS_PATH = path.resolve(process.env.PY_JS_PATH);
const JUPYTERLITE_XEUS_PATH = path.resolve(process.env.JUPYTERLITE_XEUS_PATH);
const XEUS_PYTHON_PATH = path.resolve(process.env.XEUS_PYTHON_PATH);
const EMPACK_PATH = path.resolve(process.env.EMPACK_PATH);

const CONTAINER_ROOT = "/home/mambauser";
const STORAGE_VOLUME = "emsdk_install";

function createVolume(volumeName) {
  try {
    const result = execSync(`docker volume ls -q -f name=${volumeName}`)
      .toString()
      .trim();

    if (result === "") {
      // Volume doesn't exist, so create it
      execSync(`docker volume create ${volumeName}`);
      console.log(`Volume "${volumeName}" created.`);
    }
  } catch (err) {
    console.error("Error:", err);
  }
}

function buildImage() {
  if (!PYJS_PATH || !JUPYTERLITE_XEUS_PATH || !XEUS_PYTHON_PATH) {
    throw new Error(
      "Missing path variables for pyjs, jupyterlite-xeus or xeus-python"
    );
  }
  const userInfo = os.userInfo();
  const USER_ID = userInfo.uid ?? 1000;
  const GID = userInfo.gid ?? 1000;
  execSync(
    `docker build --tag xeus-stack --build-arg NEW_MAMBA_USER_ID=${USER_ID} --build-arg NEW_MAMBA_USER_GID=${GID} -f ./dockerfile .  --build-context pyjs=${PYJS_PATH} --build-context jupyterlite-xeus=${JUPYTERLITE_XEUS_PATH} --build-context xeus-python=${XEUS_PYTHON_PATH}`,
    {
      cwd: ROOT,
      stdio: "inherit",
    }
  );
}

function clean() {
  [PYJS_PATH, JUPYTERLITE_XEUS_PATH, XEUS_PYTHON_PATH].forEach((dir) => {
    const buildPath = path.join(dir, "build");
    console.log(`Deleting ${buildPath}`);
    fs.rmSync(buildPath, { recursive: true, force: true });
  });
}

function start(mode) {
  const outDir = `${ROOT}/jupyterlite`;
  if (mode !== "bash") {
    if (fs.existsSync(outDir)) {
      fs.rmSync(outDir, { recursive: true, force: true });
    }
    fs.mkdirSync(outDir);
  }
  let cmd = "";
  if (mode === "bash") {
    cmd = "bash";
  } else if (mode === "watch") {
    cmd = "";
  } else if (mode === "compile") {
    cmd = "./build.sh";
  }
  createVolume(STORAGE_VOLUME);
  const jupyterliteMount = `${outDir}:${CONTAINER_ROOT}/jupyterlite`;
  const pyjsMount = `${PYJS_PATH}:${CONTAINER_ROOT}/pyjs`;
  const xeusMount = `${JUPYTERLITE_XEUS_PATH}:${CONTAINER_ROOT}/xeus`;
  const xeusPythonMount = `${XEUS_PYTHON_PATH}:${CONTAINER_ROOT}/xeus-python`;
  const empackMount = `${EMPACK_PATH}:${CONTAINER_ROOT}/empack`;
  const cacheMount = `${STORAGE_VOLUME}:/opt/conda/opt/emsdk`;
  
  const mount = `-v ${jupyterliteMount} -v ${pyjsMount} -v ${xeusMount} -v ${xeusPythonMount} -v ${empackMount} -v ${cacheMount}`;
  
  execSync(
    `docker run --name xeus-stack-container --rm -it ${mount} xeus-stack:latest ${cmd}`,
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
  if (cmd.toLowerCase() === "clean") {
    clean();
    return;
  }

  if (cmd.toLowerCase() === "start") {
    const mode = args[1];
    try {
      start(mode);
    } catch {}
    return;
  }
}
