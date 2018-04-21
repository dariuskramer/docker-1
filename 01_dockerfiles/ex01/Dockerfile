FROM debian

ARG TARBALL='http://dl.4players.de/ts/releases/3.1.1/teamspeak3-server_linux_amd64-3.1.1.tar.bz2'
ARG CHECKSUM='c9403f7958e1bf1c5e5cf083641b1e02b06800158df543e09d9259c69181e873'
ARG TARGET='ts3.tar.bz2'
ENV TS3SERVER_LICENSE accept

WORKDIR /opt/teamspeak

ADD ${TARBALL} ${TARGET}

RUN echo "${CHECKSUM} ${TARGET}" | sha256sum -c - &&\
	    apt update &&\
	    apt install -y ca-certificates bzip2 &&\
	    tar xf ${TARGET} --strip=1 &&\
	    apt purge -y bzip2 &&\
	    rm -rf /var/lib/apt/lists/* ${TARGET}

# Voice
# File transfer
# ServerQuery
EXPOSE 9987/udp
EXPOSE 30033
EXPOSE 10011

CMD    /opt/teamspeak/ts3server_minimal_runscript.sh


# Build
# docker build -t ts-server .
# Run
# docker run -dit --init --rm --name ts -p 9987:9987/udp -p 10011:10011 -p 30033:30033 ts-server
