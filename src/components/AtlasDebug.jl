struct AtlasDebugView <: AbstractView
    scale::Float32
end

function AtlasDebug(; scale=1f0)
    return AtlasDebugView(scale)
end

function measure(view::AtlasDebugView)::Tuple{Float32,Float32}
    atlas = get_glyph_atlas()
    width = Float32(atlas.width) * view.scale
    height = Float32(atlas.height) * view.scale
    return (width, height)
end

function apply_layout(view::AtlasDebugView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::AtlasDebugView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    atlas = get_glyph_atlas()
    draw_glyph_atlas_debug(atlas, x, y, view.scale, projection_matrix)
end