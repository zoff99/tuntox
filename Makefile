SOURCES = $(wildcard *.c)
DEPS=toxcore
CC=gcc
CFLAGS=-g -Wall -I/c/toxcore/include -pthread
#CFLAGS += $(shell pkg-config --cflags $(DEPS))
LDFLAGS=-pthread -g -lm #-static
#LDFLAGS += $(shell pkg-config --static --libs $(DEPS))
DSO_LDFLAGS=-g -lm
DSO_LDFLAGS += $(shell pkg-config --libs $(DEPS))
OBJECTS=$(SOURCES:.c=.o) libtoxcore.a libsodium.a
INCLUDES = $(wildcard *.h)


# Targets
all: tuntox

gitversion.h: FORCE
	@if [ -f .git/HEAD ] ; then echo "  GEN   $@"; echo "#define GITVERSION \"$(shell git rev-parse HEAD)\"" > $@; fi

FORCE:

tox_bootstrap.h: 
	python generate_tox_bootstrap.py 

%.o: %.c $(INCLUDES) gitversion.h tox_bootstrap.h
	@echo "  CC    $@"
	@$(CC) -c $(CFLAGS) $< -o $@

tuntox: $(OBJECTS) $(INCLUDES)
	$(CC) -o $@ $(OBJECTS) $(LDFLAGS) 

tuntox_nostatic: $(OBJECTS) $(INCLUDES)
	$(CC) -o $@ $(OBJECTS) $(DSO_LDFLAGS) 

cscope.out:
	@echo "  GEN   $@"
	@cscope -bv ./*.[ch] &> /dev/null

clean:
	rm -f *.o tuntox cscope.out gitversion.h tox_bootstrap.h

.PHONY: all clean tuntox
