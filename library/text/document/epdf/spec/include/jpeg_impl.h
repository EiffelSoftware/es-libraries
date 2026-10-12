/*
 * JPEG Implementation Wrapper for ePDF
 * Uses stb_image.h (header-only library) for JPEG decompression
 * 
 * ISO 32000-1:2008 Section 7.4.9 - DCTDecode Filter
 */

#ifndef JPEG_IMPL_H
#define JPEG_IMPL_H

#include <stdlib.h>
#include <string.h>

/* Configure stb_image for JPEG-only support */
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_JPEG          /* Only compile JPEG decoder */
#define STBI_NO_STDIO           /* No file I/O, we use memory buffers */
#define STBI_NO_LINEAR          /* No HDR support needed */
#define STBI_NO_FAILURE_STRINGS /* Reduce code size */
#include "stb_image.h"

/* Error codes (negative values indicate errors) */
#define JPEG_OK               0     /* Success */
#define JPEG_ERR_INVALID     -1     /* Invalid or corrupt JPEG data */
#define JPEG_ERR_MEMORY      -2     /* Memory allocation failed */
#define JPEG_ERR_SIZE        -3     /* Image too large */
#define JPEG_ERR_INPUT       -4     /* Invalid input parameters */

/* Global variables to store image metadata from last decode */
static int jpeg_last_width = 0;
static int jpeg_last_height = 0;
static int jpeg_last_components = 0;
static const char* jpeg_last_error = NULL;

/*
 * Decompress JPEG data from memory.
 * 
 * Parameters:
 *   input       - Pointer to JPEG compressed data
 *   input_len   - Length of compressed data in bytes
 *   output      - Pointer to receive decompressed data (caller must free with jpeg_free)
 *   output_len  - Pointer to receive decompressed data length
 *   width       - Pointer to receive image width
 *   height      - Pointer to receive image height  
 *   components  - Pointer to receive number of color components (1=gray, 3=RGB)
 *
 * Returns:
 *   JPEG_OK on success, negative error code on failure
 */
static int jpeg_decompress(
    const unsigned char *input, 
    int input_len,
    unsigned char **output,
    int *output_len,
    int *width, 
    int *height, 
    int *components) 
{
    int w, h, comp;
    unsigned char *data;
    
    /* Validate input parameters */
    if (input == NULL || input_len <= 0) {
        jpeg_last_error = "Invalid input parameters";
        return JPEG_ERR_INPUT;
    }
    
    if (output == NULL || output_len == NULL) {
        jpeg_last_error = "Invalid output parameters";
        return JPEG_ERR_INPUT;
    }
    
    /* Decompress JPEG using stb_image */
    data = stbi_load_from_memory(input, input_len, &w, &h, &comp, 0);
    
    if (data == NULL) {
        jpeg_last_error = stbi_failure_reason();
        if (jpeg_last_error == NULL) {
            jpeg_last_error = "Unknown JPEG decode error";
        }
        jpeg_last_width = 0;
        jpeg_last_height = 0;
        jpeg_last_components = 0;
        return JPEG_ERR_INVALID;
    }
    
    /* Store metadata */
    jpeg_last_width = w;
    jpeg_last_height = h;
    jpeg_last_components = comp;
    jpeg_last_error = NULL;
    
    /* Return results */
    *output = data;
    *output_len = w * h * comp;
    
    if (width != NULL) *width = w;
    if (height != NULL) *height = h;
    if (components != NULL) *components = comp;
    
    return JPEG_OK;
}

/*
 * Free decompressed JPEG data.
 * Must be called to free memory allocated by jpeg_decompress.
 *
 * Parameters:
 *   data - Pointer to data returned by jpeg_decompress
 */
static void jpeg_free(unsigned char *data) {
    if (data != NULL) {
        stbi_image_free(data);
    }
}

/*
 * Get last error message.
 * Returns pointer to static string (do not free).
 */
static const char* jpeg_get_error(void) {
    return jpeg_last_error != NULL ? jpeg_last_error : "No error";
}

/*
 * Get image width from last successful decode.
 */
static int jpeg_get_width(void) {
    return jpeg_last_width;
}

/*
 * Get image height from last successful decode.
 */
static int jpeg_get_height(void) {
    return jpeg_last_height;
}

/*
 * Get number of color components from last successful decode.
 * 1 = grayscale, 3 = RGB, 4 = RGBA (rare for JPEG)
 */
static int jpeg_get_components(void) {
    return jpeg_last_components;
}

#endif /* JPEG_IMPL_H */
