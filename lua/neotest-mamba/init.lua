local lib = require("neotest.lib")
local config = require("neotest-mamba.config")
local xml_reader = require('neotest-mamba.xml_reader')

---@type neotest.Adapter
local adapter = { name = "neotest-mamba" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function adapter.root(dir)
	local result = nil

	for _, root_file in ipairs(config.get_root_files()) do
		result = lib.files.match_root_pattern(root_file)(dir)
		if result then break end
	end

	return result
end

---@param file_path? string
---@return boolean
function adapter.is_test_file(file_path)
	return vim.endswith(file_path, "_spec.py")
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

	local position = args.tree:data()
	-- printTable(position)
	-- path: /home/quique/Repos/github.com/neotest-mamba/specs/example_spec.py
	-- name: fixed test outside context
	-- id: /home/quique/Repos/github.com/neotest-mamba/specs/example_spec.py::fixed test outside context
	-- range: 1: 15
	-- 2: 9
	-- 3: 15
	-- 4: 41

	-- type: test

	local command = { 'mamba' }

	position.path = vim.fn.fnamemodify(position.path, ":.")

	vim.list_extend(command, {
		"--no-color",
		"--format=junit",
		position.path,
	})

	return {
		command = command,
		cwd = nil,
		context = {
			file = position.path,
			id = position.id,
			name = position.name,
		},
	}
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.results(spec, result, tree)
	-- spec.context.file
	local results = {}

	local output_file = result.output
	local ok, data = pcall(lib.files.read, output_file)
	if not ok then
		logger.error("No test output file found:", output_file)
		return {}
	end

	local failed_test = xml_reader.find_failed_test_in_xml(data, spec.context.name)
	local status = 'passed'
	if failed_test then
		status = 'failed'
	end

	results[spec.context.id] = {
		status = status,
	}

	return results
end

function printTable(tbl)
	local buf = vim.api.nvim_create_buf(false, true)
	local tableContent = tableToString(tbl)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(tableContent, "\n"))
	vim.api.nvim_command("vnew")
	vim.api.nvim_win_set_buf(0, buf)
end

-- this method returns the content of a table resursively as string
function tableToString(tbl)
	local result = ""
	for key, value in pairs(tbl) do
		if type(value) == "table" then
			result = result .. key .. ": " .. tableToString(value) .. "\n"
		else
			result = result .. key .. ": " .. value .. "\n"
		end
	end
	return result
end

return adapter
