local M = {}

M.get_root_files = function()
    return { "requirements.txt", ".gitignore", "poetry.lock", "poetry.toml", "pyproject.toml" }
end

M.get_filter_dirs = function()
    return { ".git", "__pycache__", "venv", "env", ".venv", ".mypy_cache" }
end

M.transform_spec_path = function(path)
    return path
end

return M
