using Tokenize
using InteractiveUtils

"""
Abstract base type for text editor components.
Both CodeEditor and TextBox inherit from this type.
"""
abstract type AbstractTextEditorView <: AbstractView end

"""
Tokenize a Julia line and return tokens with color data.
Returns (tokens, token_data) where token_data is [(position, text, color), ...]
"""
function tokenize_julia_line(line::String)
    # Performance guards
    MAX_LINE_LENGTH = 1000  # Skip tokenization for very long lines
    MAX_PROCESSING_TIME = 0.005  # 5ms timeout - very conservative

    # Default neutral color
    default_color = Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)  # Default white

    # Skip tokenization for very long lines to prevent freezing
    if length(line) > MAX_LINE_LENGTH
        return ([], [(1, line, default_color)])
    end

    # Skip tokenization for empty lines
    if isempty(strip(line))
        return ([], [(1, line, default_color)])
    end

    # Define colors for different token types
    colors = Dict{Tokenize.Tokens.Kind,Vec4{Float32}}(
        Tokenize.Tokens.FUNCTION => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),    # Purple for keywords
        Tokenize.Tokens.END => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),        # Purple for keywords
        Tokenize.Tokens.RETURN => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),     # Purple for keywords
        Tokenize.Tokens.IF => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),         # Purple for keywords
        Tokenize.Tokens.ELSE => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),       # Purple for keywords
        Tokenize.Tokens.ELSEIF => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),     # Purple for keywords
        Tokenize.Tokens.FOR => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),        # Purple for keywords
        Tokenize.Tokens.WHILE => Vec4{Float32}(0.8f0, 0.4f0, 0.8f0, 1.0f0),      # Purple for keywords
        Tokenize.Tokens.STRING => Vec4{Float32}(0.4f0, 0.8f0, 0.4f0, 1.0f0),     # Green for strings
        Tokenize.Tokens.COMMENT => Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 1.0f0),    # Gray for comments
        Tokenize.Tokens.INTEGER => Vec4{Float32}(0.4f0, 0.6f0, 1.0f0, 1.0f0),    # Blue for numbers
        Tokenize.Tokens.FLOAT => Vec4{Float32}(0.4f0, 0.6f0, 1.0f0, 1.0f0),      # Blue for numbers
        Tokenize.Tokens.IDENTIFIER => Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0), # White for identifiers
        Tokenize.Tokens.PLUS => Vec4{Float32}(1.0f0, 0.8f0, 0.4f0, 1.0f0),       # Orange for operators
        Tokenize.Tokens.MINUS => Vec4{Float32}(1.0f0, 0.8f0, 0.4f0, 1.0f0),      # Orange for operators
        Tokenize.Tokens.STAR => Vec4{Float32}(1.0f0, 0.8f0, 0.4f0, 1.0f0),       # Orange for operators
        Tokenize.Tokens.EQ => Vec4{Float32}(1.0f0, 0.8f0, 0.4f0, 1.0f0),         # Orange for operators
    )

    # Color for function calls
    function_call_color = Vec4{Float32}(1.0f0, 1.0f0, 0.4f0, 1.0f0)  # Yellow for function calls

    try
        # Start timing for timeout protection
        start_time = time()

        # Tokenize the line with timeout protection
        tokens = collect(tokenize(line))

        # Check if we're taking too long - if so, use neutral color
        if time() - start_time > MAX_PROCESSING_TIME
            return ([], [(1, line, default_color)])
        end

        # Process tokens quickly and simply
        token_data = []
        char_pos = 1

        for token in tokens
            # Check timeout periodically
            if time() - start_time > MAX_PROCESSING_TIME
                return ([], [(1, line, default_color)])
            end

            if token.startbyte >= 0 && token.endbyte >= token.startbyte
                try
                    # Simple token text extraction - if it fails, skip
                    token_text = String(line[max(1, token.startbyte + 1):min(length(line), token.endbyte + 1)])

                    # Simple color assignment
                    color = get(colors, token.kind, default_color)

                    push!(token_data, (char_pos, token_text, color))
                    char_pos += length(collect(token_text))
                catch
                    # If any error occurs, just skip this token
                    continue
                end
            end
        end

        return (tokens, token_data)
    catch e
        # If tokenization fails completely, just use neutral color
        return ([], [(1, line, default_color)])
    end
end

"""
Tokenize a line of code and return tokens with color data.
Returns (tokens, token_data) where token_data is [(position, text, color), ...]
"""
function tokenize_line_with_colors(line::String)
    return tokenize_julia_line(line)
end

"""
Render a line using cached tokenization data with optimized batched rendering.
"""
function render_line_from_cache(
    line_data::LineTokenData,
    font,
    x::Float32,
    y::Float32,
    size_px::Int,
    projection_matrix
)
    current_x = x
    current_pos = 1
    line = line_data.line_text
    default_color = Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)

    # Sort token data by position
    sorted_tokens = sort(line_data.token_data, by=x -> x[1])

    for (pos, text, color) in sorted_tokens
        # Fill any gap with default color
        if pos > current_pos
            gap = line[current_pos:pos-1]
            if !isempty(gap)
                draw_text(font, gap, current_x, y, size_px, projection_matrix, default_color)
                current_x += measure_word_width(font, gap, size_px)
            end
        end

        # Draw the token
        if !isempty(text)
            draw_text(font, text, current_x, y, size_px, projection_matrix, color)
            current_x += measure_word_width(font, text, size_px)
        end

        current_pos = pos + length(text)
    end

    # Handle any remaining text
    if current_pos <= length(line)
        remaining = line[current_pos:end]
        if !isempty(remaining)
            draw_text(font, remaining, current_x, y, size_px, projection_matrix, default_color)
        end
    end
end

"""
Apply cursor movement action.
"""
function apply_move_cursor!(state::EditorState, action::MoveCursor)
    lines = get_lines(state)
    cursor = state.cursor

    if action.direction == :left
        if cursor.column > 1
            state.cursor = CursorPosition(cursor.line, cursor.column - 1)
        elseif cursor.line > 1
            # Move to end of previous line
            prev_line_char_length = length(collect(lines[cursor.line-1]))
            state.cursor = CursorPosition(cursor.line - 1, prev_line_char_length + 1)
        end
    elseif action.direction == :right
        current_line_char_length = cursor.line <= length(lines) ? length(collect(lines[cursor.line])) : 0
        if cursor.column <= current_line_char_length
            state.cursor = CursorPosition(cursor.line, cursor.column + 1)
        elseif cursor.line < length(lines)
            # Move to beginning of next line
            state.cursor = CursorPosition(cursor.line + 1, 1)
        end
    elseif action.direction == :up
        if cursor.line > 1
            prev_line_length = length(lines[cursor.line-1])
            new_column = min(cursor.column, prev_line_length + 1)
            state.cursor = CursorPosition(cursor.line - 1, new_column)
        end
    elseif action.direction == :down
        if cursor.line < length(lines)
            next_line_length = length(lines[cursor.line+1])
            new_column = min(cursor.column, next_line_length + 1)
            state.cursor = CursorPosition(cursor.line + 1, new_column)
        end
    elseif action.direction == :home
        state.cursor = CursorPosition(cursor.line, 1)
    elseif action.direction == :end
        if cursor.line <= length(lines)
            line_length = length(lines[cursor.line])
            state.cursor = CursorPosition(cursor.line, line_length + 1)
        end
    elseif action.direction == :word_left
        # Move to beginning of current or previous word
        state.cursor = find_word_boundary(state, cursor, :left)
    elseif action.direction == :word_right
        # Move to beginning of next word
        state.cursor = find_word_boundary(state, cursor, :right)
    elseif action.direction == :document_start
        state.cursor = CursorPosition(1, 1)
    elseif action.direction == :document_end
        if !isempty(lines)
            last_line_length = length(lines[end])
            state.cursor = CursorPosition(length(lines), last_line_length + 1)
        else
            state.cursor = CursorPosition(1, 1)
        end
    end
end

"""
Apply delete text action.
"""
function apply_delete_text!(state::EditorState, action::DeleteText)
    lines = get_lines(state)
    cursor = state.cursor

    if action.direction == :backspace
        if cursor.column > 1
            # Delete character before cursor using safe Unicode indexing
            current_line = lines[cursor.line]
            line_before = safe_substring(current_line, 1, cursor.column - 2)
            line_after = safe_substring_to_end(current_line, cursor.column)
            new_line = line_before * line_after
            lines[cursor.line] = new_line
            state.cursor = CursorPosition(cursor.line, cursor.column - 1)
        elseif cursor.line > 1
            # Merge with previous line
            prev_line = lines[cursor.line-1]
            current_line = lines[cursor.line]
            lines[cursor.line-1] = prev_line * current_line
            deleteat!(lines, cursor.line)
            # Use character length, not byte length
            prev_line_char_length = length(collect(prev_line))
            state.cursor = CursorPosition(cursor.line - 1, prev_line_char_length + 1)
        end
    elseif action.direction == :delete
        if cursor.line <= length(lines)
            current_line = lines[cursor.line]
            chars = collect(current_line)
            line_length = length(chars)

            if cursor.column <= line_length
                # Delete character at cursor using safe Unicode indexing
                before_cursor = if cursor.column <= 1
                    ""
                else
                    join(chars[1:cursor.column-1])
                end

                after_cursor = if cursor.column >= line_length
                    ""
                else
                    join(chars[cursor.column+1:end])
                end

                new_line = before_cursor * after_cursor
                lines[cursor.line] = new_line
            elseif cursor.line < length(lines)
                # Merge with next line
                next_line = lines[cursor.line+1]
                lines[cursor.line] = current_line * next_line
                deleteat!(lines, cursor.line + 1)
            end
        end
    elseif action.direction == :word_backspace
        # Delete word backward
        new_cursor = find_word_boundary(state, cursor, :left)
        delete_range!(state, new_cursor, cursor)
        state.cursor = new_cursor
    elseif action.direction == :word_delete
        # Delete word forward
        new_cursor = find_word_boundary(state, cursor, :right)
        delete_range!(state, cursor, new_cursor)
    elseif action.direction == :line_start
        # Delete from cursor to start of line
        new_cursor = CursorPosition(cursor.line, 1)
        delete_range!(state, new_cursor, cursor)
        state.cursor = new_cursor
    elseif action.direction == :line_end
        # Delete from cursor to end of line
        if cursor.line <= length(lines)
            line_length = length(lines[cursor.line])
            new_cursor = CursorPosition(cursor.line, line_length + 1)
            delete_range!(state, cursor, new_cursor)
        end
    end

    # Update the text and invalidate cache
    new_text = join(lines, "\n")
    update_text!(state, new_text)
end

"""
Apply clipboard action with platform-specific clipboard access.
"""
function apply_clipboard_action!(state::EditorState, action::ClipboardAction)
    if action.action == :copy
        text_to_copy = get_selected_text_or_line(state)
        if !isempty(text_to_copy)
            copy_to_clipboard(text_to_copy)
        end
    elseif action.action == :cut
        text_to_copy = get_selected_text_or_line(state)
        if !isempty(text_to_copy)
            copy_to_clipboard(text_to_copy)
            # Cut operation will be handled by the apply_clipboard_action in editor_actions.jl
        end
    elseif action.action == :paste
        # Paste operation will be handled by the apply_clipboard_action in editor_actions.jl
    end
end

"""
Get the currently selected text, or the current line if no text is selected.
"""
function get_selected_text_or_line(state::EditorState)::String
    if has_selection(state)
        return get_selected_text(state)
    else
        # Copy the entire current line
        lines = get_lines(state)
        if state.cursor.line <= length(lines)
            return lines[state.cursor.line]
        end
    end
    return ""
end

"""
Copy text to system clipboard using Julia's standard library.
"""
function copy_to_clipboard(text::String)
    try
        InteractiveUtils.clipboard(text)
    catch e
        @warn "Failed to copy to clipboard: $e"
    end
end

"""
Get text from system clipboard using Julia's standard library.
"""
function get_from_clipboard()::String
    try
        return InteractiveUtils.clipboard()
    catch e
        @warn "Failed to get from clipboard: $e"
        return ""
    end
end

"""
Find word boundary for word-based movement.
"""
function find_word_boundary(state::EditorState, cursor::CursorPosition, direction::Symbol)
    lines = get_lines(state)

    if cursor.line > length(lines)
        return cursor
    end

    current_line = lines[cursor.line]

    if direction == :left
        # Move left to find start of current or previous word
        pos = min(cursor.column - 1, length(current_line))

        # Skip whitespace
        while pos > 0 && isspace(current_line[pos])
            pos -= 1
        end

        # Skip non-whitespace (the word)
        while pos > 0 && !isspace(current_line[pos])
            pos -= 1
        end

        return CursorPosition(cursor.line, pos + 1)
    else  # :right
        # Move right to find start of next word
        pos = min(cursor.column, length(current_line))

        # Skip current word
        while pos <= length(current_line) && !isspace(current_line[pos])
            pos += 1
        end

        # Skip whitespace
        while pos <= length(current_line) && isspace(current_line[pos])
            pos += 1
        end

        return CursorPosition(cursor.line, pos)
    end
end

"""
Delete text between two cursor positions.
"""
function delete_range!(state::EditorState, start_cursor::CursorPosition, end_cursor::CursorPosition)
    lines = get_lines(state)

    if start_cursor.line == end_cursor.line
        # Same line deletion using safe Unicode indexing
        current_line = lines[start_cursor.line]
        start_col = min(start_cursor.column, end_cursor.column)
        end_col = max(start_cursor.column, end_cursor.column)

        line_before = safe_substring(current_line, 1, start_col - 1)
        line_after = safe_substring_to_end(current_line, end_col)
        new_line = line_before * line_after
        lines[start_cursor.line] = new_line
    else
        # Multi-line deletion (for future enhancement)
        # For now, just handle single-line cases
    end
end

"""
Convert a GLFW key event to an EditorAction.
"""
function key_event_to_action(key_event::KeyEvent)
    key = key_event.key
    mods = key_event.mods

    # Check for modifier keys
    shift_held = (mods & GLFW.MOD_SHIFT) != 0
    ctrl_held = (mods & GLFW.MOD_CONTROL) != 0
    cmd_held = (mods & GLFW.MOD_SUPER) != 0  # Command key on Mac

    # Movement actions - compare with integer values
    if key == Int(GLFW.KEY_LEFT)
        if cmd_held
            return MoveCursor(:home, shift_held)  # Command+Left = Home
        elseif ctrl_held
            return MoveCursor(:word_left, shift_held)  # Ctrl+Left = Word left
        else
            return MoveCursor(:left, shift_held)  # Simple left
        end
    elseif key == Int(GLFW.KEY_RIGHT)
        if cmd_held
            return MoveCursor(:end, shift_held)  # Command+Right = End
        elseif ctrl_held
            return MoveCursor(:word_right, shift_held)  # Ctrl+Right = Word right
        else
            return MoveCursor(:right, shift_held)  # Simple right
        end
    elseif key == Int(GLFW.KEY_UP)
        if cmd_held
            return MoveCursor(:document_start, shift_held)  # Command+Up = Document start
        else
            return MoveCursor(:up, shift_held)
        end
    elseif key == Int(GLFW.KEY_DOWN)
        if cmd_held
            return MoveCursor(:document_end, shift_held)  # Command+Down = Document end
        else
            return MoveCursor(:down, shift_held)
        end
    elseif key == Int(GLFW.KEY_HOME)
        return MoveCursor(:home, shift_held)
    elseif key == Int(GLFW.KEY_END)
        return MoveCursor(:end, shift_held)

        # Delete actions
    elseif key == Int(GLFW.KEY_BACKSPACE)
        if cmd_held
            return DeleteText(:line_start)  # Command+Backspace = Delete to line start
        elseif ctrl_held
            return DeleteText(:word_backspace)  # Ctrl+Backspace = Delete word backward
        else
            return DeleteText(:backspace)  # Simple backspace
        end
    elseif key == Int(GLFW.KEY_DELETE)
        if cmd_held
            return DeleteText(:line_end)  # Command+Delete = Delete to line end
        elseif ctrl_held
            return DeleteText(:word_delete)  # Ctrl+Delete = Delete word forward
        else
            return DeleteText(:delete)  # Simple delete
        end

        # Special character insertions
    elseif key == Int(GLFW.KEY_ENTER)
        return InsertText("\n")
    elseif key == Int(GLFW.KEY_TAB) && !shift_held
        return InsertText("    ")  # 4 spaces for tab

    # Clipboard actions (for future implementation)
    elseif key == Int(GLFW.KEY_C) && cmd_held
        return ClipboardAction(:copy)
    elseif key == Int(GLFW.KEY_X) && cmd_held
        return ClipboardAction(:cut)
    elseif key == Int(GLFW.KEY_V) && cmd_held
        return ClipboardAction(:paste)
    elseif key == Int(GLFW.KEY_A) && cmd_held
        return SelectAll()
    end

    return nothing  # Unknown key event
end

"""
Safely get a substring using character-based indexing instead of byte indexing.
This handles Unicode characters correctly.
"""
function safe_substring(text::AbstractString, start_char::Int, end_char::Int)
    try
        chars = collect(text)
        total_chars = length(chars)

        # Clamp indices to valid range
        start_idx = max(1, min(start_char, total_chars + 1))
        end_idx = max(0, min(end_char, total_chars))

        if start_idx > end_idx
            return ""
        else
            return join(chars[start_idx:end_idx])
        end
    catch e
        @warn "Error in safe_substring, returning empty string" exception = (e, catch_backtrace())
        return ""
    end
end

"""
Safely get a substring from start to end of string using character indexing.
"""
function safe_substring_to_end(text::AbstractString, start_char::Int)
    try
        chars = collect(text)
        total_chars = length(chars)
        start_idx = max(1, min(start_char, total_chars + 1))

        if start_idx > total_chars
            return ""
        else
            return join(chars[start_idx:end])
        end
    catch e
        @warn "Error in safe_substring_to_end, returning empty string" exception = (e, catch_backtrace())
        return ""
    end
end

"""
Get the character length of a string (not byte length).
"""
function char_length(text::AbstractString)
    try
        return length(collect(text))
    catch
        return 0
    end
end

"""
Convert mouse coordinates to cursor position within a text editor component.
This is a generic function that works for both CodeEditor and TextBox.
"""
function mouse_to_cursor_position(
    editor_state::EditorState,
    font,
    size_px::Int,
    padding_px::Float32,
    mouse_x::Float64,
    mouse_y::Float64,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32
)::CursorPosition
    # Calculate which line the mouse is on
    text_start_y = y + size_px + padding_px
    line_height = Float32(size_px * 1.2)

    lines = get_lines(editor_state)

    # Calculate line number (1-based)
    # We need to account for the fact that text is rendered at the baseline
    # The first line starts at text_start_y, so we adjust accordingly
    relative_y = Float32(mouse_y) - (text_start_y - size_px / 2)  # Adjust to center of first line
    line_number = max(1, min(length(lines), Int(round(relative_y / line_height)) + 1))

    # If we have no lines, return cursor at (1,1)
    if isempty(lines)
        return CursorPosition(1, 1)
    end

    # Get the line text
    if line_number > length(lines)
        # Mouse is below all text, put cursor at end of last line
        line_text = lines[end]
        line_number = length(lines)
    else
        line_text = lines[line_number]
    end

    # Calculate which character position the mouse is on
    text_start_x = x + padding_px
    relative_x = Float32(mouse_x) - text_start_x

    # If mouse is before the text starts, put cursor at beginning of line
    if relative_x <= 0
        return CursorPosition(line_number, 1)
    end

    # Find the character position by measuring text width
    current_x = 0.0f0
    column = 1

    # Convert string to characters for proper Unicode handling
    chars = collect(line_text)

    for (i, char) in enumerate(chars)
        # Measure width of this character
        char_width = measure_word_width(font, string(char), size_px)

        # If we're past the halfway point of this character, cursor goes after it
        if relative_x <= current_x + char_width / 2
            break
        end

        current_x += char_width
        column = i + 1
    end

    # Ensure column is within bounds
    column = min(column, length(chars) + 1)

    return CursorPosition(line_number, column)
end

"""
Check if there is an active text selection.
"""
function has_selection(state::EditorState)::Bool
    return state.selection_start !== nothing && state.selection_end !== nothing
end

"""
Get the selection range in a normalized form (start <= end).
Returns (start_pos, end_pos) or (nothing, nothing) if no selection.
"""
function get_selection_range(state::EditorState)::Tuple{Union{CursorPosition,Nothing},Union{CursorPosition,Nothing}}
    if !has_selection(state)
        return (nothing, nothing)
    end

    start_pos = state.selection_start
    end_pos = state.selection_end

    # Normalize selection so start <= end
    if compare_cursor_positions(start_pos, end_pos) > 0
        start_pos, end_pos = end_pos, start_pos
    end

    return (start_pos, end_pos)
end

"""
Compare two cursor positions. Returns:
- -1 if pos1 < pos2
- 0 if pos1 == pos2  
- 1 if pos1 > pos2
"""
function compare_cursor_positions(pos1::CursorPosition, pos2::CursorPosition)::Int
    if pos1.line < pos2.line
        return -1
    elseif pos1.line > pos2.line
        return 1
    else  # Same line
        if pos1.column < pos2.column
            return -1
        elseif pos1.column > pos2.column
            return 1
        else
            return 0
        end
    end
end

"""
Clear the text selection.
"""
function clear_selection(state::EditorState)::EditorState
    return EditorState(
        state.text,
        state.cursor,
        state.is_focused,
        nothing,  # Clear selection
        nothing,  # Clear selection
        state.cached_lines,
        state.text_hash
    )
end

"""
Set a text selection from start to end position.
"""
function set_selection(state::EditorState, start_pos::CursorPosition, end_pos::CursorPosition)::EditorState
    return EditorState(
        state.text,
        state.cursor,
        state.is_focused,
        start_pos,
        end_pos,
        state.cached_lines,
        state.text_hash
    )
end

"""
Get the currently selected text.
Returns empty string if no selection.
"""
function get_selected_text(state::EditorState)::String
    start_pos, end_pos = get_selection_range(state)

    if start_pos === nothing || end_pos === nothing
        return ""
    end

    lines = get_lines(state)

    if start_pos.line == end_pos.line
        # Selection within a single line
        if start_pos.line <= length(lines)
            line_chars = collect(lines[start_pos.line])
            start_col = clamp(start_pos.column - 1, 0, length(line_chars))
            end_col = clamp(end_pos.column - 1, 0, length(line_chars))

            if start_col < end_col
                return join(line_chars[start_col+1:end_col])
            end
        end
        return ""
    else
        # Multi-line selection
        result_parts = String[]

        for line_num in start_pos.line:end_pos.line
            if line_num <= length(lines)
                line_chars = collect(lines[line_num])

                if line_num == start_pos.line
                    # First line - from start position to end
                    start_col = clamp(start_pos.column - 1, 0, length(line_chars))
                    if start_col < length(line_chars)
                        push!(result_parts, join(line_chars[start_col+1:end]))
                    end
                elseif line_num == end_pos.line
                    # Last line - from beginning to end position
                    end_col = clamp(end_pos.column - 1, 0, length(line_chars))
                    if end_col > 0
                        push!(result_parts, join(line_chars[1:end_col]))
                    end
                else
                    # Middle line - entire line
                    push!(result_parts, lines[line_num])
                end
            end
        end

        return join(result_parts, "\n")
    end
end

"""
Delete the currently selected text and return new state.
Returns the state unchanged if no selection.
"""
function delete_selected_text(state::EditorState)::EditorState
    start_pos, end_pos = get_selection_range(state)

    if start_pos === nothing || end_pos === nothing
        return state
    end

    lines = get_lines(state)

    if start_pos.line == end_pos.line
        # Selection within a single line
        if start_pos.line <= length(lines)
            line_chars = collect(lines[start_pos.line])
            start_col = clamp(start_pos.column - 1, 0, length(line_chars))
            end_col = clamp(end_pos.column - 1, 0, length(line_chars))

            # Remove selected characters
            new_chars = [line_chars[1:start_col]; line_chars[end_col+1:end]]
            lines[start_pos.line] = join(new_chars)
        end

        new_cursor = CursorPosition(start_pos.line, start_pos.column)
    else
        # Multi-line selection
        if start_pos.line <= length(lines) && end_pos.line <= length(lines)
            # Get the parts to keep
            start_line_chars = collect(lines[start_pos.line])
            start_col = clamp(start_pos.column - 1, 0, length(start_line_chars))
            start_line_prefix = join(start_line_chars[1:start_col])

            end_line_chars = collect(lines[end_pos.line])
            end_col = clamp(end_pos.column - 1, 0, length(end_line_chars))
            end_line_suffix = join(end_line_chars[end_col+1:end])

            # Create the new combined line
            new_line = start_line_prefix * end_line_suffix

            # Remove the selected lines and replace with the combined line
            lines[start_pos.line] = new_line

            # Remove all lines between start and end (inclusive of end)
            if end_pos.line > start_pos.line
                for _ in 1:(end_pos.line-start_pos.line)
                    if start_pos.line + 1 <= length(lines)
                        deleteat!(lines, start_pos.line + 1)
                    end
                end
            end
        end

        new_cursor = CursorPosition(start_pos.line, start_pos.column)
    end

    # Create new state with updated text and cleared selection
    new_text = join(lines, "\n")
    return EditorState(
        new_text,
        new_cursor,
        state.is_focused,
        nothing,  # Clear selection
        nothing,  # Clear selection
        Dict{Int,LineTokenData}(),  # Clear cache since text changed
        hash(new_text)
    )
end