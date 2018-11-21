
module Exchange

# abstract API type
abstract type API end

# import Bittrex API
include("bittrex.jl")
include("kraken.jl")

# api objects
export API
export Bittrex,Kraken
export bittrex,kraken

# public methods
export getmarkets,getmarketsummaries,getmarketsummary,getmarkethistory,getmarketslist
export getticker,getorderbook,getcurrencies
export getticker,gettickshistory,getmarketdata

# authenticated methods
export buylimit,selllimit,cancel,getopenorders
export getbalances,getbalance,getdepositaddress
export withdraw,getwithdrawalhistory
export getorder,getorderhistory,getdeposithistory

# used to find an item with key in an array of Dict
function findby(array::Vector,key,value)
    for dict in array
        if haskey(dict,key)
            if dict[key] == value
                return dict
            end
        else
            error("key ",key," does not exist")
        end
    end
    println("No ",key," with value ",value," found")
end

end