abstract type AbstractTreeNode end

struct TreeNode <: AbstractTreeNode
    name::String
    children::Vector{TreeNode}
    is_folder::Bool
end

function TreeNode(name::String; children=TreeNode[], is_folder=true)
    return TreeNode(name, children, is_folder)
end