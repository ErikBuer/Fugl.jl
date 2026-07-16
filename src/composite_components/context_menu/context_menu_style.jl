struct ContextMenuStyle
    menu_style::FloatingMenuStyle
    width::Float32  # fixed width of the popup panel (independent of the child's width)
end

function ContextMenuStyle(;
    menu_style::FloatingMenuStyle=FloatingMenuStyle(),
    width::Float32=200.0f0
)
    return ContextMenuStyle(menu_style, width)
end
