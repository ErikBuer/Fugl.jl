"""
Represents the position of a cursor in the editor.

- `line`: Line number (1-based)
- `column`: Column number (1-based, character position within the line)
"""
struct CursorPosition
    line::Int
    column::Int
end

"""
Cached tokenization data for a line of code.

- `line_number`: The line number this data belongs to
- `line_text`: The original line text
- `tokens`: Vector of tokens for this line
- `token_data`: Processed token data with positions and colors
"""
struct LineTokenData
    line_number::Int
    line_text::String
    tokens::Vector{Any}  # Tokenize tokens
    token_data::Vector{Tuple{Int,String,Any}}  # (position, text, color)
end

"""
State for the code editor containing text, cursor position, and cached tokenization.

- `text`: The full text content
- `cursor`: Current cursor position
- `is_focused`: Whether the editor is focused
- `cached_lines`: Cache of tokenized line data
- `text_hash`: Hash of the text to detect changes
"""
mutable struct EditorState
    text::String
    cursor::CursorPosition
    is_focused::Bool
    cached_lines::Dict{Int,LineTokenData}
    text_hash::UInt64
end

"""
Create a new EditorState with the given text and language.
"""
function EditorState(text::String="")
    return EditorState(
        text,
        CursorPosition(1, 1),  # Start at beginning
        false,
        Dict{Int,LineTokenData}(),
        hash(text)
    )
end

"""
Create a new EditorState with updated text, preserving cursor and focus state from the old state.
"""
function EditorState(old_state::EditorState, new_text::String)
    new_state = EditorState(new_text)
    new_state.cursor = old_state.cursor
    new_state.is_focused = old_state.is_focused
    return new_state
end

"""
Update the text in the editor state and invalidate caches if needed.
"""
function update_text!(state::EditorState, new_text::String)
    new_hash = hash(new_text)
    if new_hash != state.text_hash
        state.text = new_text
        state.text_hash = new_hash
        # Clear cache - we could be smarter here and only clear affected lines
        empty!(state.cached_lines)
    end
end

"""
Get the lines of text from the editor state.
"""
function get_lines(state::EditorState)
    return split(state.text, "\n")
end

"""
Ensure tokenization data is cached for the given line.
"""
function ensure_line_tokenized!(state::EditorState, line_number::Int, line_text::AbstractString)
    if !haskey(state.cached_lines, line_number) || state.cached_lines[line_number].line_text != line_text
        # Tokenize the line and cache the result
        tokens, token_data = tokenize_line_with_colors(string(line_text))
        state.cached_lines[line_number] = LineTokenData(line_number, string(line_text), tokens, token_data)
    end
    return state.cached_lines[line_number]
end

"""
Apply an editor action to the editor state.
"""
function apply_editor_action!(state::EditorState, action::EditorAction)
    if action isa InsertText
        apply_insert_text!(state, action)
    elseif action isa MoveCursor
        apply_move_cursor!(state, action)
    elseif action isa DeleteText
        apply_delete_text!(state, action)
    elseif action isa ClipboardAction
        apply_clipboard_action!(state, action)
    end
end

"""
Apply text insertion action.
"""
function apply_insert_text!(state::EditorState, action::InsertText)
    if action.text == "\b"  # Handle backspace as special case
        apply_delete_text!(state, DeleteText(:backspace))
        return
    end

    # Insert text at cursor position
    lines = get_lines(state)
    cursor = state.cursor

    if cursor.line <= length(lines)
        current_line = lines[cursor.line]
        # Insert the text at the cursor position
        new_line = current_line[1:min(cursor.column - 1, length(current_line))] *
                   action.text *
                   current_line[min(cursor.column, length(current_line) + 1):end]
        lines[cursor.line] = new_line

        # Update cursor position
        if action.text == "\n"
            # Split line and move cursor to next line
            before_cursor = current_line[1:min(cursor.column - 1, length(current_line))]
            after_cursor = current_line[min(cursor.column, length(current_line) + 1):end]
            lines[cursor.line] = before_cursor
            insert!(lines, cursor.line + 1, after_cursor)
            state.cursor = CursorPosition(cursor.line + 1, 1)
        else
            # Move cursor forward by the length of inserted text
            state.cursor = CursorPosition(cursor.line, cursor.column + length(action.text))
        end
    else
        # Cursor is beyond the text, just append
        state.text *= action.text
        if action.text == "\n"
            state.cursor = CursorPosition(cursor.line + 1, 1)
        else
            state.cursor = CursorPosition(cursor.line, cursor.column + length(action.text))
        end
    end

    # Update the text and invalidate cache
    new_text = join(lines, "\n")
    update_text!(state, new_text)
end