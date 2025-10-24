# AI generated demo. Intended to showcase Fugl.jl capabilities. Math is likely incorrect.

using Fugl
using Fugl: Text, TextButton, Table, TableStyle, TextStyle, LinePlotElement, SOLID, ContainerStyle, FixedHeight
using FFTW
using Printf
using Statistics

# ========== Signal Parameters ==========
const SAMPLE_RATE = 48e6           # Hz
const SIGNAL_LENGTH = 16384        # Number of samples
const FFT_LENGTH = 16384           # FFT size for display
const CENTER_FREQ = 2.41e9         # 2.41 GHz center frequency

# Carrier frequencies (relative to center)
const CARRIER_OFFSETS = [-10.213412345e6, 0.0, 0.124123515e6]  # -10 MHz, 0 MHz, +10 MHz from center
const CARRIER_POWERS_DBM = [-10.0, -20.0, -40.0]  # Power levels in dBm
const NOISE_FLOOR_DBM = -80.0

# Peak detection threshold (dB above noise floor)
const PEAK_THRESHOLD_DB = 20.0

# ========== Helper Functions ==========
"""Convert dB to linear power"""
db2pow(dB) = 10^(dB / 10)

"""
    wgn_dB(x::AbstractVector, dB::Real)

Apply white Gaussian noise of specified power in dBW to signal.

## Arguments:
- `x`: Clean time series
- `dB`: Target noise power level [dBW]

## Returns:
- Noisy signal
"""
function wgn_dB(x::AbstractVector, dB::Real)
    # Apply complex noise to complex signals. Half power noise to each component.
    if eltype(x) <: Complex
        wRe = randn(size(x)) .* sqrt(db2pow(dB) / 2)
        wIm = randn(size(x)) .* sqrt(db2pow(dB) / 2)
        w = wRe .+ 1im .* wIm
    else
        w = randn(size(x)) .* sqrt(db2pow(dB))
    end
    return x .+ w
end

# ========== Signal Generation ==========
function generate_rf_signal()
    """Generate RF signal with carriers and noise"""
    t = (0:SIGNAL_LENGTH-1) / SAMPLE_RATE
    signal = zeros(ComplexF64, SIGNAL_LENGTH)

    # Add carriers (CW tones with specified power)
    for (offset, power_dbm) in zip(CARRIER_OFFSETS, CARRIER_POWERS_DBM)
        power_watts = 10^((power_dbm - 30) / 10)  # Convert dBm to Watts
        amplitude = sqrt(2 * power_watts)  # Amplitude for sine wave (RMS = amplitude/sqrt(2))
        signal .+= amplitude .* exp.(1im .* 2π .* offset .* t)
    end

    # Add white Gaussian noise
    # Convert noise floor from dBm/Hz to dBW total power in bandwidth
    # Total noise power = PSD * Bandwidth
    noise_psd_dbw_hz = NOISE_FLOOR_DBM - 30  # Convert dBm to dBW
    noise_power_dbw = noise_psd_dbw_hz + 10 * log10(SAMPLE_RATE)  # Total power in dBW

    signal = wgn_dB(signal, noise_power_dbw)

    return signal
end

# ========== FFT and Spectrum Calculation ==========
function compute_spectrum(signal, fft_length=FFT_LENGTH)
    """Compute power spectral density from signal"""
    # Take FFT of specified length
    fft_result = fft(signal[1:min(fft_length, length(signal))])

    # Compute PSD using Welch-like method
    # PSD = |FFT|^2 / (Fs * N) where Fs is sample rate and N is FFT length
    # This gives us power spectral density in W/Hz
    psd_linear = abs2.(fft_result) / (SAMPLE_RATE * fft_length)

    # Convert to dBm/Hz: P_dBm = 10*log10(P_W * 1000)
    power_dbm = 10 .* log10.(psd_linear * 1000)

    # FFT shift to center DC
    power_dbm_shifted = fftshift(power_dbm)

    # Generate frequency axis in absolute MHz
    freqs_relative = fftshift(fftfreq(fft_length, SAMPLE_RATE))  # Hz relative to center
    freqs_absolute_mhz = (CENTER_FREQ .+ freqs_relative) ./ 1e6  # Convert to absolute MHz

    return freqs_absolute_mhz, power_dbm_shifted
end

# ========== Peak Detection ==========
function detect_peaks(freqs_mhz, power_dbm, threshold_db=PEAK_THRESHOLD_DB)
    """Detect peaks in spectrum above threshold
    freqs_mhz: absolute frequencies in MHz
    """
    noise_estimate = median(power_dbm)
    threshold = noise_estimate + threshold_db

    peaks = []
    for i in 2:length(power_dbm)-1
        # Simple peak detection: local maximum above threshold
        if power_dbm[i] > threshold &&
           power_dbm[i] > power_dbm[i-1] &&
           power_dbm[i] > power_dbm[i+1]

            # freqs_mhz is already in absolute MHz
            freq_ghz = freqs_mhz[i] / 1e3  # Convert MHz to GHz
            push!(peaks, (freq_mhz=freqs_mhz[i], freq_ghz=freq_ghz, power_dbm=power_dbm[i]))
        end
    end

    # Sort by power (strongest first)
    sort!(peaks, by=p -> p.power_dbm, rev=true)

    return peaks
end


# Generate signal and compute spectrum
signal = generate_rf_signal()
freqs, power_dbm = compute_spectrum(signal)
peaks = detect_peaks(freqs, power_dbm)

# Create plot state for zoom control with fixed y-axis range
plot_state = Ref(PlotState(y_min=-100.0f0))

# Define plot style
plot_style = PlotStyle(
    background_color=Vec4{Float32}(0.1, 0.1, 0.15, 1.0),  # Dark background
    grid_color=Vec4{Float32}(0.3, 0.3, 0.35, 1.0),        # Subtle grid
    axis_color=Vec4{Float32}(0.8, 0.8, 0.8, 1.0),         # Light axes
    show_grid=true,
    padding=54.0f0,
    x_label="MHz",
    y_label="dBm/Hz",
    show_x_label=true,
    show_y_label=true,
)

# Prepare peak table data
headers = ["Frequency (GHz)", "Frequency (MHz)", "Power (dBm/Hz)"]

# Prepare peak table data
headers = ["Frequency (GHz)", "Offset (MHz)", "Power (dBm)"]
table_data = [
    [
        @sprintf("%.4f", peak.freq_ghz),
        @sprintf("%.2f", peak.freq_mhz),
        @sprintf("%.1f", peak.power_dbm)
    ]
    for peak in peaks
]

# If no peaks detected, show placeholder
if isempty(table_data)
    table_data = [["No peaks", "detected", "---"]]
end

# Dark theme table style
dark_table_style = TableStyle(
    header_background_color=Vec4f(0.1, 0.4, 0.15, 0.6),  # Dark green to match plot trace
    header_text_style=TextStyle(size_px=15, color=Vec4f(1.0, 1.0, 1.0, 1.0)),  # White text
    cell_background_color=Vec4f(0.12, 0.12, 0.16, 1.0),  # Dark background
    cell_alternate_background_color=Vec4f(0.16, 0.16, 0.20, 1.0),  # Slightly lighter for alternating rows
    cell_text_style=TextStyle(size_px=14, color=Vec4f(0.85, 0.85, 0.85, 1.0)),  # Light text
    show_grid=true,
    grid_color=Vec4f(0.3, 0.3, 0.35, 1.0),  # Subtle grid
    cell_padding=10.0f0,
)

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark background
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),  # Subtle border
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for titles
)

# Dark theme button style
dark_button_style = ContainerStyle(
    background_color=Vec4f(0.2, 0.4, 0.6, 1.0),  # Blue button
    border_color=Vec4f(0.3, 0.5, 0.7, 1.0),      # Lighter blue border
    border_width=1.0f0,
    padding=8.0f0,
    corner_radius=4.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme button text style
dark_button_text_style = TextStyle(
    size_px=14,
    color=Vec4f(1.0, 1.0, 1.0, 1.0)  # White text
)

function MyApp()
    # Create spectrum plot element
    spectrum_element = LinePlotElement(
        Float32.(power_dbm);
        x_data=Float32.(freqs),
        color=Vec4{Float32}(0.2, 0.8, 0.3, 1.0),  # Green trace
        width=2.0f0,
        line_style=SOLID,
        label="Spectrum"
    )

    IntrinsicColumn([
            # Spectrum plot card
            Card(
                "Spectrum Analyzer",
                Plot(
                    [spectrum_element],
                    plot_style,
                    plot_state[],
                    (new_state) -> plot_state[] = new_state
                ),
                style=dark_card_style,
                title_style=dark_title_style
            ),

            # Peak detection table card
            FixedHeight(
                Card(
                    "Peak Table",
                    Table(
                        headers,
                        table_data,
                        style=dark_table_style
                    ),
                    style=dark_card_style,
                    title_style=dark_title_style
                ),
                200.0f0  # Fixed height in pixels
            ),], padding=0.0, spacing=0.0)
end

Fugl.run(MyApp, title="Spectrum Analyzer Demo - Fugl.jl", window_width_px=1200, window_height_px=800, fps_overlay=false)

