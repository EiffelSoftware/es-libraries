LibreSSL as an alternative to OpenSSL
=====================================

The Eiffel `openssl` binding (and `net_ssl`, EWF https, `jwt_openssl`, ...) can be
linked with [LibreSSL](https://www.libressl.org/) instead of OpenSSL.
LibreSSL is built with CMake only (no Perl), and is linked statically.

Usage
-----
In the application target (ECF), set the custom variable:

	<variable name="libressl" value="true"/>

The LibreSSL headers and static libraries are then expected under:

	$(ISE_LIBRARY)/C_library/libressl/spec/$(ISE_PLATFORM)/include
	$(ISE_LIBRARY)/C_library/libressl/spec/$(ISE_PLATFORM)/lib

(see `C_library/openssl/clibs_openssl.ecf`). The variable "openssl_static" has no
effect when "libressl" is set.

Build
-----
Download a release tarball from https://www.libressl.org/ (portable version, for
instance `libressl-4.4.0.tar.gz`), extract it, and from the parent folder:

Linux / macOS (CMake, with Ninja or Make):

	cmake -S libressl-4.4.0 -B build -DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DLIBRESSL_APPS=OFF -DLIBRESSL_TESTS=OFF \
		-DCMAKE_INSTALL_PREFIX=$ISE_LIBRARY/C_library/libressl/spec/$ISE_PLATFORM
	cmake --build build
	cmake --install build

Windows: run `build.bat` (or `build.bat windows` for 32 bits). It downloads the
LibreSSL release, checks its SHA-256, and builds and installs the static libraries
(with the static C runtime `/MT`, as EiffelStudio) into `spec\%ISE_PLATFORM%`.
It requires CMake and Visual Studio with the C++ workload; no Perl is needed.
To use another LibreSSL release, update `LIBRESSL_VERSION` and `LIBRESSL_SHA256`
in the script (the SHA-256 is listed in the release `SHA256` file).

On Windows, the application is linked with `ssl.lib`, `crypto.lib`, `ws2_32.lib`,
`ntdll.lib` and `bcrypt.lib`.

Notes
-----
- Tested on Linux x86-64 with LibreSSL 4.4.0 (EWF https server, net_ssl echo example,
  openssl library tests). The Windows build script and link settings have not been tested yet.
- LibreSSL does not provide some legacy elliptic curves (for instance secp192k1),
  nor the OpenSSL secure heap (`BIO_s_secmem` falls back to `BIO_s_mem`).
