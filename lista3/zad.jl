# Autor: Piotr Berezowski, 236749
using JuMP, GLPK, Cbc, Statistics

function generalizedAssignment(n::Int, m::Int, p::Array{Int, 2}, c::Array{Int, 2}, T::Vector{Int}, optimizer=GLPK.Optimizer, verbose=false)
    # Algorytm dokładny
    # n - ilość zadań
    # m - ilość maszyn
    # p - zajmowana pojemność dla maszyny i zadania   (m x n)
    # c - koszt   (m x n)
    # T - pojemność maszyn
    @assert size(p) == (m, n)
    @assert size(c) == (m, n)
    @assert length(T) == m

    model = Model(optimizer)
    
    Jobs = 1:n
    Machines = 1:m

    @variable(model, x[Machines, Jobs], Bin)  # Zmienne decyzyjne

    @objective(model, Min, sum(x[i, j] * c[i, j] for i in Machines, j in Jobs))

    # Jedno zadanie może być przypisane tylko raz
    for j in Jobs
        @constraint(model, sum(x[i, j] for i in Machines) == 1)
    end

    # Ograniczenie na maksymalną pojemność maszyn
    for i in Machines
        @constraint(model, sum(x[i, j] * p[i, j] for j in Jobs) <= T[i])
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

function generalizedAssignmentRelaxation(n::Int, m::Int, p::Array{Int, 2}, c::Array{Int, 2}, T::Vector{Int}, J::Vector{Int}, M::Vector{Int}, deleted::Set{Tuple{Int, Int}}, optimizer=GLPK.Optimizer, verbose=false)
    # Relaksacja
    # n - początkowa ilość zadań
    # m - początkowa ilość maszyn
    # p - zajmowana pojemność dla maszyny i zadania   (m x n)
    # c - koszt   (m x n)
    # T - pojemność maszyn
    # J - pozostałe zadania
    # M - pozostałe maszyny
    # deleted - usunięte zmienne decyzyjne (== 0)
    @assert size(p) == (m, n)
    @assert size(c) == (m, n)
    @assert length(T) == m

    model = Model(optimizer)
    
    Jobs = 1:n
    Machines = 1:m

    @variable(model, x[Machines, Jobs] >= 0)  # zmienne decyzyjne

    @objective(model, Min, sum(x[i, j] * c[i, j] for i in Machines, j in Jobs))

    # Jedno zadanie może być przypisane tylko raz
    for j in J
        @constraint(model, sum(x[i, j] for i in Machines) == 1)
    end

    # Ograniczenie na pojemność maszyn
    for i in M
        @constraint(model, sum(x[i, j] * p[i, j] for j in J) <= T[i])
    end

    # Usunięte zmienne decyzyjne
    for (i,j) in deleted
        @constraint(model, x[i,j] == 0)
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


function readInputFile(filename)
    open(filename, "r") do io
        data = read(io, String)
        items = split(data)
        return [parse(Int, i) for i in items]
    end
end

function parseProblems(filename)
    """
    Wczytywanie i parsowanie pojedynczego pliku z OR-Library
    """
    vec = readInputFile(filename)
    idx = 2
    problems = []
    for p = 1:vec[1]
        machines = vec[idx]
        idx += 1
        jobs = vec[idx]
        idx += 1
        
        costs = zeros(Int, (machines, jobs))
        for i = 1:machines
            for j = 1:jobs
                costs[i, j] = vec[idx]
                idx += 1
            end
        end

        processingTime = zeros(Int, (machines, jobs))
        for i = 1:machines
            for j = 1:jobs
                processingTime[i, j] = vec[idx]
                idx += 1
            end
        end

        times = zeros(Int, machines)
        for i = 1:machines
            times[i] = vec[idx]
            idx += 1
        end
        prob = (jobs, machines, processingTime, costs, times)
        append!(problems, prob)
    end

    # problems - list of (n, m, p, c, T)
    return problems
end

function isCloseTo(x, y, delta=0.00000001)
    return abs(x-y) < delta
end

function algorithm(n1::Int, m1::Int, p1::Array{Int, 2}, c1::Array{Int, 2}, T1::Vector{Int})
    # Algorytm aproksymacyjny - wynik jako lista przypisań (maszyna, zadanie)
    n = copy(n1)
    m = copy(m1)
    p = copy(p1)
    c = copy(c1)
    T = copy(T1)

    F = Vector{Tuple{Int, Int}}()
    M = collect(1:m)
    J = collect(1:n)
    deleted = Set{Tuple{Int, Int}}()

    iter = 0
    while length(J) > 0
        iter += 1
        # step 1
        status, _, x = generalizedAssignmentRelaxation(
            n,
            m,
            p,
            c,
            T,
            J,
            M,
            deleted
        )
        if status != MOI.OPTIMAL
            error(status)
        end

        # step 2
        for i = 1:m
            for j = 1:n
                if isCloseTo(x[i,j], 1)
                    push!(F, (i, j))
                    setdiff!(J, [j])
                    T[i] -= p[i,j]
                elseif isCloseTo(x[i,j], 0)
                    push!(deleted, (i,j))
                end
            end
        end
        
        # step 3
        for i in M
            deg = length([1 for j in J if x[i,j] > 0])
            if deg == 1
                setdiff!(M, [i])
            elseif deg == 2 && sum(x[i, j] for j in J) >= 1
                setdiff!(M, [i])
            end
        end
    end
    return F, iter
end


function test(filename, output=false, withExact=true)
    # Generowanie tabeli dla pojedynczego zbioru problemów
    problems = parseProblems(filename)
    idx = 0
    while 5*idx < length(problems)
        problem = problems[idx*5+1:idx*5+5]
        idx += 1
        
        println("\n\nProblem $idx from set $filename    (|M| = $(problem[2]), |J| = $(problem[1]))")
        
        if withExact
            t1 = time()
            status, exactCost, exact = generalizedAssignment(
                problem[1],
                problem[2],
                problem[3],
                problem[4],
                problem[5]
            )
            t2 = time()
            if status != MOI.OPTIMAL
                error(status)
            end
            
            exactRelative = zeros(Float64, problem[2])
            for i in 1:problem[2]
                for j in 1:problem[1]
                    exactRelative[i] += problem[3][i, j] * exact[i, j]
                end
            end
            for i in 1:problem[2]
                exactRelative[i] /= problem[5][i]
            end

            println("  Exact:   ($(status))")
            println("   - Cost: $exactCost")
            println("   - Time: $(t2-t1) sec")
            println("   - Relative cap: $(round.(exactRelative; digits=3))")
            println("       [Min: $(round(minimum(exactRelative); digits=3))  Max: $(round(maximum(exactRelative); digits=3))]")

            if output
                open(filename * "_out", "a") do io
                    # |V|  &  |J|  &  [EXACT] cost  &  [EXACT] time  &  [EXACT] CAP: min & avg & max  &  [APPROX] cost  &  [APPROX] time  &  [APPROX] CAP: min & avg & max \\
                    write(io, "$(problem[2]) & $(problem[1]) & ")
                    write(io, "$exactCost & $(round(t2-t1; digits=4)) & ")
                    write(io, "$(round(minimum(exactRelative); digits=3)) & $(round(mean(exactRelative); digits=3)) & $(round(maximum(exactRelative); digits=3)) & ")
                end
            end
        end

        t3 = time()
        approx, iter = algorithm(
            problem[1],
            problem[2],
            problem[3],
            problem[4],
            problem[5]
        )
        t4 = time()
        
        approxCost = 0.0
        for (i,j) in approx
            approxCost += problem[4][i, j]
        end
        
        approxRelative = zeros(Float64, problem[2])
        for (i,j) in approx
            approxRelative[i] += problem[3][i, j]
        end
        for i in 1:problem[2]
            approxRelative[i] /= problem[5][i]
        end

        println("  Approx:   ($(iter)  iterations)")
        println("   - Cost: $approxCost")
        println("   - Time: $(t4-t3) sec")
        println("   - Relative cap: $(round.(approxRelative; digits=3))")
        println("       [Min: $(round(minimum(approxRelative); digits=3))  Max: $(round(maximum(approxRelative); digits=3))]")

        if output
            open(filename * "_out", "a") do io
                # |V|  &  |J|  &  [EXACT] cost  &  [EXACT] time  &  [EXACT] CAP: min & avg & max  &  [APPROX] cost  &  [APPROX] time  &  [APPROX] CAP: min & avg & max \\
                if !withExact
                    write(io, "$(problem[2]) & $(problem[1]) & ")
                    write(io, "--- & --- & ")
                    write(io, "--- & --- & --- & ")
                end
                write(io, "$approxCost & $(round(t4-t3; digits=4)) & ")
                write(io, "$(round(minimum(approxRelative); digits=3)) & $(round(mean(approxRelative); digits=3)) & $(round(maximum(approxRelative); digits=3)) & $(iter) \\\\ \n")
            end
        end
    end
end