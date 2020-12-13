# Author: Piotr Berezowski, 236749

set CarTypes;  # typy samochodów

set Cities;  # miasta

param Distance{Cities, Cities};  # dystans między misastami

param CostMultiplier{CarTypes};  # mnożnik kosztu podstawowego dla typów samochodów

param CarSupply{CarTypes, Cities};  # podaż typu w miastach

param CarDemand{CarTypes, Cities};  # popyt na typ w miastach

var x{CarTypes, Cities, Cities} >= 0;

minimize cost:  sum{type in CarTypes, i in Cities, j in Cities} x[type, i, j] * Distance[i, j] * CostMultiplier[type];

s.t. supply_limit{type in CarTypes, i in Cities}:   sum{j in Cities} x[type, i, j] <= CarSupply[type, i];
s.t. demand_for_all_types{j in Cities}:     sum{type in CarTypes, i in Cities} x[type, i, j] >= sum{type in CarTypes} CarDemand[type, j];
s.t. demand_for_vip{j in Cities}:   sum{i in Cities} x['vip', i, j] >= CarDemand['vip', j];

solve;

printf "Result:   (From --> To)\n";
for {i in Cities, j in Cities : sum{type in CarTypes} x[type, i, j] > 0} {
    printf "%s  -->  %s  ", i, j;
    # printf "%s  &  %s", i, j;
    for{type in CarTypes} {
        printf "    (%s): %g", type, x[type, i, j];
        # printf "  & %g", x[type, i, j];
    }
    printf "\n";
    # printf "  \\\\ \n";
}

printf "\tOptimal cost: %g\n", sum{type in CarTypes, i in Cities, j in Cities} x[type, i, j] * Distance[i, j] * CostMultiplier[type];

end;
