using Tokenize
using GLFW

"""
Tokenize a Julia line and return tokens with color data.
Returns (tokens, token_data) where token_data is [(position, text, color), ...]
"""
function tokenize_julia_line(line::String)
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
    default_color = Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)  # Default white

    try
        # Tokenize the line
        tokens = collect(tokenize(line))

        # Build a list of (position, text, color) tuples
        token_data = []

        # First pass: collect all tokens
        all_tokens = []
        for token in tokens
            if token.startbyte >= 0 && token.endbyte >= token.startbyte
                # Extract text using proper 1-based indexing
                start_pos = token.startbyte + 1
                end_pos = min(token.endbyte + 1, length(line))

                if start_pos <= length(line)
                    token_text = line[start_pos:end_pos]
                    push!(all_tokens, (start_pos, token_text, token.kind))
                end
            end
        end

        # Second pass: determine colors, checking for function calls
        for i in 1:length(all_tokens)
            pos, text, kind = all_tokens[i]

            # Check if this identifier is followed by a left parenthesis (function call)
            if kind == Tokenize.Tokens.IDENTIFIER && i < length(all_tokens)
                # Look for the next non-whitespace token
                next_idx = i + 1
                while next_idx <= length(all_tokens) && all_tokens[next_idx][3] == Tokenize.Tokens.WHITESPACE
                    next_idx += 1
                end

                # If next token is LPAREN, this is a function call
                if next_idx <= length(all_tokens) && all_tokens[next_idx][3] == Tokenize.Tokens.LPAREN
                    color = function_call_color
                else
                    color = get(colors, kind, default_color)
                end
            else
                color = get(colors, kind, default_color)
            end

            push!(token_data, (pos, text, color))
        end

        return (tokens, token_data)
    catch e
        # If tokenization fails, render as plain text
        @warn "Failed to tokenize line: $line" exception = e
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
Render a line using cached tokenization data.
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
            prev_line_length = length(lines[cursor.line-1])
            state.cursor = CursorPosition(cursor.line - 1, prev_line_length + 1)
        end
    elseif action.direction == :right
        current_line_length = cursor.line <= length(lines) ? length(lines[cursor.line]) : 0
        if cursor.column <= current_line_length
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
            # Delete character before cursor
            current_line = lines[cursor.line]
            new_line = current_line[1:cursor.column-2] * current_line[cursor.column:end]
            lines[cursor.line] = new_line
            state.cursor = CursorPosition(cursor.line, cursor.column - 1)
        elseif cursor.line > 1
            # Merge with previous line
            prev_line = lines[cursor.line-1]
            current_line = lines[cursor.line]
            lines[cursor.line-1] = prev_line * current_line
            deleteat!(lines, cursor.line)
            state.cursor = CursorPosition(cursor.line - 1, length(prev_line) + 1)
        end
    elseif action.direction == :delete
        if cursor.line <= length(lines)
            current_line = lines[cursor.line]
            if cursor.column <= length(current_line)
                # Delete character at cursor
                new_line = current_line[1:cursor.column-1] * current_line[cursor.column+1:end]
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
Apply clipboard action (placeholder for now).
"""
function apply_clipboard_action!(state::EditorState, action::ClipboardAction)
    # TODO: Implement clipboard actions
    # This would require platform-specific clipboard access
    @info "Clipboard action: $(action.action)"
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
        # Same line deletion
        current_line = lines[start_cursor.line]
        start_col = min(start_cursor.column, end_cursor.column)
        end_col = max(start_cursor.column, end_cursor.column)

        new_line = current_line[1:start_col-1] * current_line[end_col:end]
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
    end

    return nothing  # Unknown key event
end