using Tokenize

struct CodeEditorView <: AbstractView
    text::String              # Text content of the CodeEditor
    is_focused::Bool          # Focus state of the CodeEditor
    language::Symbol          # Programming language (:julia, :python, etc.)
    style::TextStyle          # Style for the CodeEditor
    on_change::Function       # Callback for text changes
    on_focus_change::Function # Callback for focus changes
end

function CodeEditor(
    text::String,
    is_focused;
    language::Symbol=:julia,
    style=TextStyle(),
    on_change::Function=() -> nothing,
    on_focus_change::Function=() -> nothing
)
    return CodeEditorView(text, is_focused, language, style, on_change, on_focus_change)
end

function measure(view::CodeEditorView)::Tuple{Float32,Float32}
    # The CodeEditor fills the parent container, so it doesn't have intrinsic size
    return (0.0f0, 0.0f0)
end

function apply_layout(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32)
    # The CodeEditor occupies the entire area provided by the parent
    return (x, y, width, height)
end

function interpret_view(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.font
    size_px = view.style.size_px

    # Render the background
    bg_color = view.is_focused ?
               Vec4{Float32}(0.05f0, 0.05f0, 0.1f0, 1.0f0) :  # Dark blue when focused
               Vec4{Float32}(0.1f0, 0.1f0, 0.15f0, 1.0f0)     # Darker when not focused

    draw_rectangle(generate_rectangle_vertices(x, y, width, height), bg_color, projection_matrix)

    # Split the text into lines
    lines = split(view.text, "\n")

    # Render each line with syntax highlighting
    current_y = y + view.style.size_px
    line_height = Float32(size_px * 1.2)  # Add some line spacing

    for (line_num, line) in enumerate(lines)
        if current_y > y + height
            break  # Don't render lines outside the visible area
        end

        render_line_with_syntax_highlighting(
            line,
            view.language,
            font,
            x + 10.0f0,  # Left padding
            current_y,
            size_px,
            projection_matrix,
            line_num
        )

        current_y += line_height
    end
end

function render_line_with_syntax_highlighting(
    line::AbstractString,
    language::Symbol,
    font,
    x::Float32,
    y::Float32,
    size_px::Int,
    projection_matrix,
    line_num::Int
)
    if language == :julia
        render_julia_syntax_highlighting(line, font, x, y, size_px, projection_matrix)
    else
        # Fallback to plain text rendering
        color = Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)  # Light gray
        draw_text(font, line, x, y, size_px, projection_matrix, color)
    end
end

function render_julia_syntax_highlighting(
    line::AbstractString,
    font,
    x::Float32,
    y::Float32,
    size_px::Int,
    projection_matrix
)
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

    current_x = x

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

        # Sort by position and render
        sort!(token_data, by=x -> x[1])

        current_pos = 1
        for (pos, text, color) in token_data
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
    catch e
        # If tokenization fails, render as plain text
        @warn "Failed to tokenize line: $line" exception = e
        draw_text(font, line, x, y, size_px, projection_matrix, default_color)
    end
end

function detect_click(view::CodeEditorView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    if view.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return  # Only handle clicks when the left button is pressed
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if !view.is_focused
            view.on_focus_change(true)  # Trigger focus change callback
        end
        return
    end

    if view.is_focused
        view.on_focus_change(false)  # Trigger focus change callback
    end
end

function handle_key_input(view::CodeEditorView, mouse_state::InputState)
    if !view.is_focused
        return  # Only handle key input when the CodeEditor is focused
    end

    text = view.text  # Start with the current text

    for key in mouse_state.key_buffer
        if key == '\b'  # Handle backspace
            if !isempty(text)
                text = text[1:end-1]
            end
        elseif key == '\r' || key == '\n'  # Handle enter/return
            text *= "\n"
        elseif key == '\t'  # Handle tab (add 4 spaces for indentation)
            text *= "    "
        else
            text *= string(key)
        end

        # Trigger the on_change callback
        view.on_change(text)
    end
end
