note
	description: "[
		The right to read console input, held by at most one reader at a time.

		Two readers of one console race for its bytes, and for the driver's decoding state
		(pending UTF-8 bytes, a pending UTF-16 high surrogate, a synthesized key sequence):
		bytes are lost or duplicated, and a cursor position report can go to the wrong reader.
		So every reader takes the claim first and gives it back when it stops reading:
		  * EVENT_THREAD holds it from {EVENT_THREAD}.start until its `execute` ends;
		  * {ANSI_TERMINAL_BACKEND}.query_cursor_position holds it during the query.

		Thread-safe: a claim can be taken on one thread and released on another.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSOLE_INPUT_CLAIM

create
	make

feature {NONE} -- Initialization

	make
			-- Create a free claim.
		do
			create mutex.make
		ensure
			free: not is_held
		end

feature -- Status report

	is_held: BOOLEAN
			-- Is a reader reading the console?
		do
			mutex.lock
			Result := internal_is_held
			mutex.unlock
		end

feature -- Basic operations

	try_acquire: BOOLEAN
			-- Take the claim if it is free. True if taken: the caller then owns it and must
			-- `release` it. False if another reader holds it.
		do
			mutex.lock
			if not internal_is_held then
				internal_is_held := True
				Result := True
			end
			mutex.unlock
		ensure
			held: Result implies is_held
		end

	release
			-- Give the claim back. Only its owner may call this.
		require
			held: is_held
		do
			mutex.lock
			internal_is_held := False
			mutex.unlock
		end

feature {NONE} -- Implementation

	mutex: MUTEX
			-- Lock guarding `internal_is_held`

	internal_is_held: BOOLEAN

end
