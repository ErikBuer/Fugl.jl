"""
Draw the tooltip background with shadow and border.
"""
function draw_tooltip_background(style::TooltipStyle, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Draw shadow first (behind tooltip)
    if style.shadow_offset > 0.0f0
        shadow_x = x + style.shadow_offset
        shadow_y = y + style.shadow_offset
        shadow_vertices = generate_rectangle_vertices(shadow_x, shadow_y, width, height)
        draw_rounded_rectangle(
            shadow_vertices,
            width,
            height,
            style.shadow_color,
            style.shadow_color,  # Shadow has no border
            0.0f0,
            style.corner_radius,
            projection_matrix,
            style.anti_aliasing_width
        )
    end

    # Draw tooltip background
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
        style.anti_aliasing_width
    )
end

"""
Draw the tooltip text with proper wrapping and layout.
"""
function draw_tooltip_text(text::String, style::TooltipStyle, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    # Create text component with wrapping enabled
    text_component = Text(
        text;
        style=style.text_style,
        horizontal_align=:left,
        vertical_align=:top,  # Align to top for multi-line text
        wrap_text=true
    )

    # Position text within padding
    text_x = x + style.padding
    text_y = y + style.padding
    text_width = width - 2 * style.padding
    text_height = height - 2 * style.padding

    # Render the text
    interpret_view(text_component, text_x, text_y, text_width, text_height, projection_matrix, cursor_position)
end

"""
Calculate the required height for the tooltip text given a specific width.
"""
function calculate_tooltip_text_height(text::String, style::TooltipStyle, available_width::Float32)::Float32
    # Create a temporary text component to measure height
    text_component = Text(
        text;
        style=style.text_style,
        horizontal_align=:left,
        vertical_align=:top,
        wrap_text=true
    )

    # Calculate text height with the available width minus padding
    text_width = available_width - 2 * style.padding
    text_height = measure_height(text_component, text_width)

    # Add padding to get total tooltip height
    return text_height + 2 * style.padding
end

"""
Main function to draw the entire tooltip.
"""
function draw_tooltip(text::String, style::TooltipStyle, x::Float32, y::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    if isempty(text)
        return
    end

    # Use the configured width from style
    tooltip_width = style.width
    tooltip_height = calculate_tooltip_text_height(text, style, tooltip_width)

    # Draw background first
    draw_tooltip_background(style, x, y, tooltip_width, tooltip_height, projection_matrix)

    # Draw text on top
    draw_tooltip_text(text, style, x, y, tooltip_width, tooltip_height, projection_matrix, cursor_position)
end