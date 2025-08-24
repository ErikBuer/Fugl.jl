"""
Generate a content hash for all rendering-relevant tree state
"""
function hash_tree_content(tree::Union{TreeNode,Nothing}, state::TreeState, style::TreeStyle)
    h = hash(typeof(tree))
    function hash_node(node::TreeNode, h)
        h = hash((node.name, node.is_folder, length(node.children)), h)
        for child in node.children
            h = hash_node(child, h)
        end
        return h
    end
    if tree !== nothing
        h = hash_node(tree, h)
    end
    h = hash((state.open_folders, state.selected_item), h)
    h = hash((style.selected, style.normal), h)
    return h
end