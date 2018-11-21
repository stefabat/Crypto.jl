
abstract type Order end

"""Implement a buy limit order"""
struct BuyLimit <: Order
    market      # exchange market
    quantity    # quantity in base currency
    rate        # exchange rate
    time        # time of creation
end


"""Constructor of `BuyLimit` object"""
function BuyLimit(market,quantity,rate)
    return BuyLimit(market,quantity,rate,now())
end


"""Implement a sell limit order"""
struct SellLimit <: Order
    market      # exchange market
    quantity    # quantity in market currency
    rate        # exchange rate
    time        # time of creation
end


"""Constructor of `SellLimit` object"""
function SellLimit(market,quantity,rate)
    return SellLimit(market,quantity,rate,now())
end


"""Print buy limit order information"""
function printinfo(order::Order)
    bq = order.quantity             # base quantity
    cm = order.quantity * order.market.transactionfee # commission
    mq = (bq - cm) / order.rate     # taxed market quantity
    println("  ------------")
    println("\tOrder type: ",typeof(order),"    created @ ",order.time)
    println("\tquantity: ",mq," ",order.market.marketcurrency," @ ",order.rate)
    println("\tprice: ",bq," ",order.market.basecurrency)
    println("\tcommision: ",cm," ",order.market.basecurrency)
    println("  ------------")
end


# """Print sell limit order information"""
# function printinfo(order::SellLimit)
#     mq = order.quantity             # market quantity
#     cm = order.quantity * order.market.transactionfee # commission
#     bq = (mq - cm) / order.rate     # taxed base quantity
#     println("  ------------")
#     println("\tOrder type: SELL     created @ ",order.time)
#     println("\tsell: ",mq," ",order.market.marketcurrency," @ ",order.rate)
#     println("\ttot : ",bq," ",order.market.basecurrency)
#     println("\tcommision: ",cm," ",order.market.marketcurrency)
#     println("  ------------")
# end
