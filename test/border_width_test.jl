using Fugl
using Fugl: Text

function main()

    function MyApp()
        Container(
            IntrinsicRow([
                    Container(; style=ContainerStyle(border_width=0.0f0)),
                    Container(; style=ContainerStyle(border_width=4.0f0)),
                    Container(; style=ContainerStyle(border_width=10.0f0))
                ], spacing=20.0f0)
        )
    end


    Fugl.run(MyApp, title="Border Width Test", window_width_px=400, window_height_px=500)
end

main()
