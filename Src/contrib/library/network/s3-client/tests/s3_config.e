note
	description: "Summary description for {S3_CONFIG}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	S3_CONFIG

create
	default_create

feature -- Configuration

	s3_endpoint: STRING_8
			-- S3 endpoint URL from environment or default.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("S3_ENDPOINT") as endpoint_env then
				Result := endpoint_env.to_string_8
			else
				create Result.make_from_string ("http://localhost:9000/my-bucket/test/")
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	s3_access_key: STRING_32
			-- S3 access key from environment or default.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("S3_ACCESS_KEY") as key_env then
				Result := key_env
			else
				create Result.make_from_string_general ("minio")
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	s3_secret_key: STRING_32
			-- S3 secret key from environment or default.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("S3_SECRET_KEY") as key_env then
				Result := key_env
			else
				create Result.make_from_string_general ("minio")
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	s3_region: STRING_8
			-- S3 bucket name from environment or default.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("S3_REGION") as region_env then
				Result := region_env.to_string_8
			else
				create Result.make_from_string ("us-east-1")
			end
		ensure
			result_not_empty: not Result.is_empty
		end

end -- class S3_CONFIG


