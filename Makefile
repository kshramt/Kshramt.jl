# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber


JULIA := julia


box = $(1:%=%.sha256)
unbox = $(1:%.sha256=%)


# Tasks
.PHONY: all check
all:
check: test/runtests.jl.tested


%.sha256.new: %
	sha256sum $< >| $@


%.sha256: %.sha256.new
	cmp -s $< $@ || cat $< >| $@


test/runtests.jl.tested: $(call box,src/Kshramt.jl)


%.tested: %.sha256
	$(JULIA) $(call unbox,$<)
	touch $@
