note
	description: "Tests for Markdown inline escaping (backslash escapes)."

class
   	 TEST_MD_ESCAPING

inherit
   	 TEST_MD_PARSER_BASE

feature -- Tests (Escaping)

   	 test_basic_backslash_escapes
   	    	 local
   	    	    	 t: MD_CONTENT_TEXT
   	    	    	 o: STRING
   	    	 do
   	    	    	 create t.make_from_string ("\*Not emphasized\*, \`Not code\`, \[Not a link\].%N")
   	    	    	 create o.make_empty
   	    	    	 t.document.process (create {MD_XHTML_GENERATOR}.make (o))
   	    	    	 assert ("xhtml",
   	    	    	    	 o.same_string ("<p>*Not emphasized*, `Not code`, [Not a link].</p>%N"))
   	    	 end

   	 test_full_backslash_escapes_punctuation
   	    	 local
   	    	    	 t: MD_CONTENT_TEXT
   	    	    	 o: STRING
   	    	 do
   	    	    	 create t.make_from_string ("Escaped: \! \%" \# \$ \%% \& \' \( \) \* \+ \, \- \. \/ \: \; \< \= \> \? \@ \[ \\ \] \^ \_ \` \{ \| \} \~.%N")
   	    	    	 create o.make_empty
   	    	    	 t.document.process (create {MD_XHTML_GENERATOR}.make (o))
   	    	    	 assert ("xhtml",
   	    	    	    	 o.has_substring ("Escaped: ! %" # $ %% &amp; ' ( ) * + , - . / : ; &lt; = &gt; ? @ [ \ ] ^ _ ` { | } ~."))
   	    	 end

   	 test_backslash_before_non_escapable
   	    	 local
   	    	    	 t: MD_CONTENT_TEXT
   	    	    	 o: STRING
   	    	 do
   	    	    	 create t.make_from_string ("Backslash before letter: \\a and before digit: \\1.%N")
   	    	    	 create o.make_empty
   	    	    	 t.document.process (create {MD_XHTML_GENERATOR}.make (o))
   	    	    	    	 -- Backslashes before non-escapable characters should be preserved.
   	    	    	 assert ("xhtml",
   	    	    	    	 o.same_string ("<p>Backslash before letter: \a and before digit: \1.</p>%N"))
   	    	 end

end

