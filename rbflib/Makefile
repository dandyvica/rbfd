#-----------------------------------------------------------------
# base directories
#-----------------------------------------------------------------
basedir = $(shell pwd)
srcdir = $(basedir)/src
objdir = $(basedir)/obj
exedir = $(basedir)/bin
libdir = $(basedir)/lib
xlsimportdir = $(srcdir)/rbf/xls
docdir = $(basedir)/doc

ut_objdir = $(basedir)/unittest/obj
ut_exedir = $(basedir)/unittest/bin
mainobj = $(ut_objdir)/__main.o

#-----------------------------------------------------------------
# compiler flags
#-----------------------------------------------------------------
DFLAGS = -w -c -I$(srcdir)

#-----------------------------------------------------------------
# object modules
#-----------------------------------------------------------------
$(objdir)/field.o: $(srcdir)/rbf/field.d
	dmd $(DFLAGS) $< -od$(objdir)

$(objdir)/record.o: $(srcdir)/rbf/record.d
	dmd $(DFLAGS) $< -od$(objdir)

$(objdir)/format.o: $(srcdir)/rbf/format.d
	dmd $(DFLAGS) $< -od$(objdir)

$(objdir)/reader.o: $(srcdir)/rbf/reader.d
	dmd $(DFLAGS) $< -od$(objdir)
	
$(objdir)/writer.o: $(srcdir)/rbf/writer.d
	dmd $(DFLAGS) $< -od$(objdir)
	
$(objdir)/xlsxwriter.o: $(srcdir)/rbf/xlsxwriter.d
	dmd $(DFLAGS) -J$(xlsimportdir) $< -od$(objdir)
	
$(objdir)/args.o: $(srcdir)/util/args.d	
	dmd $(DFLAGS) -J$(xlsimportdir) $< -od$(objdir)

$(objdir)/logger.o: $(srcdir)/util/logger.d	
	dmd $(DFLAGS) -J$(xlsimportdir) $< -od$(objdir)

#-----------------------------------------------------------------
# lib creation
#-----------------------------------------------------------------
rbflib: $(libdir)/rbf.a
$(libdir)/rbf.a: $(objdir)/field.o $(objdir)/record.o $(objdir)/format.o $(objdir)/reader.o
	dmd -lib -od$(libdir) $^ -of$@

$(libdir)/util.lib: $(objdir)/args.o $(objdir)/logger.o
	dmd -lib -od$(libdir) $^ -of$@
	
rbf: $(libdir)/rbf.lib
util:$(libdir)/util.lib

#-----------------------------------------------------------------
# hot specific stuff
#-----------------------------------------------------------------
$(objdir)/hotdocument.o: $(srcdir)/hot/hotdocument.d
	dmd $(DFLAGS) $< -od$(objdir)

$(objdir)/overpunch.o: $(srcdir)/hot/overpunch.d
	dmd $(DFLAGS) $< -od$(objdir)

$(objdir)/readhot.o: $(srcdir)/hot/readhot.d
	dmd $(DFLAGS) $< -od$(objdir)

#-----------------------------------------------------------------
# readhot
#-----------------------------------------------------------------
$(exedir)/readhot: $(objdir)/readhot.o $(objdir)/overpunch.o $(objdir)/hotdocument.o $(libdir)/rbf.a
	dmd  $^ -of$@

readhot: $(exedir)/readhot



#-----------------------------------------------------------------
# unit test construction
#-----------------------------------------------------------------
utfield: $(ut_exedir)/utfield
utrecord: $(ut_exedir)/utrecord
utformat: $(ut_exedir)/utformat
utreader: $(ut_exedir)/utreader
utwriter: $(ut_exedir)/utwriter

$(ut_exedir)/utfield: $(ut_objdir)/field.o
	dmd $(mainobj) $^ -of$@

$(ut_exedir)/utrecord: $(objdir)/field.o $(ut_objdir)/record.o
	dmd $(mainobj) $^ -of$@
	
$(ut_exedir)/utformat: $(objdir)/field.o $(objdir)/record.o $(ut_objdir)/format.o
	dmd $(mainobj) $^ -of$@
	
$(ut_exedir)/utreader: $(objdir)/field.o $(objdir)/record.o $(objdir)/format.o $(ut_objdir)/reader.o
	dmd $(mainobj) $^ -of$@

$(ut_exedir)/utwriter: $(objdir)/field.o $(objdir)/record.o $(objdir)/format.o $(objdir)/reader.o $(ut_objdir)/writer.o
	dmd $(mainobj) $^ -of$@
#-----------------------------------------------------------------
# unit test object modules
#-----------------------------------------------------------------
$(ut_objdir)/field.o: $(srcdir)/rbf/field.d	
	dmd $(DFLAGS) -main -unittest $< -od$(ut_objdir)
	
$(ut_objdir)/record.o: $(srcdir)/rbf/record.d	
	dmd $(DFLAGS) -main -unittest $< -od$(ut_objdir)
	
$(ut_objdir)/format.o: $(srcdir)/rbf/format.d	
	dmd $(DFLAGS) -main -unittest $< -od$(ut_objdir)
	
$(ut_objdir)/reader.o: $(srcdir)/rbf/reader.d	
	dmd $(DFLAGS) -main -unittest $< -od$(ut_objdir)
	
$(ut_objdir)/writer.o: $(srcdir)/rbf/writer.d	
	dmd $(DFLAGS) -main -unittest $< -od$(ut_objdir)
	

#-----------------------------------------------------------------
# other useful tags
#-----------------------------------------------------------------
clean:
	rm $(objdir)/*.o
	rm $(libdir)/rbf.lib
	rm $(ut_objdir)/*.o	
	rm $(ut_exedir)/*

utclean:
	rm $(basedir)/unittest/obj/*.o
	rm $(basedir)/unittest/bin/*

#-----------------------------------------------------------------
# build documentation
#-----------------------------------------------------------------
doc:
	dmd -o- -D -Dd$(docdir) $(srcdir)/rbf/field.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/record.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/format.d
	dmd -o- -I$(srcdir) -D -Dd$(docdir) $(srcdir)/rbf/reader.d
