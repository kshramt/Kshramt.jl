# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber

# Tasks
.PHONY: all test doc
all: test
test:
	cd test
	julia run.jl
doc: doc/README.html

# Rules

doc/%.html: %.adoc
	asciidoctor --destination-dir $(@D) $<
