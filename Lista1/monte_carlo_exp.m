
n = 10^6;
x = random('Exponential', 1, n, 1);
xexp = x(x < 1);
y = sum(xexp.^2)/n;
yi = 0.1606027;
%histogram(x,'Normalization','probability')