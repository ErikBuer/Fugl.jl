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
    cache_id::UInt64  # Unique cache ID for render caching
end

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
    return EditorState(text, cursor, is_focused, nothing, nothing, cached_lines, text_hash, generate_cache_id())
end

"""
Create a new EditorState with the given text and cursor at the beginning.
"""
function EditorState(text::String)
    return EditorState(text, CursorPosition(1, 1), false, nothing, nothing, Dict{Int,LineTokenData}(), hash(text), generate_cache_id())
end

"""
Create a new EditorState from an existing state with keyword-based modifications.
"""
function EditorState(state::EditorState;
    text=state.text,
    cursor=state.cursor,
    is_focused=state.is_focused,
    selection_start=state.selection_start,
    selection_end=state.selection_end,
    cached_lines=state.cached_lines,
    text_hash=state.text_hash)
    return EditorState(text, cursor, is_focused, selection_start, selection_end, cached_lines, text_hash, state.cache_id)
end

"""
Split text into lines for easier manipulation.
Returns a vector of strings, where each string is a line of text.
"""
function get_lines(state::EditorState)
    return split(state.text, '\n')
end

"""
Split text into lines for easier manipulation.
Returns a vector of strings, where each string is a line of text.
"""
function get_lines(text::String)
    return split(text, '\n')
end

"""
Get the number of lines in the editor.
"""
function get_line_count(state::EditorState)
    return length(get_lines(state))
end

"""
Get the character length of a specific line (1-indexed).
Returns 0 if the line number is out of bounds.
"""
function get_line_length(state::EditorState, line_number::Int)
    lines = get_lines(state)
    if line_number >= 1 && line_number <= length(lines)
        return length(collect(lines[line_number]))  # Use collect for proper Unicode character counting
    end
    return 0
end

"""
Clamp cursor position to valid bounds within the text.
"""
function clamp_cursor(state::EditorState, cursor::CursorPosition)
    lines = get_lines(state)

    # Clamp line to valid range
    line = max(1, min(cursor.line, max(1, length(lines))))

    # Clamp column to valid range for the line
    if line <= length(lines)
        line_length = length(collect(lines[line]))
        column = max(1, min(cursor.column, line_length + 1))
    else
        column = 1
    end

    return CursorPosition(line, column)
end

"""
Check if a line needs to be re-tokenized based on text changes.
"""
function needs_retokenization(state::EditorState, line_number::Int)
    if !haskey(state.cached_lines, line_number)
        return true
    end

    lines = get_lines(state)
    if line_number > length(lines)
        return false  # Line doesn't exist
    end

    cached_line = state.cached_lines[line_number]
    current_line_text = lines[line_number]

    return cached_line.line_text != current_line_text
end

"""
Get or create tokenized line data for a specific line.
"""
function get_tokenized_line(state::EditorState, line_number::Int)
    # Check if we have cached data and it's still valid
    if haskey(state.cached_lines, line_number) && !needs_retokenization(state, line_number)
        return state.cached_lines[line_number]
    end

    # Get the line text
    lines = get_lines(state)
    if line_number > length(lines) || line_number < 1
        # Return empty tokenization for invalid line numbers
        return LineTokenData(line_number, "", [], [])
    end

    line_text = lines[line_number]

    # Tokenize the line (but don't cache it in the immutable state)
    tokens, token_data = tokenize_line_with_colors(string(line_text))
    return LineTokenData(line_number, string(line_text), tokens, token_data)
end
