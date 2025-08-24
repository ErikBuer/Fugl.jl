mutable struct SliderStyle
    background_color::Vec4{Float32}  # RGBA color for the slider background
    handle_color::Vec4{Float32}      # RGBA color for the slider handle
    border_color::Vec4{Float32}      # RGBA color for the slider border
    border_width::Float32         # Border width in pixels
    radius::Float32               # Corner radius for rounded corners
end

function SliderStyle(;
    background_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),
    handle_color=Vec4{Float32}(0.67f0, 0.75f0, 0.78f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    radius=2.0f0,
)
    return SliderStyle(background_color, handle_color, border_color, border_width, radius)
end