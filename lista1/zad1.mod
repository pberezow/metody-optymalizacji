# Author: Piotr Berezowski, 236749

param n;
set Range := 1..n;

param a{i in Range, j in Range} := 1 / (i + j - 1);
param b{i in Range} := sum{j in Range} 1 / (i + j - 1);

var x{Range} >= 0;

minimize test: sum{i in Range} x[i] * b[i];

s.t.    label{i in Range}: sum{j in Range} a[i, j] * x[j] = b[i];

solve;

param x0{i in Range} := 1;
param rel_err := sqrt( sum{i in Range} (x[i] - x0[i])^2 ) / sqrt( sum{i in Range} x0[i]^2 );

printf "Relative error for n=%g:\t%g ~= %.2f\n", n, rel_err, rel_err;

data;

param n := 7;

end;
