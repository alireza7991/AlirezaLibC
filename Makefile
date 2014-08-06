-include .config

ARCH = arm
SUBARCH = 
ASMSUBARCH = el


exec_prefix = /usr/local
bindir = $(exec_prefix)/bin

prefix = build
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
includedir = $(prefix)/include
syslibdir = /lib

SRCS = $(sort $(wildcard src/*/*.c arch/$(ARCH)/src/*.c))
OBJS = $(SRCS:.c=.o)
LOBJS = $(OBJS:.o=.lo)
GENH = include/bits/alltypes.h
GENH_INT = src/internal/version.h
IMPH = src/internal/stdio_impl.h src/internal/pthread_impl.h src/internal/libc.h
CFLAGS_C99FSE = -std=c99 -ffreestanding -nostdinc 

CFLAGS_ALL = $(CFLAGS_C99FSE)
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I./arch/$(ARCH) -I./src/internal -I./include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS)
CFLAGS_ALL_STATIC = $(CFLAGS_ALL)
CFLAGS_ALL_SHARED = $(CFLAGS_ALL) -fPIC -DSHARED

AR      = $(ALC_CROSS_PREFIX)ar
RANLIB  = $(ALC_CROSS_PREFIX)ranlib

INSTALL = ./tools/install.sh

ARCH_INCLUDES = $(wildcard arch/$(ARCH)/bits/*.h)
ALL_INCLUDES = $(sort $(wildcard include/*.h include/*/*.h) $(GENH) $(ARCH_INCLUDES:arch/$(ARCH)/%=include/%))

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=lib/lib%.a)
CRT_LIBS = lib/crt1.o lib/Scrt1.o lib/crti.o lib/crtn.o
STATIC_LIBS = lib/libc.a
SHARED_LIBS = lib/libc.so
TOOL_LIBS = lib/alireza-gcc.specs
ALL_LIBS = $(CRT_LIBS) $(STATIC_LIBS) $(SHARED_LIBS) $(EMPTY_LIBS) $(TOOL_LIBS)
ALL_TOOLS = tools/alireza-gcc

LDSO_PATHNAME = $(syslibdir)/ld-alireza-$(ARCH)$(SUBARCH).so.1

CC = $(ALC_CROSS_PREFIX)gcc
CFLAGS = -Os -pipe -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables -Wa,--noexecstack -Werror=implicit-function-declaration -Werror=implicit-int -Werror=pointer-sign -Werror=pointer-arith -fno-stack-protector 
CFLAGS_C99FSE = -std=c99 -nostdinc -ffreestanding -fexcess-precision=standard -frounding-math
CFLAGS_MEMOPS = -fno-tree-loop-distribute-patterns
LDFLAGS = -Wl,--hash-style=both
LIBCC = -lgcc -lgcc_eh
OPTIMIZE_GLOBS = internal/*.c malloc/*.c string/*.c


all: $(ALL_LIBS) $(ALL_TOOLS)

install: install-libs install-headers install-tools

clean:
	rm -f crt/*.o
	rm -f $(OBJS)
	rm -f $(LOBJS)
	rm -f $(ALL_LIBS) lib/*.[ao] lib/*.so
	rm -f $(ALL_TOOLS)
	rm -f $(GENH) $(GENH_INT)
	rm -f include/bits

include/bits:
	@ln -sf ../arch/$(ARCH)/bits $@

include/bits/alltypes.h.in: include/bits

include/bits/alltypes.h: include/bits/alltypes.h.in include/alltypes.h.in tools/mkalltypes.sed
	@sed -f tools/mkalltypes.sed include/bits/alltypes.h.in include/alltypes.h.in > $@

src/internal/version.h: $(wildcard VERSION .git)
	@echo "\tGEN " $@
	@printf '#define VERSION "%s"\n' "$$(sh tools/version.sh)" > $@

src/internal/version.lo: src/internal/version.h

src/ldso/dynlink.lo: arch/$(ARCH)/reloc.h

crt/crt1.o crt/Scrt1.o: $(wildcard arch/$(ARCH)/crt_arch.h)

crt/Scrt1.o: CFLAGS += -fPIC

OPTIMIZE_SRCS = $(wildcard $(OPTIMIZE_GLOBS:%=src/%))
$(OPTIMIZE_SRCS:%.c=%.o) $(OPTIMIZE_SRCS:%.c=%.lo): CFLAGS += -O3

MEMOPS_SRCS = src/string/memcpy.c src/string/memmove.c src/string/memcmp.c src/string/memset.c
$(MEMOPS_SRCS:%.c=%.o) $(MEMOPS_SRCS:%.c=%.lo): CFLAGS += $(CFLAGS_MEMOPS)

# This incantation ensures that changes to any subarch asm files will
# force the corresponding object file to be rebuilt, even if the implicit
# rule below goes indirectly through a .sub file.
define mkasmdep
$(dir $(patsubst %/,%,$(dir $(1))))$(notdir $(1:.s=.o)): $(1)
endef
$(foreach s,$(wildcard src/*/$(ARCH)*/*.s),$(eval $(call mkasmdep,$(s))))

%.o: $(ARCH)$(ASMSUBARCH)/%.sub
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $(dir $<)$(shell cat $<)
%.o: $(ARCH)/%.s
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $<
%.o: %.c $(GENH) $(IMPH)
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $<
%.lo: $(ARCH)$(ASMSUBARCH)/%.sub
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $(dir $<)$(shell cat $<)
%.lo: $(ARCH)/%.s
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $<
%.lo: %.c $(GENH) $(IMPH)
	@echo "\tCC " $@
	@$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $<
lib/libc.so: $(LOBJS)
	@echo "\tLD " $@
	@$(CC) $(CFLAGS_ALL_SHARED) $(LDFLAGS) -nostdlib -shared \
	-Wl,-e,_dlstart -Wl,-Bsymbolic-functions \
	-o $@ $(LOBJS) $(LIBCC)

lib/libc.a: $(OBJS)
	@rm -f $@
	@echo "\tAR " $@
	@$(AR) rc $@ $(OBJS)
	@echo "\tRANLIB " $@
	@$(RANLIB) $@

$(EMPTY_LIBS):
	@echo "\tRM " $@
	@rm -f $@
	@echo "\tAR " $@
	@$(AR) rc $@

lib/%.o: crt/%.o
	@echo "\tCP " $< $@
	@cp $< $@

lib/alireza-gcc.specs: tools/alireza-gcc.specs.sh
	@echo "\tGEN " $@
	@sh $< "$(includedir)" "$(libdir)" "$(LDSO_PATHNAME)" > $@

tools/alireza-gcc:
	@echo "\tGEN " $@
	@printf '#!/bin/sh\nexec %sgcc "$$@" -specs "%s/alireza-gcc.specs"\n' $(ALC_CROSS_PREFIX) "$(libdir)" > $@
	@chmod +x $@
	@export PATH=${PATH}:$(bindir)

%_defconfig:
	@echo "* Loading default configurations of " $@
	@cp configs/$@ .config

menuconfig:
	@./tools/mconf Main.conf

$(DESTDIR)$(bindir)/%: tools/%
	@$(INSTALL) -D $< $@

$(DESTDIR)$(libdir)/%.so: lib/%.so
	@$(INSTALL) -D -m 755 $< $@

$(DESTDIR)$(libdir)/%: lib/%
	@$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: arch/$(ARCH)/bits/%
	@$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/%: include/%
	@$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(LDSO_PATHNAME): $(DESTDIR)$(libdir)/libc.so
	@$(INSTALL) -D -l $(libdir)/libc.so $@ || true

install-libs: $(ALL_LIBS:lib/%=$(DESTDIR)$(libdir)/%) $(if $(SHARED_LIBS),$(DESTDIR)$(LDSO_PATHNAME),)

install-headers: $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%)

install-tools: $(ALL_TOOLS:tools/%=$(DESTDIR)$(bindir)/%)

release: all
	tar cf AlirezaLibC-$(VERSION).tar build

.PRECIOUS: $(CRT_LIBS:lib/%=crt/%)

.PHONY: all clean install install-libs install-headers install-tools
