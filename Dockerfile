FROM alpine:3.12 as builder

LABEL maintainer "https://github.com/blacktop"

ENV ZEEK_VERSION 3.2.3

RUN apk add --no-cache zlib openssl libstdc++ libpcap libgcc
RUN apk add --no-cache -t .build-deps \
  bsd-compat-headers \
  libmaxminddb-dev \
  linux-headers \
  openssl-dev \
  libpcap-dev \
  python3-dev \
  zlib-dev \
  binutils \
  fts-dev \
  cmake \
  clang \
  bison \
  bash \
  swig \
  perl \
  make \
  flex \
  git \
  g++ \
  fts

RUN echo "===> Cloning zeek..." \
  && cd /tmp \
  && git clone --recursive --branch v$ZEEK_VERSION https://github.com/zeek/zeek.git

RUN echo "===> Compiling zeek..." \
  && cd /tmp/zeek \
  && CC=clang ./configure --prefix=/usr/local/zeek \
  --build-type=MinSizeRel \
  --disable-broker-tests \
  --disable-zeekctl \
  --disable-auxtools \
  --disable-python \
  && make -j 2 \
  && make install

RUN echo "===> Shrinking image..." \
  && strip -s /usr/local/zeek/bin/zeek

RUN echo "===> Size of the Zeek install..." \
  && du -sh /usr/local/zeek
####################################################################################################
ENV PATH $PATH:/usr/local/zeek/bin

ENTRYPOINT ["zeek"]
CMD ["-h"]

####################################################################################################
RUN echo "===> Cloning librdkafka" \
  && cd /tmp \
  && curl -L https://github.com/edenhill/librdkafka/archive/v1.4.2.tar.gz | tar xvz \
  && cd librdkafka-1.4.2/ \
  && ./configure --enable-sasl \
  && make \
  && make install  


RUN apk add --no-cache py3-pip

RUN echo "===> Installing zkg package manager" \
  && pip3 install gitpython semantic-version \
  && pip3 install zkg \
  && pip3 install git+git://github.com/zeek/package-manager@master \
  && zkg autoconfig \
  && zkg install --force apache/metron-bro-plugin-kafka --version master \
  && zeek -N Apache::Kafka

#RUN echo "===> Cloning metron plugin" \
#  && cd /tmp \
#  && git clone 

