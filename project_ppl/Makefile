DEF      := ppl
KOMPILED := $(DEF)-kompiled
TESTS    := $(wildcard tests/*.ppl)

KOMPILE_FLAGS := --gen-glr-bison-parser
ifeq ($(shell uname), Darwin)
KOMPILE_FLAGS += --no-haskell-binary
endif

.PHONY: all kompile test update-results clean

all: test

kompile: $(KOMPILED)/timestamp

$(KOMPILED)/timestamp: $(DEF).k
	kompile $(DEF).k $(KOMPILE_FLAGS)

# run every test program and compare with its expected output
test: $(TESTS:=.test)

tests/%.ppl.test: kompile
	krun tests/$*.ppl | diff - tests/$*.ppl.out

# regenerate the expected outputs
update-results: kompile
	for t in $(TESTS); do krun $$t > $$t.out; done

clean:
	rm -rf $(KOMPILED)
