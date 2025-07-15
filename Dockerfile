FROM docker.io/alpine:3.22.1@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1

# renovate: datasource=repology depName=alpine_3_22/curl
ENV CURL_VERSION="8.14.1-r1"
# renovate: datasource=repology depName=alpine_3_22/yq-go
ENV YQ_GO_VERSION="4.45.4-r0"

RUN apk --no-cache add \
    curl=${CURL_VERSION} \
    yq-go=${YQ_GO_VERSION}

RUN adduser app -h /app -u 1000 -g 1000 -DH

WORKDIR /app
RUN chown -R 1000:1000 /app
COPY --chown=1000:1000 \
    default-config.yaml \
    merge-hosts-lists.sh \
    ./

USER 1000
VOLUME ["/data"]
ENTRYPOINT ["/app/merge-hosts-lists.sh"]
CMD ["./default-config.yaml", "/data/hosts"]
