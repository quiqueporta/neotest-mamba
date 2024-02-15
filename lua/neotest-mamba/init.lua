local lib = require("neotest.lib")

---@type neotest.Adapter
local adapter = { name = "neotest-mamba" }

adapter.root = function(path)
	return lib.files.match_root_pattern("requirements.txt")(path)
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
    ; -- Tests --
    ; Matches: `it('test')`
    (with_item value:
    (call function: (identifier)@func_name (#any-of? @func_name "it" "fit" "context")
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

	local binary = "mamba"
	local command = vim.split(binary, "%s+")

	vim.list_extend(command, {
		"--format=documentation",
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
