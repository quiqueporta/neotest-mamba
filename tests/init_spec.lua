local async = require("nio").tests
local Tree = require("neotest.types").Tree
local plugin = require("neotest-mamba")
require("neotest-mamba-assertions")

A = function(...)
    print(vim.inspect(...))
end

describe("adapter enabled", function()
    async.it("enable adapter", function()
        assert.Not.Nil(plugin.root("./specs"))
    end)
end)

describe("is_test_file", function()
    it("matches mamba specs files", function()
        assert.True(plugin.is_test_file("./spec/example_spec.py"))
    end)

    it("does not match plain pyhton files", function()
        assert.False(plugin.is_test_file("./example.py"))
    end)

end)

describe("discover_positions", function()
    async.it("provides meaningful names from a basic spec", function()
        local positions = plugin.discover_positions("./specs/example_spec.py"):to_list()

        local expected_output = {
            {
                name = "example_spec.py",
                type = "file",
            },
            {
                {
                    name = "first test",
                    type = "test",
                },
                {
                    name = "fixed test outside context",
                    type = "test",
                },
            },
        }

        assert.equals(expected_output[1].name, positions[1].name)
        assert.equals(expected_output[1].type, positions[1].type)
        assert.equals(expected_output[2][1].name, positions[2][1].name)
        assert.equals(expected_output[2][1].type, positions[2][1].type)

        assert.equals(1, #positions[2])
        for i, value in ipairs(expected_output[2][2]) do
            assert.is.truthy(value)
            local position = positions[2][i + 1][1]
            assert.is.truthy(position)
            assert.equals(value.name, position.name)
            assert.equals(value.type, position.type)
        end
    end)

end)

describe("build_spec", function()
    async.it("builds command for file test", function()
        local positions = plugin.discover_positions("./specs/example_spec.py"):to_list()
        local tree = Tree.from_list(positions, function(pos)
            return pos.id
        end)
        local spec = plugin.build_spec({ tree = tree })

        assert.is.truthy(spec)
        local command = spec.command
        assert.is.truthy(command)
        assert.contains(command, "mamba")
        assert.contains(command, "--format=documentation")
        assert.contains(command, "./specs/example_spec.py")
        assert.is.truthy(spec.context.file)
    end)
end)

