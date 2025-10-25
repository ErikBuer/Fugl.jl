# Fugl.jl

[![docs badge](https://img.shields.io/badge/docs-latest-blue.svg)](https://erikbuer.github.io/Fugl.jl/dev/)

`Fugl.jl` is a functional GUI library written in Julia using OpenGL.

It is intended to be a simple library with few dependencies, suitable for making engineering applications.

Fugl has a short distance from component to shader, enabling fast and intuitive user interfaces.

<img width="1080" height="1080" alt="Shot with name and subtitle" src="https://github.com/user-attachments/assets/bfdb3123-1972-4736-b686-2124bbcbd08d" />


## Simple Funcitonal API

```julia
using Fugl

function MyApp()
    Container(
        Row(
            Container(),
            Container(),
            Container(),
        )
    )
end

# Run the GUI:
# Fugl.run(MyApp, title="Fugl Demo", window_width_px=812, window_height_px=300, fps_overlay=true)

screenshot(MyApp, "row.png", 812, 300);
```

![Line Plot](docs/src/assets/row.png)

## Real-Time Performance

Fugl is written with real-time applications in mind.

![realtime plot](https://github.com/user-attachments/assets/5c0e1d61-dce3-4156-83ea-5eb35f298638)

## Demo Application

![Line Plot](docs/src/assets/ArrayApp_demo.gif)
