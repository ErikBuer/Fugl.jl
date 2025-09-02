# Rotate

The `Rotate` component applies rotation transformations to any child component.

```@example rotate_basic
using Fugl # hide
using Fugl: Text

function MyApp()
        Container(
            Row([
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

screenshot(MyApp, "basic_rotation.png", 812, 400)
nothing # hide
```

![Basic rotation](basic_rotation.png)
