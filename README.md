## Docker image to set up xeus lite kernel development environment.

Helper commands to start developing xeus-based kernels for JupyterLite. It allows building a JupyterLite instance with the local version of `empack`, `xeus-python`, `pyjs` and `jupyterlite_xeus` together.

### Prerequisite

- nodejs >=18
- docker >=23

### Usage

- At the root of this repo, create a `.env` file containing the path to `pyjs`, `xeus-python`, `jupyterlite-xeus`, and `empack` source code.

```shell
# .env file
PY_JS_PATH=../pyjs
JUPYTERLITE_XEUS_PATH=../xeus
XEUS_PYTHON_PATH=../xeus-python
EMPACK_PATH=../empack
```

- Build image (only need to run once)

```bash
npm install
npm run build
```

- Build `jupyterlite`:

```bash
npm start
```

`jupyterlite` assets will be available at `./jupyterlite/_output`, you can serve the site with any static file server, for example:

```bash
 python -m http.server 3344 -d jupyterlite/_output
```

- Build JupyterLite and watch for code changes:

```bash
npm start:watch
```

- Optional commands:

```bash
npm run clean # Clean build assets
npm run start:bash # Open a bash shell in the container
```

### Customize jupyterlite build

- All files located in `./jupyterlite` will be copied to the build directory in the container. So you can add your config file (`jupyter_lite_config.py|json`,...) to this directory.

- To add local JupyterLite extensions to the build, update `.env` file with path to your extensions and key prefixed by `JUPYTERLITE_EXTERNAL`

```bash
#.env file
JUPYTERLITE_EXTERNAL_MY_CUSTOM_EXTENSION=../demo/my-custom-ext
```

- To install additional packages to the kernel enviromnent, create `jupyterlite/environment.yml` file with following content:

```yaml
name: xeus-build-wasm
channels:
  - https://repo.mamba.pm/emscripten-forge
  - conda-forge
dependencies:
  - package-1
  - package-2
```
