%% FPGA Assignment 4 - CORDIC tanh implementaiton
% Author: Roozmehr Jalilian (97101467)
clc
clearvars
close all

%% Input Vector Generation

% Parameters
WF = 16;                        % no. of fractional bits
WI = 8;                         % no. of integer bits
WII = 4;                        % no. of actual integer bits
WB = WF + WI;                   % total bits
WBI = WF + WII;
N = 13;                         % no. of  main CORDIC stages
M = 3;                          % no. of negative CORDIC stages
step = 0.01;                    % step-size

X = (-9:step:9)';               % input vector
nVector = length(X);            % no. of test vectors
X_fi = fi(X, 1, WB, WF);        % fi variant of input (with bit extension)
X_fi_in = fi(X, 1, WBI, WF);    % fi variant of input

% Writing to file
fileID = fopen('input_vector.txt', 'w');
fmt = '%s\n';
for i = 1 : nVector
    fprintf(fileID, fmt, num2str(hex(X_fi_in(i))));
end
fclose(fileID);

%% Pre-calculation of ROM Constants

clc

e_h1 = zeros(M,1);                  % hyperbolic negative iterations
for i = -(M-1):0
    e_h1(-i+1) = atanh(1-2^(i-2));
end
e_h2 = zeros(N,1);                  % hyperbolic main iterations
for i = 1:N
    e_h2(i) = atanh(2^(-i));
end
e_d = zeros(N,1);                  % division iterations
for i = 1:N
    e_d(i) = 2^(-i);
end

% Dispalying continuous assignments for CORDIC ROM verilog module
disp('ROM constants (for Verilog file)')
for i = -(M-1):0
    disp("assign Data["+(i+M-1)+"] = "+WB+"'h"+hex(fi(e_h1(-i+1), 1, WB, WF))+';')
end
for i = 1:N
    disp("assign Data["+(i+M-1)+"] = "+WB+"'h"+hex(fi(e_h2(i), 1, WB, WF))+';')
end
for i = 1:N
    disp("assign Data["+(i+M+N-1)+"] = "+WB+"'h"+hex(fi(e_d(i), 1, WB, WF))+';')
end

%% Output Vector Generation

clc

myTanh = zeros(nVector,1);                      % output vector
myTanh_fi = fi(zeros(nVector,1), 1, WB, WF);    % fi variant of output vector
realTanh = myTanh;                              % actual tanh vector

for i = 1:nVector
    myTanh_fi(i) = cordic_tanh(WI, WF, N, M, X(i), e_h1, e_h2, e_d);    % call function
    myTanh(i) = myTanh_fi.data(i);      % real data of fixed-point output
    realTanh(i) = tanh(X_fi.data(i));   % actual tanh function with FP input
end

% Writing to file
fileID = fopen('output_MATLAB.txt', 'w');
fmt = '%s\n';
for i = 1 : nVector
    fprintf(fileID, fmt, num2str(hex(myTanh_fi(i))));
end
fclose(fileID);

% Plotting Errors
figure(1)
    plot(X, abs(myTanh-realTanh), 'b')
    grid on
    xlabel('X')
    ylabel('Absolute Error')
    title('ABS Error of the implemented CORDIC tanh function')
    
figure(2)
    plot(X, 100*abs((myTanh-realTanh)./realTanh), 'r')
    grid on
    xlabel('X')
    ylabel('Absolute Relative Error (%)')
    title('ABS Rel. Error of the implemented CORDIC tanh function')
    