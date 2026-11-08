MAKEFILE_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
DEF=kool-typed-dynamic
EXT=kool
TESTDIR=tests
KRUN_FLAGS=--output none

%/cycle.kool: kompile
	true
%/threads.kool: kompile
	true

include $(MAKEFILE_PATH)/../../../../find-k.mak
include ${K_HOME}/include/kframework/ktest.mak
