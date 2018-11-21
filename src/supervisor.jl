
include("order.jl")
import Exchange: API,getbalance


"""Define the `Supervisor` object. Can be either online or offline."""
struct Supervisor
    api::API    # API
    wallet::Dict{String,Float64}    # wallet
    investors::Vector{Investor}     # list of investors
    connected::Bool     # is it connected to the online account
end


"""Constructor of the `Supervisor` class"""
function Supervisor(api::API)
    wallet = initializewallet(api)
    investors = Vector{Investor}()
    return Supervisor(api,wallet,investors)
end


"""Add an investor to a supervisor"""
function addinvestor(sup::Supervisor,inv::Investor)
    push!(sup.investors,inv)
    println("Adding investor on market ",marketname(inv.market))
end


"""Place a limit buy order"""
function placeorder(sup::Supervisor,ord::BuyLimit)
    # check in the wallet if the balance is enough
    balance = getbalance(sup,ord.market.basecurrency)
    digits  = 10
    if balance >= ord.quantity
        # compute commission to pay
        commission = round(ord.quantity * ord.market.transactionfee,digits)
        # compute taxed market amount
        marketquantity = round((ord.quantity - commission) / ord.rate,digits)
        # check that the marketdamount is more than min trade size
        if marketquantity >= ord.market.mintradesize
            # update base balance in the wallet
            sup.wallet[ord.market.basecurrency]   -= ord.quantity
            sup.wallet[ord.market.marketcurrency] += marketquantity
            updatewallet(sup)
            printinfo(ord)
            return true
        else
            println("amount less than min trade size")
            return false
        end
    else
        println("not enough ",ord.market.basecurrency," in the wallet")
        print("buy amount: ",ord.quantity," ",ord.market.basecurrency)
        println("\tbalance: ",balance," ",ord.market.basecurrency)
        return false
    end
end


"""Place a limit sell order"""
function placeorder(sup::Supervisor,ord::SellLimit)
    # check in the wallet if the balance is enough
    balance = getbalance(sup,ord.market.marketcurrency)
    digits = 10
    if balance >= ord.quantity
        if ord.quantity >= ord.market.mintradesize
            # compute commission to pay
            commission = round(ord.quantity * ord.market.transactionfee,digits)
            # compute taxed base quantity
            basequantity = round((ord.quantity - commission) * ord.rate,digits)
            # update base balance in the wallet
            sup.wallet[ord.market.marketcurrency] -= ord.quantity
            sup.wallet[ord.market.basecurrency]   += basequantity
            updatewallet(sup)
            printinfo(ord)
            return true
        else
            println("amount less than min trade size")
            return false
        end
    else
        println("not enough ",ord.market.marketcurrency," in the wallet")
        print("sell amount: ",ord.quantity," ",ord.market.marketcurrency)
        println("\tbalance: ",balance," ",ord.market.marketcurrency)
        return false
    end
end


function getbalance(sup::Supervisor,currency::String)
    return sup.wallet[currency]
end


function updatewallet(sup::Supervisor)
    map(x->round(x,10),values(sup.wallet))
end


function printbalances(sup::Supervisor)
    println("### BALANCES")
    for currency in keys(sup.wallet)
        balance = round(get(sup.wallet,currency,0.0),10)
        if balance > 0.0
            println("### ",currency,": ",balance)
        end
    end
end


function initializewallet(api::API)
    currencies = getcurrencies(api)
    wallet = Dict{String,Float64}()
    for i = 1:length(currencies)
        push!(wallet,currencies[i]["Currency"] => 0.0)
    end
    return wallet
end
