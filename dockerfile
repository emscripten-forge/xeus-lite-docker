FROM mambaorg/micromamba:debian12-slim

USER root
RUN  apt update && apt install patch -y

ARG NEW_MAMBA_USER_ID=1000
ARG NEW_MAMBA_USER_GID=1000

RUN if [ "$(id ${MAMBA_USER} -u)" != "$NEW_MAMBA_USER_ID" ]; then \
    usermod "-u ${NEW_MAMBA_USER_ID}" "${MAMBA_USER}"; \
    fi
RUN if [ "$(id ${MAMBA_USER} -g)" != "$NEW_MAMBA_USER_GID" ]; then \
    groupmod -o -g ${NEW_MAMBA_USER_GID} ${MAMBA_USER} && \
    usermod -g ${NEW_MAMBA_USER_GID} ${MAMBA_USER}; \
    fi

USER $MAMBA_USER

ARG MAMBA_DOCKERFILE_ACTIVATE=1 
ENV EMSDK_INSTALL_LOCATION=/home/$MAMBA_USER/emsdk_install
ENV EMSDK_VER=3.1.45
ENV WASM_BUILD_ENV=xeus-build-wasm
ENV PREFIX=$MAMBA_ROOT_PREFIX/envs/$WASM_BUILD_ENV

COPY --chown=$MAMBA_USER:$MAMBA_USER docker/environment.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes

COPY --chown=$MAMBA_USER:$MAMBA_USER ./pyjs/emsdk/setup_emsdk.sh /tmp/setup_emsdk.sh
RUN /tmp/setup_emsdk.sh $EMSDK_VER $EMSDK_INSTALL_LOCATION

RUN micromamba create -n $WASM_BUILD_ENV --platform=emscripten-wasm32 \
    -c https://repo.mamba.pm/emscripten-forge \
    -c https://repo.mamba.pm/conda-forge --yes \
    ipython pybind11 nlohmann_json pybind11_json bzip2 \
    sqlite zlib libffi exceptiongroup ipython \ 
    xeus xeus-python-shell xeus-lite libpython

WORKDIR /home/$MAMBA_USER
COPY --chown=$MAMBA_USER:$MAMBA_USER ./pyjs ./pyjs
COPY --chown=$MAMBA_USER:$MAMBA_USER ./xeus-python ./xeus-python
COPY --chown=$MAMBA_USER:$MAMBA_USER ./xeus ./xeus

WORKDIR /home/$MAMBA_USER/pyjs

RUN export CMAKE_PREFIX_PATH=$PREFIX \
    && export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX \ 
    && export CXXFLAGS="" \ 
    && export CFLAGS="" \ 
    && export LDFLAGS=""\
    && $EMSDK_INSTALL_LOCATION/emsdk activate $EMSDK_VER \
    && . $EMSDK_INSTALL_LOCATION/emsdk_env.sh \
    && mkdir build && pushd build \
    && emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DBUILD_RUNTIME_BROWSER=ON \
    -DBUILD_RUNTIME_NODE=OFF \
    -DCMAKE_INSTALL_PREFIX=$PREFIX .. \ 
    && make -j2 && make install && popd

WORKDIR /home/$MAMBA_USER/xeus-python

RUN export CMAKE_PREFIX_PATH=$PREFIX \
    && export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX \
    && rm -f $PREFIX/bin/python* \
    && export CXXFLAGS="" \ 
    && export CFLAGS="" \ 
    && export LDFLAGS=""\
    && $EMSDK_INSTALL_LOCATION/emsdk activate $EMSDK_VER \
    && . $EMSDK_INSTALL_LOCATION/emsdk_env.sh \
    && mkdir build && pushd build \
    && emcmake cmake -DENABLE_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DXPYT_EMSCRIPTEN_WASM_BUILD=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX .. \
    && make -j4 && make install && popd
