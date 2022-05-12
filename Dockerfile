FROM alpine:latest
RUN apk add --no-cache bash
ADD pluto.sh /
RUN chmod 755 /pluto.sh
ENTRYPOINT ["bash", "pluto.sh"]
