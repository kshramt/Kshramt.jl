# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber

JULIA := julia

# Tasks
.PHONY: all check
all:
check: test/runtests.jl.tested

# Rules
test/%.tested: test/% src/Kshramt.jl
	$(JULIA) $<
	touch $@
