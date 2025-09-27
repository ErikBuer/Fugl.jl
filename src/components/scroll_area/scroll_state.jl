"""
State for tracking vertical scroll area scrolling information
"""
struct VerticalScrollState
    scroll_offset::Float32
    content_height::Float32
    viewport_height::Float32
    max_scroll::Float32
end

"""
State for tracking horizontal scroll area scrolling information
"""
struct HorizontalScrollState
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

"""
Create a new VerticalScrollState from an existing state with keyword-based modifications
"""
function VerticalScrollState(state::VerticalScrollState;
    scroll_offset::Float32=state.scroll_offset,
    content_height::Float32=state.content_height,
    viewport_height::Float32=state.viewport_height
)
    max_scroll = max(0.0f0, content_height - viewport_height)
    clamped_offset = clamp(scroll_offset, 0.0f0, max_scroll)

    return VerticalScrollState(clamped_offset, content_height, viewport_height, max_scroll)
end

"""
Create a new HorizontalScrollState from an existing state with keyword-based modifications
"""
function HorizontalScrollState(state::HorizontalScrollState;
    scroll_offset::Float32=state.scroll_offset,
    content_width::Float32=state.content_width,
    viewport_width::Float32=state.viewport_width
)
    max_scroll = max(0.0f0, content_width - viewport_width)
    clamped_offset = clamp(scroll_offset, 0.0f0, max_scroll)

    return HorizontalScrollState(clamped_offset, content_width, viewport_width, max_scroll)
end