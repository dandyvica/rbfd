#-----------------------------------------------------------------
# base _directories
#-----------------------------------------------------------------
base_dir = $(shell pwd)

# directories for building Win64 executable
src_dir = $(base_dir)\source
obj_dir = $(base_dir)\obj
bin_dir = $(base_dir)\bin
views_dir = $(base_dir)\views
data_dir = \dev\data

# list of all sources
sources=$(shell dir /s /b *.d)
#d_files = $(notdir $(sources))
objects = $(sources:.d=.obj)
#objects = $(addprefix $(obj_dir)\,$(obj_files))

#-----------------------------------------------------------------
# DMD compiler flags
#-----------------------------------------------------------------
DFLAGS = -w -c -m64 -I$(src_dir) -J$(views_dir) -J$(data_dir)\local\conf

LDFLAGS = -L--no-as-needed -L-L$(sqlite_libpath) -L-L$(rbflib_lib_dir) -L-lsqlite3 -L-lrbf

#-----------------------------------------------------------------
# readrbf objects rules
#-----------------------------------------------------------------
$(objdir)\%.obj: (src_dir)\%.d
	dmd $(DFLAGS) $< -od$(obj_dir)


all: $(objects)

#-----------------------------------------------------------------
# useful trick to print out variable value
#-----------------------------------------------------------------
clean:
	del $(obj_dir)\*.obj

#-----------------------------------------------------------------
# useful trick to print out variable value
#-----------------------------------------------------------------
print-%  : ; @echo $* = $($*)
