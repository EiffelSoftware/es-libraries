TOP = ..
DIR = $dir_sep
OUTDIR= .
INDIR= .
CC = $cc
OUTPUT_CMD = $output_cmd
CFLAGS = -I"$rt_include" -I. -I..$(DIR)spec$(DIR)include -D_UNICODE -DUNICODE
JCFLAGS = $(CFLAGS) $optimize $ccflags
JMTCFLAGS = $(CFLAGS) $optimize $mtccflags 
JILCFLAGS = $(CFLAGS) $optimize $mtccflags  -DEIF_IL_DLL
LN = copy
MV = $mv
RM = $del
MAKE = $make
MKDIR = $mkdir
OBJECTS = eif_webview2.$obj
MT_OBJECTS = MTeif_webview2.$obj

.c.$obj:
	$(CC) -c $(JCFLAGS) $<

all:: $output_libraries
	$(MAKE) clean

standard:: eif_webview2.lib
mtstandard:: mteif_webview2.lib

clean:
	$(RM) *.$obj
	$(RM) *.lib

eif_webview2.lib: $(OBJECTS)
	$alib_line
	$(MKDIR) ..$(DIR)spec$(DIR)$(ISE_C_COMPILER)$(DIR)$(ISE_PLATFORM)$(DIR)lib
	$(MV) $@ ..$(DIR)spec$(DIR)$(ISE_C_COMPILER)$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)$@

mteif_webview2.lib: $(MT_OBJECTS)
	$alib_line
	$(MKDIR) ..$(DIR)spec$(DIR)$(ISE_C_COMPILER)$(DIR)$(ISE_PLATFORM)$(DIR)lib
	$(MV) $@ ..$(DIR)spec$(DIR)$(ISE_C_COMPILER)$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)$@

#Multithreaded targets.
MTeif_webview2.$obj: eif_webview2.c
	$(CC) $(JMTCFLAGS) $(OUTPUT_CMD)$@ -c $?
