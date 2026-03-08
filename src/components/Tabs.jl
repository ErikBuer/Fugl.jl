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
    text_style::TextStyle=TextStyle(size_px=14, color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0)),
    selected_text_style::TextStyle=TextStyle(size_px=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
    tab_corner_radius::Float32=0.0f0,
    tab_border_width::Float32=0.0f0,
    selected_border_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.6f0, 0.9f0, 1.0f0),
    unselected_border_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 0.2f0, 1.0f0)
)
    return TabsStyle(tab_height, tab_padding, selected_color, unselected_color, border_color, text_style, selected_text_style, tab_corner_radius, tab_border_width, selected_border_color, unselected_border_color)
end

struct TabsView <: AbstractView
    tabs::Vector{Tuple{String,AbstractView}}  # Vector of (name, content) tuples
    selected_index::Int
    style::TabsStyle
    on_tab_change::Function  # Callback when tab is changed: (new_index) -> nothing
end

function Tabs(
    tabs::Vector{<:Tuple{String,<:AbstractView}};
    selected_index::Int=1,
    style::TabsStyle=TabsStyle(),
    on_tab_change::Function=(index) -> nothing
)
    # Validate selected_index
    if selected_index < 1 || selected_index > length(tabs)
        selected_index = 1
    end

    # Convert to the expected type
    converted_tabs = Vector{Tuple{String,AbstractView}}([(name, view) for (name, view) in tabs])

    return TabsView(converted_tabs, selected_index, style, on_tab_change)
end

function measure(view::TabsView)::Tuple{Float32,Float32}
    if isempty(view.tabs)
        return (0.0f0, 0.0f0)
    end

    # Measure the selected tab's content
    _, content = view.tabs[view.selected_index]
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
        _, selected_content = view.tabs[view.selected_index]
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
    # Calculate tab widths (equal width for all tabs)
    num_tabs = length(view.tabs)
    tab_width = width / Float32(num_tabs)

    font = get_default_font()

    for (i, (name, _)) in enumerate(view.tabs)
        tab_x = x + (i - 1) * tab_width
        is_selected = i == view.selected_index

        # Choose colors and styles based on selection state
        bg_color = is_selected ? view.style.selected_color : view.style.unselected_color
        text_style = is_selected ? view.style.selected_text_style : view.style.text_style
        tab_border_color = is_selected ? view.style.selected_border_color : view.style.unselected_border_color

        # Draw tab background with border
        vertices = generate_rectangle_vertices(tab_x, y, tab_width, height)
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
                tab_width,
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
            border_x = tab_x + tab_width
            border_vertices = [
                Point2f(border_x, y + height),
                Point2f(border_x, y),
                Point2f(border_x + 1.0f0, y),
                Point2f(border_x + 1.0f0, y + height)
            ]
            draw_rectangle(border_vertices, view.style.border_color, projection_matrix)
        end

        # Draw tab text (centered)
        text_width = measure_word_width(font, name, text_style.size_px)
        text_x = tab_x + (tab_width - text_width) / 2.0f0
        text_y = y + text_style.size_px + (height - text_style.size_px) / 2.0f0

        draw_text(font, name, text_x, text_y, text_style.size_px, projection_matrix, text_style.color)
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

        # Determine which tab was clicked
        num_tabs = length(view.tabs)
        tab_width = width / Float32(num_tabs)
        clicked_tab = Int(floor((mouse_state.x - x) / tab_width)) + 1

        if clicked_tab >= 1 && clicked_tab <= num_tabs && clicked_tab != view.selected_index
            handle_tab_click() = view.on_tab_change(clicked_tab)
            return ClickResult(z, () -> handle_tab_click())
        end
    end

    # Forward interaction to selected content
    content_y = y + tab_height
    content_height = height - tab_height

    if content_height > 0
        _, selected_content = view.tabs[view.selected_index]
        return detect_click(selected_content, mouse_state, x, content_y, width, content_height, z)
    end

    return nothing
end
