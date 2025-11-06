#!/bin/bash
export VIRTUAL_ENV_DISABLE_PROMPT=1
source /opt/venv/bin/activate

# Add boost variables
export BOOST_ROOT=/opt/boost
export BOOST_INCLUDEDIR=$BOOST_ROOT/include
export BOOST_LIBRARYDIR=$BOOST_ROOT/lib

export CPATH=$BOOST_INCLUDEDIR:$CPATH
export LIBRARY_PATH=$BOOST_LIBRARYDIR:$LIBRARY_PATH
export LD_LIBRARY_PATH=$BOOST_LIBRARYDIR:$LD_LIBRARY_PATH

# set opam
eval $(opam env --set-root --root=/opt/opam)

exec "$@"
