#!/usr/bin/env julia

using Fugl
using Fugl: Text

function test_rotated_component()
    function MyApp()
        Container(
            Column([
                    Text("Normal Text"),
                    Rotate(Text("90° Rotated Text"), rotation_degrees=90.0f0),
                    Rotate(Text("45° Rotated Text"), rotation_degrees=45.0f0),
                    Rotate(
                        Container(
                            Column([
                                Text("Multi-line"),
                                Text("Rotated Container")
                            ]),
                            style=ContainerStyle(
                                background_color=Vec4{Float32}(0.2f0, 0.4f0, 0.6f0, 1.0f0),
                                padding=10.0f0
                            )
                        ),
                        rotation_degrees=30.0f0
                    )
                ], spacing=30.0, padding=20.0)
        )
    end

    Fugl.run(MyApp, title="Rotated Component Test", window_width_px=600, window_height_px=500)
end

test_rotated_component()
