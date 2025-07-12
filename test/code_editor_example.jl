using Fugl
using Fugl: Text
using Fugl: Vec4, ContainerStyle

function main()
    # State for the code editor
    code_text = Ref("""function hello_world()
    println("Hello, World!")
    x = 42  # This is a number
    name = "Julia"  # This is a string
    return x + length(name)
end

# Call the function
result = hello_world()""")

    is_focused = Ref(false)

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Simple Julia Code Editor"))),
            Container(
                CodeEditor(
                    code_text[],
                    is_focused[];
                    language=:julia,
                    on_change=(text) -> (code_text[] = text),
                    on_focus_change=(focused) -> (is_focused[] = focused)
                )
            ),
        ])
    end

    # Run the GUI
    Fugl.run(MyApp, title="Julia Code Editor", window_width_px=1000, window_height_px=700)
end

main()
