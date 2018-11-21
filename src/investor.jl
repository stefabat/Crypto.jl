
using DataFrames:DataFrame,join

# NOTE: signal has to be mutable, a mutable strategy allows
# for more flexibility, market should be ideally immutable
mutable struct Investor
    market::Market          # market in which it invests
    strategy::Strategy      # startegy used to trade
    signal::String          # invest signal
end


"""Basic constructor for `Investor` class"""
function Investor(market, strategy)
    println("Investor on market ",marketname(market)," created")
    return Investor(market,strategy,"none")
end


"""Observe the market `polltime` second and predict what to do"""
function observe(inv::Investor, interval::Dates.Period, polltime::Integer = 60)
    # infinite loop
    while true
        # base action is doing nothing
        inv.signal = "none"
        
        # retrieve history from market (last 100 ticks)
        # TODO: last 100 tick hardcoded -> to change
        tickhistory = history(inv.market,interval)[end-100:end]

        # try to apply strategy
        try
            inv.signal = apply(inv.strategy, tickhistory)
        catch e
            info(e)
        end

        # print info if prediction is buy/sell
        if inv.signal != "none"
            println(inv.signal, " @ ", last(inv.market))
        end

        # sleep for a while
        sleep(polltime)
    end
end


"""Run a strategy simulation on historic market data"""
function backtest(inv::Investor, interval::Dates.Period = Dates.Minute(10))
    # retrieve history from the market
    tickhistory = history(inv.market,interval)

    # initialize prediction array
    signal = Vector{String}(length(tickhistory))
    gain   = zeros(length(tickhistory))
    buyprice = -1.0
    lastsignal = "none" 

    # go through history
    for (i,ohlc) in enumerate(tickhistory)
        # print status info
        if mod(i,60) == 0
            println("\n-----\n",round(100*i/length(tickhistory),1)," %\n-----\n")
        end

        # base prediction is doing nothing
        signal[i]  = "none"

        # try to apply the strategy, (first iters throw bounds err)
        try
            signal[i] = apply(inv.strategy, tickhistory[1:i])
        catch e
            # info(e)
        end

        # if buy/sell triggered, print info
        if signal[i] != "none"
            if signal[i] == "buy"
                if buyprice < 0.0
                    println(i," :  ",signal[i], " @ ", ohlc.close)
                    buyprice = ohlc.close
                end
            elseif signal[i] == "sell"
                if buyprice > 0.0
                    println(i," : ",signal[i], " @ ", ohlc.close)
                    gain[i] = round(100*((ohlc.close - buyprice) / buyprice),2)
                    buyprice = -1.0
                end
            end
        end


    end

    data = DataFrame(open   = map(x->x.open ,tickhistory),
                     high   = map(x->x.high ,tickhistory),
                     low    = map(x->x.low  ,tickhistory),
                     close  = map(x->x.close,tickhistory),
                     bvol   = map(x->x.bvol,tickhistory),
                     mvol   = map(x->x.mvol,tickhistory),
                     time   = map(x->x.time,tickhistory),
                     signal = signal,
                     gain   = gain)
    return data
end

