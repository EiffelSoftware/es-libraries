TOP = ..
DIR = $dir_sep
OUTDIR= .
INDIR= .
LN = copy
MV = $mv
RM = $del
MAKE = $make
MKDIR = $mkdir

all:: dynamic static

# Note: create the spec folders after build_dyn_*.bat, as it removes the spec folder
# (otherwise the dlls are copied into a single file named "bin").
dynamic:
	echo Compiling dynamic openssl for $(ISE_PLATFORM)
	if $(ISE_PLATFORM) EQU win64 build_dyn_64.bat
	if $(ISE_PLATFORM) EQU windows build_dyn_32.bat
	$(MKDIR) spec$(DIR)$(ISE_PLATFORM)$(DIR)bin
	$(MKDIR) spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)dynamic
	if $(ISE_PLATFORM) EQU win64 $(MV) builds$(DIR)dynamic_64$(DIR)bin$(DIR)*.dll spec$(DIR)$(ISE_PLATFORM)$(DIR)bin  
	if $(ISE_PLATFORM) EQU win64 $(MV) builds$(DIR)dynamic_64$(DIR)lib$(DIR)*.lib spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)dynamic
	if $(ISE_PLATFORM) EQU windows $(MV) builds$(DIR)dynamic_32$(DIR)bin$(DIR)*.dll spec$(DIR)$(ISE_PLATFORM)$(DIR)bin  
	if $(ISE_PLATFORM) EQU windows $(MV) builds$(DIR)dynamic_32$(DIR)lib$(DIR)*.lib spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)dynamic
	echo Copy the dll into the Delivery folders...
	copy spec$(DIR)$(ISE_PLATFORM)$(DIR)bin$(DIR)*.dll $(EIFFEL_SRC)$(DIR)Delivery$(DIR)studio$(DIR)spec$(DIR)$(ISE_PLATFORM)$(DIR)bin  

static:
	echo Compiling static openssl for $(ISE_PLATFORM)
	$(MKDIR) spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)static
	if $(ISE_PLATFORM) EQU win64 build_static_64.bat
	if $(ISE_PLATFORM) EQU win64 $(MV) builds$(DIR)static_64$(DIR)lib$(DIR)*.lib spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)static
	if $(ISE_PLATFORM) EQU windows build_static_32.bat
	if $(ISE_PLATFORM) EQU windows $(MV) builds$(DIR)static_32$(DIR)lib$(DIR)*.lib spec$(DIR)$(ISE_PLATFORM)$(DIR)lib$(DIR)static

