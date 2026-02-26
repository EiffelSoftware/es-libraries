/*
 * csprng_impl.h - Platform-specific cryptographically secure random generation
 * 
 * Provides cross-platform CSPRNG functions:
 * - Windows: BCryptGenRandom (CNG API)
 * - Unix/Linux/macOS: /dev/urandom
 * - OpenBSD: arc4random_buf (recommended by OpenBSD)
 * 
 * Both functions are always defined. On unsupported platforms, they return
 * CSPRNG_ERR_UNSUPPORTED to allow compile-time inclusion of all code.
 * 
 * Security: On any error, the output buffer is zeroed to prevent
 * information leakage (inspired by mackron/cryptorand best practices).
 * 
 * Author: EiffelPDF
 * Date: 2026-01-26
 */

#ifndef CSPRNG_IMPL_H
#define CSPRNG_IMPL_H

#include <stddef.h>
#include <string.h>  /* For memset */

/* MSVC C compiler compatibility: MSVC uses __inline instead of inline for C */
#if defined(_MSC_VER) && !defined(__cplusplus)
#define CSPRNG_INLINE static __inline
#else
#define CSPRNG_INLINE static inline
#endif

/* Error codes */
#define CSPRNG_OK              0
#define CSPRNG_ERR_OPEN       -1
#define CSPRNG_ERR_READ       -2
#define CSPRNG_ERR_API        -3
#define CSPRNG_ERR_UNSUPPORTED -4
#define CSPRNG_ERR_TOO_BIG    -5

/* Security helper: Zero memory on error */
#define CSPRNG_ZERO_BUFFER(buf, size) do { if ((buf) != NULL && (size) > 0) memset((buf), 0, (size)); } while(0)

/* Platform detection */
#if defined(_WIN32)
#define CSPRNG_WIN32
#elif defined(__OpenBSD__)
#define CSPRNG_ARC4RANDOM
#elif defined(__linux__) || defined(__APPLE__) || defined(__DragonFly__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__ANDROID__)
#define CSPRNG_URANDOM
#endif

#ifdef CSPRNG_WIN32

/* ============================================================
 * WINDOWS PLATFORM
 * ============================================================ */
#include <windows.h>
#include <bcrypt.h>

#ifndef NT_SUCCESS
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0)
#endif

/* Windows: Real implementation using BCryptGenRandom */
CSPRNG_INLINE int csprng_fill_bytes_win32(unsigned char *buffer, size_t size) {
    NTSTATUS status;
    
    if (buffer == NULL || size == 0) {
        return CSPRNG_OK;
    }
    
    /* Windows BCryptGenRandom uses ULONG for size (4 bytes max) */
    if (size > 0xFFFFFFFFUL) {
        CSPRNG_ZERO_BUFFER(buffer, size);
        return CSPRNG_ERR_TOO_BIG;
    }
    
    status = BCryptGenRandom(
        NULL,
        buffer,
        (ULONG)size,
        BCRYPT_USE_SYSTEM_PREFERRED_RNG
    );
    
    if (NT_SUCCESS(status)) {
        return CSPRNG_OK;
    }
    
    /* Zero buffer on failure for security */
    CSPRNG_ZERO_BUFFER(buffer, size);
    return CSPRNG_ERR_API;
}

/* Windows: Stub for urandom (not supported) */
CSPRNG_INLINE int csprng_fill_bytes_urandom(unsigned char *buffer, size_t size) {
    (void)buffer;
    (void)size;
    return CSPRNG_ERR_UNSUPPORTED;
}

#elif defined(CSPRNG_ARC4RANDOM)

/* ============================================================
 * OPENBSD PLATFORM (arc4random_buf)
 * OpenBSD recommends arc4random over /dev/urandom
 * ============================================================ */
#include <stdlib.h>

/* OpenBSD: arc4random_buf is always successful and never blocks */
CSPRNG_INLINE int csprng_fill_bytes_urandom(unsigned char *buffer, size_t size) {
    if (buffer == NULL || size == 0) {
        return CSPRNG_OK;
    }
    
    arc4random_buf(buffer, size);
    return CSPRNG_OK;
}

/* OpenBSD: Stub for BCrypt (not supported) */
CSPRNG_INLINE int csprng_fill_bytes_win32(unsigned char *buffer, size_t size) {
    (void)buffer;
    (void)size;
    return CSPRNG_ERR_UNSUPPORTED;
}

#elif defined(CSPRNG_URANDOM)

/* ============================================================
 * UNIX/LINUX/MACOS PLATFORM
 * ============================================================ */
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>  /* For EINTR handling */

/* Linux 3.17+ supports getrandom() syscall - more secure than /dev/urandom */
#if defined(__linux__) && defined(__GLIBC__) && (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 25))
#define CSPRNG_HAS_GETRANDOM
#include <sys/random.h>
#endif

/* Unix: Real implementation using getrandom() or /dev/urandom fallback */
CSPRNG_INLINE int csprng_fill_bytes_urandom(unsigned char *buffer, size_t size) {
    ssize_t bytes_read;
    size_t total_read = 0;
    
    if (buffer == NULL || size == 0) {
        return CSPRNG_OK;
    }
    
#ifdef CSPRNG_HAS_GETRANDOM
    /* Use getrandom() syscall on modern Linux - no file descriptor needed */
    while (total_read < size) {
        /* GRND_NONBLOCK would fail if entropy pool isn't ready; we use blocking mode */
        bytes_read = getrandom(buffer + total_read, size - total_read, 0);
        if (bytes_read < 0) {
            if (errno == EINTR)
                continue;  /* Retry on signal interrupt */
            /* For other errors, fall through to /dev/urandom */
            break;
        }
        total_read += (size_t)bytes_read;
    }
    if (total_read == size) {
        return CSPRNG_OK;
    }
    /* Reset for /dev/urandom fallback */
    total_read = 0;
#endif
    
    /* Fallback: /dev/urandom */
    {
        int fd = open("/dev/urandom", O_RDONLY);
        if (fd < 0) {
            CSPRNG_ZERO_BUFFER(buffer, size);
            return CSPRNG_ERR_OPEN;
        }
        
        while (total_read < size) {
            bytes_read = read(fd, buffer + total_read, size - total_read);
            if (bytes_read <= 0) {
                close(fd);
                CSPRNG_ZERO_BUFFER(buffer, size);
                return CSPRNG_ERR_READ;
            }
            total_read += (size_t)bytes_read;
        }
        
        close(fd);
    }
    
    return CSPRNG_OK;
}

/* Unix: Stub for BCrypt (not supported) */
CSPRNG_INLINE int csprng_fill_bytes_win32(unsigned char *buffer, size_t size) {
    (void)buffer;
    (void)size;
    return CSPRNG_ERR_UNSUPPORTED;
}

#else

/* ============================================================
 * UNSUPPORTED PLATFORM
 * ============================================================ */

CSPRNG_INLINE int csprng_fill_bytes_urandom(unsigned char *buffer, size_t size) {
    (void)buffer;
    (void)size;
    return CSPRNG_ERR_UNSUPPORTED;
}

CSPRNG_INLINE int csprng_fill_bytes_win32(unsigned char *buffer, size_t size) {
    (void)buffer;
    (void)size;
    return CSPRNG_ERR_UNSUPPORTED;
}

#endif /* Platform selection */

#endif /* CSPRNG_IMPL_H */
