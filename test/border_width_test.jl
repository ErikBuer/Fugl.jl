using Fugl
using Fugl: Text

function main()
    function MyApp()
        Container(
            IntrinsicColumn([
                    IntrinsicHeight(Container(Text("Border Width Test"))), Container(
                        Text("Border Width: 1px");
                        style=ContainerStyle(border_width_px=1.0f0, border_color=Vec4{Float32}(1.0f0, 0.0f0, 0.0f0, 1.0f0))
                    ), Container(
                        Text("Border Width: 5px");
                        style=ContainerStyle(border_width_px=5.0f0, border_color=Vec4{Float32}(0.0f0, 1.0f0, 0.0f0, 1.0f0))
                    ), Container(
                        Text("Border Width: 10px");
                        style=ContainerStyle(border_width_px=10.0f0, corner_radius_px=50.0f0, border_color=Vec4{Float32}(0.0f0, 0.0f0, 1.0f0, 1.0f0))
                    ), Container(
                        Text("Border Width: 20px");
                        style=ContainerStyle(border_width_px=20.0f0, corner_radius_px=10.0f0, border_color=Vec4{Float32}(1.0f0, 0.0f0, 1.0f0, 1.0f0))
                    )
                ],
                padding=10.0f0, spacing=10.0f0)
        )
    end

    Fugl.run(MyApp, title="Border Width Test", window_width_px=400, window_height_px=500)
end

main()
