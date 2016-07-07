#-----------------------------------------------------------------
# base _directories
#-----------------------------------------------------------------
base_dir = $(shell pwd)

# directories for building Win64 executable
src_dir = $(base_dir)/source
c_src_dir = $(base_dir)/source/c
obj_dir = $(base_dir)/obj
bin_dir = $(base_dir)/bin
lib_dir = $(base_dir)/lib
views_dir = $(base_dir)/views
data_dir = ~/data

# PostGreSQL include path
pg_include = $(HOME)/PostgreSQL/pg95/include

#-----------------------------------------------------------------
# libraries
#-----------------------------------------------------------------
sqlite_libpath = /usr/lib

#-----------------------------------------------------------------
# build list of items
#-----------------------------------------------------------------
# list of all sources without path
sources_name=$(shell find . -name '*.d' -exec basename {} +)
#
# list of all sources including path
sources_path=$(shell find . -name '*.d')

# list of all objects to build
objects = $(addprefix $(obj_dir)/,$(sources_name:.d=.o))

#-----------------------------------------------------------------
# DMD & GCC compiler & linker flags
#-----------------------------------------------------------------
DFLAGS = -w -c -m64 -I$(src_dir) -J$(views_dir) -J$(data_dir)/local/conf -version=postgres -vcolumns
LDFLAGS = -L-L$(sqlite_libpath) -L-L$(lib_dir) -L-lsqlite3 -L-lrbfpg -L-lpq
CFLAGS = -c -I$(pg_include)


#-----------------------------------------------------------------
# readrbf objects rules
#-----------------------------------------------------------------
readrbf:
	gcc $(CFLAGS) $(c_src_dir)/rbfpg.c -o $(obj_dir)/rbfpg.o
	ar crv $(lib_dir)/librbfpg.a $(obj_dir)/rbfpg.o
	dmd $(DFLAGS) $(sources_path) -od$(obj_dir)
	dmd -of$(bin_dir)/readrbf $(objects) $(LDFLAGS)

rbflib:

#-----------------------------------------------------------------
# cleanup 
#-----------------------------------------------------------------
clean:
	del $(obj_dir)/*.o

#-----------------------------------------------------------------
# useful trick to print out variable value
#-----------------------------------------------------------------
print-%  : ; @echo $* = $($*)
