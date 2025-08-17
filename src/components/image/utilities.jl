function calculate_image_vertical_offset(container_height::Real, text_height::Real, align::Symbol)::Float32
    if align == :top
        return 0.0f0
    elseif align == :middle
        return (container_height - text_height) / 2.0f0
    elseif align == :bottom
        return container_height - text_height
    else
        error("Unsupported vertical alignment: $align")
    end
end