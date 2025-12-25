struct TextStyle
    font::FreeTypeAbstraction.FTFont
    size_px::Int
    color::Vec4{Float32}  # RGBA color
end

function TextStyle(;
    font_path::String=joinpath(@__DIR__, "../../../assets/fonts/FragmentMono-Regular.ttf"),
    size_px=16,
    color=Vec{4,Float32}(0.0, 0.0, 0.0, 1.0),
)
    font = get_font_by_path(font_path)
    return TextStyle(font, size_px, color)
end

"""
Copy constructor for TextStyle that allows overriding specific fields.
"""
function TextStyle(base::TextStyle;
    font=base.font,
    size_px=base.size_px,
    color=base.color
)
    return TextStyle(font, size_px, color)
end