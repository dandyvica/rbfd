#-----------------------------------------------------------------
# base _directories
#-----------------------------------------------------------------
base_dir = $(shell pwd)
data_dir = ~/data

# directories for lib
rbflib_dir = $(base_dir)/rbf
rbflib_src_dir = $(rbflib_dir)/source
rbflib_obj_dir = $(rbflib_dir)/obj
rbflib_bin_dir = $(rbflib_dir)/bin
rbflib_lib_dir = $(rbflib_dir)/lib
rbflib_views_dir = $(rbflib_dir)/views

# directories for bin
readrbf_dir = $(base_dir)/readrbf
readrbf_src_dir = $(readrbf_dir)/source
readrbf_obj_dir = $(readrbf_dir)/obj
readrbf_bin_dir = $(readrbf_dir)/bin
readrbf_views_dir = $(readrbf_dir)/views

# directories for bin
package_dir = $(readrbf_dir)/package
$(shell mkdir -p $(readrbf_dir)/package)

#-----------------------------------------------------------------
# DMD compiler flags
#-----------------------------------------------------------------
DFLAGS = -w -c -I$(rbflib_src_dir) -J$(rbflib_views_dir) -J$(readrbf_views_dir)

sqlite_libpath = /usr/lib/x86_64-linux-gnu
LDFLAGS = -L--no-as-needed -L-L$(sqlite_libpath) -L-L$(rbflib_lib_dir) -L-lsqlite3 -L-lrbf

#-----------------------------------------------------------------
# rbflib objects rules
#-----------------------------------------------------------------
$(rbflib_obj_dir)/config.o: $(rbflib_src_dir)/rbf/config.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/element.o: $(rbflib_src_dir)/rbf/element.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/errormsg.o: $(rbflib_src_dir)/rbf/errormsg.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/field.o: $(rbflib_src_dir)/rbf/field.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/fieldtype.o: $(rbflib_src_dir)/rbf/fieldtype.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/layout.o: $(rbflib_src_dir)/rbf/layout.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/log.o: $(rbflib_src_dir)/rbf/log.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/nameditems.o: $(rbflib_src_dir)/rbf/nameditems.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/reader.o: $(rbflib_src_dir)/rbf/reader.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/record.o: $(rbflib_src_dir)/rbf/record.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/recordfilter.o: $(rbflib_src_dir)/rbf/recordfilter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/boxwriter.o: $(rbflib_src_dir)/rbf/writers/boxwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/csvwriter.o: $(rbflib_src_dir)/rbf/writers/csvwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/htmlwriter.o: $(rbflib_src_dir)/rbf/writers/htmlwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/identwriter.o: $(rbflib_src_dir)/rbf/writers/identwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/sqlite3writer.o: $(rbflib_src_dir)/rbf/writers/sqlite3writer.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/tagwriter.o: $(rbflib_src_dir)/rbf/writers/tagwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/txtwriter.o: $(rbflib_src_dir)/rbf/writers/txtwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/writer.o: $(rbflib_src_dir)/rbf/writers/writer.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/xlsx1writer.o: $(rbflib_src_dir)/rbf/writers/xlsx1writer.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/xlsx2writer.o: $(rbflib_src_dir)/rbf/writers/xlsx2writer.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/xlsxformat.o: $(rbflib_src_dir)/rbf/writers/xlsxformat.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/xlsxwriter.o: $(rbflib_src_dir)/rbf/writers/xlsxwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)

$(rbflib_obj_dir)/xmlwriter.o: $(rbflib_src_dir)/rbf/writers/xmlwriter.d
	dmd $(DFLAGS) $< -od$(rbflib_obj_dir)


#-----------------------------------------------------------------
# lib rule for creating librbf.a
#-----------------------------------------------------------------
rbflib: $(rbflib_lib_dir)/librbf.a

$(rbflib_lib_dir)/librbf.a: \
	$(rbflib_obj_dir)/config.o \
	$(rbflib_obj_dir)/element.o \
	$(rbflib_obj_dir)/errormsg.o \
	$(rbflib_obj_dir)/field.o \
	$(rbflib_obj_dir)/fieldtype.o \
	$(rbflib_obj_dir)/layout.o \
	$(rbflib_obj_dir)/log.o \
	$(rbflib_obj_dir)/nameditems.o \
	$(rbflib_obj_dir)/reader.o \
	$(rbflib_obj_dir)/record.o \
	$(rbflib_obj_dir)/recordfilter.o \
	$(rbflib_obj_dir)/boxwriter.o \
	$(rbflib_obj_dir)/csvwriter.o \
	$(rbflib_obj_dir)/htmlwriter.o \
	$(rbflib_obj_dir)/identwriter.o \
	$(rbflib_obj_dir)/sqlite3writer.o \
	$(rbflib_obj_dir)/tagwriter.o \
	$(rbflib_obj_dir)/txtwriter.o \
	$(rbflib_obj_dir)/writer.o \
	$(rbflib_obj_dir)/xlsx1writer.o \
	$(rbflib_obj_dir)/xlsx2writer.o \
	$(rbflib_obj_dir)/xlsxformat.o \
	$(rbflib_obj_dir)/xlsxwriter.o \
	$(rbflib_obj_dir)/xmlwriter.o 
	dmd -lib -od$(rbflib_lib_dir) $^ -of$@

#-----------------------------------------------------------------
# main rule for creating readrbf
#-----------------------------------------------------------------
readrbf: $(readrbf_bin_dir)/readrbf

$(readrbf_bin_dir)/readrbf: \
	$(readrbf_obj_dir)/app.o \
	$(readrbf_obj_dir)/args.o \
	$(rbflib_lib_dir)/librbf.a
	dmd $(LDFLAGS) -od$(readrbf_bin_dir) $(readrbf_obj_dir)/app.o $(readrbf_obj_dir)/args.o -of$@

$(readrbf_obj_dir)/app.o: $(readrbf_src_dir)/app.d
	dmd $(DFLAGS) -I$(readrbf_src_dir)/readrbf $< -od$(readrbf_obj_dir)

$(readrbf_obj_dir)/args.o: $(rbflib_views_dir)/help.txt $(readrbf_src_dir)/readrbf/args.d 
	dmd $(DFLAGS) -I$(readrbf_src_dir) $(readrbf_src_dir)/readrbf/args.d -od$(readrbf_obj_dir)

$(rbflib_views_dir)/help.txt: $(readrbf_src_dir)/doc/help.md
	pandoc -s -t man $< -o $(rbflib_views_dir)/help.1
	man $(rbflib_views_dir)/help.1 | col -b > $@
	rm $(rbflib_views_dir)/help.1

#-----------------------------------------------------------------
# other useful tags
#-----------------------------------------------------------------
clean:
	rm $(rbflib_obj_dir)/*.*
	rm $(readrbf_obj_dir)/*.*
	rm $(rbflib_lib_dir)/*.*
	rm $(readrbf_bin_dir)/*.*

#-----------------------------------------------------------------
# build documentation
#-----------------------------------------------------------------
doc:
	dmd -o- -D -Dd$(doc_dir) $(src_dir)/rbf/field.d
	dmd -o- -I$(src_dir) -D -Dd$(doc_dir) $(src_dir)/rbf/record.d
	dmd -o- -I$(src_dir) -D -Dd$(doc_dir) $(src_dir)/rbf/format.d
	dmd -o- -I$(src_dir) -D -Dd$(doc_dir) $(src_dir)/rbf/reader.d
