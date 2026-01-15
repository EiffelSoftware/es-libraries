# S3 Client Library

Eiffel library for interacting with S3-compatible storage services (AWS S3, MinIO, etc.).

## Overview

This library provides a simple interface to perform common S3 operations:
- List objects in a bucket
- Read objects from a bucket
- Write objects to a bucket
- Delete objects from a bucket

## Requirements

- Eiffel HTTP client library (`http_client`)
- Eiffel XML parser library (`xml_parser`, `xml_tree`)
- Eiffel JSON parser library (`json`)

## Usage

### AWS S3 Example

```eiffel
local
	client: S3_CLIENT
	objects: detachable LIST [S3_OBJECT]
	content: detachable STRING_8
do
	-- Initialize client for AWS S3
	-- Note: Use the region-specific endpoint or s3.amazonaws.com
	create client.make (
		"https://s3.us-east-1.amazonaws.com",  -- AWS S3 endpoint (region-specific)
		"AKIAIOSFODNN7EXAMPLE",                -- AWS Access Key ID
		"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",  -- AWS Secret Access Key
		"my-bucket",                           -- S3 bucket name
		"us-east-1"                            -- AWS region (must match endpoint region)
	)

	-- List objects in bucket
	objects := client.list_bucket (Void)
	if attached objects as obj_list then
		across obj_list as obj loop
			print (obj.item.key)
			io.put_new_line
		end
	end

	-- Read a file
	content := client.read_file ("path/to/file.txt")
	if attached content as file_content then
		print (file_content)
	end

	-- Write a file
	if client.write_file ("path/to/new-file.txt", "File content") then
		print ("File written successfully")
	end

	-- Delete a file
	if client.delete_file ("path/to/file.txt") then
		print ("File deleted successfully")
	end
end
```

### MinIO Example

```eiffel
local
	client: S3_CLIENT
	objects: detachable LIST [S3_OBJECT]
	content: detachable STRING_8
do
	-- Initialize client for MinIO
	create client.make (
		"http://localhost:9000",  -- MinIO endpoint
		"minioadmin",             -- MinIO access key
		"minioadmin",             -- MinIO secret key
		"my-bucket",              -- Bucket name
		"us-east-1"               -- Region (can be any valid AWS region name)
	)

	-- Use the same operations as AWS S3
	objects := client.list_bucket (Void)
	-- ... rest of the code is identical
end
```

### AWS S3 Configuration Notes

1. **Endpoint Format**: 
   - **Region-specific**: `https://s3.us-east-1.amazonaws.com` (recommended)
   - **Global**: `https://s3.amazonaws.com` (works but region must still be specified)
   - The region in `make()` must match the endpoint region

2. **AWS Credentials**:
   - Get your **Access Key ID** and **Secret Access Key** from AWS IAM
   - Create an IAM user with S3 permissions
   - Never commit credentials to version control

3. **Common AWS Regions**:
   - `us-east-1` (N. Virginia)
   - `us-west-2` (Oregon)
   - `eu-west-1` (Ireland)
   - `ap-southeast-1` (Singapore)
   - See [AWS Regions](https://docs.aws.amazon.com/general/latest/gr/rande.html) for full list

4. **Bucket Naming**:
   - Bucket names must be globally unique across all AWS accounts
   - Must follow [S3 bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)

5. **HTTPS**: Always use `https://` endpoints for AWS S3 in production

### List Objects with Prefix

```eiffel
-- List objects with a prefix filter
objects := client.list_bucket ("documents/")
```

### Using s3:// URLs

The library supports `s3://` URLs for specifying objects. You can use them with `read_file`, `write_file`, and `delete_file`:

```eiffel
local
	client: S3_CLIENT
	content: detachable STRING_8
do
	-- Initialize client (bucket name is "my-bucket")
	create client.make (
		"https://s3.us-east-1.amazonaws.com",
		"AKIAIOSFODNN7EXAMPLE",
		"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
		"my-bucket",
		"us-east-1"
	)

	-- Read using s3:// URL
	content := client.read_file ("s3://my-bucket/path/to/file.txt")
	
	-- Write using s3:// URL
	client.write_file ("s3://my-bucket/path/to/new-file.txt", "Content")
	
	-- Delete using s3:// URL
	client.delete_file ("s3://my-bucket/path/to/file.txt")
	
	-- Get metadata for a file
	if attached client.get_metadata ("path/to/file.txt") as meta then
		if attached meta.content_type as ct then
			print ("Content-Type: " + ct)
		end
		if attached meta.content_length as size then
			print ("Size: " + size.out + " bytes")
		end
		if attached meta.last_modified as lm then
			print ("Last Modified: " + lm)
		end
		if attached meta.etag as tag then
			print ("ETag: " + tag)
		end
	end
	
	-- You can also use regular keys (without s3:// prefix)
	content := client.read_file ("path/to/file.txt")
end
```

**Note**: When using `s3://` URLs, the bucket name in the URL must match the bucket name used when creating the client. If they don't match, the operation will fail silently (return Void or False).

### Parsing s3:// URLs

You can also parse `s3://` URLs programmatically:

```eiffel
local
	client: S3_CLIENT
	parsed: detachable TUPLE [bucket: STRING_8; key: detachable STRING_8]
do
	create client.make (...)
	parsed := client.parse_s3_url ("s3://my-bucket/path/to/file.txt")
	if attached parsed as p then
		print ("Bucket: " + p.bucket)  -- "my-bucket"
		if attached p.key as k then
			print ("Key: " + k)  -- "path/to/file.txt"
		end
	end
end
```

## API Reference

### S3_CLIENT

Main client class for S3 operations.

#### Creation

- `make (a_endpoint: READABLE_STRING_8; a_access_key: READABLE_STRING_32; a_secret_key: READABLE_STRING_32; a_bucket: READABLE_STRING_8; a_region: READABLE_STRING_8)`
  - Initialize S3 client with endpoint, credentials, bucket name, and AWS region.

#### Features

- `list_bucket (a_prefix: detachable READABLE_STRING_8): detachable LIST [S3_OBJECT]`
  - List objects in bucket, optionally filtered by prefix.

- `read_file (a_key: READABLE_STRING_8): detachable STRING_8`
  - Read file content for given key. `a_key` can be a simple key or an `s3://` URL.

- `write_file (a_key: READABLE_STRING_8; a_content: READABLE_STRING_8): BOOLEAN`
  - Write content to file with given key. `a_key` can be a simple key or an `s3://` URL.

- `delete_file (a_key: READABLE_STRING_8): BOOLEAN`
  - Delete file with given key. `a_key` can be a simple key or an `s3://` URL.

- `get_metadata (a_key: READABLE_STRING_8): detachable S3_OBJECT_METADATA`
  - Get metadata for object `a_key` (file or folder) using HEAD request.
  - Returns metadata object or Void if object doesn't exist.

- `parse_s3_url (a_url: READABLE_STRING_8): detachable TUPLE [bucket: STRING_8; key: detachable STRING_8]`
  - Parse an `s3://` URL and extract bucket name and optional object key.

### S3_OBJECT

Represents an S3 object (file) in a bucket.

#### Features

- `key: STRING_8` - Object key (path/name)
- `size: INTEGER` - Object size in bytes
- `last_modified: STRING_8` - Last modified timestamp

### S3_OBJECT_METADATA

Represents metadata for an S3 object (file or folder).

#### Features

- `metadata: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]` - All metadata headers
- `content_type: detachable READABLE_STRING_8` - Content-Type of the object
- `content_length: detachable INTEGER_64` - Size in bytes
- `last_modified: detachable READABLE_STRING_8` - Last-Modified timestamp
- `etag: detachable READABLE_STRING_8` - ETag (entity tag)
- `storage_class: detachable READABLE_STRING_8` - Storage class (e.g., "STANDARD", "GLACIER")
- `server_side_encryption: detachable READABLE_STRING_8` - Encryption method
- `custom_metadata: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]` - Custom metadata (x-amz-meta-*)
- `exists: BOOLEAN` - Does the object exist?
- `is_folder: BOOLEAN` - Is this a folder/prefix? (heuristic check)

## Testing

The library includes a comprehensive test suite located in the `tests/` directory.

### Running Tests

To run the tests, you need:

1. A running S3-compatible server (e.g., MinIO)
2. Set environment variables (optional, defaults provided):
   - `S3_ENDPOINT` - S3 endpoint URL (default: `http://localhost:9000`)
   - `S3_ACCESS_KEY` - Access key (default: `minioadmin`)
   - `S3_SECRET_KEY` - Secret key (default: `minioadmin`)
   - `S3_BUCKET` - Bucket name (default: `test-bucket`)

3. Compile and run tests:
```bash
ec -config tests/test.ecf -target tests -c_compile -finalize -tests
```

### Test Coverage

The test suite includes:
- `test_s3_client_write_file` - Tests writing files to S3
- `test_s3_client_read_file` - Tests reading files from S3
- `test_s3_client_list_bucket` - Tests listing bucket contents
- `test_s3_client_list_bucket_with_prefix` - Tests listing with prefix filter
- `test_s3_client_delete_file` - Tests deleting files from S3
- `test_s3_client_read_nonexistent_file` - Tests error handling for non-existent files
- `test_s3_object_creation` - Tests S3_OBJECT class

## Authentication

This library uses **AWS Signature Version 4 (AWS4-HMAC-SHA256)** for authentication, which is the standard authentication method for AWS S3 and S3-compatible services.

The signature generation includes:
- Canonical request construction
- String-to-sign creation
- HMAC-SHA256 signature calculation
- Authorization header generation

All requests automatically include the required `Authorization` and `x-amz-date` headers.

## Notes

- The library uses AWS Signature Version 4 (AWS4-HMAC-SHA256) for authentication.
- The library is compatible with AWS S3, MinIO, and other S3-compatible services.
- Error handling is done through detachable return types and boolean results.
- The region parameter is required for proper signature generation (e.g., "us-east-1", "eu-west-1").
- For AWS S3, use region-specific endpoints (e.g., `s3.us-east-1.amazonaws.com`) for best compatibility.
- Always use HTTPS endpoints for AWS S3 in production environments.

## License

Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)

