#!/bin/bash

echo "############## BUILDING PYJS ##############"
cd  /home/$MAMBA_USER/pyjs
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX
export CXXFLAGS=""
export CFLAGS=""
export LDFLAGS=""
export PYTHON="/opt/conda/bin/python"

# $EMSDK_INSTALL_LOCATION/emsdk activate $EMSDK_VER
# . $EMSDK_INSTALL_LOCATION/emsdk_env.sh
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

echo "############## BUILDING JUPYTERLITE ##############"
cd /home/$MAMBA_USER/xeus
ls $PREFIX/lib/python3.11/site-packages/pyjs
python -m pip install -e . -v --no-build-isolation
cd $LITE_DIR
rm -fr *
jupyter lite build --XeusAddon.prefix=$PREFIX --XeusAddon.mounts=$PREFIX/lib/python3.11/site-packages/pyjs:/lib/python3.11/site-packages/pyjs