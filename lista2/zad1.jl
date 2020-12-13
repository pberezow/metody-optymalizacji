# Author: Piotr Berezowski, 236749
using JuMP, GLPK, Cbc


function collectingFeatures(m::Int, n::Int, t::Vector{Int}, q::Array{Bool, 2}, optimizer=GLPK.Optimizer, verbose=true)
    # m - liczba cech
    # n - liczba serwerów
    # t - wektor czasów przeszukiwania serwerów (długość = n)
    # q - macierz określająca występowanie cech na serwerach (rozmiar m x n)

    @assert length(t) == n
    @assert size(q) == (m, n)

    model = Model(optimizer)
    
    Features = 1:m
    Servers = 1:n

    # x[i] określa, czy i-ty serwer będzie przeszukiwany
    @variable(model, x[Servers], Bin)

    # minimalizujemy łączny czas odczytu wszystkich cech z serwerów
    @objective(model, Min, sum(x[i] * t[i] for i in Servers))

    # każda cecha musi zostać odczytana
    @constraint(model, [i = Features], sum(x[j] * q[i, j] for j = Servers) >= 1)

    if verbose
        print(model)
        optimize!(model)
    else
        set_silent(model)
        optimize!(model)
        unset_silent(model)
    end

    status = termination_status(model)
    if status == MOI.OPTIMAL
        return status, objective_value(model), value.(x)
    else
        return status, nothing, nothing
    end
end


# DATA
featuresCount = 7
serversCount = 6

time = [1, 2, 5, 2, 4, 10]

# [3 x 2]
isOnServer = Array{Bool, 2}(
    [
        1 0 0 1 0 0;
        0 1 0 0 1 0;
        0 0 1 0 0 1;
        1 0 0 1 0 0;
        0 1 0 0 1 0;
        0 0 1 0 0 1;
        0 0 0 0 0 1
    ])

status, result, servers = collectingFeatures(featuresCount, serversCount, time, isOnServer)

if status == MOI.OPTIMAL
    println("Wynik: $(result)")
    print("Użyte serwery: ")
    for (idx, val) in enumerate(servers)
        if val == 1
            print(" $(idx)")
        end
    end
    println()
else
    println("Status: $(status)")
end