note
	description: "[
			Deferred class defining the logger interface for ePDF library.
			Provides two log levels: info and failure
		]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_LOGGER

feature -- Logging

	info (m: READABLE_STRING_GENERAL)
			-- Log an informational message.
		deferred
		end

	failure (m: READABLE_STRING_GENERAL)
			-- Log a failure message.
		deferred
		end

end
