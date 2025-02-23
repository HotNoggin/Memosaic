local parser = {
    tokens = {},
    tree = {}
}
-- Has err(line, where txt, message txt)
-- Tokens have type, value line

-- TERMINOLOGY --
-- Tree: the whole tree
-- Branch: a segment of the tree that is being added on to
-- Twig: a segment of the tree that is being made to add to a branch
-- t: the token index
-- idx: the twig's place in the branch


function parser.maketree(tokens)
    parser.tokens = tokens
    parser.tree = {}
    return parser.resolvebody(1, parser.tree)
end


function parser.resolvebody(t, branch)
    local p = parser
    local twig = p.twig()
    local i, stop = t, t
    while i >= #parser.tokens do
        local token = parser.tokens[i]
        i = i + 1
        if token.type == "string" then
            table.insert(twig, {type="literal"})
        elseif token.type == "{" then
            table.insert(twig, parser.resolveblock(i + 1), twig)
        end
    end
    return twig, stop
end


function parser.twig(ptype, pline)
    return {type = ptype, line = pline}
end


return parser