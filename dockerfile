FROM mambaorg/micromamba:debian12-slim as base-env

USER root
RUN  apt update && apt install patch -y

ARG MAMBA_DOCKERFILE_ACTIVATE=1 
ARG NEW_MAMBA_USER_ID=1000
ARG NEW_MAMBA_USER_GID=1000

ENV EMSDK_INSTALL_LOCATION=/home/$MAMBA_USER/emsdk_install
ENV EMSDK_VER=3.1.45
ENV WASM_BUILD_ENV=xeus-build-wasm
ENV PREFIX=$MAMBA_ROOT_PREFIX/envs/$WASM_BUILD_ENV
ENV LITE_DIR=/home/$MAMBA_USER/jupyterlite

RUN if [ "$(id ${MAMBA_USER} -u)" != "$NEW_MAMBA_USER_ID" ]; then \
    usermod "-u ${NEW_MAMBA_USER_ID}" "${MAMBA_USER}"; \
    fi
RUN if [ "$(id ${MAMBA_USER} -g)" != "$NEW_MAMBA_USER_GID" ]; then \
    groupmod -o -g ${NEW_MAMBA_USER_GID} ${MAMBA_USER} && \
    usermod -g ${NEW_MAMBA_USER_GID} ${MAMBA_USER}; \
    fi

USER $MAMBA_USER

COPY --chown=$MAMBA_USER:$MAMBA_USER ./script/environment.yaml /tmp/env.yaml
COPY --chown=$MAMBA_USER:$MAMBA_USER ./script/wasm-env.yaml /tmp/wasm-env.yaml

RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes

# COPY --chown=$MAMBA_USER:$MAMBA_USER --from=pyjs ./emsdk/setup_emsdk.sh /tmp/setup_emsdk.sh
# RUN /tmp/setup_emsdk.sh $EMSDK_VER $EMSDK_INSTALL_LOCATION

RUN micromamba create -n $WASM_BUILD_ENV --platform=emscripten-wasm32 -f /tmp/wasm-env.yaml --yes

FROM base-env AS build-pyjs

WORKDIR /home/$MAMBA_USER

RUN npm install -g nodemon
COPY --chown=$MAMBA_USER:$MAMBA_USER ./script/build.sh ./build.sh 
COPY --chown=$MAMBA_USER:$MAMBA_USER ./script/nodemon.json ./nodemon.json 
RUN chmod +x ./build.sh

CMD ["/opt/conda/envs/xeus-build-wasm/bin/nodemon"] 
