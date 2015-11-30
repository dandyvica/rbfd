#-----------------------------------------------------------------
# base directories
#-----------------------------------------------------------------
basedir = $(shell pwd)
srcdir = $(basedir)/source/rbf
objdir = $(basedir)/obj
exedir = $(basedir)/bin
libdir = $(basedir)/lib
importdir = $(basedir)/views
docdir = $(basedir)/doc
incdir = $(basedir)/source

ut_objdir = $(basedir)/temp
ut_exedir = $(basedir)/temp
mainobj = $(ut_objdir)/__main.o

# list of source files
srclist = boxwriter.d config.d csvwriter.d element.d errormsg.d field.d fieldtype.d htmlwriter.d \
		  identwriter.d layout.d log.d nameditems.d reader.d record.d recordfilter.d sqlite3writer.d \
		  tagwriter.d txtwriter.d writer.d xlsx1writer.d xlsx2writer.d xlsxformat.d xlsxwriter.d xmlwriter.d 

# platform dependant settings
# windows
ifdef COMSPEC
	targetlib = $(libdir)\rbf.lib
else
	targetlib = $(libdir)/librbf.a
endif


#-----------------------------------------------------------------
# compiler flags
#-----------------------------------------------------------------
DMDFLAGS = -w -c -I$(incdir)

#-----------------------------------------------------------------
# object modules
#-----------------------------------------------------------------
vpath %.d $(srcdir)
$(objdir)/%.o: %.d
	dmd $(DMDFLAGS) $< -od$(objdir)

#-----------------------------------------------------------------
# lib creation
#-----------------------------------------------------------------
objlist = $(patsubst %.d,%.o,$(wildcard $(srcdir)/*.d))

rbflib: $(targetlib)
$(targetlib): $(objlist)
	dmd -lib -od$(libdir) $^ -of$@

#-----------------------------------------------------------------
# other useful tags
#-----------------------------------------------------------------
clean:
	rm $(objdir)/*.o
	rm $(libdir)/rbf.lib
	rm $(ut_objdir)/*.o	
	rm $(ut_exedir)/*

#-----------------------------------------------------------------
# build documentation
#-----------------------------------------------------------------
doc:
	dmd -o- -D -Dd$(docdir) $(srcdir)/rbf/field.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/record.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/format.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/reader.d
