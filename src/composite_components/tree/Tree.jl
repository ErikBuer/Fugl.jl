include("tree_style.jl")
include("tree_node.jl")
include("tree_state.jl")
include("utilities.jl")
export tree_from_walkdir

struct TreeView <: AbstractView
    state::TreeState
    indent::Float32
    style::TreeStyle
    on_state_change::Function  # Callback for state changes (expand/collapse/select)
    on_select::Function        # Callback for file selection (path, name)
end

function Tree(state::TreeState; indent=18f0, style=TreeStyle(), on_state_change=(new_state) -> nothing, on_select=(path, name) -> nothing)
    return TreeView(state, indent, style, on_state_change, on_select)
end

function measure(view::TreeView)::Tuple{Float32,Float32}
    # Estimate height by counting visible nodes
    function count_visible(node)
        count = 1
        if node.is_expanded
            for child in node.children
                count += count_visible(child)
            end
        end
        return count
    end
    height = count_visible(view.state.tree) * 22f0  # 22px per row
    return (Inf32, height)
end

function apply_layout(view::TreeView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::TreeView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    current_y = y

    if view.state.tree === nothing
        return
    end

    if isempty(view.state.tree.children)
        return
    end

    function draw_node(node::TreeNode, depth::Int, parent_path::String="")
        # Build the current path, but skip the root folder name
        current_path = parent_path == "" ? node.name : joinpath(parent_path, node.name)

        # Root node: always expanded, no marker
        if depth == 0
            text = node.name
        else
            is_open = node.is_folder && (node.name in view.state.open_folders)
            marker = node.is_folder ? (is_open ? "▼" : "▶") : ""
            marker_text = marker != "" ? marker * " " : ""
            text = marker_text * node.name
        end

        is_selected = current_path == view.state.selected_item
        style = is_selected ? view.style.selected : view.style.normal

        interpret_view(Text(text; style=style, horizontal_align=:left), x + view.indent * depth, current_y, width - view.indent * depth, 22f0, projection_matrix)
        current_y += 22f0

        # Always show children for root node
        if depth == 0
            for child in node.children
                draw_node(child, depth + 1, "")
            end
        else
            is_open = node.is_folder && (node.name in view.state.open_folders)
            if node.is_folder && is_open
                for child in node.children
                    draw_node(child, depth + 1, current_path)
                end
            end
        end
    end

    draw_node(view.state.tree, 0)
end

function detect_click(view::TreeView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    current_y = y

    # Guard: do nothing if tree is missing or empty
    if view.state.tree === nothing || isempty(view.state.tree.children)
        return
    end

    function click_node(node::TreeNode, depth::Int, parent_path::String="")
        # Build the current path, but skip the root folder name
        current_path = parent_path == "" ? node.name : joinpath(parent_path, node.name)

        # Root node: do not allow expand/collapse or selection
        if depth == 0
            current_y += 22f0
            for child in node.children
                # For children of root, parent_path is "" so path starts from here
                click_node(child, depth + 1, "")
            end
            return
        end

        # Check if mouse is within this row
        if mouse_state.y >= current_y && mouse_state.y < current_y + 22f0 &&
           mouse_state.x >= x + view.indent * depth && mouse_state.x < x + width

            # Folder: toggle open/closed in immutable state
            if node.is_folder && mouse_state.was_clicked[LeftButton]
                new_open = copy(view.state.open_folders)
                if node.name in new_open
                    delete!(new_open, node.name)
                else
                    push!(new_open, node.name)
                end
                new_state = TreeState(view.state.tree; open_folders=new_open, selected_item=view.state.selected_item)
                view.on_state_change(new_state)
            end

            # File: select item in immutable state
            if !node.is_folder && mouse_state.was_clicked[LeftButton]
                new_state = TreeState(view.state.tree; open_folders=view.state.open_folders, selected_item=current_path)
                view.on_state_change(new_state)
                # Call on_select hook with (path, name)
                view.on_select(current_path, node.name)
            end
        end

        current_y += 22f0
        if node.is_folder && (node.name in view.state.open_folders)
            for child in node.children
                click_node(child, depth + 1, current_path)
            end
        end
    end

    click_node(view.state.tree, 0)
end