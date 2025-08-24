struct TreeState
    tree::TreeNode
    open_folders::Set{String}             # Set of folder paths/names that are expanded
    selected_item::Union{String,Nothing}  # Path or name of selected item
end

"""
Create a new TreeState with the given tree.
"""
function TreeState(tree::TreeNode; open_folders=Set{String}(), selected_item=nothing)
    return TreeState(tree, open_folders, selected_item)
end

"""
Create a new TreeState from an existing state with keyword-based modifications.
"""
function TreeState(state::TreeState;
    tree=state.tree,
    open_folders=state.open_folders,
    selected_item=state.selected_item
)
    return TreeState(tree, open_folders, selected_item)
end