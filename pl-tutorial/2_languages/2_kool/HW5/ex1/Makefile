MAKEFILE_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
DEF=kool-untyped
EXT=kool
TESTDIR=tests
KRUN_FLAGS=--output none

%/threads.kool: kompile
	true

include $(MAKEFILE_PATH)/../../../../find-k.mak
include ${K_HOME}/include/kframework/ktest.mak
