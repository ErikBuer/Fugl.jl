#!/usr/bin/env julia

using Fugl
using Fugl: Text

function test_text_clipping()
    function MyApp()
        Container(
            Column([
                    Text("Wrapping enabled (default): This is a very long text that should wrap to multiple lines when it exceeds the container width", wrap_text=true),
                    Text("Clipping enabled: This is a very long text that should be clipped instead of wrapping to multiple lines", wrap_text=false),
                    Text("Short text", wrap_text=false)  # This should display normally since it fits
                ], spacing=20.0, padding=20.0),
            style=ContainerStyle(background_color=Vec4{Float32}(0.1f0, 0.1f0, 0.1f0, 1.0f0))
        )
    end

    Fugl.run(MyApp, title="Text Clipping Test", window_width_px=400, window_height_px=300)
end

test_text_clipping()
