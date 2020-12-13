set BasicProducts; # lista produktów podstawowych
set SecondaryProducts;  # lista produktów drugorzędnych
set Products := BasicProducts union SecondaryProducts;
param ProductsCost{Products};

set RawMaterials; # surowce
param MaterialsCost{RawMaterials};
param MinMaterialsLimit{RawMaterials};
param MaxMaterialsLimit{RawMaterials};

param WasteRatio{RawMaterials, BasicProducts}; # % powstałych odpadów
param WasteCost{RawMaterials, BasicProducts};

param BasicMinBlendLimit{RawMaterials, BasicProducts};
param BasicMaxBlendLimit{RawMaterials, BasicProducts};

param SecondaryBlendRatio{RawMaterials, SecondaryProducts};
param SecondaryUsingWastesRatio{BasicProducts, SecondaryProducts};



var boughtMaterials{m in RawMaterials} >= 0;  # done
var materialsUsedForProduct{m in RawMaterials, p in Products} >= 0; # done
var createdProduct{p in Products} >= 0; # done
var createdWastes{m in RawMaterials, p in BasicProducts} >= 0; # done
var usedWastes{m in RawMaterials, p in BasicProducts} >= 0; # done
var recycledWastes{m in RawMaterials, p in BasicProducts} >= 0;
var wastesUsedForSecProduct{m in RawMaterials, p in BasicProducts, SecondaryProducts} >= 0; # done


maximize profit: ((sum{p in Products} createdProduct[p] * ProductsCost[p]) - (sum{m in RawMaterials, p in BasicProducts} recycledWastes[m, p] * WasteCost[m, p]) - (sum{m in RawMaterials} boughtMaterials[m] * MaterialsCost[m]));

#1  wszystkie ograniczenia do boughtMaterials
s.t. minMaterials{m in RawMaterials}: boughtMaterials[m] >= MinMaterialsLimit[m];
s.t. maxMaterials{m in RawMaterials}: boughtMaterials[m] <= MaxMaterialsLimit[m];
s.t. exactMaterials{m in RawMaterials}: boughtMaterials[m] = sum{p in Products} materialsUsedForProduct[m, p];

#2  wszystkie ograniczenia do materialsUsedForProduct
s.t. minMaterialsForBasicProduct{m in RawMaterials, p in BasicProducts}: materialsUsedForProduct[m, p] >= BasicMinBlendLimit[m, p] * sum{sm in RawMaterials} materialsUsedForProduct[sm, p];
s.t. maxMaterialsForBasicProduct{m in RawMaterials, p in BasicProducts}: materialsUsedForProduct[m, p] <= BasicMaxBlendLimit[m, p] * sum{sm in RawMaterials} materialsUsedForProduct[sm, p];
s.t. materialsForSecondaryProduct{m in RawMaterials, p in SecondaryProducts}: materialsUsedForProduct[m, p] = createdProduct[p] * SecondaryBlendRatio[m, p];

# wszystkie dla ilosci wytworzonych produktów - createdProduct
s.t. createdBasicProduct{p in BasicProducts}: createdProduct[p] = sum{m in RawMaterials} materialsUsedForProduct[m, p] * (1-WasteRatio[m, p]);
s.t. createdSecondaryProduct{p in SecondaryProducts}: createdProduct[p] = sum{m in RawMaterials} (materialsUsedForProduct[m, p] + sum{bp in BasicProducts} wastesUsedForSecProduct[m, bp, p]);

# ilość wytworzonych odpadów
s.t. wastes{m in RawMaterials, p in BasicProducts}: createdWastes[m, p] = materialsUsedForProduct[m, p] * WasteRatio[m, p];

# rozkład odpadów na recykling + secondary i warunek na ilosc użytych do produkcji secondary
s.t. wastesDistribution{m in RawMaterials, p in BasicProducts}: createdWastes[m, p] = usedWastes[m, p] + recycledWastes[m, p];
s.t. usedWastesDistributionBetweenSecProducts{m in RawMaterials, bp in BasicProducts}: usedWastes[m, bp] = sum{p in SecondaryProducts} wastesUsedForSecProduct[m, bp, p];

s.t. asdasd{p in SecondaryProducts, bp in BasicProducts}: createdProduct[p] * SecondaryUsingWastesRatio[bp, p] = sum{m in RawMaterials} wastesUsedForSecProduct[m, bp, p];

solve;

display profit;

# display boughtMaterials;

display materialsUsedForProduct;
display createdWastes;
display usedWastes;
display recycledWastes;
# display wastesUsedForSecProduct;

data;

set BasicProducts := 'A' 'B';
set SecondaryProducts := 'C' 'D';
param ProductsCost := 'A' 3 'B' 2.5 'C' 0.6 'D' 0.5;

set RawMaterials := 1 2 3;
param MaterialsCost := 1 2.1 2 1.6 3 1.0;
param MinMaterialsLimit := 1 2000 2 3000 3 4000;
param MaxMaterialsLimit := 1 6000 2 5000 3 7000;

param WasteRatio: 'A' 'B' :=
            1     0.1 0.2
            2     0.2 0.2
            3     0.4 0.5;

param WasteCost: 'A' 'B' :=
            1    0.1 0.05
            2    0.1 0.05
            3    0.2 0.4;

param BasicMinBlendLimit : 'A' 'B' :=
                        1  0.2 0.1
                        2  0.4 0
                        3  0   0;

param BasicMaxBlendLimit : 'A' 'B' :=
                        1  1   1
                        2  1   1
                        3  0.1 0.3;

param SecondaryBlendRatio : 'C' 'D' :=
                        1   0.2 0
                        2   0   0.3
                        3   0   0;

param SecondaryUsingWastesRatio : 'C' 'D' :=
                             'A'  0.8 0
                             'B'  0   0.7;


end;