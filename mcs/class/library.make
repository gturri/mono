#USE_SOURCE_RULES=1
MCS = mono $(topdir)/mcs/mcs.exe
MCS_FLAGS = --target library --noconfig
INSTALL = /usr/bin/install
prefix = /usr


SOURCES_CMD=find . \
	! \( $(SOURCES_INCLUDE:%=! -path '%' ) \) -a	\
	  \( $(SOURCES_EXCLUDE:%=! -path '%' ) \) -a	\
	  ! -path '*/__*.cs'


all: .makefrag $(LIBRARY)

clean:
	-rm -rf $(LIBRARY) .response .makefrag library-deps.stamp


ifdef USE_SOURCE_RULES

.PHONY: .makefrag
.makefrag:
	@echo -n "SOURCES=" >$@
	@$(SOURCES_CMD) | tee .response | sed -e 's/$$/ \\/' >>$@

else

.response: $(LIB_LIST)
	cat $^ |egrep '\.cs$$' >$@

.makefrag: $(LIB_LIST) $(topdir)/class/library.make
	echo -n "library-deps.stamp: " >$@.new
	cat $< |egrep '\.cs$$' | sed -e 's,\.cs,.cs \\,' >>$@.new
	cat $@.new |sed -e '$$s, \\$$,,' >$@
	echo -e "\ttouch library-deps.stamp" >>$@
	rm -rf $@.new

endif

-include .makefrag

ifdef USE_SOURCE_RULES
$(LIBRARY): $(SOURCES) $(topdir)/class/library.make
else
$(LIBRARY): .response library-deps.stamp
endif
	MONO_PATH=$(MONO_PATH_PREFIX)$(MONO_PATH) $(MCS) $(MCS_FLAGS) -o $(LIBRARY) $(LIB_FLAGS) @.response

install: all
	mkdir -p $(prefix)/lib/
	$(INSTALL) -m 644 $(LIBRARY) $(prefix)/lib/

