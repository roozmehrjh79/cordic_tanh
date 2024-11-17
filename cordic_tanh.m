%% CORDIC tanh function
% Author: Roozmehr Jalilian (97101467)
function Z = cordic_tanh(WI, WF, N, M, z0, e_h1, e_h2, e_d)
    % Note:
    %   WI = integer bit-width
    %   WF = fractional bit-width
    %   N = no. of main iterations
    %   M = no. of negative iterations
    %   z0 = input angle
    %   e_h1 = ROM input for negative hyperbolic iterations
    %   e_h2 = ROM input for main hyperbolic iterations
    %   e_d = ROM input for division iterations
    
    WB = WF + WI;                   % no. of total bits
    
    % Calculation of 1/K
    K = 1;
    for i = -(M-1):0
        K = K * sqrt(1-(1-2^(i-2))^2);
    end
    for i = 1:N
        K = K * sqrt(1-2^(-2*i));
    end
    K_fi = fi(1/K, 1, WB, WF);
    
    % fi Object Declarations
    x0_fi = K_fi;
    y0_fi = fi(0, 1, WB, WF);
    z0_fi = fi(z0, 1, WB, WF);
    
    % CORDIC - tanh Calculation (Phase 1.1 - Negative Iterations)
    xin_fi = x0_fi;
    yin_fi = y0_fi;
    zin_fi = z0_fi;
    ei_fi = fi(e_h1, 1, WB, WF);    % fixed-point variant of ROM constants

    for i = -(M-1):0
        xi_fi = xin_fi;
        yi_fi = yin_fi;
        zi_fi = zin_fi;

        if (zi_fi >= 0)
            di = 1;
        else
            di = -1;
        end

        if (di > 0)
            xin_fi = fi( xi_fi + yi_fi - bitshift(yi_fi,i-2) , 1, WB, WF);
            yin_fi = fi( yi_fi + xi_fi - bitshift(xi_fi,i-2) , 1, WB, WF);
            zin_fi = fi( zi_fi - ei_fi(-i+1) , 1, WB, WF);
        else
            xin_fi = fi( xi_fi - yi_fi + bitshift(yi_fi,i-2) , 1, WB, WF);
            yin_fi = fi( yi_fi - xi_fi + bitshift(xi_fi,i-2) , 1, WB, WF);
            zin_fi = fi( zi_fi + ei_fi(-i+1) , 1, WB, WF);
        end

    end
    
    % CORDIC - tanh Calculation (Phase 1.2 - Evaluation of sinh & cosh)
    ei_fi = fi(e_h2, 1, WB, WF);

    j = 2;              % stall flag (used to repeat iterations 4 & 13)
    i = 1;
    while(i <= N)
        xi_fi = xin_fi;
        yi_fi = yin_fi;
        zi_fi = zin_fi;

        if (zi_fi >= 0)
            di = 1;
        else
            di = -1;
        end

        if (di > 0)
            xin_fi = fi( xi_fi + bitshift(yi_fi,-i) , 1, WB, WF);
            yin_fi = fi( yi_fi + bitshift(xi_fi,-i) , 1, WB, WF);
            zin_fi = fi( zi_fi - ei_fi(i) , 1, WB, WF);
        else
            xin_fi = fi( xi_fi - bitshift(yi_fi,-i) , 1, WB, WF);
            yin_fi = fi( yi_fi - bitshift(xi_fi,-i) , 1, WB, WF);
            zin_fi = fi( zi_fi + ei_fi(i) , 1, WB, WF);
        end

        if ((i==4 && j==2) || (i==13 && j==1))
            j = j - 1;
        else
            i = i + 1;
        end

    end
    
    % CORDIC - tanh Calculation (Phase 2 - Division)
    zin_fi = fi(0, 1, WB, WF);
    ei_fi = fi(e_d, 1, WB, WF);

    for i = 1:N
        xi_fi = xin_fi;
        yi_fi = yin_fi;
        zi_fi = zin_fi;

        if (xi_fi*yi_fi >= 0)
            di = -1;
        else
            di = 1;
        end

        if (di > 0)
            yin_fi = fi( yi_fi + bitshift(xi_fi,-i) , 1, WB, WF);
            zin_fi = fi( zi_fi - ei_fi(i) , 1, WB, WF);
        else
            yin_fi = fi( yi_fi - bitshift(xi_fi,-i) , 1, WB, WF);
            zin_fi = fi( zi_fi + ei_fi(i) , 1, WB, WF);
        end

    end
    
    Z = zin_fi;
end

