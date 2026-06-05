struct TreeStyle
    normal_text::TextStyle
    hover_text::TextStyle
    hover_background::Vec4{Float32}
    selected_text::TextStyle
    selected_background::Vec4{Float32}
    active_text::TextStyle       # mouse-down / pressed
    active_background::Vec4{Float32}
    corner_radius::Float32
end

function TreeStyle(;
    normal_text=TextStyle(),
    hover_text=TextStyle(color=Vec4(0.16f0, 0.44f0, 0.85f0, 1.0f0)),
    hover_background=Vec4{Float32}(0.86f0, 0.91f0, 0.98f0, 1.0f0),
    selected_text=TextStyle(color=Vec4(0.24f0, 0.36f0, 0.7f0, 1.0f0)),
    selected_background=Vec4{Float32}(0.82f0, 0.88f0, 0.97f0, 1.0f0),
    active_text=TextStyle(color=Vec4(0.12f0, 0.30f0, 0.70f0, 1.0f0)),
    active_background=Vec4{Float32}(0.75f0, 0.84f0, 0.96f0, 1.0f0),
    corner_radius=5.0f0
)
    TreeStyle(
        normal_text,
        hover_text,
        hover_background,
        selected_text,
        selected_background,
        active_text,
        active_background,
        corner_radius
    )
end