note
	description: "Summary description for {JWT_INVALID_TOKEN_ERROR}."
	date: "$Date$"
	revision: "$Revision$"

class
	JWT_INVALID_TOKEN_ERROR

inherit
	JWT_ERROR

feature -- Access

	id: IMMUTABLE_STRING_8 = "INVALID"

	message: READABLE_STRING_8
		do
			Result := "Invalid token"
		end

end
