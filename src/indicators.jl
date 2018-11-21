

"""Simple moving average over vector `v` with window `period`"""
function sma(v::Vector{Float64}, period::Integer)
    # allocate vector
    out = zeros(length(v)-period+1)
    # loop over vector and compute average
    for i = 1:length(out)
        out[i] = mean(v[i:i+period-1])
    end
    return out
end


"""Exponential moving average"""
function ema(v::Vector{Float64}, period::Integer; wilder::Bool = false)
    # allocate vector
    out = zeros(length(v)-period+1)
    # first element is an sma
    out[1] = mean(v[1:1+period-1])
    # weighting
    if wilder
        weight = 1.0 / period
    else
        weight = 2.0 / (period + 1)
    end
    # loop over prices and compute
    for i = 2:length(out)
        out[i] = weight*v[i+period-1] + (1.0-weight)*out[i-1]
    end
    return out
end


"""Relative strength index"""
function rsi(v::Vector{Float64}, period::Integer; wilder::Bool = true)
    # compute differences
    dv = diff(v)
    # initialize ups and downs arrays
    ups = zeros(length(dv))
    dws = zeros(length(dv))

    for i = 1:length(dv)
        if dv[i] > 0.0      # up
            ups[i] = dv[i]
        elseif dv[i] < 0.0  # down
            dws[i] = -dv[i]
        end
    end
    # obtain emas
    upsema = ema(ups, period; wilder=wilder)
    dwsema = ema(dws, period; wilder=wilder)
    # RS ratio
    rs = upsema ./ dwsema

    return 100 - 100 ./ (1 + rs)
end
