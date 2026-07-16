"""
    draw_floating_menu(options, state, style, x, y, width, projection_matrix, window_size)

Draw the floating menu panel background and its currently visible rows (per
`floating_menu_visible_range`), highlighting `state.hover_index` with `style.hover_color`
and `state.pressed_index` with `style.pressed_color` (pressed takes priority over hover,
same as `Container`'s `pressed_style`/`hover_style`). `(x, y, width)` should come from
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

        row_color = if state.pressed_index == option_index
            style.pressed_color
        elseif state.hover_index == option_index
            style.hover_color
        else
            nothing
        end

        if row_color !== nothing
            highlight_vertices = generate_rectangle_vertices(x, item_y, width, style.item_height_px)
            draw_rounded_rectangle(
                highlight_vertices,
                width,
                style.item_height_px,
                row_color,
                Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
                0.0f0,
                0.0f0,
                projection_matrix,
                1.5f0
            )
        end

        text_component = Text(
            options[option_index];
            style=style.text_style,
            horizontal_align=:left,
            vertical_align=:middle
        )

        text_x = x + style.padding
        available_text_width = width - 2 * style.padding

        interpret_view(text_component, text_x, item_y, available_text_width, style.item_height_px, projection_matrix, Point2f(0.0f0, 0.0f0), window_size)
    end
end
