note
    description: "Soft line break (between lines in a paragraph)."

class
    MD_SOFT_BREAK

inherit
    MD_INLINE

create
    make

feature -- Initialization

    make
            -- Create a soft line break.
        do
        end

feature -- Visitor

    process (a_visitor: MD_VISITOR)
            -- Process `Current` using `a_visitor`.
        do
            a_visitor.visit_soft_break (Current)
        end

end

