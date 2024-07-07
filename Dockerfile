FROM cm2network/steamcmd:root as build_stage

ENV TERM xterm

ENV STEAM_APP_ID 730
ENV STEAM_APP cs2
ENV STEAM_DIR "${HOMEDIR}/${STEAM_APP}-dedicated"

SHELL ["/bin/bash", "-c"]

RUN set -xo pipefail \
      && apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
          wget \
          ca-certificates \
          lib32z1 \
          libicu-dev \
          net-tools \
          locales \
          curl \
          jq \
          unzip \
          simpleproxy \
      && locale-gen en_US.UTF-8 \
      && mkdir -p ${HOMEDIR}/.steam/sdk64 \
      && ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ${HOMEDIR}/.steam/sdk64/steamclient.so \
      && mkdir -p ${STEAM_DIR} \
      && { \
            echo '@ShutdownOnFailedCommand 1'; \
            echo '@NoPromptForPassword 1'; \
            echo "force_install_dir ${CS_DIR}"; \
            echo 'login anonymous'; \
            echo "app_update ${STEAM_APP_ID}"; \
            echo 'quit'; \
        } > ${STEAM_DIR}/autoupdate_script.txt \
      && rm -rf "/var/lib/apt/lists/*"

COPY --chown=${USER}:${USER} containerfs ${HOMEDIR}/

FROM build_stage AS cs2-prac-docker

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN set -xo pipefail \
    && chown -R "${USER}:${USER}" "${STEAM_DIR}"


USER ${USER}
WORKDIR ${HOMEDIR}
VOLUME ${STEAM_DIR}
ENTRYPOINT ["bash"]
#ENTRYPOINT exec ${HOMEDIR}/start.sh

EXPOSE 27015/tcp \
       27015/udp \
       27020/udp
