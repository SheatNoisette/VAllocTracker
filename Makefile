CC ?= clang
V_COMPILER = $(shell which v)
V_FLAGS = -skip-unused -gc none -autofree
CFILE_OUT = out.c
CFLAGS = -O2

ifdef DEBUG
	V_FLAGS += -cg
	CFLAGS = -g3 -O0
endif

all: valloctrackerdemo

valloctrackerdemo:
	$(V_COMPILER) . $(V_FLAGS) -o $(CFILE_OUT)
	$(CC) $(CFLAGS) $(CFILE_OUT) -o valloctrackerdemo

clean:
	$(RM) -f $(CFILE_OUT) valloctrackerdemo
