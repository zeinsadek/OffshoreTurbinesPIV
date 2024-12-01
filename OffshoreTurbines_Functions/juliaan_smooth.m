% Guassian Smoothing
function [tmpX] = juliaan_smooth(X,  N)

tmpx = -N/2:1:N/2;
tmpy = -N/2:1:N/2;
[tmpx, tmpy] = meshgrid(tmpx, tmpy);
sigma = N/4;

K1 = 1/(sigma*(2*3.14)^0.5)*exp(  (-1/2).* ( (tmpx./sigma ).^2 ));
K2 = 1/(sigma*(2*3.14)^0.5)*exp(  (-1/2).* ( (tmpy./sigma ).^2 ));
K = K1.*K2;
K = K./sum(K(:));

tmpX = nanconv(X ,K ,'nanout','edge','same');

end