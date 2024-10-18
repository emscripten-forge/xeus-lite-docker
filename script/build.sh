#!/bin/bash
set -e

echo "############## INSTALLING EMPACK ##############"
cd  /home/$MAMBA_USER/empack
python -m pip install -e . -v --no-build-isolation --no-deps

echo "############## BUILDING PYJS ##############"
cd  /home/$MAMBA_USER/pyjs
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX
export CXXFLAGS=""
export CFLAGS=""
export LDFLAGS=""
export PYTHON="/opt/conda/bin/python"

mkdir -p build
pushd build
emcmake cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DBUILD_RUNTIME_BROWSER=ON -DBUILD_RUNTIME_NODE=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX ..
emmake make -j4
emmake make install
popd

echo "############## BUILDING XEUS-PYTHON ##############"
cd /home/$MAMBA_USER/xeus-python
rm -f $PREFIX/bin/python*
mkdir -p build
pushd build
emcmake cmake -DENABLE_SHARED=OFF -DCMAKE_BUILD_TYPE=Release  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DXPYT_EMSCRIPTEN_WASM_BUILD=ON -DCMAKE_INSTALL_PREFIX=$PREFIX ..
emmake make -j4
emmake make install
popd

echo "############## INSTALL EXTENSIONS ##############"
for subdir in /home/$MAMBA_USER/extensions/*; do
    if [ -d "$subdir" ]; then
        echo "Running pip install -e $subdir"
        pip install -e "$subdir" -v --no-build-isolation
    fi
done

echo "############## BUILDING JUPYTERLITE ##############"
cd /home/$MAMBA_USER/xeus
rm -fr tsconfig.tsbuildinfo
python -m pip install -e . -v --no-build-isolation
cd $LITE_DIR
if [ -f ./environment.yml ]; then
  micromamba install -n $WASM_BUILD_ENV --platform=emscripten-wasm32 -f ./environment.yml --yes
fi
rm -fr _output .jupyterlite.doit.db
jupyter lite build --XeusAddon.prefix=$PREFIX --XeusAddon.mounts=$PREFIX/lib/python3.11/site-packages/pyjs:/lib/python3.11/site-packages/pyjs