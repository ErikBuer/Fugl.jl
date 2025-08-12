# This file contains the action application logic that was previously in editor_state.jl
# It's separated to resolve circular dependencies between editor_state.jl and editor_action.jl

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
    elseif action isa SelectWord
        return apply_select_word(state, action)
    elseif action isa StartMouseSelection
        return apply_start_mouse_selection(state, action)
    elseif action isa ExtendMouseSelection
        return apply_extend_mouse_selection(state, action)
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

"""
Apply select word action.
Returns a new EditorState with the word at the cursor position selected.
"""
function apply_select_word(state::EditorState, action::SelectWord)
    lines = get_lines(state)
    cursor = action.cursor_position
    
    if cursor.line <= 0 || cursor.line > length(lines)
        return state
    end
    
    line_text = lines[cursor.line]
    line_chars = collect(line_text)
    
    if isempty(line_chars)
        return state
    end
    
    # Clamp cursor position to line bounds
    char_pos = max(1, min(cursor.column, length(line_chars) + 1))
    
    # If cursor is at end of line, select the last word
    if char_pos > length(line_chars)
        char_pos = length(line_chars)
    end
    
    # Find word boundaries
    word_start = char_pos
    word_end = char_pos
    
    # Expand backwards to find word start
    while word_start > 1 && is_word_char(line_chars[word_start - 1])
        word_start -= 1
    end
    
    # Expand forwards to find word end
    while word_end <= length(line_chars) && is_word_char(line_chars[word_end])
        word_end += 1
    end
    
    # If we didn't find a word character, select nothing
    if word_start == word_end || !is_word_char(line_chars[word_start])
        return state
    end
    
    selection_start = CursorPosition(cursor.line, word_start)
    selection_end = CursorPosition(cursor.line, word_end)
    
    return EditorState(
        state.text,
        selection_end,  # Move cursor to end of selection
        state.is_focused,
        selection_start,
        selection_end,
        state.cached_lines,
        state.text_hash
    )
end

"""
Helper function to determine if a character is part of a word
"""
function is_word_char(c::Char)
    return isletter(c) || isdigit(c) || c == '_'
end

"""
Apply start mouse selection action.
Returns a new EditorState with selection started at the given position.
"""
function apply_start_mouse_selection(state::EditorState, action::StartMouseSelection)
    return EditorState(
        state.text,
        action.start_position,  # Move cursor to start position
        state.is_focused,
        action.start_position,  # Start selection
        action.start_position,  # End selection (initially same as start)
        state.cached_lines,
        state.text_hash
    )
end

"""
Apply extend mouse selection action.
Returns a new EditorState with selection extended to the given position.
"""
function apply_extend_mouse_selection(state::EditorState, action::ExtendMouseSelection)
    # Keep the existing selection start, extend to new end position
    selection_start = state.selection_start
    if selection_start === nothing
        # If no selection exists, start one from current cursor
        selection_start = state.cursor
    end
    
    return EditorState(
        state.text,
        action.end_position,  # Move cursor to end position
        state.is_focused,
        selection_start,
        action.end_position,
        state.cached_lines,
        state.text_hash
    )
end
