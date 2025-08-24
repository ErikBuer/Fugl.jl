"""
Convert walkdir output to TreeNode tree
"""
function tree_from_walkdir(items::Vector{Tuple{String,Vector{String},Vector{String}}})
    node_map = Dict{String,TreeNode}()
    for (path, dirs, files) in items
        # Root folder is always a folder
        is_root = path == items[1][1]
        node_map[path] = TreeNode(basename(path), TreeNode[], true)
    end
    for (path, dirs, files) in items
        node = node_map[path]
        for d in dirs
            subpath = joinpath(path, d)
            if haskey(node_map, subpath)
                push!(node.children, node_map[subpath])
            end
        end
        for f in files
            push!(node.children, TreeNode(f, TreeNode[], false))
        end
    end
    return node_map[items[1][1]]
end