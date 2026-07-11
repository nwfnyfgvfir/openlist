# Runtime image for custom OpenList (pre-built linux/amd64 binary from CI).
# Mirrors OpenList Dockerfile.ci layout.
# Default: Docker Hub. Override with:
#   --build-arg BASE_IMAGE=ghcr.io/openlistteam/openlist-base-image:base
ARG BASE_IMAGE=openlistteam/openlist-base-image:base
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="OpenList with double-click left/right seek (±10s)"
LABEL maintainer="openlist-custom"

ARG USER=openlist
ARG UID=1001
ARG GID=1001

WORKDIR /opt/openlist/

RUN (getent group ${GID} >/dev/null 2>&1 || addgroup -g ${GID} ${USER}) && \
    (id -u ${USER} >/dev/null 2>&1 || adduser -D -u ${UID} -G ${USER} ${USER}) && \
    mkdir -p /opt/openlist/data && \
    chown -R ${UID}:${GID} /opt/openlist

COPY --chmod=755 --chown=${UID}:${GID} openlist ./openlist
COPY --chmod=755 --chown=${UID}:${GID} entrypoint.sh /entrypoint.sh

USER ${USER}
RUN /entrypoint.sh version || true

ENV UMASK=022
VOLUME /opt/openlist/data/
EXPOSE 5244 5245
CMD ["/entrypoint.sh"]
