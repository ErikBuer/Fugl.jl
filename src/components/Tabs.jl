"""
Tabs component - displays tabbed content with clickable tab headers.
Each tab has a name and associated content view.
"""

struct TabsStyle
    tab_height::Float32
    tab_padding::Float32
    selected_color::Vec4{Float32}
    unselected_color::Vec4{Float32}
    border_color::Vec4{Float32}
    text_style::TextStyle
    selected_text_style::TextStyle
    tab_corner_radius::Float32
    tab_border_width::Float32
    selected_border_color::Vec4{Float32}
    unselected_border_color::Vec4{Float32}
end

function TabsStyle(;
    tab_height::Float32=35.0f0,
    tab_padding::Float32=15.0f0,
    selected_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.4f0, 0.7f0, 1.0f0),
    unselected_color::Vec4{Float32}=Vec4{Float32}(0.15f0, 0.15f0, 0.15f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    text_style::TextStyle=TextStyle(size_points=14, color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0)),
    selected_text_style::TextStyle=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
    tab_corner_radius::Float32=0.0f0,
    tab_border_width::Float32=0.0f0,
    selected_border_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.6f0, 0.9f0, 1.0f0),
    unselected_border_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 0.2f0, 1.0f0)
)
    return TabsStyle(tab_height, tab_padding, selected_color, unselected_color, border_color, text_style, selected_text_style, tab_corner_radius, tab_border_width, selected_border_color, unselected_border_color)
end

struct TabsView <: AbstractView
    tabs::Vector{Tuple{String,AbstractView,Float32}}  # Vector of (name, content, width) tuples. width=NaN means flexible
    selected_index::Int
    style::TabsStyle
    on_tab_change::Function  # Callback when tab is changed: (new_index) -> nothing
end

function Tabs(
    tabs::Vector{<:Tuple{String,<:AbstractView,Float32}};
    selected_index::Int=1,
    style::TabsStyle=TabsStyle(),
    on_tab_change::Function=(index) -> nothing
)
    # Validate selected_index
    if selected_index < 1 || selected_index > length(tabs)
        selected_index = 1
    end

    # Convert to the expected type
    converted_tabs = Vector{Tuple{String,AbstractView,Float32}}([(name, view, width) for (name, view, width) in tabs])

    return TabsView(converted_tabs, selected_index, style, on_tab_change)
end

# Convenience constructor for tabs without explicit widths (all flexible)
function Tabs(
    tabs::Vector{<:Tuple{String,<:AbstractView}};
    selected_index::Int=1,
    style::TabsStyle=TabsStyle(),
    on_tab_change::Function=(index) -> nothing
)
    # Add NaN width to all tabs (flexible)
    tabs_with_width = [(name, view, NaN32) for (name, view) in tabs]
    return Tabs(tabs_with_width; selected_index=selected_index, style=style, on_tab_change=on_tab_change)
end

function measure(view::TabsView)::Tuple{Float32,Float32}
    if isempty(view.tabs)
        return (0.0f0, 0.0f0)
    end

    # Measure the selected tab's content
    _, content, _ = view.tabs[view.selected_index]
    content_width, content_height = measure(content)

    # Add tab bar height
    total_height = view.style.tab_height + content_height

    return (content_width, total_height)
end

function apply_layout(view::TabsView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(
    view::TabsView,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    projection_matrix::Mat4{Float32},
    mouse_x::Float32,
    mouse_y::Float32
)
    if isempty(view.tabs)
        return
    end

    tab_height = view.style.tab_height

    # Render tab buttons
    render_tab_bar(view, x, y, width, tab_height, projection_matrix)

    # Render selected tab content
    content_y = y + tab_height
    content_height = height - tab_height

    if content_height > 0
        _, selected_content, _ = view.tabs[view.selected_index]
        interpret_view(selected_content, x, content_y, width, content_height, projection_matrix, mouse_x, mouse_y)
    end
end

function render_tab_bar(
    view::TabsView,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    projection_matrix::Mat4{Float32}
)
    # Calculate tab widths
    num_tabs = length(view.tabs)

    # Calculate total fixed width and count flexible tabs
    total_fixed_width = 0.0f0
    num_flexible = 0
    for (_, _, tab_width) in view.tabs
        if isnan(tab_width)
            num_flexible += 1
        else
            total_fixed_width += tab_width
        end
    end

    # Calculate flexible tab width
    flexible_width = num_flexible > 0 ? (width - total_fixed_width) / Float32(num_flexible) : 0.0f0

    font = get_default_font()
    current_x = x

    for (i, (name, _, tab_width)) in enumerate(view.tabs)
        # Determine actual width for this tab
        actual_tab_width = isnan(tab_width) ? flexible_width : tab_width

        is_selected = i == view.selected_index

        # Choose colors and styles based on selection state
        bg_color = is_selected ? view.style.selected_color : view.style.unselected_color
        text_style = is_selected ? view.style.selected_text_style : view.style.text_style
        tab_border_color = is_selected ? view.style.selected_border_color : view.style.unselected_border_color

        # Draw tab background with border
        vertices = generate_rectangle_vertices(current_x, y, actual_tab_width, height)
        if view.style.tab_corner_radius > 0.0f0 || view.style.tab_border_width > 0.0f0
            # Only round the top corners for tabs
            corner_radii = Vec4{Float32}(
                view.style.tab_corner_radius,  # top-left
                view.style.tab_corner_radius,  # top-right
                0.0f0,                          # bottom-right
                0.0f0                           # bottom-left
            )
            draw_configurable_rectangle(
                vertices,
                actual_tab_width,
                height,
                bg_color,
                tab_border_color,
                view.style.tab_border_width,
                corner_radii,
                projection_matrix,
                1.0f0      # anti-aliasing width
            )
        else
            draw_rectangle(vertices, bg_color, projection_matrix)
        end

        # Draw separator border on the right edge (except last tab)
        if i < num_tabs && view.style.tab_border_width == 0.0f0
            border_x = current_x + actual_tab_width
            border_vertices = [
                Point2f(border_x, y + height),
                Point2f(border_x, y),
                Point2f(border_x + 1.0f0, y),
                Point2f(border_x + 1.0f0, y + height)
            ]
            draw_rectangle(border_vertices, view.style.border_color, projection_matrix)
        end

        # Draw tab text (centered)
        text_width = measure_word_width(font, name, text_style.size_points)
        text_x = current_x + (actual_tab_width - text_width) / 2.0f0
        text_y = y + text_style.size_points + (height - text_style.size_points) / 2.0f0

        draw_text(font, name, text_x, text_y, text_style.size_points, projection_matrix, text_style.color)

        # Move to next tab position
        current_x += actual_tab_width
    end
end

function detect_click(
    view::TabsView,
    mouse_state::InputState,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    parent_z::Int32
)::Union{ClickResult,Nothing}
    if isempty(view.tabs)
        return nothing
    end

    z = Int32(parent_z + 1)
    tab_height = view.style.tab_height

    # Check if click is in tab bar area
    if mouse_state.mouse_down[LeftButton] &&
       mouse_state.y >= y && mouse_state.y <= (y + tab_height) &&
       mouse_state.x >= x && mouse_state.x <= (x + width)

        # Calculate tab widths (same logic as render_tab_bar)
        num_tabs = length(view.tabs)
        total_fixed_width = 0.0f0
        num_flexible = 0
        for (_, _, tab_width) in view.tabs
            if isnan(tab_width)
                num_flexible += 1
            else
                total_fixed_width += tab_width
            end
        end
        flexible_width = num_flexible > 0 ? (width - total_fixed_width) / Float32(num_flexible) : 0.0f0

        # Determine which tab was clicked
        current_x = x
        clicked_tab = 0
        for (i, (_, _, tab_width)) in enumerate(view.tabs)
            actual_tab_width = isnan(tab_width) ? flexible_width : tab_width
            if mouse_state.x >= current_x && mouse_state.x < current_x + actual_tab_width
                clicked_tab = i
                break
            end
            current_x += actual_tab_width
        end

        if clicked_tab >= 1 && clicked_tab <= num_tabs && clicked_tab != view.selected_index
            handle_tab_click() = view.on_tab_change(clicked_tab)
            return ClickResult(z, () -> handle_tab_click())
        end
    end

    # Forward interaction to selected content
    content_y = y + tab_height
    content_height = height - tab_height

    if content_height > 0
        _, selected_content, _ = view.tabs[view.selected_index]
        return detect_click(selected_content, mouse_state, x, content_y, width, content_height, z)
    end

    return nothing
end
