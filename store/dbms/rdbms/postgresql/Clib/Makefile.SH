#!/bin/sh
# Makefile.SH for PostgreSQL EiffelStore library

case $CONFIG in
'')
	if test ! -f config.sh; then
		(echo "Can't find config.sh."; exit 1)
	fi 2>/dev/null
	. ./config.sh
	;;
esac
case "$O" in
*strdup*)
	;;
*)
	;;
esac

echo "Extracting Makefile (with stripping of C-code in Makefile.SH)..."

$spitshell >Makefile <<!GSTRUNC!

SHELL = /bin/sh
CC = $cc
CFLAGS = $optimize $ccflags $large -I$rt_include -I. \`${ISE_LIBRARY}/library/store/dbms/rdbms/postgresql/Clib/pg-config --cflags\`
LDFLAGS = $ldflags
LIBS = $libs
MAKE = make
MKDEP = $mkdep \$(DPFLAGS) --
MV = $mv
RM = $rm -f
RANLIB = $ranlib
AR = $ar

.c.o:
	\$(CC) -c \$(CFLAGS) \$<

OBJECTS = eif_postgresql.o

postgresql_store.a: \$(OBJECTS)
	\$(RM) \$@
	\$(AR) cr \$@ \$(OBJECTS)
	\$(RANLIB) \$@

clean:
	\$(RM) *.o *.a

!GSTRUNC!
