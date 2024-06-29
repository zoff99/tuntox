SOURCES = $(wildcard *.c)
DEPS=libsodium

ismingw = 0
ccmachine = $(shell $(CC) -dumpmachine)
ifeq ($(findstring mingw, $(ccmachine)), mingw)
  ismingw = 1
  CFLAGS += --static
endif

ASAN_CFLAGS = -fsanitize=address -fno-omit-frame-pointer -static-libasan
CFLAGS += -g -O3 -fPIC -Wall -D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wno-unused-variable -Wno-unknown-pragmas -Wno-array-parameter -Wno-enum-compare -Wno-unused-result -Wno-format-truncation #-std=c99
CFLAGS += $(shell pkg-config --cflags $(DEPS))
LDFLAGS += -g -pthread -lm -static
LDFLAGS += $(shell pkg-config --static --libs $(DEPS))
DSO_LDFLAGS += -g -pthread -lm
DSO_LDFLAGS += $(shell pkg-config --libs $(DEPS))
OBJECTS=$(SOURCES:.c=.o)
INCLUDES = $(wildcard *.h)
PYTHON = /usr/bin/env python3
INSTALL = install -C
INSTALL_MKDIR = $(INSTALL) -d -m 755
OS=$(shell uname)

ifneq ($(OS),Darwin)
	LDFLAGS += -lrt
	DSO_LDFLAGS += -lrt
endif

PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

# Targets
all: tuntox tuntox_nostatic
asan_all: asan_build asan_tuntox_nostatic

gitversion.h:
	@if [ -d .git ]; then \
		echo "  GEN   $@"; \
		echo "#define GITVERSION \"$(shell git rev-parse HEAD)\"" > $@; \
	fi

tox_bootstrap.h: 
	$(PYTHON) generate_tox_bootstrap.py 

asan_build:
	$(eval CFLAGS += $(ASAN_CFLAGS))

%.o: %.c $(INCLUDES) gitversion.h tox_bootstrap.h
	# @echo "  CC    $@"
	$(CC) -c $(CFLAGS) $< -o $@

tuntox: $(OBJECTS) $(INCLUDES)
	$(CC) -o $@ $(OBJECTS) -lpthread $(LDFLAGS) 

asan_tuntox_nostatic: $(OBJECTS) $(INCLUDES)
	$(CC) -o $@ $(OBJECTS) -lpthread $(DSO_LDFLAGS) $(ASAN_CFLAGS)

tuntox_nostatic: $(OBJECTS) $(INCLUDES)
	$(CC) -o $@ $(OBJECTS) -lpthread $(DSO_LDFLAGS) 

cscope.out:
	@echo "  GEN   $@"
	@cscope -bv ./*.[ch] &> /dev/null

clean:
	$(RM) *.o tuntox tuntox_nostatic cscope.out

install: tuntox_nostatic
	$(INSTALL_MKDIR) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) tuntox_nostatic $(DESTDIR)$(BINDIR)/tuntox

.PHONY: all asan_all clean asan_build
