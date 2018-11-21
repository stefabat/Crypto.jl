

include("indicators.jl")

abstract type Strategy end


struct SMA <: Strategy
    short::Integer          # number of ticks for the short sma
    long::Integer           # number of ticks for the long sma
    persistence::Integer    # number of times
end


# apply simple moving average strategy
function apply(strategy::SMA, tickhistory::Vector{OHLC})

    p = strategy.persistence
    # number of datapoints needed
    npts = strategy.long + p + 1
    
    # extract close prices
    closeprices = map(x->x.close,tickhistory)[end-npts:end]
    
    # compute short and long sma
    shortsma = sma(closeprices, strategy.short)
    longsma  = sma(closeprices, strategy.long)

    # compute the difference between moving averages
    smadiff  = shortsma[end-1-p:end] - longsma[end-1-p:end]

    # buy/sell if crossing occurs and persists
    if smadiff[1] < 0.0
        if all(x -> x > 0.0, smadiff[2:end])
            return "buy"
        end
    elseif smadiff[1] > 0.0
        if all(x -> x < 0.0, smadiff[2:end])
            return "sell"
        end
    end

    # return nothing if criteria were not met
    return "none"
end


struct EMA <: Strategy
    short::Integer          # number of ticks for the short ema
    long::Integer           # number of ticks for the long ema
    persistence::Integer    # number of times
end


# apply exp moving average strategy
function apply(strategy::EMA, tickhistory::Vector{OHLC})

    p = strategy.persistence

    # compute ema over 3 times more points than the long ema
    npts = 3*(strategy.long + p + 1)

    # extract close prices
    closeprices = map(x->x.close,tickhistory)[end-npts:end]

    # compute short and long ema
    shortema = ema(closeprices, strategy.short)
    longema  = ema(closeprices, strategy.long)

    # compute the difference between moving averages only for
    # the required 2 + p points
    emadiff  = shortema[end-1-p:end] - longema[end-1-p:end]

    # buy/sell if crossing occurs and persists
    if emadiff[1] < 0.0
        if all(x -> x > 0.0, emadiff[2:end])
            return "buy"
        end
    elseif emadiff[1] > 0.0
        if all(x -> x < 0.0, emadiff[2:end])
            return "sell"
        end
    end

    # return nothing if criteria were not met
    return "none"
end



struct RSI <: Strategy
    period::Integer          # number of ticks for the short ema
    oversold::Integer       # threshold to buy or sell
    overbought::Integer
end


# apply RSI strategy
function apply(strategy::RSI, tickhistory::Vector{OHLC})

    # extract close prices
    closeprices = map(x->x.close,tickhistory)

    # compute short and long ema
    rsidata = rsi(closeprices, strategy.period)

    # buy/sell if crossing occurs and persists
    if rsidata[end] < strategy.oversold
        return "buy"
    elseif rsidata[end] > strategy.overbought
        return "sell"
    end

    # return nothing if criteria were not met
    return "none"
end


