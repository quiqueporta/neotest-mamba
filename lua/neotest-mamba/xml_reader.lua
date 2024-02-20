local M = {}

-- function M.parse_xml(xml_content)
--     local result = {}

--     -- Encuentra todas las etiquetas de testcase con fallos y obtiene el atributo 'file'
--     for file_path in xml_content:gmatch('<testcase%s.-failure.-file="(.-)"') do
--         table.insert(result, file_path)
--     end

--     return result
-- end

function M.find_failed_test_in_xml(xml_content, test_name)
    local result = {}

    for file_path, testcase_name in xml_content:gmatch('<testcase%s.-file="(.-)".-name="(.-)"') do
        print(test_name, file_path, testcase_name)
        if testcase_name:find(test_name, 1, true) then
            table.insert(result, { file = file_path, name = testcase_name })
        end
    end

    return #result > 0
end


return M
