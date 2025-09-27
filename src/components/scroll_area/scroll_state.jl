"""
State for tracking vertical scroll area scrolling information
"""
mutable struct VerticalScrollState
    scroll_offset::Float32
    content_height::Float32
    viewport_height::Float32
    max_scroll::Float32
end

"""
State for tracking horizontal scroll area scrolling information
"""
mutable struct HorizontalScrollState
    scroll_offset::Float32
    content_width::Float32
    viewport_width::Float32
    max_scroll::Float32
end

"""
Create a new VerticalScrollState
"""
function VerticalScrollState(;
    scroll_offset::Float32=0.0f0,
    content_height::Float32=0.0f0,
    viewport_height::Float32=0.0f0
)
    max_scroll = max(0.0f0, content_height - viewport_height)
    clamped_offset = clamp(scroll_offset, 0.0f0, max_scroll)

    return VerticalScrollState(clamped_offset, content_height, viewport_height, max_scroll)
end

"""
Create a new HorizontalScrollState
"""
function HorizontalScrollState(;
    scroll_offset::Float32=0.0f0,
    content_width::Float32=0.0f0,
    viewport_width::Float32=0.0f0
)
    max_scroll = max(0.0f0, content_width - viewport_width)
    clamped_offset = clamp(scroll_offset, 0.0f0, max_scroll)

    return HorizontalScrollState(clamped_offset, content_width, viewport_width, max_scroll)
end