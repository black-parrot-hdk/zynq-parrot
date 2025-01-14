# ZynqParrot Software Support

This directory is used to cross-compile software support for ZynqParrot hosts. Currently supported are x86, Zynq 7000 and Zynq UltraScale+. By running the setup here, users will be able to use their host x86 system and compile programs that run on Zynq. As a proof of concept, Verilator is provided as a cross-compiled example.

Makefile targets:
			# Set TARGET_NAME to one of x86, pynqz2, ultra96v2
            xsa: Creates a default xsa file for the host selected
            environment-setup: Creates an environment setup script to init the cross-compile env
			verilator: Creates verilator bin which verilates on x86 but can be compiled on host
            clean: Removes working directory for specific target

