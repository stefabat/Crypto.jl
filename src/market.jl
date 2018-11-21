

include("exchange.jl")
using Exchange
import Base: last,connect

mutable struct Tick
    bid ::Float64   # highest bid price
    ask ::Float64   # lowest ask price
    last::Float64   # price of last transaction
end

struct OHLC
    open ::Float64  # price at opening of interval
    high ::Float64  # highest price in interval
    low  ::Float64  # lowest price in interavl
    close::Float64  # price at closing of interval
    bvol ::Float64  # volume in base currency
    mvol ::Float64  # volume in market currency
    time ::DateTime # timestamp
end

function OHLC(ohlc::OHLC, time::DateTime)
    open  = ohlc.open
    high  = ohlc.high
    low   = ohlc.low
    close = ohlc.close
    
    bv = ohlc.bvol
    mv = ohlc.mvol

    return OHLC(open,high,low,close,bv,mv,time)
end

function OHLC(ohlc::Dict)
    open  = ohlc["O"]
    high  = ohlc["H"]
    low   = ohlc["L"]
    close = ohlc["C"]
    
    bv = ohlc["BV"]
    mv = ohlc["V"]

    time = DateTime(ohlc["T"])
    # we add one hour because Bittrex ticks are on Greenwich time
    # time = DateTime(tick["T"]) + Dates.Hour(1)
    # assert(time < now())

    return OHLC(open,high,low,close,bv,mv,time)
end

struct Market
    api::API                    # api to which the market is connected

    marketname::String          # market name

    basecurrency    ::String    # base currency acronym
    basecurrencylong::String    # base currency full name
    basefee         ::Float64   # withdraw fee for base currency

    marketcurrency    ::String  # market currency acronym
    marketcurrencylong::String  # market currency full name
    marketfee         ::Float64 # withdraw fee for market currency

    mintradesize::Float64       # min tradeable amount [in base currency]
    makerfee    ::Float64       # maker transaction fee in %
    takerfee    ::Float64       # taker transaction fee in %

    tick::Tick                  # tick of the market

    history::Vector{OHLC}       # ohlc history in 1 min intervals
end


"""Constructor for the `Market` class for a given market name."""
function Market(api::Bittrex, marketname::String)

    marketdata = getmarketdata(api, marketname)

    mn = marketdata["MarketName"]

    bc = marketdata["BaseCurrency"]
    bl = marketdata["BaseCurrencyLong"]
    bf = marketdata["BaseFee"]

    mc = marketdata["MarketCurrency"]
    ml = marketdata["MarketCurrencyLong"]
    mf = marketdata["MarketFee"]

    mt = marketdata["MinTradeSize"]
    maf = marketdata["MakerFee"]
    taf = marketdata["TakerFee"]

    ticker = getticker(api,mn)
    tick = Tick(ticker["Bid"], ticker["Ask"], ticker["Last"])

    rawhistory = gettickshistory(api, marketname, "fiveMin")
    history = [OHLC(ohlc) for ohlc in rawhistory]

    return Market(api,mn,bc,bl,bf,mc,ml,mf,mt,maf,taf,tick,history)
end


"""Update the market ticker"""
function updatetick(market::Market)
    # get the tick and save the timestamp
    tick = getticker(market.api,marketname(market))

    # set tick info
    market.tick.bid  = tick["Bid"]
    market.tick.ask  = tick["Ask"]
    market.tick.last = tick["Last"]
end


"""Update the market ohlc history"""
function updatehistory(market::Market)
    history = gettickshistory(market.api,marketname(market))
    temp = []
    # loop in reverse from last ohlc tick
    for ohlc in reverse(history)
        t1 = DateTime(ohlc["T"])
        t2 = market.history[end].time
        if t1 > t2  # at least one older timestamp, continue to loop
            push!(temp,OHLC(ohlc))
        elseif t1 == t2 # we reached the same ohlc tick
            append!(market.history,reverse(temp))
            return  # we are done
        elseif t1 < t2    # somehow we skipped the matching date
            error("ohlc history update unsuccessful")
        end
    end
end


"""Poll the market every `polltick` seconds"""
function poll(market::Market, polltick::Integer)
    assert(polltick > 0)
    while true
        println("Polling market ",marketname(market)," @ ",now())
        updatetick(market)
        updatehistory(market)
        sleep(polltick)
    end
end


"""
Create and start an independent `Task` starting to poll the market.
"""
function connect(market::Market, polltick::Int)
    println("Connecting market ",marketname(market)," @ ",now())
    return @schedule poll(market, polltick)
end


"""
Kill the `Task` polling a market.
"""
function disconnect(market::Market, task::Task)
    try
        Base.throwto(task,InterruptException())
    catch
        println("Disconnecting market ",marketname(market)," @ ",now())
    end
end

# some getter functions
marketname(market::Market) = market.marketname
ask(market::Market)  = market.tick.ask
bid(market::Market)  = market.tick.bid
last(market::Market) = market.tick.last


"""Return OHLC history"""
function history(market::Market, interval::Dates.Period = Dates.Minute(5))
    low  = maxintfloat()
    bvol = mvol = high = close = 0.0
    old  = market.history[1]
    open = old.open
    hist = Vector{OHLC}()
    for ohlc in market.history
        oldtime = round(old.time,interval)
        newtime = round(ohlc.time,interval)
        if newtime == oldtime
            bvol += ohlc.bvol
            mvol += ohlc.mvol
            if high < ohlc.high
                high = ohlc.high
            end
            if low > ohlc.low
                low = ohlc.low
            end
        elseif newtime > oldtime || ohlc == last(market.history)
            close = old.close
            push!(hist,OHLC(open,high,low,close,bvol,mvol,oldtime))
            open = ohlc.open
            bvol = ohlc.bvol
            mvol = ohlc.mvol
            high = ohlc.high
            low  = ohlc.low
        end
        old = ohlc
    end
    return hist
end

"""Return the volume of last `period` in base currency"""
function basevolume(market::Market, period::Dates.Period = Dates.Hour(24))
    bv = 0.0
    tp = now() - period
    for ohlc in reverse(market.ohlc)
        if ohlc.time >= tp
            bv += ohlc.bvol
        else
            break
        end
    end
    return bv
end


"""Return the volume of last `period` in market currency"""
function marketvolume(market::Market, period::Dates.Period = Dates.Hour(24))
    mv = 0.0
    tp = now() - period
    for ohlc in reverse(market.ohlc)
        if ohlc.time >= tp
            mv += ohlc.mvol
        else
            break
        end
    end
    return mv
end


"""Convert an object of type `OHLC` into a `Dict`"""
function ohlc2dict(ohlc)
    dict = Dict{String,Any}()
    push!(dict,"open"=>ohlc.open)
    push!(dict,"high"=>ohlc.high)
    push!(dict,"low"=>ohlc.low)
    push!(dict,"close"=>ohlc.close)
    push!(dict,"bvol"=>ohlc.bvol)
    push!(dict,"mvol"=>ohlc.mvol)
    push!(dict,"time"=>ohlc.time)
    return dict
end
