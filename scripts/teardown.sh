#!/bin/sh

: ${KWOK_WORKDIR:="/tmp"}
export KWOK_WORKDIR

docker rm -f nuodb-cp-rest nuodb-cp-operator noop-provisioner
kwokctl delete cluster
