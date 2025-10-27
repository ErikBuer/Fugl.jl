function draw_dropdown_button(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Choose background color based on state
    bg_color = if view.state.is_open
        view.style.background_color_open
    elseif view.state.is_hovered
        view.style.background_color_hover
    else
        view.style.background_color
    end

    # Draw button background
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        bg_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.5f0
    )

    # Draw selected text or placeholder
    display_text = if view.state.selected_index > 0 && view.state.selected_index <= length(view.state.options)
        view.state.options[view.state.selected_index]
    else
        placeholder_text
    end

    text_component = Text(
        display_text;
        style=view.style.text_style,
        horizontal_align=:left,
        vertical_align=:middle
    )

    # Position text with proper vertical centering
    text_x = x + view.style.padding
    text_y = y + view.style.padding
    available_text_width = width - 2 * view.style.padding - 20.0f0  # Reserve space for arrow
    text_height = height - 2 * view.style.padding

    interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix)

    # Draw dropdown arrow
    draw_dropdown_arrow(view, x + width - view.style.padding - 10.0f0, y + height / 2.0f0, projection_matrix)
end

function draw_dropdown_list(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Draw background for the entire dropdown list
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        view.style.background_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.5f0
    )

    # Draw each visible option
    visible_items = min(length(view.state.options), view.style.max_visible_items)

    for i in 1:visible_items
        if i > length(view.state.options)
            break
        end

        item_y = y + (i - 1) * view.style.item_height_px
        item_height = view.style.item_height_px

        # Highlight hovered item
        if view.state.hover_index == i
            highlight_vertices = generate_rectangle_vertices(x, item_y, width, item_height)
            draw_rounded_rectangle(
                highlight_vertices,
                width,
                item_height,
                view.style.background_color_hover,
                Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0), # No border for highlight
                0.0f0,
                0.0f0,
                projection_matrix,
                1.5f0
            )
        end

        # Draw option text
        option_text = view.state.options[i]
        text_component = Text(
            option_text;
            style=view.style.text_style,
            horizontal_align=:left,
            vertical_align=:middle
        )

        # Position text with proper vertical centering
        text_x = x + view.style.padding
        text_y = item_y
        available_text_width = width - 2 * view.style.padding
        text_height = item_height

        interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix)
    end
end

function draw_dropdown_arrow(view::DropdownView, x::Float32, y::Float32, projection_matrix::Mat4{Float32})
    # Simple arrow indicator using text
    arrow_text = view.state.is_open ? "▲" : "▼"

    arrow_component = Text(
        arrow_text;
        style=TextStyle(size_px=12, color=view.style.arrow_color),
        horizontal_align=:center,
        vertical_align=:middle
    )

    # Give the arrow a small area to center within
    arrow_size = 16.0f0  # Fixed size for arrow area
    arrow_x = x - arrow_size / 2.0f0
    arrow_y = y - arrow_size / 2.0f0

    interpret_view(arrow_component, arrow_x, arrow_y, arrow_size, arrow_size, projection_matrix)
end