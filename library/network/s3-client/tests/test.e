note
	description: "Summary description for {TEST}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST

inherit
	S3_CONFIG

create
	make

feature -- Initialization

	make
		do
			test_s3_client_list_bucket
		end

	test_s3_client_list_bucket
			-- Test listing objects in S3 bucket.
		local
			client: S3_CLIENT
			objects: detachable LIST [S3_OBJECT]
			l_last: READABLE_STRING_8
		do
			create client.make_with_endpoint (s3_endpoint, s3_region, s3_access_key, s3_secret_key)
			print ("List bucket " + client.bucket_name + " from " + client.endpoint + "%N")
			objects := client.list_bucket (Void, False)
			if attached objects as obj_list then
				print ("-> " + obj_list.count.out + " item(s)%N:")
				across
					obj_list as obj
				loop
					print (" - ")
					print (obj.item.key)
					print (" (size: ")
					print (obj.item.size.out)
					print (" modified: ")
					print (obj.item.last_modified)
					print (")")
					Io.put_new_line
					l_last := obj.item.key
				end
				if l_last /= Void then
					if attached client.prefix as p and then l_last.starts_with (p) then
						l_last := l_last.substring (p.count + 1, l_last.count)
					end
					print ("%NChecking the %"" + l_last + "%" file ...%N")
					print ("%NContent for %"" + l_last + "%"%N")
					if attached client.read_file (l_last) as l_content then
						print (l_content)
					end
					print ("%NMetadata for %"" + l_last + "%"%N")
					if attached client.metadata (l_last) as l_metadata then
						print (" - Content-Type: ")
						print (l_metadata.content_type);
						Io.put_new_line
						print (" - Content-Length: ")
						print (l_metadata.content_length);
						Io.put_new_line
						print (" - Last-Modified: ")
						print (l_metadata.last_modified);
						Io.put_new_line
						print (" - eTag: ")
						print (l_metadata.etag);
						Io.put_new_line
					end
				end
			else
				io.error.put_string ("Bucket not found%N")
			end
		end

end -- class TEST


