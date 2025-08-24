struct TreeStyle
    selected::TextStyle
    normal::TextStyle
end

function TreeStyle(; selected=TextStyle(color=Vec4(0.24f0, 0.36f0, 0.7f0, 1.0f0)), normal=TextStyle())
    TreeStyle(
        selected,
        normal
    )
end