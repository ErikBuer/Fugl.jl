# Fugl.jl

[![docs badge](https://img.shields.io/badge/docs-latest-blue.svg)](https://erikbuer.github.io/Fugl.jl/dev/)

`Fugl.jl` is a functional GUI library written in Julia using OpenGL.

It is intended to be a simple library with few depencdencies, suitable for making engineering applications.

Fugl has a short distance from component to shader, enabling fast and intuitive user interfaces.

## Example

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

## Demo Application

![Line Plot](docs/src/assets/ArrayApp_demo.gif)

<img width="1200" height="800" alt="image" src="https://github.com/user-attachments/assets/283e1f58-5a1a-4521-b362-576c6cebb155" />
