
import BittrexAPI

struct Bittrex <: API
    api::BittrexAPI.Bittrex
end

function bittrex(version = "v1.1")
    api = BittrexAPI.Bittrex(version)
    return Bittrex(api)
end
 
function bittrex(apikey, secretkey, version = "v1.1")
    api = BittrexAPI.Bittrex(apikey, secretkey, version)
    return Bittrex(api)
end

function getmarkets(api::Bittrex)
    return BittrexAPI.getmarkets(api.api)
end

function getcurrencies(api::Bittrex)
    return BittrexAPI.getcurrencies(api.api)
end

function getticker(api::Bittrex, market::String)
    return BittrexAPI.getticker(api.api, market)
end

function getmarketsummaries(api::Bittrex)
    return BittrexAPI.getmarketsummaries(api.api)
end

function getmarketsummary(api::Bittrex, market::String)
    return BittrexAPI.getmarketsummary(api.api, market)
end

function getorderbook(api::Bittrex, market::String, booktype::String = "both")
    return BittrexAPI.getorderbook(api.api, market, booktype)
end

function getmarkethistory(api::Bittrex, market::String)
    return BittrexAPI.getmarkethistory(api.api, market)
end

function buylimit(api::Bittrex, market::String, quantity, rate)
    return BittrexAPI.buylimit(api.api, market, quantity, rate)
end

function selllimit(api::Bittrex, market::String, quantity, rate)
    return BittrexAPI.selllimit(api.api, market, quantity, rate)
end

function cancel(api::Bittrex, uuid::String)
    return BittrexAPI.cancel(api.api, uuid)
end

function getopenorders(api::Bittrex)
    return BittrexAPI.getopenorders(api.api)
end

function getopenorders(api::Bittrex, market::String)
    return BittrexAPI.getopenorders(api.api, market)
end

function getbalances(api::Bittrex)
    return BittrexAPI.getbalances(api.api)
end

function getbalance(api::Bittrex, currency::String)
    return BittrexAPI.getbalance(api.api, currency)
end

function getdepositaddress(api::Bittrex, currency::String)
    return BittrexAPI.getdepositaddress(api.api, currency)
end

function withdraw(api::Bittrex, currency::String, quantity, address::String)
    return BittrexAPI.withdraw(api.api, currency, quantity, address)
end

function getorder(api::Bittrex, uuid::String)
    return BittrexAPI.getorder(api.api, uuid)
end

function getorderhistory(api::Bittrex)
    return BittrexAPI.getorderhistory(api.api)
end

function getorderhistory(api::Bittrex, market::String)
    return BittrexAPI.getorderhistory(api.apip, market)
end

function getwithdrawalhistory(api::Bittrex)
    return BittrexAPI.getwithdrawalhistory(api.api)
end

function getwithdrawalhistory(api::Bittrex, currency::String)
    return BittrexAPI.getwithdrawalhistory(api.api, currency)
end

function getdeposithistory(api::Bittrex)
    return BittrexAPI.getdeposithistory(api.api)
end

function getdeposithistory(api::Bittrex, currency::String)
    return BittrexAPI.getdeposithistory(api.api, currency)
end

function gettickshistory(api::Bittrex, market::String, interval = "oneMin")
    return BittrexAPI.gettickshistory(api.api, market, interval)
end

"""Get list of of markets names only"""
function getmarketslist(api::Bittrex)
    markets = BittrexAPI.getmarkets(api.api)
    marketnames = Vector{String}()
    sizehint!(marketnames,(length(markets)))
    for market in markets
        push!(marketnames,market["MarketName"])
    end
    return marketnames
end

"""Get all relevant info on all markets."""
function getmarketdata(api::Bittrex)
    # fetch data from api
    markets    = BittrexAPI.getmarkets(api.api)
    summaries  = BittrexAPI.getmarketsummaries(api.api)
    currencies = BittrexAPI.getcurrencies(api.api)

    # initialize the return array
    marketdata = []

    for market in markets
        # get all info from the relevant market
        summary    = findby(summaries,"MarketName",market["MarketName"])
        basecurr   = findby(currencies,"Currency",market["BaseCurrency"])
        marketcurr = findby(currencies,"Currency",market["MarketCurrency"])

        # create the entry and push it into the array
        data       = Dict("MarketName"         => market["MarketName"],
                          "MarketCurrency"     => market["MarketCurrency"],
                          "MarketCurrencyLong" => market["MarketCurrencyLong"],
                          "BaseCurrency"       => market["BaseCurrency"],
                          "BaseCurrencyLong"   => market["BaseCurrencyLong"],
                          "MinTradeSize"       => market["MinTradeSize"],
                          "BaseFee"            => basecurr["TxFee"],
                          "MarketFee"          => marketcurr["TxFee"],
                          "MakerFee"           => 0.0025,
                          "TakerFee"           => 0.0025,
                          "BaseVolume"         => summary["BaseVolume"],
                          "MarketVolume"       => summary["Volume"])

        push!(marketdata,data)
    end

    # sort them by decreasing base volume in last 24h
    sort!(marketdata,rev=true,by=x->x["BaseVolume"])

    return marketdata
end

"""Get all relevant info on a single market."""
function getmarketdata(api::Bittrex, marketname::String)
    # get list of markets and check that marketname exists
    assert(in(marketname,getmarketslist(api)))
    # fetch data from api
    summary    = BittrexAPI.getmarketsummary(api.api,marketname)
    markets    = BittrexAPI.getmarkets(api.api)
    currencies = BittrexAPI.getcurrencies(api.api)

    # find the market requested
    market = findby(markets, "MarketName", marketname)
    basecurr = findby(currencies, "Currency", market["BaseCurrency"])
    marketcurr = findby(currencies, "Currency", market["MarketCurrency"])

    # create the dictionary with all the info
    data       = Dict("MarketName"         => market["MarketName"],
                      "MarketCurrency"     => market["MarketCurrency"],
                      "MarketCurrencyLong" => market["MarketCurrencyLong"],
                      "BaseCurrency"       => market["BaseCurrency"],
                      "BaseCurrencyLong"   => market["BaseCurrencyLong"],
                      "MinTradeSize"       => market["MinTradeSize"],
                      "BaseFee"            => basecurr["TxFee"],
                      "MarketFee"          => marketcurr["TxFee"],
                      "MakerFee"           => 0.0025,
                      "TakerFee"           => 0.0025,
                      "BaseVolume"         => summary["BaseVolume"],
                      "MarketVolume"       => summary["Volume"])

    return data
end
