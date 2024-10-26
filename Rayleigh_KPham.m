%{
    AUTHOR:     Khang Pham
    DATE:       October 28, 2022
    TITLE:      "Function for Simulation of Rician Channel"
    REFERENCES: (1)  Dr. Qilian Liang
                (2)  Aileen Sengupta
%}
function [GI, GQ] = Rayleigh_Fading(fd, LENGTHburst, SymR8, samp)
    % fd     : (FLOAT) Doppler frequency 
    % length : (INTEGER) Length of input burst
    % SymR8  : (FLOAT) Symbols per second
    % samp   : samp = 1 (works for some reason)
    
    GI = [];    %INIT GUASSIAN IN-PHASE CHANNEL LENGTH
    GQ = [];    %INIT GUASSIAN QUADRATURE CHANNEL LENGTH
    N = 100;    %NUMBER OF SCATTERS(default)
    
    %DEFINE VARIABLES FOR GI(t) and GQ(t):
    M = ((N/2) - 1)/2;
    alpha = 0;  %defines GI,GQ axises. Makes cos(alpha)=1, sin(alpha)=0
    wm = 2*pi*fd;   
    
    T0=10*rand(1);          %FOR MONTE-CARLO SIMULATION
    for i=1:LENGTHburst*samp
        t=T0+i*(1/(SymR8*samp));
        gI=0;       %INIT FOR SUMMATION
        gQ=0;       %INIT FOR SUMMATION
        for n=1:M   %SUMMATION PORTION OF RAYLEIGH FLAT-FADING
            beta(n)=pi*n/M;
            w(n)=wm*cos(2*pi*n/N);
            gI=gI+cos(w(n)*t)*2*cos(beta(n)); %INCREMENT gI
            gQ=gQ+cos(w(n)*t)*2*sin(beta(n)); %INCREMENT gQ
        end
        gI=gI+cos(wm*t)*2*cos(alpha)/sqrt(2);
        gQ=gQ+cos(wm*t)*2*sin(alpha)/sqrt(2);
        gI=gI/sqrt(2*(M+1)); %NORMALIZE POWER
        gQ=gQ/sqrt(2*M);     %NORMALIZE POWER
        GI=[GI,gI];
        GQ=[GQ,gQ];
    end
end