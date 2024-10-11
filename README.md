## Docker image to set up Xeus lite kernel dev enviroment.

### Prerequisite
- nodejs >=18
- docker >=23

### Getting started
- Create `.env` file containing path to `pyjs`, `xeus-python`, `jupyterlite-xeus` repositories

```shell
# .env file
PY_JS_PATH=../pyjs
JUPYTERLITE_XEUS_PATH=../xeus
XEUS_PYTHON_PATH=../xeus-python
```

- Build image
```bash
npm install 
npm run build # Only need to run once
```
- Build `jupyterlite` and watch for changes:

```bash
npm start
```

Once finished, `jupyterlite` assets will be available at `./jupyterlite/_output`, you can serve the site with any static file server, for example:

```bash
 python -m http.server 3344 -d jupyterlite/_output
```

- Optional commands:
```bash
npm run clean # Clean build assets
npm start bash # Open a bash shell in the container
``