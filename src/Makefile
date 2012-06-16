PKGNAME=megaser
APP_NAME=megaser

ECHO = echo
Q    = @

ERL         = /usr/bin/erl
ERLC        = /usr/bin/erlc
EBIN_DIR    = ../ebin

EMULATOR := beam

ERL_SOURCES := $(./)
ERL_HEADERS := $(*.hrl)
ERL_OBJECTS := $(ERL_SOURCES:%.erl=$(EBIN_DIR)/%.beam)

EBIN_FILES = $(ERL_OBJECTS)


all:
		$(ERLC) -o $(EBIN_DIR)  *.erl 

# -buper_bin  for uPER

debug:
	$(MAKE) DEBUG=-DDEBUG

clean:
	rm -rf $(EBIN_FILES)

