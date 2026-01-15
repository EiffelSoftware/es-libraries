note
	description: "Eiffel tests for S3 client library."
	description: "[
		Tests for S3 client operations:
		- List bucket
		- Read file
		- Write file
		- Delete file
		
		Note: These tests require a running S3-compatible server (e.g., MinIO).
		Set environment variables or modify the test configuration:
		- S3_ENDPOINT: S3 endpoint URL (default: http://localhost:9000)
		- S3_ACCESS_KEY: Access key (default: minioadmin)
		- S3_SECRET_KEY: Secret key (default: minioadmin)
		- S3_BUCKET: Bucket name (default: test-bucket)
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_S3_CLIENT

inherit
	EQA_TEST_SET

	S3_CONFIG
		undefine
			default_create
		end

feature -- Test routines

	s3_client: S3_CLIENT
		do
			create Result.make_with_endpoint (s3_endpoint.to_string_8, s3_region.to_string_8, s3_access_key, s3_secret_key)
		end

	test_s3_client_write_file
			-- Test writing a file to S3 bucket.
		local
			client: S3_CLIENT
			test_key: STRING_8
			test_content: STRING_8
			success: BOOLEAN
		do
			client := s3_client
			test_key := "test-write-file.txt"
			test_content := "This is test content for S3 write operation.%N";
			client.write_file (test_key, test_content)
			success := client.last_operation_succeed
			assert ("write_file succeeded", success)
		end

	test_s3_client_read_file
			-- Test reading a file from S3 bucket.
		local
			client: S3_CLIENT
			test_key: STRING_8
			test_content: READABLE_STRING_8
			read_content: detachable READABLE_STRING_8
		do
			client := s3_client
			test_key := "test-read-file.txt"
			test_content := "This is test content for S3 read operation.%N";
			client.write_file (test_key, test_content)
			if client.last_operation_succeed then
				read_content := client.read_file (test_key)
				assert ("read_file returned content", read_content /= Void)
				if attached read_content as content then
					assert ("content matches", content.same_string (test_content))
				end
			else
				assert ("write_file failed, skipping read test", False)
			end
		end

	test_s3_client_list_bucket
			-- Test listing objects in S3 bucket.
		local
			client: S3_CLIENT
			test_key: STRING_8
			test_content: STRING_8
			objects: detachable LIST [S3_OBJECT]
		do
			client := s3_client
			test_key := "test-list-file.txt"
			test_content := "This is test content for S3 list operation.%N";
			client.write_file (test_key, test_content)
			if client.last_operation_succeed then
				objects := client.list_bucket (Void, True)
				assert ("list_bucket returned objects", objects /= Void)
				if attached objects as obj_list then
					assert ("bucket contains at least one object", obj_list.count > 0)
					across
						obj_list as obj
					loop
						if obj.item.key.same_string (test_key) then
							assert ("test file found in list", True)
						end
					end
				end
			else
				assert ("write_file failed, skipping list test", False)
			end
		end

	test_s3_client_list_bucket_with_prefix
			-- Test listing objects in S3 bucket with prefix filter.
		local
			client: S3_CLIENT
			test_key: STRING_8
			test_content: STRING_8
			objects: detachable LIST [S3_OBJECT]
			l_full_prefix: STRING_8
		do
			client := s3_client
			test_key := "prefix/test-prefix-file.txt"
			test_content := "This is test content for S3 list with prefix operation.%N";
			client.write_file (test_key, test_content)
			if client.last_operation_succeed then
				objects := client.list_bucket ("prefix/", True)
				assert ("list_bucket with prefix returned objects", objects /= Void)
				if attached objects as obj_list then
					assert ("prefix filter returned at least one object", obj_list.count > 0)
					l_full_prefix := client.prefix_path ("prefix/")
					across
						obj_list as obj
					loop
						assert ("object has prefix", obj.item.key.starts_with (l_full_prefix))
					end
				end
			else
				assert ("write_file failed, skipping prefix list test", False)
			end
		end

	test_s3_client_delete_file
			-- Test deleting a file from S3 bucket.
		local
			client: S3_CLIENT
			test_key: STRING_8
			test_content: STRING_8
			success: BOOLEAN
		do
			client := s3_client
			test_key := "test_delete_file.txt"
			test_content := "This is test content for S3 delete operation.%N";
			client.write_file (test_key, test_content)
			if client.last_operation_succeed then
				client.delete_file (test_key)
				success := client.last_operation_succeed
				assert ("delete_file succeeded", success)
				if attached client.read_file (test_key) as content then
					assert ("file should be deleted", False)
				else
					assert ("file successfully deleted", True)
				end
			else
				assert ("write_file failed, skipping delete test", False)
			end
		end

	test_s3_client_read_nonexistent_file
			-- Try to read a file that doesn't exist
			-- Test S3_OBJECT creation and access.
		local
			client: S3_CLIENT
			read_content: detachable READABLE_STRING_8
		do
			client := s3_client
			read_content := client.read_file ("nonexistent-file-12345.txt")
			assert ("read_file returned Void for non-existent file", read_content = Void)
		end

	test_s3_object_creation
		local
			obj: S3_OBJECT
			test_key: STRING_8
			test_size: INTEGER_32
			test_last_modified: STRING_8
		do
			test_key := "test-object.txt"
			test_size := 1024
			test_last_modified := "2024-01-01T00:00:00Z"
			create obj.make (test_key, test_size, test_last_modified)
			assert ("key matches", obj.key.same_string (test_key))
			assert ("size matches", obj.size = test_size)
			assert ("last_modified matches", obj.last_modified.same_string (test_last_modified))
		end

end
