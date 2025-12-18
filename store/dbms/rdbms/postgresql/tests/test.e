note
	description: "Summary description for {TEST}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST

create
	make

feature -- Initialization

	make
		local
			l_db: POSTGRESQL
		do
			print ("Hello")
			io.put_new_line
			create l_db
			print (l_db.True_representation)
			io.put_new_line
			print (l_db.False_representation)
			io.put_new_line
			print ("bye.")
			io.put_new_line
		end

note
	license: "The specified license contains syntax errors!"
end
