using Fugl
using Fugl: Text

function main()
    function MyApp()
        Container(
            IntrinsicColumn([
                    IntrinsicHeight(Container(Text("Separator Lines Demo"))),

                    # Horizontal line demo
                    IntrinsicHeight(Container(Text("Horizontal Line:"))),
                    HLine(end_length=20.0f0),  # Default horizontal line
                    IntrinsicHeight(Container(Text("Thick Red Horizontal Line:"))),
                    HLine(SeparatorStyle(line_width=5.0f0, color=Vec4{Float32}(1.0f0, 0.2f0, 0.2f0, 1.0f0))),

                    # Some content to separate
                    IntrinsicHeight(Container(Text("Content above vertical lines"))),
                    HLine(SeparatorStyle(line_width=2.0f0, color=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0)), -20.0f0),  # Blue line
                ],
                padding=10.0f0, spacing=10.0f0)
        )
    end

    Fugl.run(MyApp, title="Separator Lines Demo", window_width_px=600, window_height_px=400)
end

main()
