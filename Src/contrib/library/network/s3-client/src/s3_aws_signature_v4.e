note
	description: "AWS Signature Version 4 (AWS4-HMAC-SHA256) signature generator for S3 requests."

class
	S3_AWS_SIGNATURE_V4

create
	make

feature {NONE} -- Initialization

	make (a_access_key: READABLE_STRING_32; a_secret_key: READABLE_STRING_32; a_region: READABLE_STRING_8; a_service: READABLE_STRING_8)
			-- Initialize signature generator with `a_access_key`, `a_secret_key`, `a_region`, and `a_service`.
		require
			access_key_not_empty: a_access_key /= Void and then not a_access_key.is_empty
			secret_key_not_empty: a_secret_key /= Void and then not a_secret_key.is_empty
			region_not_empty: a_region /= Void and then not a_region.is_empty
			service_not_empty: a_service /= Void and then not a_service.is_empty
		do
			access_key := a_access_key
			secret_key := a_secret_key
			region := a_region
			service := a_service
		ensure
			access_key_set: attached access_key as ak and then ak.same_string (a_access_key)
			secret_key_set: attached secret_key as sk and then sk.same_string (a_secret_key)
			region_set: region.same_string (a_region)
			service_set: service.same_string (a_service)
		end

feature -- Access

	access_key: detachable IMMUTABLE_STRING_32
			-- AWS access key.

	secret_key: detachable IMMUTABLE_STRING_32
			-- AWS secret key.

	region: IMMUTABLE_STRING_8
			-- AWS region (e.g., "us-east-1").

	service: IMMUTABLE_STRING_8
			-- AWS service name (e.g., "s3").

feature -- Signature generation

	generate_authorization_header (a_method: READABLE_STRING_8; a_path: READABLE_STRING_8; a_query_string: detachable READABLE_STRING_8; a_headers: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]; a_payload_hash: detachable READABLE_STRING_8): STRING_8
			-- Generate Authorization header for AWS Signature Version 4.
			-- `a_method`: HTTP method (GET, PUT, DELETE, etc.)
			-- `a_path`: Request path
			-- `a_query_string`: Optional query string
			-- `a_headers`: Request headers
			-- `a_payload_hash`: SHA256 hash of request payload (hex encoded)
		require
			method_not_empty: a_method /= Void and then not a_method.is_empty
			path_not_empty: a_path /= Void and then not a_path.is_empty
			headers_not_void: a_headers /= Void
		local
			date_stamp: STRING_8
			date_time_stamp: STRING_8
			canonical_request: STRING_8
			string_to_sign: STRING_8
			signature: STRING_8
			credential_scope: STRING_8
			l_header_key: READABLE_STRING_8
			l_header_value: READABLE_STRING_8
			now: DATE_TIME
		do
			across
				a_headers as h
			loop
				l_header_key := @ h.key
				if l_header_key.is_case_insensitive_equal ("x-amz-date") then
					l_header_value := h
					create date_time_stamp.make_from_string (l_header_value)
				end
			end
			if date_time_stamp = Void then
				create now.make_now_utc
				date_time_stamp := format_date_time_stamp (now)
			end
			date_stamp := date_time_stamp.substring (1, 8)
			canonical_request := build_canonical_request (a_method, a_path, a_query_string, a_headers, a_payload_hash, date_time_stamp)
			credential_scope := build_credential_scope (date_stamp)
			string_to_sign := build_string_to_sign (date_time_stamp, credential_scope, canonical_request)
			signature := calculate_signature (date_stamp, string_to_sign)
			create Result.make (200);
			Result.append ("AWS4-HMAC-SHA256 ");
			Result.append ("Credential=")
			if attached access_key as ak then
				Result.append (ak.to_string_8)
			end;
			Result.append ("/");
			Result.append (credential_scope);
			Result.append (", ");
			Result.append ("SignedHeaders=");
			Result.append (build_signed_headers (a_headers));
			Result.append (", ");
			Result.append ("Signature=");
			Result.append (signature)
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	build_canonical_request (a_method: READABLE_STRING_8; a_path: READABLE_STRING_8; a_query_string: detachable READABLE_STRING_8; a_headers: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]; a_payload_hash: detachable READABLE_STRING_8; a_date_time: READABLE_STRING_8): STRING_8
			-- Build canonical request string.
		require
			method_not_empty: a_method /= Void and then not a_method.is_empty
			path_not_empty: a_path /= Void and then not a_path.is_empty
			headers_not_void: a_headers /= Void
			date_time_not_empty: a_date_time /= Void and then not a_date_time.is_empty
		local
			canonical_headers: READABLE_STRING_8
			signed_headers: READABLE_STRING_8
			canonical_query: READABLE_STRING_8
			payload: READABLE_STRING_8
		do
			create Result.make (500);
			Result.append (a_method.as_upper);
			Result.append_character ('%N');
			Result.append (uri_encode_path (a_path));
			Result.append_character ('%N')
			if a_query_string /= Void and then not a_query_string.is_empty then
				canonical_query := canonicalize_query_string (a_query_string);
				Result.append (canonical_query)
			end;
			Result.append_character ('%N')
			canonical_headers := build_canonical_headers (a_headers, a_date_time);
			Result.append (canonical_headers);
			Result.append_character ('%N')
			signed_headers := build_signed_headers (a_headers);
			Result.append (signed_headers);
			Result.append_character ('%N')
			if a_payload_hash /= Void then
				payload := a_payload_hash
			else
				payload := "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
			end;
			Result.append (payload)
		ensure
			result_not_empty: not Result.is_empty
		end

	build_canonical_headers (a_headers: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]; a_date_time: READABLE_STRING_8): STRING_8
			-- Build canonical headers string.
		require
			headers_not_void: a_headers /= Void
			date_time_not_empty: a_date_time /= Void and then not a_date_time.is_empty
		local
			sorted_keys: ARRAYED_LIST [READABLE_STRING_8]
			header_map: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]
			lower_key: READABLE_STRING_8
		do
			create Result.make (200)
			create sorted_keys.make (a_headers.count + 2);
			sorted_keys.compare_objects
			create header_map.make (a_headers.count + 2);
			header_map.compare_objects
			across
				a_headers as h
			loop
				lower_key := (@h.key).as_lower
				if not header_map.has (lower_key) then
					header_map.force (trim_header_value (h), lower_key);
					sorted_keys.force (lower_key)
				end
			end
			if not header_map.has ("host") then
				across
					a_headers as h
				loop
					if (@h.key).is_case_insensitive_equal ("host") then
						header_map.force (trim_header_value (h), "host")
						if not sorted_keys.has ("host") then
							sorted_keys.force ("host")
						end
					end
				end
			end
			if not sorted_keys.has ("host") then
				sorted_keys.force ("host")
			end
			if not header_map.has ("x-amz-date") then
				header_map.force (a_date_time, "x-amz-date")
			end
			if not sorted_keys.has ("x-amz-date") then
				sorted_keys.force ("x-amz-date")
			end;
			strings_sorter.sort (sorted_keys)
			across
				sorted_keys as k
			loop
				Result.append (k);
				Result.append_character (':')
				if attached header_map.item (k) as val then
					Result.append (val)
				end;
				Result.append_character ('%N')
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	strings_sorter: QUICK_SORTER [READABLE_STRING_GENERAL]
		do
			create Result.make (create {STRING_COMPARATOR}.make)
		end

	build_signed_headers (a_headers: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]): STRING_8
			-- Build signed headers list (semicolon-separated, lowercase).
		require
			headers_not_void: a_headers /= Void
		local
			sorted_keys: ARRAYED_LIST [STRING_8]
			key: STRING_8
			first: BOOLEAN
		do
			create Result.make (100)
			create sorted_keys.make (a_headers.count + 2);
			sorted_keys.compare_objects
			across
				a_headers as h
			loop
				create key.make_from_string (@h.key);
				key.to_lower;
				sorted_keys.force (key)
			end
			if not sorted_keys.has ("host") then
				sorted_keys.force ("host")
			end
			if not sorted_keys.has ("x-amz-date") then
				sorted_keys.force ("x-amz-date")
			end;
			strings_sorter.sort (sorted_keys)
			first := True
			across
				sorted_keys as k
			loop
				if not first then
					Result.append_character (';')
				end;
				Result.append (k)
				first := False
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	build_string_to_sign (a_date_time: READABLE_STRING_8; a_credential_scope: READABLE_STRING_8; a_canonical_request: READABLE_STRING_8): STRING_8
			-- Build string to sign.
		require
			date_time_not_empty: a_date_time /= Void and then not a_date_time.is_empty
			credential_scope_not_empty: a_credential_scope /= Void and then not a_credential_scope.is_empty
			canonical_request_not_empty: a_canonical_request /= Void and then not a_canonical_request.is_empty
		local
			canonical_hash: STRING_8
		do
			canonical_hash := sha256_hash (a_canonical_request)
			create Result.make (200);
			Result.append ("AWS4-HMAC-SHA256%N");
			Result.append (a_date_time);
			Result.append_character ('%N');
			Result.append (a_credential_scope);
			Result.append_character ('%N');
			Result.append (canonical_hash)
		ensure
			result_not_empty: not Result.is_empty
		end

	build_credential_scope (a_date_stamp: READABLE_STRING_8): STRING_8
			-- Build credential scope string.
		require
			date_stamp_not_empty: a_date_stamp /= Void and then not a_date_stamp.is_empty
		do
			create Result.make (50);
			Result.append (a_date_stamp);
			Result.append_character ('/');
			Result.append (region);
			Result.append_character ('/');
			Result.append (service);
			Result.append ("/aws4_request")
		ensure
			result_not_empty: not Result.is_empty
		end

	calculate_signature (a_date_stamp: READABLE_STRING_8; a_string_to_sign: READABLE_STRING_8): STRING_8
			-- Calculate AWS signature using HMAC-SHA256.
		require
			date_stamp_not_empty: a_date_stamp /= Void and then not a_date_stamp.is_empty
			string_to_sign_not_empty: a_string_to_sign /= Void and then not a_string_to_sign.is_empty
		local
			k_secret: STRING_8
			k_date_bytes: SPECIAL [NATURAL_8]
			k_region_bytes: SPECIAL [NATURAL_8]
			k_service_bytes: SPECIAL [NATURAL_8]
			k_signing_bytes: SPECIAL [NATURAL_8]
			hmac: HMAC_SHA256
		do
			create k_secret.make_from_string ("AWS4")
			if attached secret_key as sk then
				k_secret.append (sk.to_string_8)
			end
			create hmac.make_ascii_key (k_secret);
			hmac.update_from_string (a_date_stamp)
			k_date_bytes := hmac.digest
			create hmac.make (k_date_bytes);
			hmac.update_from_string (region)
			k_region_bytes := hmac.digest
			create hmac.make (k_region_bytes);
			hmac.update_from_string (service)
			k_service_bytes := hmac.digest
			create hmac.make (k_service_bytes);
			hmac.update_from_string ("aws4_request")
			k_signing_bytes := hmac.digest
			create hmac.make (k_signing_bytes);
			hmac.update_from_string (a_string_to_sign)
			Result := hmac.lowercase_hexadecimal_string_digest
		ensure
			result_not_empty: not Result.is_empty
		end

	sha256_hash (a_string: READABLE_STRING_8): STRING_8
			-- Calculate SHA256 hash of `a_string` and return as hexadecimal string.
		require
			string_not_void: a_string /= Void
		local
			sha: SHA256
		do
			create sha.make;
			sha.update_from_string (a_string)
			Result := sha.digest_as_hexadecimal_string.as_lower
		ensure
			result_not_empty: not Result.is_empty
		end

	format_date_stamp (a_date: DATE_TIME): STRING_8
			-- Format date as YYYYMMDD.
		require
			date_not_void: a_date /= Void
		do
			create Result.make (8);
			Result.append_integer (a_date.year)
			if a_date.month < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.month)
			if a_date.day < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.day)
		ensure
			result_count: Result.count = 8
		end

	format_date_time_stamp (a_date: DATE_TIME): STRING_8
			-- Format date-time as YYYYMMDDTHHMMSSZ.
		require
			date_not_void: a_date /= Void
		do
			Result := format_date_stamp (a_date);
			Result.append_character ('T')
			if a_date.hour < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.hour)
			if a_date.minute < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.minute)
			if a_date.second < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.second);
			Result.append_character ('Z')
		ensure
			result_count: Result.count = 16
		end

	uri_encode_path (a_path: READABLE_STRING_8): STRING_8
			-- URI encode path component (preserving slashes).
		require
			path_not_void: a_path /= Void
		local
			i: INTEGER_32
			c: CHARACTER_8
			code: NATURAL_8
		do
			create Result.make (a_path.count * 2)
			from
				i := 1
			until
				i > a_path.count
			loop
				c := a_path [i]
				if (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c = '-' or c = '_' or c = '.' or c = '~' or c = '/' then
					Result.append_character (c)
				else
					code := c.code.to_natural_8;
					Result.append_character ('%%')
					if code < 16 then
						Result.append_character ('0')
					end;
					Result.append (code.to_hex_string.as_upper)
				end
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	canonicalize_query_string (a_query: READABLE_STRING_8): STRING_8
			-- Canonicalize query string (sort and encode).
		require
			query_not_void: a_query /= Void
		local
			params: ARRAYED_LIST [TUPLE [key: READABLE_STRING_8; value: READABLE_STRING_8]]
			parts: LIST [READABLE_STRING_8]
			param: READABLE_STRING_8
			eq_pos: INTEGER_32
			key, value: READABLE_STRING_8
			first: BOOLEAN
			i, j: INTEGER_32
			temp: TUPLE [key: READABLE_STRING_8; value: READABLE_STRING_8]
		do
			create params.make (5)
			parts := a_query.split ('&')
			across
				parts as part
			loop
				param := part
				eq_pos := param.index_of ('=', 1)
				if eq_pos > 0 then
					key := param.substring (1, eq_pos - 1)
					value := param.substring (eq_pos + 1, param.count)
				else
					key := param
					value := ""
				end;
				params.force ([uri_encode_query_key (key), uri_encode_query_value (value)])
			end
			from
				i := 1
			until
				i > params.count
			loop
				from
					j := 1
				until
					j >= params.count - i + 1
				loop
					if params [j].key > params [j + 1].key then
						temp := params [j]
						params [j] := params [j + 1]
						params [j + 1] := temp
					end
					j := j + 1
				end
				i := i + 1
			end
			create Result.make (a_query.count)
			first := True
			across
				params as p
			loop
				if not first then
					Result.append_character ('&')
				end;
				Result.append (p.key);
				Result.append_character ('=');
				Result.append (p.value)
				first := False
			end
		ensure
			result_not_void: Result /= Void
		end

	uri_encode_query_key (a_key: READABLE_STRING_8): STRING_8
			-- URI encode query parameter key.
		require
			key_not_void: a_key /= Void
		do
			Result := uri_encode_query_component (a_key)
		ensure
			result_not_void: Result /= Void
		end

	uri_encode_query_value (a_value: READABLE_STRING_8): STRING_8
			-- URI encode query parameter value.
		require
			value_not_void: a_value /= Void
		do
			Result := uri_encode_query_component (a_value)
		ensure
			result_not_void: Result /= Void
		end

	uri_encode_query_component (a_component: READABLE_STRING_8): STRING_8
			-- URI encode query string component (key or value).
		require
			component_not_void: a_component /= Void
		local
			i: INTEGER_32
			c: CHARACTER_8
			code: NATURAL_8
		do
			create Result.make (a_component.count * 2)
			from
				i := 1
			until
				i > a_component.count
			loop
				c := a_component [i]
				if (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c = '-' or c = '_' or c = '.' or c = '~' then
					Result.append_character (c)
				else
					code := c.code.to_natural_8;
					Result.append_character ('%%')
					if code < 16 then
						Result.append_character ('0')
					end;
					Result.append (code.to_hex_string.as_upper)
				end
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	trim_header_value (a_value: READABLE_STRING_8): STRING_8
			-- Trim and normalize header value.
		require
			value_not_void: a_value /= Void
		do
			create Result.make_from_string (a_value);
			Result.left_adjust;
			Result.right_adjust;
			Result.replace_substring_all ("  ", " ")
		ensure
			result_not_void: Result /= Void
		end

invariant
	access_key_attached: access_key /= Void
	secret_key_attached: secret_key /= Void
	region_not_empty: not region.is_empty
	service_not_empty: not service.is_empty

note
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	copyright: "2025-2026, Jocelyn Fiat, Eiffel Software and others"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end -- class S3_AWS_SIGNATURE_V4


