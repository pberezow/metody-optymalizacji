# Author: Piotr Berezowski, 236749

set BasicProducts;   # Products A and B
set SecondaryProducts;   # Products C and D
set Products := BasicProducts union SecondaryProducts;   # All products
set RawMaterials;   # Set of s1 s2 and s3

param RawMaterialsLowerBound{RawMaterials};   # Lower bound on ammount of each material
param RawMaterialsUpperBound{RawMaterials};   # Upper bound on ammount of each material

param WasteRatio{RawMaterials, BasicProducts};   # How much waste is produced from 1kg of material

param Value{Products};   # Profit from 1kg of final product

param MaterialCost{RawMaterials};   # Cost of 1kg of each material

param UtilizationCost{RawMaterials, BasicProducts};   # Cost of waste utilization

var x{RawMaterials, Products} >= 0;   # How much material is used to produce each product
var y{RawMaterials, BasicProducts} >= 0;   # How much wastes is used to produce secondary products


maximize profit: 
    sum{p in BasicProducts} Value[p] * (sum{m in RawMaterials} (1-WasteRatio[m, p])*x[m, p])
    + Value['C'] * sum{m in RawMaterials}(x[m, 'C'] + y[m, 'A'])
    + Value['D'] * sum{m in RawMaterials}(x[m, 'D'] + y[m, 'B'])
    - sum{m in RawMaterials, p in Products} MaterialCost[m] * x[m, p]
    - sum{m in RawMaterials, p in BasicProducts} UtilizationCost[m, p] * (WasteRatio[m,p]*x[m,p] - y[m,p]);

# Ammount of bought material need to be >= lowerBound and <= upperBound
s.t. materials_lower_bound{m in RawMaterials}: sum{p in Products} x[m, p] >= RawMaterialsLowerBound[m];
s.t. materials_upper_bound{m in RawMaterials}: sum{p in Products} x[m, p] <= RawMaterialsUpperBound[m];

# Limit ammount of wastes used to produce secondary product, can't be > than all available wastes
s.t. used_materials{m in RawMaterials, p in BasicProducts}: y[m, p] <= WasteRatio[m,p] * x[m,p];

# Proportions of each ingredients included in each product blend
s.t. blend_A_1: x[1, 'A'] >= 0.2 * sum{m in RawMaterials} x[m, 'A'];
s.t. blend_A_2: x[2, 'A'] >= 0.4 * sum{m in RawMaterials} x[m, 'A'];
s.t. blend_A_3: x[3, 'A'] <= 0.1 * sum{m in RawMaterials} x[m, 'A'];

s.t. blend_B_1: x[1, 'B'] >= 0.1 * sum{m in RawMaterials} x[m, 'B'];
s.t. blend_B_3: x[3, 'B'] <= 0.3 * sum{m in RawMaterials} x[m, 'B'];

s.t. blend_C_1: x[1, 'C'] = 0.2 * sum{m in RawMaterials} (x[m, 'C'] + y[m, 'A']);
s.t. blend_C_2: x[2, 'C'] = 0;
s.t. blend_C_3: x[3, 'C'] = 0;

s.t. blend_D_1: x[1, 'D'] = 0;
s.t. blend_D_2: x[2, 'D'] = 0.3 * sum{m in RawMaterials} (x[m, 'D'] + y[m, 'B']);
s.t. blend_D_3: x[3, 'D'] = 0;

solve;

printf "Max profit: %g$\n\n", profit;

for{m in RawMaterials} {
    printf "Total of %s material used: %g kg\n", m, sum{p in Products} x[m, p];
}
printf "\n";
for{p in BasicProducts} {
    printf "Produce %g kg of product %s using:\n", sum{m in RawMaterials} (1-WasteRatio[m, p]) * x[m,p], p;
    for{m in RawMaterials} {
        printf "    %g kg of %s material\n", x[m, p], m;
    }
    printf "\n";
}

printf "Produce %g kg of product C using:\n", sum{m in RawMaterials} (x[m, 'C'] + y[m, 'A']);
printf "    %g kg of 1 material\n", x[1, 'C'];
printf "    %g kg of waste from product A\n", sum{m in RawMaterials}y[m, 'A'];

printf "\n";

printf "Produce %g kg of product D using:\n", sum{m in RawMaterials} (x[m, 'D'] + y[m, 'B']);
printf "    %g kg of 2 material\n", x[2, 'D'];
printf "    %g kg of waste from product B\n", sum{m in RawMaterials}y[m, 'B'];

printf "\n";

for{p in BasicProducts} {
    printf "Total of waste from product %s to utilize: %g\n", p, sum{m in RawMaterials} (WasteRatio[m, p] * x[m,p] - y[m, p]);
}

# for{m in RawMaterials} {
#     printf "%s   ", m;
#     for{p in Products} {
#         printf "& (%s)%g   ",p, x[m, p];
#     }
#     printf "& %g \\\\ \n", sum{p in Products} x[m, p];
# }

# printf "\\textbf{Produkt} & \\textbf{Surowiec} ";
# printf "& \\textbf{Użyte} & \\textbf{Zniszczone} & \\textbf{Razem} \\\\ \n";
# printf "\\hline\n";
# for{p in BasicProducts} {
#     for{m in RawMaterials} {
#         printf "%s   & %s   & %g   & %g   & %g \\\\ \n", p, m, y[m, p], WasteRatio[m, p] * x[m,p] - y[m, p], WasteRatio[m, p] * x[m,p];
#     }
#     printf "%s   & 1 + 2 + 3   & %g   & %g   & %g \\\\ \n", p, sum{m in RawMaterials}y[m, p], sum{m in RawMaterials} (WasteRatio[m, p] * x[m,p] - y[m, p]), sum{m in RawMaterials} WasteRatio[m, p] * x[m,p];
#     printf "\\hline\n";
# }


data;

set BasicProducts := 'A' 'B';
set SecondaryProducts := 'C' 'D';
set RawMaterials := 1 2 3;

param RawMaterialsLowerBound := 1 2000 2 3000 3 4000;
param RawMaterialsUpperBound := 1 6000 2 5000 3 7000;

param WasteRatio: 'A' 'B' :=
            1     0.1 0.2
            2     0.2 0.2
            3     0.4 0.5;

param Value := 'A' 3 'B' 2.5 'C' 0.6 'D' 0.5;

param MaterialCost := 1 2.1 2 1.6 3 1.0;

param UtilizationCost: 'A' 'B' :=
                  1    0.1 0.05
                  2    0.1 0.05
                  3    0.2 0.4;

end;
