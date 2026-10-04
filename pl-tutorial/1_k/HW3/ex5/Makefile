MAKEFILE_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
DEF=imp
EXT=imp
KOMPILE_FLAGS=--gen-glr-bison-parser --enable-search
# every test is run with --search; we observe all possible final outputs
KRUN_FLAGS=--search --pattern '<output> _:List ListItem(\#buffer(S:String)) </output>'

include $(MAKEFILE_PATH)/../../../find-k.mak
include ${K_HOME}/include/kframework/ktest.mak

tests/div.imp: kompile
	cat $@.in 2>/dev/null | $(KRUN_OR_LEGACY) $@ --definition $(KOMPILED_DIR) --search $(CHECK) $@.out

tests/spawn.imp: kompile
	cat $@.in 2>/dev/null | $(KRUN_OR_LEGACY) $@ --definition $(KOMPILED_DIR) --search --pattern "<output> ListItem(_) ListItem(_) ListItem(#buffer(Out:String)) </output>" $(CHECK) $@.out
