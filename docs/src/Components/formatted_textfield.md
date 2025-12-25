# FormattedTextField

The `FormattedTextField` component provides advanced single-line text input with custom parsing, validation, and formatting. 
Suitable for specialized form inputs that need to enforce specific formats like hex colors, phone numbers, or custom data types.

## Basic Usage

``` @example FormattedTextFieldBasic
using Fugl

# Simple hex color validator
function hex_validator(text::String)
    # Allow only valid hex characters and #
    filtered = replace(uppercase(text), r"[^#0-9A-F]" => "")
    # Ensure at most one # at the beginning
    if startswith(filtered, "#")
        filtered = "#" * replace(filtered[2:end], "#" => "")
    end
    # Limit to 7 characters (#RRGGBB)
    return filtered[1:min(7, length(filtered))]
end

# Parser that formats and validates hex colors
function hex_parser(text::String)
    # Remove # prefix if present, ensure uppercase
    clean = uppercase(replace(text, "#" => ""))
    # Validate hex format (6 digits)
    if match(r"^[0-9A-F]{6}$", clean) !== nothing
        return ("#" * clean, clean)
    else
        return ("#000000", "000000")  # Default to black
    end
end

function MyApp()
    hex_state = Ref(EditorState("#FF5733"))
    
    Card(
        "Hex Color Input:",
        FormattedTextField(
            hex_state[];
            parser=hex_parser,
            validator=hex_validator,
            on_state_change=(new_state) -> hex_state[] = new_state,
            on_change=(hex_value) -> println("Valid hex: #", hex_value)
        )
    )
end

screenshot(MyApp, "formattedTextField_hex.png", 812, 300);
nothing #hide
```

![Hex Color FormattedTextField](formattedTextField_hex.png)
