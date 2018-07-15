#!/bin/bash
if [ ${EUID:-${UID}} = 0 ]; then
  docker build ./ -t ringo-qt --no-cache=true
  docker run -it --rm -v `pwd`:/mnt/dist ringo-qt
else
  echo "permission denied"
fi

