# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fugl.jl is a functional (immediate-mode style) GUI library for Julia built directly on OpenGL (ModernGL, GLAbstraction, GLFW). It targets engineering applications with real-time performance and a short distance from component to shader.

## Commands

```bash
# Run the full test suite (immutability test + doctests)
julia --project -e 'using Pkg; Pkg.test()'

# Run a single test file
julia --project -e 'using Test, Fugl; include("test/test_view_immutability.jl")'

# Run doctests only
julia --project test/doctest.jl

# Build docs locally (fast path; run from project root)
julia --project docs/make_local.jl

# Run an interactive demos (opens a GLFW window)
julia --project test/demo_file.jl
```

CI runs tests headlessly with `xvfb-run` on Julia 1.6 and 1.11. Doctests are part of both the test suite and the docs build, so docstring examples in `src/` and code blocks in `docs/src/*.md` must actually run and match their output.

The `test/` directory doubles as a collection of runnable demo scripts (`*_demo.jl`, `*_test.jl`); only `test_view_immutability.jl` and `doctest.jl` are wired into `runtests.jl`.

## Architecture

### Functional/immutable UI paradigm

The core rule: **all view structs must be immutable**. `test/test_view_immutability.jl` enforces this by reflecting over every `AbstractView` subtype — adding a `mutable struct` view fails CI. State lives outside the view tree (in user-held structs like `EditorState`, `SliderState`, `PlotState`) and is threaded through via constructor arguments and change callbacks (e.g. `on_interaction_state_change`, `on_state_change`). The UI function is re-invoked every frame to rebuild the whole view tree.

### The view interface (src/abstract_view.jl)

Every component subtypes `AbstractView` (or `SizedView` for components with intrinsic dimensions) and implements some of:

- `interpret_view(view, x, y, width, height, projection_matrix, cursor_pos, window_size)` — layout + render in one pass
- `detect_click(view, input_state, x, y, width, height, parent_z)` — returns a `ClickResult` whose `action` closure is executed *before* rendering each frame; z-order decides which handler wins
- `measure`, `measure_height(view, available_width)`, `measure_width(view, available_height)`, `preferred_width/height` — intrinsic sizing used by `Intrinsic*` wrappers and alignment components

### Frame loop (src/Fugl.jl `run`)

Per frame: GLFW callbacks buffer input into a mutable `InputState`; the loop snapshots it under `OPENGL_LOCK` (`collect_state!`), calls the user's `ui_function()` to build a fresh tree, runs `detect_click` (executing at most one captured action), then `interpret_view` on the whole tree, then overlays. Periodic `GC.gc` and freeze detection are built in.

### Component organization

- `src/components/` — primitives: layout (Row, Column, Align*, Padding, Fixed*/Intrinsic*/Flexible* sizing wrappers), Container/BaseContainer, text, text_editor, table, scroll_area, slider, image, etc. Registered and exported via `src/components.jl` (include order matters — files depend on earlier ones).
- `src/composite_components/` — built from primitives: buttons, TextField, NumberField, dropdown, modal, tooltip, tree, file_explorer, and the plot family (cartesian `plot/`, `polar_plot/`, `smith_plot/`).
- Interactive components follow the Container pattern: a base style plus optional `hover_style`/`pressed_style`/`disabled_style`, selected per-frame from an `InteractionState` (an immutable struct with copy-with-modifications constructors).

### Coordinates and DPI

Layout happens in "effective points" (logical GLFW coordinates divided by an optional manual scale); rendering maps that space to the framebuffer via orthographic projection matrices. `src/dpi_scaling.jl` provides conversions (`fugl_to_pixels`, `pixels_to_fugl`, etc.) — overlays and pixel-perfect rendering use a separate pixel-based projection matrix.

### Rendering

Shaders live in `src/shaders.jl` with a registration mechanism (`register_shader_initializer!`) so subsystems (e.g. plots) can add their own; see `docs/src/adding_shaders.md`. Global GL state (viewport, framebuffer stack) is tracked in `src/gl_context_state.jl`. `screenshot(ui_function, file, w, h)` renders one frame to an offscreen framebuffer — this is how docs generate their images and how you can verify visual changes headlessly.
