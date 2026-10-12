/*
 * DEFLATE/ZLIB Implementation (RFC 1951/1950)
 * C wrapper for EiffelPDF using system zlib library
 * 
 * Decompression: Custom implementation supporting stored, fixed, and dynamic Huffman
 * Compression: Uses system zlib compress2() for real compression
 */

#ifndef ZLIB_IMPL_H
#define ZLIB_IMPL_H

#include <stdlib.h>
#include <string.h>
#include <zlib.h>  /* System zlib for real compression */

/* Type definitions */
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

/* Error codes (negative values indicate errors) */
#define ZLIB_OK               0    /* Success (used for validation) */
#define ZLIB_ERR_BUFFER      -1    /* Output buffer too small */
#define ZLIB_ERR_DATA        -2    /* Corrupt or invalid compressed data */
#define ZLIB_ERR_HEADER      -3    /* Invalid ZLIB header */
#define ZLIB_ERR_BLOCK       -4    /* Invalid block type or structure */
#define ZLIB_ERR_INPUT       -5    /* Insufficient input data */

/* Maximum code lengths */
#define MAXBITS 15
#define MAXLCODES 286
#define MAXDCODES 30
#define MAXCODES (MAXLCODES + MAXDCODES)
#define FIXLCODES 288

/* Length and distance base values and extra bits (RFC 1951) */
static const u16 lens[29] = {
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
    35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
};
static const u16 lext[29] = {
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
};
static const u16 dists[30] = {
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
    257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
    8193, 12289, 16385, 24577
};
static const u16 dext[30] = {
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
    7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
};

/* Order of code length alphabet */
static const u16 order[19] = {
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
};

/* Huffman decoding structure */
typedef struct {
    u16 count[MAXBITS + 1];   /* Count of codes per length */
    u16 symbol[MAXCODES];     /* Canonically ordered symbols */
} Huffman;

/* Bit stream state */
typedef struct {
    const u8 *in;     /* Input buffer */
    int in_len;       /* Input length */
    int in_pos;       /* Current byte position */
    u32 bit_buf;      /* Bit buffer */
    int bit_cnt;      /* Number of bits in buffer */
    u8 *out;          /* Output buffer */
    int out_len;      /* Output buffer size */
    int out_pos;      /* Current output position */
    int err;          /* Error flag */
} ZState;

/* Read bits from input */
static u32 zlib_bits(ZState *s, int n) {
    u32 val;
    
    while (s->bit_cnt < n) {
        if (s->in_pos >= s->in_len) {
            s->err = ZLIB_ERR_INPUT;
            return 0;
        }
        s->bit_buf |= ((u32)s->in[s->in_pos++]) << s->bit_cnt;
        s->bit_cnt += 8;
    }
    
    val = s->bit_buf & ((1u << n) - 1);
    s->bit_buf >>= n;
    s->bit_cnt -= n;
    return val;
}

/* Decode symbol using Huffman table -- using puff.c algorithm */
static int zlib_decode(ZState *s, const Huffman *h) {
    int len;            /* current number of bits in code */
    int code;           /* len bits being decoded */
    int first;          /* first code of length len */
    int count;          /* number of codes of length len */
    int index;          /* index of first code of length len in symbol table */

    code = first = index = 0;
    for (len = 1; len <= MAXBITS; len++) {
        code |= zlib_bits(s, 1);        /* get next bit */
        if (s->err) return -1;
        count = h->count[len];
        if (code - count < first)       /* if length len, return symbol */
            return h->symbol[index + (code - first)];
        index += count;                 /* else update for next length */
        first += count;
        first <<= 1;
        code <<= 1;
    }
    s->err = 1;
    return -1;                          /* ran out of codes */
}

/* Build Huffman table from code lengths */
static int zlib_construct(Huffman *h, const u16 *lengths, int n) {
    int i, symbol, len;
    u16 offs[MAXBITS + 1];
    
    /* Count codes of each length */
    for (len = 0; len <= MAXBITS; len++)
        h->count[len] = 0;
    for (symbol = 0; symbol < n; symbol++)
        h->count[lengths[symbol]]++;
    
    /* Check for invalid code set */
    if (h->count[0] == n)
        return 0;  /* No codes - OK for empty tree */
    
    /* Build offset table for sorting symbols by code length */
    offs[1] = 0;
    for (len = 1; len < MAXBITS; len++)
        offs[len + 1] = offs[len] + h->count[len];
    
    /* Sort symbols by code length */
    for (symbol = 0; symbol < n; symbol++) {
        if (lengths[symbol] != 0)
            h->symbol[offs[lengths[symbol]]++] = symbol;
    }
    
    return 0;
}

/* Decode stored block */
static int zlib_stored(ZState *s) {
    int len, nlen;
    
    /* Discard remaining bits in current byte */
    s->bit_buf = 0;
    s->bit_cnt = 0;
    
    /* Get length and complement */
    if (s->in_pos + 4 > s->in_len) {
        s->err = ZLIB_ERR_INPUT;
        return -1;
    }
    
    len = s->in[s->in_pos++];
    len |= s->in[s->in_pos++] << 8;
    nlen = s->in[s->in_pos++];
    nlen |= s->in[s->in_pos++] << 8;
    
    /* Check complement */
    if ((len ^ nlen) != 0xFFFF) {
        s->err = ZLIB_ERR_BLOCK;
        return -1;
    }
    
    /* Check bounds */
    if (s->in_pos + len > s->in_len) {
        s->err = ZLIB_ERR_INPUT;
        return -1;
    }
    if (s->out_pos + len > s->out_len) {
        s->err = ZLIB_ERR_BUFFER;
        return -1;
    }
    
    /* Copy data */
    memcpy(s->out + s->out_pos, s->in + s->in_pos, len);
    s->in_pos += len;
    s->out_pos += len;
    
    return 0;
}

/* Build fixed Huffman tables */
static void zlib_fixed(Huffman *lencode, Huffman *distcode) {
    static u16 lengths[FIXLCODES];
    int symbol;
    
    /* Literal/length codes 0-143: length 8 */
    for (symbol = 0; symbol < 144; symbol++)
        lengths[symbol] = 8;
    /* Literal/length codes 144-255: length 9 */
    for (symbol = 144; symbol < 256; symbol++)
        lengths[symbol] = 9;
    /* Literal/length codes 256-279: length 7 */
    for (symbol = 256; symbol < 280; symbol++)
        lengths[symbol] = 7;
    /* Literal/length codes 280-287: length 8 */
    for (symbol = 280; symbol < FIXLCODES; symbol++)
        lengths[symbol] = 8;
    zlib_construct(lencode, lengths, FIXLCODES);
    
    /* Distance codes 0-29: length 5 */
    for (symbol = 0; symbol < 30; symbol++)
        lengths[symbol] = 5;
    zlib_construct(distcode, lengths, 30);
}

/* Decode dynamic Huffman tables */
static int zlib_dynamic(ZState *s, Huffman *lencode, Huffman *distcode) {
    int nlen, ndist, ncode;
    int index, err;
    u16 lengths[MAXCODES];
    u16 codelen[19];
    Huffman codecode;
    int symbol, len, last;
    
    /* Number of codes */
    nlen = zlib_bits(s, 5) + 257;
    ndist = zlib_bits(s, 5) + 1;
    ncode = zlib_bits(s, 4) + 4;
    
    if (nlen > MAXLCODES || ndist > MAXDCODES) {
        s->err = ZLIB_ERR_DATA;
        return -1;
    }
    
    /* Read code length code lengths */
    for (index = 0; index < 19; index++)
        codelen[index] = 0;
    for (index = 0; index < ncode; index++)
        codelen[order[index]] = zlib_bits(s, 3);
    
    /* Build code length code */
    err = zlib_construct(&codecode, codelen, 19);
    if (err) return err;
    
    /* Read literal/length + distance code lengths */
    index = 0;
    while (index < nlen + ndist) {
        symbol = zlib_decode(s, &codecode);
        if (s->err) return -1;
        
        if (symbol < 16) {
            /* Literal code length */
            lengths[index++] = symbol;
        } else if (symbol == 16) {
            /* Repeat last length 3-6 times */
            if (index == 0) { s->err = ZLIB_ERR_DATA; return -1; }
            len = zlib_bits(s, 2) + 3;
            last = lengths[index - 1];
            while (len-- > 0 && index < nlen + ndist)
                lengths[index++] = last;
        } else if (symbol == 17) {
            /* Repeat zero 3-10 times */
            len = zlib_bits(s, 3) + 3;
            while (len-- > 0 && index < nlen + ndist)
                lengths[index++] = 0;
        } else if (symbol == 18) {
            /* Repeat zero 11-138 times */
            len = zlib_bits(s, 7) + 11;
            while (len-- > 0 && index < nlen + ndist)
                lengths[index++] = 0;
        } else {
            s->err = ZLIB_ERR_DATA;
            return -1;
        }
    }
    
    if (s->err) return -1;
    
    /* Build Huffman tables */
    err = zlib_construct(lencode, lengths, nlen);
    if (err) return err;
    err = zlib_construct(distcode, lengths + nlen, ndist);
    if (err) return err;
    
    return 0;
}

/* Decode Huffman block */
static int zlib_codes(ZState *s, const Huffman *lencode, const Huffman *distcode) {
    int symbol, len, dist;
    
    while (1) {
        symbol = zlib_decode(s, lencode);
        if (s->err) return -1;
        
        if (symbol < 256) {
            /* Literal byte */
            if (s->out_pos >= s->out_len) {
                s->err = ZLIB_ERR_BUFFER;
                return -1;
            }
            s->out[s->out_pos++] = (u8)symbol;
        } else if (symbol == 256) {
            /* End of block */
            return 0;
        } else {
            /* Length/distance pair */
            symbol -= 257;
            if (symbol >= 29) { s->err = ZLIB_ERR_DATA; return -1; }
            
            len = lens[symbol] + zlib_bits(s, lext[symbol]);
            
            symbol = zlib_decode(s, distcode);
            if (s->err) return -1;
            if (symbol >= 30) { s->err = ZLIB_ERR_DATA; return -1; }
            
            dist = dists[symbol] + zlib_bits(s, dext[symbol]);
            
            /* Check distance */
            if (dist > s->out_pos) { s->err = ZLIB_ERR_DATA; return -1; }
            
            /* Check output space */
            if (s->out_pos + len > s->out_len) { s->err = ZLIB_ERR_BUFFER; return -1; }
            
            /* Copy from back reference */
            while (len-- > 0) {
                s->out[s->out_pos] = s->out[s->out_pos - dist];
                s->out_pos++;
            }
        }
    }
}

/* Main inflate function */
static int zlib_inflate(const u8 *in, int in_len, u8 *out, int out_len) {
    ZState s;
    int bfinal, btype;
    Huffman lencode, distcode;
    int start_pos = 0;
    
    /* Input validation */
    if (in_len < 2) {
        return ZLIB_ERR_INPUT;
    }
    
    /* Initialize state */
    s.in = in;
    s.in_len = in_len;
    s.in_pos = 0;
    s.bit_buf = 0;
    s.bit_cnt = 0;
    s.out = out;
    s.out_len = out_len;
    s.out_pos = 0;
    s.err = 0;
    
    /* Skip zlib header if present
     * Zlib header: CMF (1 byte) + FLG (1 byte)
     * CMF = CINFO (bits 4-7) + CM (bits 0-3)
     * CM = 8 for deflate, so low nibble should be 0x08
     * FLG includes FCHECK, FDICT, FLEVEL
     * (CMF*256 + FLG) % 31 == 0 for valid headers
     */
    if ((in[0] & 0x0F) == 0x08) {
        /* Low nibble is 8 (deflate method) - this is a zlib header */
        u16 header = (((u16)in[0]) << 8) | in[1];
        if ((header % 31) != 0) {
            /* Invalid header checksum */
            return ZLIB_ERR_HEADER;
        }
        if (in[1] & 0x20) {
            /* FDICT flag set - dictionary not supported */
            return ZLIB_ERR_HEADER;
        }
        /* Valid zlib header - skip 2 bytes */
        s.in_pos = 2;
    }
    
    /* Process blocks */
    do {
        bfinal = zlib_bits(&s, 1);
        btype = zlib_bits(&s, 2);
        
        if (s.err) return s.err;  /* Return specific error code */
        
        if (btype == 0) {
            /* Stored block */
            if (zlib_stored(&s) != 0) return (s.err != 0) ? s.err : ZLIB_ERR_BLOCK;
        } else if (btype == 1) {
            /* Fixed Huffman codes */
            zlib_fixed(&lencode, &distcode);
            if (zlib_codes(&s, &lencode, &distcode) != 0) return (s.err != 0) ? s.err : ZLIB_ERR_DATA;
        } else if (btype == 2) {
            /* Dynamic Huffman codes */
            if (zlib_dynamic(&s, &lencode, &distcode) != 0) return (s.err != 0) ? s.err : ZLIB_ERR_DATA;
            if (zlib_codes(&s, &lencode, &distcode) != 0) return (s.err != 0) ? s.err : ZLIB_ERR_DATA;
        } else {
            /* Invalid block type (3) */
            return ZLIB_ERR_BLOCK;
        }
    } while (!bfinal);
    
    return s.out_pos;  /* Success: return actual decompressed size */
}

/* Deflate using real zlib compression (compress2) - this is the main function */
static int zlib_deflate_stored(const u8 *in, int in_len, u8 *out, int out_len) {
    uLongf dest_len = (uLongf)out_len;
    int result;
    
    /* Use compress2 with default compression level (Z_DEFAULT_COMPRESSION = 6) */
    result = compress2((Bytef *)out, &dest_len, (const Bytef *)in, (uLong)in_len, Z_DEFAULT_COMPRESSION);
    
    if (result == Z_OK) {
        return (int)dest_len;  /* Return compressed size */
    } else if (result == Z_BUF_ERROR) {
        return ZLIB_ERR_BUFFER;  /* Output buffer too small */
    } else {
        return ZLIB_ERR_DATA;    /* Compression error */
    }
}

/* Keep stored blocks version as fallback (not used, for reference only) */
static int zlib_deflate_stored_no_compression(const u8 *in, int in_len, u8 *out, int out_len) {
    int pos = 0;
    int i;
    int remaining = in_len;
    int block_start = 0;
    u32 a = 1, b = 0, adler;
    
    /* Check minimum output size */
    if (out_len < in_len + 11 + (in_len / 65535) * 5) return 0;
    
    /* Zlib header */
    out[pos++] = 0x78;
    out[pos++] = 0x01;
    
    /* Stored blocks */
    while (remaining > 0) {
        int block_size = remaining > 65535 ? 65535 : remaining;
        int is_final = (remaining <= 65535) ? 1 : 0;
        
        out[pos++] = (u8)is_final;
        out[pos++] = (u8)(block_size & 0xFF);
        out[pos++] = (u8)((block_size >> 8) & 0xFF);
        out[pos++] = (u8)((~block_size) & 0xFF);
        out[pos++] = (u8)((~block_size >> 8) & 0xFF);
        
        memcpy(out + pos, in + block_start, block_size);
        pos += block_size;
        block_start += block_size;
        remaining -= block_size;
    }
    
    /* Adler-32 checksum */
    for (i = 0; i < in_len; i++) {
        a = (a + in[i]) % 65521;
        b = (b + a) % 65521;
    }
    adler = (b << 16) | a;
    
    out[pos++] = (u8)((adler >> 24) & 0xFF);
    out[pos++] = (u8)((adler >> 16) & 0xFF);
    out[pos++] = (u8)((adler >> 8) & 0xFF);
    out[pos++] = (u8)(adler & 0xFF);
    
    return pos;
}

#endif /* ZLIB_IMPL_H */
