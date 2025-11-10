FROM ubuntu:latest

RUN apt-get update && apt-get install -y sudo

COPY linux_cli.sh /usr/local/bin/linux_cli
RUN chmod +x /usr/local/bin/linux_cli

ENTRYPOINT ["/usr/local/bin/linux_cli"]

CMD ["-h"]
