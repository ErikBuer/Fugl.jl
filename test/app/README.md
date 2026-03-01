# JuliaC test app

## Quick Build

Use the build script that handles font copying:

```bash
# From repository root
julia test/app/build.jl
```

## Manual Build

```bash
# From repository root

# 1. Compile
julia --project -e "using JuliaC; JuliaC.main(ARGS)" -- --output-exe testapp --bundle build --trim=safe --experimental test/app/apptest.jl

# 2. Copy font to bundle (required!)
mkdir -p build/share/fonts
cp assets/fonts/FragmentMono-Regular.ttf build/share/fonts/

# 3. Run
./build/bin/testapp
```

**Note**: The font file must be copied to the bundle directory for the app to run.