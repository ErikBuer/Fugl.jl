include("tree_style.jl")
include("tree_node.jl")
include("tree_state.jl")
include("utilities.jl")
export tree_from_walkdir
include("tree_cache.jl")

struct TreeView <: AbstractView
    state::TreeState
    indent::Float32
    style::TreeStyle
    on_state_change::Function  # Callback for state changes (expand/collapse/select)
    on_select::Function        # Callback for file selection (path, name)
end

function Tree(
    state::TreeState;
    indent=18f0,
    style=TreeStyle(),
    on_state_change=(new_state) -> nothing,
    on_select=(path, name) -> nothing
)
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

function interpret_view(view::TreeView, x_points::Float32, y_points::Float32, width_points::Float32, height_points::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    # Get DPI scaling to convert logical points to pixel coordinates
    dpi_scaling = get_current_dpi_scaling()
    scale_factor = dpi_scaling[].manual_scale * get_system_dpi_ratio(dpi_scaling)

    # The framebuffer is rendered in pixel coordinates to get the highest quality
    cache_width_pixels = Int32(round(width_points * scale_factor))
    cache_height_pixels = Int32(round(height_points * scale_factor))

    # Ensure minimum cache size to avoid zero-sized framebuffers
    if cache_width_pixels <= 0 || cache_height_pixels <= 0
        return  # Skip rendering if size is invalid
    end

    bounds_points = (x_points, y_points, width_points, height_points)
    bounds_pixels = (Float32(x_points) * scale_factor, Float32(y_points) * scale_factor, Float32(width_points) * scale_factor, Float32(height_points) * scale_factor)

    cache = get_render_cache(view.state.cache_id)

    # Tree render cache logic
    content_hash = hash_tree_content(view.state.tree, view.state, view.style)

    # Check if we need to invalidate cache
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds_pixels)

    if needs_redraw || !cache.is_valid
        try
            if cache.framebuffer === nothing || cache.cache_width != cache_width_pixels || cache.cache_height != cache_height_pixels
                framebuffer, color_texture, depth_texture = create_render_framebuffer(cache_width_pixels, cache_height_pixels; with_depth=false)
                update_cache!(cache, framebuffer, color_texture, depth_texture, cache.last_content_hash, bounds_pixels)
            end
        catch e
            @warn "Failed to create plot framebuffer: $e"
            return  # Skip rendering if framebuffer creation fails
        end
        render_tree_to_framebuffer(view, cache, width_points, height_points, projection_matrix, cursor_position[1], cursor_position[2], window_size)
        cache.is_valid = true
    end

    # If cache is valid and has a color texture, draw it
    if cache.is_valid && cache.color_texture !== nothing
        draw_cached_texture(cache.color_texture, x_points, y_points, width_points, height_points, projection_matrix)
        return
    end
end

function render_tree_to_framebuffer(view::TreeView, cache::RenderCache, width_points::Float32, height_points::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32, window_size::Size)
    # Push framebuffer and viewport
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer
        ModernGL.glClearColor(1.0f0, 1.0f0, 1.0f0, 0.0f0) # White background, transparent
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT | ModernGL.GL_DEPTH_BUFFER_BIT)

        # Create framebuffer-specific projection matrix in points
        fb_projection = get_orthographic_matrix(0.0f0, width_points, height_points, 0.0f0, -1.0f0, 1.0f0)

        # Draw the tree into the framebuffer using shared function
        render_tree_content(view, 0.0f0, 0.0f0, width_points, height_points, fb_projection, GeometryBasics.Point{2,Float32}((mouse_x, mouse_y)), window_size)
    finally
        pop_viewport!()
        pop_framebuffer!()
    end
end

"""
Render the tree content (shared between direct and framebuffer drawing)
"""
function render_tree_content(view::TreeView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    current_y = y
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
        is_hovered = depth > 0 && current_path == view.state.hovered_item
        is_active = depth > 0 && current_path == view.state.pressed_item

        # Draw row background for hovered / active / selected rows
        row_bg_color = if is_active
            view.style.active_background
        elseif is_hovered
            view.style.hover_background
        elseif is_selected
            view.style.selected_background
        else
            nothing
        end

        if row_bg_color !== nothing
            bg_x = x + 2.0f0
            bg_y = current_y + 1.0f0
            bg_width = max(0.0f0, width - 4.0f0)
            bg_height = 20.0f0
            bg_vertices = generate_rectangle_vertices(bg_x, bg_y, bg_width, bg_height)
            draw_rounded_rectangle(
                bg_vertices,
                bg_width,
                bg_height,
                row_bg_color,
                row_bg_color,
                0.0f0,
                view.style.corner_radius,
                projection_matrix,
                1.0f0
            )
        end

        style = if is_active
            view.style.active_text
        elseif is_hovered
            view.style.hover_text
        elseif is_selected
            view.style.selected_text
        else
            view.style.normal_text
        end

        interpret_view(Text(text; style=style, horizontal_align=:left, wrap_text=false), x + view.indent * depth, current_y, width - view.indent * depth, 22f0, projection_matrix, cursor_position, window_size)
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

    if view.state.tree !== nothing && !isempty(view.state.tree.children)
        draw_node(view.state.tree, 0)
    end
end

function detect_click(view::TreeView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    current_y = y
    z = Int32(parent_z + 1)
    hovered_item::Union{String,Nothing} = nothing
    click_action::Union{Function,Nothing} = nothing

    # Guard: do nothing if tree is missing or empty
    if view.state.tree === nothing || isempty(view.state.tree.children)
        if view.state.hovered_item !== nothing || view.state.pressed_item !== nothing
            view.on_state_change(TreeState(view.state; hovered_item=nothing, pressed_item=nothing))
        end
        return nothing
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
            hovered_item = current_path

            # Click is detected on mouse-up, but only if this row had mouse-down first.
            if mouse_state.mouse_up[LeftButton] && view.state.pressed_item == current_path
                if node.is_folder
                    click_action = () -> begin
                        new_open = copy(view.state.open_folders)
                        if node.name in new_open
                            delete!(new_open, node.name)
                        else
                            push!(new_open, node.name)
                        end
                        new_state = TreeState(view.state.tree;
                            open_folders=new_open,
                            selected_item=view.state.selected_item,
                            hovered_item=hovered_item,
                            pressed_item=nothing
                        )
                        view.on_state_change(new_state)
                    end
                else
                    click_action = () -> begin
                        new_state = TreeState(view.state.tree;
                            open_folders=view.state.open_folders,
                            selected_item=current_path,
                            hovered_item=hovered_item,
                            pressed_item=nothing
                        )
                        view.on_state_change(new_state)
                        view.on_select(current_path, node.name)
                    end
                end
            end
        end

        current_y += 22f0
        if node.is_folder && (node.name in view.state.open_folders)
            for child in node.children
                click_node(child, depth + 1, current_path)
            end
        end
        return
    end

    click_node(view.state.tree, 0)

    new_pressed_item = view.state.pressed_item
    if mouse_state.mouse_down[LeftButton]
        new_pressed_item = hovered_item
    elseif mouse_state.mouse_up[LeftButton]
        new_pressed_item = nothing
    end

    if click_action === nothing && (hovered_item != view.state.hovered_item || new_pressed_item != view.state.pressed_item)
        view.on_state_change(TreeState(view.state; hovered_item=hovered_item, pressed_item=new_pressed_item))
    end

    if click_action !== nothing
        return ClickResult(z, click_action)
    end

    return nothing
end