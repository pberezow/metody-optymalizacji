# Author: Piotr Berezowski, 236749
using JuMP, GLPK, Cbc


function scheduleTasks(n::Int, d::Array{Int, 2}, optimizer=GLPK.Optimizer, verbose=true)
    # n - ilość zadań
    # d - czas wykonania zadań na kolejnych procesorach (rozmiar 3 x n, t[2, 10] oznacza czas wykonania 10 zadania na 2 procesorze)


    model = Model(optimizer)

    Tasks = 1:n
    T = sum(d) + 1
    Processors = 1:3

    @variable(model, x[Processors, Tasks] >= 0)  # moment rozpoczęcia zadania na procesorze
    @variable(model, M)  # zmienna do oznaczenia czasu zakonczenia ostatniego zadania
    @variable(model, Precedence[i=Tasks, j=Tasks; i != j], Bin)  # zadanie i wykonywane przed zadaniem j

    @objective(model, Min, M)

    # symulowanie max
    @constraint(model, [j = Tasks], x[3, j] + d[3, j] <= M)

    # zadania się nie nakładają - tylko jedno w tym samym czasie na jednym procesorze
    @constraint(model, [p = Processors, i = Tasks, j = Tasks; i < j], x[p, i] - x[p, j] + T*Precedence[i, j] >= d[p, j])
    @constraint(model, [p = Processors, i = Tasks, j = Tasks; i < j], x[p, j] - x[p, i] + T*(1 - Precedence[i, j]) >= d[p, i])

    # zadanie moze wystartowac na k+1 procesorze jesli zakonczylo sie na k-tym
    for p in 1:2
        @constraint(model, [j = Tasks], x[p, j] + d[p, j] <= x[p+1, j])
    end

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

n = 5
d = [
    1 2 3 4 5;
    2 3 4 3 2;
    1 2 3 1 2
]

status, result, times = scheduleTasks(n, d)

if status == MOI.OPTIMAL
    println("Wynik: $(result)")
    println("Kolejność zadań:")
    horizon = 0:sum(d)
    for p in 1:3
        for t in horizon
            print("-")
        end
        println()

        runningTill = -1
        for t in horizon
            printed = false
            for j in 1:n
                if times[p, j] == t
                    if t <= runningTill
                        println("ERROR")
                    end
                    print("$(j)")
                    printed = true
                    runningTill = t + d[p, j] - 1
                    break
                end
            end
            if !printed
                if t <= runningTill
                    print("#")
                else
                    print(" ")
                end
            end
        end
        println()
    end
    for t in horizon
        print("-")
    end
    println()
else
    println("Status: $(status)")
end