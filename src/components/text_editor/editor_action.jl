abstract type EditorAction end

struct InsertText <: EditorAction
    text::String
end

struct MoveCursor <: EditorAction
    direction::Symbol  # :left, :right, :up, :down, :home, :end
    select::Bool       # true if shift is held
end

struct DeleteText <: EditorAction
    direction::Symbol  # :backspace, :delete
end

struct ClipboardAction <: EditorAction
    action::Symbol     # :copy, :cut, :paste
end