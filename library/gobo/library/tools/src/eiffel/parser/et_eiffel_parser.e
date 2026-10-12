note

	description:

		"Eiffel parsers"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2026, Eric Bezault and others"
	license: "MIT License"

class ET_EIFFEL_PARSER

inherit

	ET_FAULT_TOLERANT_EIFFEL_PARSER
		redefine
			parse_from_file,
			parse_from_class_text
		end

create

	make

feature {NONE} -- Parsing

	parse_from_file (a_file: KI_CHARACTER_INPUT_STREAM)
			-- Parse all classes in `a_file'.
			-- Fast parsing first, reparse with verbose parser
			-- when a syntax error was found.
		local
			l_old_ast_factory: ET_AST_FACTORY
			l_old_error_handler: detachable ET_ERROR_HANDLER
			l_text_file: detachable KL_TEXT_INPUT_FILE
			l_cluster: detachable ET_CLUSTER
		do
			if not attached {ET_DECORATED_AST_FACTORY} ast_factory and attached {KL_TEXT_INPUT_FILE} a_file as l_file and attached {ET_CLUSTER} group as l_group_cluster then
				l_text_file := l_file
				l_cluster := l_group_cluster
				l_old_error_handler := error_handler
				system_processor.set_error_handler_only (tokens.null_error_handler)
			end
			precursor (a_file)
			if l_old_error_handler /= Void then
				system_processor.set_error_handler_only (l_old_error_handler)
			end
			if has_syntax_error and l_text_file /= Void and l_cluster /= Void then
				reset
				l_old_ast_factory := ast_factory
				system_processor.set_ast_factory_only (tokens.decorated_ast_factory)
				l_text_file.close
				l_text_file.open_read
				if l_text_file.is_open_read then
					precursor (l_text_file)
				else
					error_handler.report_gcaab_error (l_cluster, filename)
				end
				system_processor.set_ast_factory_only (l_old_ast_factory)
				if not has_syntax_error and attached last_syntax_error_position as l_position then
					report_syntax_error (l_position, Void, "")
				end
			end
		end

	parse_from_class_text (a_class_text: STRING_8)
			-- Parse all classes in `a_class_text'.
			-- Fast parsing first, reparse with verbose parser
			-- when a syntax error was found.
		local
			l_old_ast_factory: ET_AST_FACTORY
			l_old_error_handler: detachable ET_ERROR_HANDLER
		do
			if not attached {ET_DECORATED_AST_FACTORY} ast_factory then
				l_old_error_handler := error_handler
				system_processor.set_error_handler_only (tokens.null_error_handler)
			end
			precursor (a_class_text)
			if l_old_error_handler /= Void then
				system_processor.set_error_handler_only (l_old_error_handler)
			end
			if has_syntax_error and l_old_error_handler /= Void then
				reset
				l_old_ast_factory := ast_factory
				system_processor.set_ast_factory_only (tokens.decorated_ast_factory)
				precursor (a_class_text)
				system_processor.set_ast_factory_only (l_old_ast_factory)
				if not has_syntax_error and attached last_syntax_error_position as l_position then
					report_syntax_error (l_position, Void, "")
				end
			end
		end

end
