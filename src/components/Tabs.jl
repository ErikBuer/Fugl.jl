"""
Tabs component — displays tabbed content with clickable tab headers.
"""

"""
    TabStyle(; background_color, border_color, border_width, corner_radius, text_style)

Visual style for a single tab button — analogous to `ContainerStyle`.
Passed as `normal_style`, `selected_style`, or `hover_style` directly on the `Tabs` constructor.
"""
struct TabStyle
    background_color::Vec4{Float32}
    border_color::Vec4{Float32}
    border_width::Float32
    corner_radius::Float32
    text_style::TextStyle
end

function TabStyle(;
    background_color::Vec4{Float32}=Vec4{Float32}(0.18f0, 0.18f0, 0.18f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.25f0, 0.25f0, 0.25f0, 1.0f0),
    border_width::Float32=0.0f0,
    corner_radius::Float32=0.0f0,
    text_style::TextStyle=TextStyle(size_points=14, color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0)),
)
    return TabStyle(background_color, border_color, border_width, corner_radius, text_style)
end

"""
    TabsStyle(; tab_height, tab_padding, separator_color)

Layout and shared-appearance style for the `Tabs` component.
Per-state visual styles (`normal_style`, `selected_style`, `hover_style`) are
passed as separate keyword arguments directly on the `Tabs` constructor.
"""
struct TabsStyle
    tab_height::Float32
    tab_padding::Float32
    separator_color::Vec4{Float32}
end

function TabsStyle(;
    tab_height::Float32=35.0f0,
    tab_padding::Float32=15.0f0,
    separator_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
)
    return TabsStyle(tab_height, tab_padding, separator_color)
end

const _DEFAULT_SELECTED_TAB_STYLE = TabStyle(
    background_color=Vec4{Float32}(0.2f0, 0.4f0, 0.7f0, 1.0f0),
    border_color=Vec4{Float32}(0.3f0, 0.6f0, 0.9f0, 1.0f0),
    text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
)

struct TabsView <: AbstractView
    tabs::Vector{Tuple{String,AbstractView,Float32}}  # (label, content, width); width=NaN = flexible
    selected_index::Int
    style::TabsStyle
    normal_style::TabStyle
    selected_style::TabStyle
    hover_style::Union{Nothing,TabStyle}
    on_tab_change::Function
end

# Constructor: string labels with explicit widths
function Tabs(
    tabs::Vector{<:Tuple{String,<:AbstractView,Float32}};
    selected_index::Int=1,
    style::TabsStyle=TabsStyle(),
    normal_style::TabStyle=TabStyle(),
    selected_style::TabStyle=_DEFAULT_SELECTED_TAB_STYLE,
    hover_style::Union{Nothing,TabStyle}=nothing,
    on_tab_change::Function=(index) -> nothing,
)
    if selected_index < 1 || selected_index > length(tabs)
        selected_index = 1
    end
    converted = Vector{Tuple{String,AbstractView,Float32}}([(name, v, w) for (name, v, w) in tabs])
    return TabsView(converted, selected_index, style, normal_style, selected_style, hover_style, on_tab_change)
end

# Constructor: string labels without explicit widths (all flexible)
function Tabs(
    tabs::Vector{<:Tuple{String,<:AbstractView}};
    selected_index::Int=1,
    style::TabsStyle=TabsStyle(),
    normal_style::TabStyle=TabStyle(),
    selected_style::TabStyle=_DEFAULT_SELECTED_TAB_STYLE,
    hover_style::Union{Nothing,TabStyle}=nothing,
    on_tab_change::Function=(index) -> nothing,
)
    tabs_with_width = [(name, view, NaN32) for (name, view) in tabs]
    return Tabs(tabs_with_width; selected_index, style, normal_style, selected_style, hover_style, on_tab_change)
end

function measure(view::TabsView)::Tuple{Float32,Float32}
    if isempty(view.tabs)
        return (0.0f0, 0.0f0)
    end
    _, content, _ = view.tabs[view.selected_index]
    content_width, content_height = measure(content)
    return (content_width, view.style.tab_height + content_height)
end

function apply_layout(view::TabsView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(
    view::TabsView,
    x::Float32, y::Float32, width::Float32, height::Float32,
    projection_matrix::Mat4{Float32},
    mouse_x::Float32, mouse_y::Float32
)
    isempty(view.tabs) && return

    tab_height = view.style.tab_height
    render_tab_bar(view, x, y, width, tab_height, projection_matrix, mouse_x, mouse_y)

    content_y = y + tab_height
    content_height = height - tab_height
    if content_height > 0
        _, selected_content, _ = view.tabs[view.selected_index]
        interpret_view(selected_content, x, content_y, width, content_height, projection_matrix, mouse_x, mouse_y)
    end
end

# Compute the width allocated to each flexible-width tab
function _tab_flexible_width(tabs::Vector{Tuple{String,AbstractView,Float32}}, total_width::Float32)::Float32
    total_fixed = sum(w for (_, _, w) in tabs if !isnan(w); init=0.0f0)
    num_flex = count(((_, _, w),) -> isnan(w), tabs)
    return num_flex > 0 ? (total_width - total_fixed) / Float32(num_flex) : 0.0f0
end

function render_tab_bar(
    view::TabsView,
    x::Float32, y::Float32, width::Float32, height::Float32,
    projection_matrix::Mat4{Float32},
    mouse_x::Float32, mouse_y::Float32
)
    num_tabs = length(view.tabs)
    flexible_width = _tab_flexible_width(view.tabs, width)

    # Determine which tab (if any) the mouse is hovering in the tab bar
    hovered_index = 0
    if mouse_y >= y && mouse_y <= y + height
        curr_x = x
        for (i, (_, _, tab_width)) in enumerate(view.tabs)
            actual_w = isnan(tab_width) ? flexible_width : tab_width
            if mouse_x >= curr_x && mouse_x < curr_x + actual_w
                hovered_index = i
                break
            end
            curr_x += actual_w
        end
    end

    font = get_default_font()
    current_x = x

    for (i, (name, _, tab_width)) in enumerate(view.tabs)
        actual_tab_width = isnan(tab_width) ? flexible_width : tab_width
        is_selected = i == view.selected_index
        is_hovered = i == hovered_index

        # Resolve the active per-tab style
        tab_style = if is_selected
            view.selected_style
        elseif is_hovered && view.hover_style !== nothing
            view.hover_style
        else
            view.normal_style
        end

        # Draw tab background
        vertices = generate_rectangle_vertices(current_x, y, actual_tab_width, height)
        if tab_style.corner_radius > 0.0f0 || tab_style.border_width > 0.0f0
            corner_radii = Vec4{Float32}(
                tab_style.corner_radius,  # top-left
                tab_style.corner_radius,  # top-right
                0.0f0,                    # bottom-right
                0.0f0,                    # bottom-left
            )
            draw_configurable_rectangle(
                vertices, actual_tab_width, height,
                tab_style.background_color, tab_style.border_color,
                tab_style.border_width, corner_radii,
                projection_matrix, 1.0f0
            )
        else
            draw_rectangle(vertices, tab_style.background_color, projection_matrix)
        end

        # Draw separator between tabs when borders are not used
        if i < num_tabs && tab_style.border_width == 0.0f0
            border_x = current_x + actual_tab_width
            border_vertices = [
                Point2f(border_x, y + height),
                Point2f(border_x, y),
                Point2f(border_x + 1.0f0, y),
                Point2f(border_x + 1.0f0, y + height),
            ]
            draw_rectangle(border_vertices, view.style.separator_color, projection_matrix)
        end

        # Draw tab label (centered)
        text_style = tab_style.text_style
        text_width = measure_word_width(font, name, text_style.size_points)
        text_x = current_x + (actual_tab_width - text_width) / 2.0f0
        text_y = y + text_style.size_points + (height - text_style.size_points) / 2.0f0
        draw_text(font, name, text_x, text_y, text_style.size_points, projection_matrix, text_style.color)

        current_x += actual_tab_width
    end
end

function detect_click(
    view::TabsView,
    mouse_state::InputState,
    x::Float32, y::Float32, width::Float32, height::Float32,
    parent_z::Int32
)::Union{ClickResult,Nothing}
    isempty(view.tabs) && return nothing

    z = Int32(parent_z + 1)
    tab_height = view.style.tab_height

    # Check clicks in the tab bar area
    if mouse_state.mouse_down[LeftButton] &&
       mouse_state.y >= y && mouse_state.y <= (y + tab_height) &&
       mouse_state.x >= x && mouse_state.x <= (x + width)

        flexible_width = _tab_flexible_width(view.tabs, width)
        current_x = x
        for (i, (_, _, tab_width)) in enumerate(view.tabs)
            actual_tab_width = isnan(tab_width) ? flexible_width : tab_width
            if mouse_state.x >= current_x && mouse_state.x < current_x + actual_tab_width
                if i != view.selected_index
                    return ClickResult(z, () -> view.on_tab_change(i))
                end
                break
            end
            current_x += actual_tab_width
        end
    end

    # Forward interaction to selected tab content
    content_y = y + tab_height
    content_height = height - tab_height
    if content_height > 0
        _, selected_content, _ = view.tabs[view.selected_index]
        return detect_click(selected_content, mouse_state, x, content_y, width, content_height, z)
    end

    return nothing
end
