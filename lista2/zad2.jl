# Author: Piotr Berezowski, 236749
using JuMP, GLPK, Cbc


function settingProgram(I::Vector{Int}, m::Int, n::Int, r::Array{Int, 2}, t::Array{Int, 2}, M::Int, optimizer=GLPK.Optimizer, verbose=true)
    # I - zbiór funkcji do obliczenia (wchodzących w skład programu)
    # m - liczba funkcji w bibliotece
    # n - liczba podprogramów dla każdej funkcji
    # r - macierz potrzebnej pamięci (rozmiar m x n)
    # t - macierz czasu wykonania podprogramów (rozmiar m x n)
    # M - maksymalna pamięć

    @assert (m, n) == size(t)
    @assert (m, n) == size(r)

    model = Model(optimizer)

    Functions = 1:m
    Subroutines = 1:n

    # x[i, j] określa czy j-ty podporgram dla i-tej funkcji wchodzi w skład programu
    @variable(model, x[Functions, Subroutines], Bin)

    # minimalizujemy całkowity czas wykonania programu
    @objective(model, Min, sum(x[i, j] * t[i, j] for i in Functions, j in Subroutines))

    # dokładnie 1 podprogram dla każdej funkcji
    @constraint(model, [i = I], sum(x[i, j] for j in Subroutines) == 1)

    # ograniczenie na maksymalne zużycie pamięci
    @constraint(model, mem, sum(x[i, j] * r[i, j] for i in Functions, j in Subroutines) <= M)

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

I = [1, 2, 3, 4, 5]
functionsCount = 5
subroutinesCount = 4

maxMemmory = 10

memory = [
    10 1 1 2;
    2 2 3 1;
    2 3 1 1;
    2 3 1 1;
    2 3 1 1
]
time = [
    1 4 5 2;
    1 2 2 5;
    4 2 5 6;
    4 2 5 6;
    4 2 5 6
]

status, result, subroutines = settingProgram(I, functionsCount, subroutinesCount, memory, time, maxMemmory, Cbc.Optimizer)

if status == MOI.OPTIMAL
    println("Wynik: $(result)")
    println("Wybrane podprogramy: (funkcja --> podprogram)")
    for func in 1:size(subroutines)[1]
        for sr in 1:size(subroutines)[2]
            if subroutines[func, sr] == 1
                println("  $(func) --> $(sr)")
            end
        end
    end
else
    println("Status: $(status)")
end