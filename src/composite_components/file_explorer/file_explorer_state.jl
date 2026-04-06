"""
State for the FileExplorer component.
"""
struct FileExplorerState
    current_dir::String                      # Absolute path of the directory currently displayed
    open_dirs::Set{String}                   # Relative paths (from current_dir) of expanded dirs
    selected::Union{String,Nothing}          # Relative path of the selected entry, or nothing
end

"""
    FileExplorerState(current_dir; open_dirs=Set{String}(), selected=nothing)
"""
function FileExplorerState(current_dir::String;
    open_dirs::Set{String}=Set{String}(),
    selected::Union{String,Nothing}=nothing,
)
    return FileExplorerState(isdir(current_dir) ? abspath(current_dir) : pwd(), open_dirs, selected)
end

"""
Copy constructor with keyword overrides.
"""
function FileExplorerState(state::FileExplorerState;
    current_dir=state.current_dir,
    open_dirs=state.open_dirs,
    selected=state.selected,
)
    return FileExplorerState(current_dir, open_dirs, selected)
end
