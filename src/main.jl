# Including the Module file acts as "import Bittrex"

include("market.jl");
include("strategy.jl");
include("investor.jl");
# include("supervisor.jl")

api = Exchange.bittrex();
market = Market(api,"USDT-ETH");
strategy = EMA(9,20,3);
investor = Investor(market,strategy);
data = backtest(investor,Dates.Minute(20))

# printing only buy/sell operations
data[data[:, :signal] .!= "none", :]
# total gain/loss in percentage
round(reduce(*,1.0 .+ data[:gain]./100)*100 - 100,2)
# if we didn't do anything
round(((data[end,:close]-data[1,:close]) / data[1,:close])*100,2)

using PlotlyJS
trace = candlestick(x    =data[:time],
                    open =data[:open],
                    high =data[:high],
                    low  =data[:low] ,
                    close=data[:close]
)

# adding info on data
shortsma = sma(data[:close],strategy.short)
longsma  = sma(data[:close],strategy.long)
data[:short] = [repeat([DataFrames.missing],inner=strategy.short-1);shortsma]
data[:long]  = [repeat([DataFrames.missing],inner=strategy.long-1) ;longsma]


trace1 = PlotlyJS.scatter(x=data[3:end,:time],y=data[3:end,:short])
trace2 = PlotlyJS.scatter(x=data[6:end,:time],y=data[6:end,:long])

PlotlyJS.plot([trace,trace1,trace2])


cp = map(x->x["C"],hist)
bp = cp[buyt];
sp = cp[sellt];
bt = convert(Vector{Float64},buyt);
st = convert(Vector{Float64},sellt);

using Gnuplot
@gp(cp,"w l lc rgb 'blue'",bt,bp,"w p lc rgb 'green'",st,sp,"w p lc rgb 'red'")

basecurr   = "BTC"  # base currency with which we trade
minvolume  = 25     # min volume of market (in base curr)
maxmarkets = 5      # max number of markets in which we trade

supervisor = Supervisor(api)
supervisor.wallet["BTC"] = 0.1

markets = []
push!(markets,Market(api,"BTC-ETH"))
push!(markets,Market(api,"BTC-LTC"))
push!(markets,Market(api,"BTC-XMR"))
push!(markets,Market(api,"BTC-XRP"))
push!(markets,Market(api,"BTC-XLM"))

investors = []
for market in markets
    strategy = SimpleChange(-0.01,0.01,0.01)
    push!(investors,Investor(supervisor,market,strategy))
end

printbalances(supervisor)

for i in 1:13000
    for investor in investors
        try
            updatetick(investor.market)
            speculate(investor)
            println("  --- --- ---")
        catch e
            info(e)
        end
    end
    # printbalances(supervisor)
    # println("  --- --- ---")
end

printbalances(supervisor)

# apikey    = "f0ae2486450c4e53bbb8915ae8e73828"
# apisecret = "a4633eba5ced42288755ca1ae7fa4632"
# bittrex = Bittrex(apikey,apisecret)





# create the investors
# for market in marketdata
#     if market["BaseCurrency"] == basecurr && market["BaseVolume"] > minvolume
#         try
#             tick = getticker(bittrex,market["MarketName"])
#             strategy = SimpleChange(-0.01,0.01,0.01,[tick["Last"]])  # strategy
#             investor = Investor(supervisor,Market(bittrex,market,30),strategy,Vector())
#             addinvestor(supervisor,investor)
#         catch
#             println("skipping ",market["MarketName"]," market")
#         end
#     end
#     if length(supervisor.investors) == maxmarkets
#         break
#     end
# end

# markettasks = []
# for investor in supervisor.investors
#     push!(markettasks,connect(investor.market))
# end
