note
	description: "[
		Class providing access to the logger.
		Classes that need logging inherit from this class.
	]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_WITH_LOGGING

feature -- Logging

	set_logger (log: like logger)
			-- Set the logger with `log'.
		do
			logger := log
		end

	logger: detachable PDF_LOGGER assign set_logger
			-- Current logger instance.

	log_info (m: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			if attached logger as log then
				log.info (m)
			end
		end

	log_failure (m: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			if attached logger as log then
				log.failure (m)
			end
		end

end
