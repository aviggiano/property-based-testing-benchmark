FROM ubuntu:20.04

RUN set -eux

ENV DEBIAN_FRONTEND=noninteractive 

WORKDIR /home/ubuntu

RUN echo "Install OS libraries"
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl gcc make python3-pip unzip jq wget tar software-properties-common

RUN echo "Install Python 3.11"
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update
RUN apt-get install -y python3.11

RUN echo "Install Git"
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update
RUN apt-get install -y git

RUN echo "Install solc-select"
RUN pip3 install solc-select

RUN echo "Install solc"
RUN solc-select install 0.8.20

RUN echo "Install slither"
RUN pip3 install slither-analyzer

RUN echo "Install echidna"
RUN wget https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.zip -O echidna.zip
RUN unzip echidna.zip
RUN tar -xvkf echidna.tar.gz
RUN mv echidna /usr/bin/
RUN rm echidna.zip echidna.tar.gz

RUN echo "Install foundry"
RUN curl -L https://foundry.paradigm.xyz | bash
RUN export PATH="$PATH:/root/.foundry/bin"
ENV PATH="$PATH:/root/.foundry/bin"
RUN PATH="$PATH:/root/.foundry/bin" foundryup

RUN echo "Install go"
RUN apt-get update
RUN apt install -y glibc-source
RUN wget https://go.dev/dl/go1.21.1.linux-arm64.tar.gz && tar -C /usr/local -xzf go1.21.1.linux-arm64.tar.gz
RUN rm go1.21.1.linux-arm64.tar.gz
RUN export PATH="$PATH:/usr/local/go/bin"
ENV PATH="$PATH:/usr/local/go/bin"

RUN echo "Install medusa"
RUN wget https://github.com/crytic/medusa/releases/download/v0.1.2/medusa-linux-x64.tar.gz && tar -C /usr/local/bin -xvf medusa-linux-x64.tar.gz
RUN rm medusa-linux-x64.tar.gz
RUN export PATH="$PATH:/usr/local/bin/medusa"

RUN echo "Install halmos"
# Using experimental `early-exit` branch
RUN pip3 install git+https://github.com/a16z/halmos@early-exit

COPY . .
RUN cd benchmark && pip3 install -r requirements.txt
ENTRYPOINT python3 -m benchmark "$@"