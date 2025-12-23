mutable struct SliderStyle
    background_color::Vec4{Float32} # RGBA color for the slider background
    handle_color::Vec4{Float32}     # RGBA color for the slider handle
    border_color::Vec4{Float32}     # RGBA color for the slider border
    border_width::Float32           # Border width in pixels
    radius::Float32                 # Corner radius for rounded corners
    fill_color::Vec4{Float32}       # RGBA color for the filled portion of the track
    marker_color::Union{Nothing,Vec4{Float32}}  # RGBA color for step markers (nothing disables markers)
    track_height::Float32           # Height of the slider track in pixels
    handle_width::Float32           # Width of the slider handle in pixels
    handle_height_offset::Float32   # Additional height for handle relative to track
    min_width::Float32              # Minimum width for the slider
end

function SliderStyle(;
    background_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),
    handle_color=Vec4{Float32}(0.67f0, 0.75f0, 0.78f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    radius=2.0f0,
    fill_color=Vec4{Float32}(0.4f0, 0.6f0, 0.8f0, 0.6f0),
    marker_color::Union{Nothing,Vec4{Float32}}=Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 0.8f0),
    track_height=20.0f0,
    handle_width=12.0f0,
    handle_height_offset=4.0f0,
    min_width=50.0f0
)
    return SliderStyle(background_color, handle_color, border_color, border_width, radius, fill_color, marker_color, track_height, handle_width, handle_height_offset, min_width)
end