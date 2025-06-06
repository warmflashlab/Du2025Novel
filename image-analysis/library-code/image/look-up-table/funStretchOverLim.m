function lowhigh = funStretchOverLim(I,Tol)

%%% original stretchlim can't have percentage over 1, here to extend to any
%%% number exceeding 1, help negative images look negative

if max(Tol) > 1
    if min(Tol) < 1
        lowhigh = stretchlim(I,[min(Tol),0.95]);
        lowhigh(2) = lowhigh(2)*max(Tol);
    else
        disp('Low limit needs to be smaller than 1!')
    end  
else
    lowhigh = stretchlim(I,Tol);
end

end