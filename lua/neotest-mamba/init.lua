local lib = require("neotest.lib")

---@type neotest.Adapter
local adapter = { name = "neotest-mamba" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function adapter.root(dir)
	local result = nil
	local root_files = { "requirements.txt", ".gitignore", "poetry.lock", "poetry.toml", "pyproject.toml" }

	for _, root_file in ipairs(root_files) do
		result = lib.files.match_root_pattern(root_file)(dir)
		if result then
			break
		end
	end

	return result
end

---@param file_path? string
---@return boolean
function adapter.is_test_file(file_path)
	if file_path == nil then
		return false
	end
	local is_test_file = false

	local patterns = {
		"spec/.*_spec%.py",
		"specs/.*_spec%.py",
	}

	for _, pattern in ipairs(patterns) do
		if string.match(file_path, pattern) then
			is_test_file = true
			goto matched_pattern
			break
		end
	end
	::matched_pattern::
	return is_test_file
end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path)
	local query = [[
	; -- Namespaces --
    ; Matches: `description('test') fdescription('test')`
    (with_item value:
    (call function: (identifier)@func_name (#any-of? @func_name "description" "fdescription")
        arguments: (argument_list (string (string_content) @namespace.name))
    )) @namespace.definition
    ; Matches: `context('test') fcontext('test')`
    (with_item value:
    (call function: (identifier)@func_name (#any-of? @func_name "context" "fcontext")
        arguments: (argument_list (string (string_content) @namespace.name))
    )) @namespace.definition
    ; -- Tests --
    ; Matches: `it('test') fit('test')`
    (with_item value:
    (call function: (identifier)@func_name (#any-of? @func_name "it" "fit")
        arguments: (argument_list (string (string_content) @test.name))
    )) @test.definition
  ]]

	return lib.treesitter.parse_positions(path, query, { nested_tests = true })
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function adapter.build_spec(args)
	local tree = args.tree

	if not tree then
		return
	end

	local pos = args.tree:data()
	-- remove leading `./`
	pos.path = string.sub(pos.path, 3)

	local binary = "mamba"
	local command = vim.split(binary, "%s+")

	vim.list_extend(command, {
		"--format=junit",
		pos.path,
	})

	return {
		command = command,
		cwd = nil,
		context = {
			file = pos.path,
		},
	}
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.results(spec, result, tree)
	local results = {}
	return results
end

return adapter
