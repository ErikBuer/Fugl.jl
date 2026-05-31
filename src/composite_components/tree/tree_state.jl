struct TreeState
    tree::Union{TreeNode,Nothing}         # Root node of the tree
    open_folders::Set{String}             # Set of folder paths/names that are expanded
    selected_item::Union{String,Nothing}  # Path (relative) of selected item
    hovered_item::Union{String,Nothing}   # Path of row currently hovered
    pressed_item::Union{String,Nothing}   # Path of row where mouse down happened
    cache_id::UInt64                      # Cache ID for render caching
end

"""
Create a new TreeState with the given tree.
"""
function TreeState(tree::Union{TreeNode,Nothing}; open_folders=Set{String}(), selected_item=nothing, hovered_item=nothing, pressed_item=nothing)
    return TreeState(tree, open_folders, selected_item, hovered_item, pressed_item, generate_cache_id())
end

"""
Create a new TreeState from an existing state with keyword-based modifications.
"""
function TreeState(state::TreeState;
    tree=state.tree,
    open_folders=state.open_folders,
    selected_item=state.selected_item,
    hovered_item=state.hovered_item,
    pressed_item=state.pressed_item,
    cache_id=state.cache_id
)
    return TreeState(tree, open_folders, selected_item, hovered_item, pressed_item, cache_id)
end