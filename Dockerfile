FROM ubuntu:14.04

#x86_64-w64-mingw32.static はなんかだめだった（適当）
ARG target="i686-w64-mingw32.static"


ENV DEBIAN_FRONTEND noninteractive
WORKDIR /mnt


#install dependencies
RUN apt-get update
RUN apt-get install p7zip-full autoconf automake autopoint bash bison bzip2 cmake flex gettext git g++ gperf intltool libffi-dev libtool libltdl-dev libssl-dev libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils libgtk2.0-dev mingw-w64 -y
RUN apt-get install g++-multilib libc6-dev-i386 -y


#get MXE
RUN git clone https://github.com/mxe/mxe.git
RUN cd mxe && git checkout 546151eb850fe937566b006d5a0c952194bc4b9d


#set MXE_PATH
ENV MXE_PATH=/mnt/mxe


#compile boost
RUN cd $MXE_PATH && make MXE_TARGETS="${target}" boost


#compile qt
RUN cd $MXE_PATH && make MXE_TARGETS="${target}" qt


#compile berkeley db
RUN wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz && \
    tar zxvf db-4.8.30.NC.tar.gz && cd ./db-4.8.30.NC && \
    mkdir build_mxe && cd build_mxe && \
    CC=$MXE_PATH/usr/bin/${target}-gcc \
    CXX=$MXE_PATH/usr/bin/${target}-g++ \
    ../dist/configure \
   	  --disable-replication \
   	  --disable-shared \
   	  --enable-mingw \
  	  --enable-cxx \
  	  --host=${target} \
	    --prefix=$MXE_PATH/usr/${target} && \
    make && make install


#compile miniupnpc
RUN wget http://miniupnp.free.fr/files/miniupnpc-1.6.20120509.tar.gz && \
    tar zxvf miniupnpc-1.6.20120509.tar.gz && cd /mnt/miniupnpc-1.6.20120509 && \
    CC=$MXE_PATH/usr/bin/${target}-gcc \
    AR=$MXE_PATH/usr/bin/${target}-ar \ 
    CFLAGS="-DSTATICLIB -I$MXE_PATH/usr/${target}/include" \
    LDFLAGS="-L$MXE_PATH/usr/${target}/lib" \
    make libminiupnpc.a && \
    mkdir $MXE_PATH/usr/${target}/include/miniupnpc && \
    cp *.h $MXE_PATH/usr/${target}/include/miniupnpc && \
    cp libminiupnpc.a $MXE_PATH/usr/${target}/lib


#set PATH
ENV PATH /mnt/mxe/usr/bin:$PATH


RUN sed -i '1i#ifndef Q_MOC_RUN' /mnt/mxe/usr/${target}/include/boost/type_traits/detail/has_binary_operator.hpp
RUN echo "#endif" >> /mnt/mxe/usr/${target}/include/boost/type_traits/detail/has_binary_operator.hpp


#compile ringo
RUN git clone https://github.com/tomotomo9696/ringo && cd ringo && \
    MXE_INCLUDE_PATH=/mnt/mxe/usr/${target}/include && \
    MXE_LIB_PATH=/mnt/mxe/usr/${target}/lib && \
    ${target}-qmake-qt4 \
      USE_UPNP=1 \
      USE_BUILD_INFO=1 \
      USE_O3=1 \
	    BOOST_LIB_SUFFIX=-mt \
	    BOOST_THREAD_LIB_SUFFIX=_win32-mt \
	    BOOST_INCLUDE_PATH=$MXE_INCLUDE_PATH/boost \
	    BOOST_LIB_PATH=$MXE_LIB_PATH \
	    OPENSSL_INCLUDE_PATH=$MXE_INCLUDE_PATH/openssl \
	    OPENSSL_LIB_PATH=$MXE_LIB_PATH \
	    BDB_INCLUDE_PATH=$MXE_INCLUDE_PATH \
	    BDB_LIB_PATH=$MXE_LIB_PATH \
	    MINIUPNPC_INCLUDE_PATH=$MXE_INCLUDE_PATH \
	    MINIUPNPC_LIB_PATH=$MXE_LIB_PATH \
	    QMAKE_LRELEASE=/mnt/mxe/usr/${target}/qt/bin/lrelease ringo-qt.pro && \
    make -f Makefile.Release


RUN mkdir /mnt/dist



CMD cp /mnt/ringo/release/ringo-qt.exe /mnt/dist
