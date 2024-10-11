## Docker image to set up Xeus lite kernel dev enviroment.

Docker image and helpers to start developing xeus-based kernels for JupyterLite. It allows to build a JupyterLite instance with local version of `empack`, `xeus-python`, `pyjs` and `jupyterlite_xeus` together.

### Prerequisite

- nodejs >=18
- docker >=23

### Usage

- At the root of this repo, create an `.env` file containing path to `pyjs`, `xeus-python`, `jupyterlite-xeus` repositories

```shell
# .env file
PY_JS_PATH=../pyjs
JUPYTERLITE_XEUS_PATH=../xeus
XEUS_PYTHON_PATH=../xeus-python
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

Once finished, `jupyterlite` assets will be available at `./jupyterlite/_output`, you can serve the site with any static file server, for example:

```bash
 python -m http.server 3344 -d jupyterlite/_output
```
- Build JupyterLite and watch for code changes:

```bash
jlpm start:watch
```

- Optional commands:

```bash
npm run clean # Clean build assets
npm run start:bash # Open a bash shell in the container
```
