"""
    draw_floating_menu(options, state, style, x, y, width, projection_matrix, window_size)

Draw the floating menu panel background and its currently visible rows (per
`floating_menu_visible_range`). Each row is rendered as a `BaseContainer` using
`style.item_style`, `style.hover_style`, or `style.pressed_style` — same
priority `Container` uses for its own `hover_style`/`pressed_style` (pressed beats
hover, `src/components/container/Container.jl`). `(x, y, width)` should come from
`floating_menu_geometry` so the drawn panel matches whatever rectangle was used for
hit-testing.
"""
function draw_floating_menu(options::Vector{String}, state::FloatingMenuState, style::FloatingMenuStyle, x::Float32, y::Float32, width::Float32, projection_matrix::Mat4{Float32}, window_size::Size)
    n_options = length(options)
    height = floating_menu_height(n_options, style)

    # Panel background
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        style.background_color,
        style.border_color,
        style.border_width,
        style.corner_radius,
        projection_matrix,
        1.5f0
    )

    for option_index in floating_menu_visible_range(state, n_options, style)
        row = option_index - state.scroll_offset
        item_y = y + (row - 1) * style.item_height_px

        active_style = if state.pressed_index == option_index && style.pressed_style !== nothing
            style.pressed_style
        elseif state.hover_index == option_index && style.hover_style !== nothing
            style.hover_style
        else
            style.item_style
        end

        text_component = Text(
            options[option_index];
            style=style.text_style,
            horizontal_align=:left,
            vertical_align=:middle
        )
        row_container = BaseContainer(text_component; style=active_style)

        interpret_view(row_container, x, item_y, width, style.item_height_px, projection_matrix, Point2f(0.0f0, 0.0f0), window_size)
    end
end
