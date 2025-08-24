struct TreeStyle
    selected::TextStyle
    normal::TextStyle
end

function TreeStyle(; selected=TextStyle(color=Vec4(0.2f0, 0.5f0, 1.0f0, 1.0f0)), normal=TextStyle())
    TreeStyle(
        selected,
        normal
    )
end