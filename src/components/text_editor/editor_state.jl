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
- `selection_start`: Start position of text selection (if any)
- `selection_end`: End position of text selection (if any)
- `cached_lines`: Cache of tokenized line data
- `text_hash`: Hash of the text to detect changes
"""
struct EditorState
    text::String
    cursor::CursorPosition
    is_focused::Bool
    selection_start::Union{CursorPosition,Nothing}
    selection_end::Union{CursorPosition,Nothing}
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
        nothing,  # No selection initially
        nothing,  # No selection initially
        Dict{Int,LineTokenData}(),
        hash(text)
    )
end

"""
Create a new EditorState with updated text, preserving cursor and focus state from the old state.
"""
function EditorState(old_state::EditorState, new_text::String)
    return EditorState(
        new_text,
        old_state.cursor,
        old_state.is_focused,
        nothing,  # Clear selection when text changes
        nothing,  # Clear selection when text changes
        Dict{Int,LineTokenData}(),  # Fresh cache for new text
        hash(new_text)
    )
end

"""
Create a new EditorState with updated focus state, preserving text and cursor from the old state.
"""
function EditorState(old_state::EditorState; is_focused::Bool)
    # Copy cache more efficiently - only copy if cache is small
    cached_lines = if length(old_state.cached_lines) < 100
        copy(old_state.cached_lines)
    else
        # Don't copy large caches to prevent memory bloat
        Dict{Int,LineTokenData}()
    end

    return EditorState(
        old_state.text,
        old_state.cursor,
        is_focused,
        old_state.selection_start,  # Preserve selection
        old_state.selection_end,    # Preserve selection
        cached_lines,
        old_state.text_hash
    )
end

"""
Create a new EditorState with explicit parameters for all fields.
This is the default struct constructor - it's automatically generated.
"""
# No need for explicit constructor - Julia provides it automatically

"""
Create a new EditorState with old 5-parameter signature (for backward compatibility).
"""
function EditorState(
    text::String,
    cursor::CursorPosition,
    is_focused::Bool,
    cached_lines::Dict{Int,LineTokenData},
    text_hash::UInt64
)
    return EditorState(text, cursor, is_focused, nothing, nothing, cached_lines, text_hash)
end

"""
Update the text in the editor state and invalidate caches if needed.
Returns a new EditorState with updated text.
"""
function update_text(state::EditorState, new_text::String)
    new_hash = hash(new_text)
    if new_hash != state.text_hash
        # Return new state with updated text and cleared cache
        return EditorState(
            new_text,
            state.cursor,
            state.is_focused,
            Dict{Int,LineTokenData}(),  # Clear cache
            new_hash
        )
    else
        # No change needed, return original state
        return state
    end
end

"""
Get the lines of text from the editor state.
"""
function get_lines(state::EditorState)
    # Convert SubStrings to String to avoid Unicode indexing issues
    return [String(line) for line in split(state.text, "\n")]
end

"""
Get tokenization data for the given line, using cache if available.
Returns the LineTokenData for the line.
"""
function get_line_tokenized(state::EditorState, line_number::Int, line_text::AbstractString)
    # Check if we have cached data for this line
    if haskey(state.cached_lines, line_number) && state.cached_lines[line_number].line_text == line_text
        return state.cached_lines[line_number]
    end

    # Tokenize the line (but don't cache it in the immutable state)
    tokens, token_data = tokenize_line_with_colors(string(line_text))
    return LineTokenData(line_number, string(line_text), tokens, token_data)
end

"""
Apply an editor action to the editor state.
Returns a new EditorState with the action applied.
"""
function apply_editor_action(state::EditorState, action::EditorAction)
    if action isa InsertText
        return apply_insert_text(state, action)
    elseif action isa MoveCursor
        return apply_move_cursor(state, action)
    elseif action isa DeleteText
        return apply_delete_text(state, action)
    elseif action isa ClipboardAction
        return apply_clipboard_action(state, action)
    elseif action isa SelectAll
        return apply_select_all(state, action)
    else
        return state  # Unknown action, return unchanged state
    end
end

"""
Apply text insertion action.
Returns a new EditorState with the text inserted.
"""
function apply_insert_text(state::EditorState, action::InsertText)
    if action.text == "\b"  # Handle backspace as special case
        return apply_delete_text(state, DeleteText(:backspace))
    end

    # Insert text at cursor position
    lines = get_lines(state)
    cursor = state.cursor
    new_cursor = cursor

    if cursor.line <= length(lines)
        current_line = lines[cursor.line]
        # Use safe character-based string operations
        chars = collect(current_line)
        line_length = length(chars)

        # Split line safely at cursor position
        cursor_pos = min(cursor.column - 1, line_length)
        before_cursor = if cursor_pos <= 0
            ""
        else
            join(chars[1:cursor_pos])
        end

        after_cursor = if cursor_pos >= line_length
            ""
        else
            join(chars[cursor_pos+1:end])
        end

        # Create new line with inserted text
        new_line = before_cursor * action.text * after_cursor
        lines[cursor.line] = new_line

        # Update cursor position
        if action.text == "\n"
            # Split line and move cursor to next line
            lines[cursor.line] = before_cursor
            insert!(lines, cursor.line + 1, after_cursor)
            new_cursor = CursorPosition(cursor.line + 1, 1)
        else
            # Move cursor forward by the character length of inserted text
            inserted_char_length = length(collect(action.text))
            new_cursor = CursorPosition(cursor.line, cursor.column + inserted_char_length)
        end
    else
        # Cursor is beyond the text, just append
        new_text = state.text * action.text
        if action.text == "\n"
            new_cursor = CursorPosition(cursor.line + 1, 1)
        else
            # Move cursor forward by the character length of inserted text
            inserted_char_length = length(collect(action.text))
            new_cursor = CursorPosition(cursor.line, cursor.column + inserted_char_length)
        end
        # Return early for append case
        return EditorState(
            new_text,
            new_cursor,
            state.is_focused,
            nothing,  # Clear selection when text changes
            nothing,
            Dict{Int,LineTokenData}(),  # Clear cache
            hash(new_text)
        )
    end

    # Create new state with updated text and cursor
    new_text = join(lines, "\n")
    return EditorState(
        new_text,
        new_cursor,
        state.is_focused,
        nothing,  # Clear selection when text changes
        nothing,
        Dict{Int,LineTokenData}(),  # Clear cache
        hash(new_text)
    )
end

"""
Apply cursor movement action.
Returns a new EditorState with the cursor moved and selection updated if needed.
"""
function apply_move_cursor(state::EditorState, action::MoveCursor)
    lines = get_lines(state)
    cursor = state.cursor

    new_cursor = if action.direction == :left
        if cursor.column > 1
            CursorPosition(cursor.line, cursor.column - 1)
        elseif cursor.line > 1
            prev_line = lines[cursor.line-1]
            CursorPosition(cursor.line - 1, length(collect(prev_line)) + 1)
        else
            cursor  # At beginning of text
        end
    elseif action.direction == :right
        if cursor.line <= length(lines)
            current_line = lines[cursor.line]
            line_length = length(collect(current_line))
            if cursor.column <= line_length
                CursorPosition(cursor.line, cursor.column + 1)
            elseif cursor.line < length(lines)
                CursorPosition(cursor.line + 1, 1)
            else
                cursor  # At end of text
            end
        else
            cursor
        end
    elseif action.direction == :up
        if cursor.line > 1
            prev_line = lines[cursor.line-1]
            prev_line_length = length(collect(prev_line))
            new_column = min(cursor.column, prev_line_length + 1)
            CursorPosition(cursor.line - 1, new_column)
        else
            CursorPosition(1, 1)  # Move to beginning
        end
    elseif action.direction == :down
        if cursor.line < length(lines)
            next_line = lines[cursor.line+1]
            next_line_length = length(collect(next_line))
            new_column = min(cursor.column, next_line_length + 1)
            CursorPosition(cursor.line + 1, new_column)
        else
            # Move to end of last line
            if !isempty(lines)
                last_line = lines[end]
                CursorPosition(length(lines), length(collect(last_line)) + 1)
            else
                CursorPosition(1, 1)
            end
        end
    elseif action.direction == :home
        CursorPosition(cursor.line, 1)
    elseif action.direction == :end
        if cursor.line <= length(lines)
            current_line = lines[cursor.line]
            CursorPosition(cursor.line, length(collect(current_line)) + 1)
        else
            cursor
        end
    else
        cursor  # Unknown direction
    end

    # Handle text selection
    new_selection_start = state.selection_start
    new_selection_end = state.selection_end

    if action.select
        # Extend or create selection
        if state.selection_start === nothing
            # Start new selection from original cursor position
            new_selection_start = cursor
            new_selection_end = new_cursor
        else
            # Extend existing selection - keep selection_start, update selection_end
            new_selection_end = new_cursor
        end
    else
        # Clear selection
        new_selection_start = nothing
        new_selection_end = nothing
    end

    return EditorState(
        state.text,
        new_cursor,
        state.is_focused,
        new_selection_start,
        new_selection_end,
        state.cached_lines,  # Keep cache since text didn't change
        state.text_hash
    )
end

"""
Apply text deletion action.
Returns a new EditorState with the text deleted.
"""
function apply_delete_text(state::EditorState, action::DeleteText)
    lines = get_lines(state)
    cursor = state.cursor
    new_cursor = cursor

    if action.direction == :backspace
        if cursor.column > 1
            # Delete character before cursor
            current_line = lines[cursor.line]
            chars = collect(current_line)
            char_pos = cursor.column - 1
            if char_pos > 0 && char_pos <= length(chars)
                new_chars = [chars[1:char_pos-1]; chars[char_pos+1:end]]
                lines[cursor.line] = join(new_chars)
                new_cursor = CursorPosition(cursor.line, cursor.column - 1)
            end
        elseif cursor.line > 1
            # Delete newline - merge with previous line
            prev_line = lines[cursor.line-1]
            current_line = lines[cursor.line]
            new_cursor_column = length(collect(prev_line)) + 1
            lines[cursor.line-1] = prev_line * current_line
            deleteat!(lines, cursor.line)
            new_cursor = CursorPosition(cursor.line - 1, new_cursor_column)
        end
    elseif action.direction == :delete
        if cursor.line <= length(lines)
            current_line = lines[cursor.line]
            chars = collect(current_line)
            char_pos = cursor.column - 1
            if char_pos >= 0 && char_pos < length(chars)
                # Delete character at cursor
                new_chars = [chars[1:char_pos]; chars[char_pos+2:end]]
                lines[cursor.line] = join(new_chars)
            elseif cursor.line < length(lines)
                # Delete newline - merge with next line
                next_line = lines[cursor.line+1]
                lines[cursor.line] = current_line * next_line
                deleteat!(lines, cursor.line + 1)
            end
        end
    end

    # Create new state with updated text and cursor
    new_text = join(lines, "\n")
    return EditorState(
        new_text,
        new_cursor,
        state.is_focused,
        nothing,  # Clear selection when text changes
        nothing,
        Dict{Int,LineTokenData}(),  # Clear cache since text changed
        hash(new_text)
    )
end

"""
Apply clipboard action.
Returns a new EditorState (placeholder implementation).
"""
function apply_clipboard_action(state::EditorState, action::ClipboardAction)
    # TODO: Implement clipboard operations
    # For now, just return the unchanged state
    return state
end

"""
Apply select all action.
Returns a new EditorState with all text selected.
"""
function apply_select_all(state::EditorState, action::SelectAll)
    lines = get_lines(state)
    if isempty(lines) || (length(lines) == 1 && isempty(lines[1]))
        # No text to select
        return state
    end

    # Set selection from start to end of text
    selection_start = CursorPosition(1, 1)
    last_line = lines[end]
    selection_end = CursorPosition(length(lines), length(collect(last_line)) + 1)

    return EditorState(
        state.text,
        selection_end,  # Move cursor to end
        state.is_focused,
        selection_start,
        selection_end,
        state.cached_lines,
        state.text_hash
    )
end