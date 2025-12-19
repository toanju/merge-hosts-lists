FROM docker.io/alpine:3.23.2@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62

# renovate: datasource=repology depName=alpine_3_23/curl
ENV CURL_VERSION="8.17.0-r1"
# renovate: datasource=repology depName=alpine_3_23/yq-go
ENV YQ_GO_VERSION="4.49.2-r1"

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
