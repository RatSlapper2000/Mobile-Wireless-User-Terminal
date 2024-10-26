%{
    AUTHOR:     Khang Pham
    DATE:       November 2, 2022
    TITLE:      "Function for Simulation of Rician Channel"
    REFERENCES: (1)  Dr. Qilian Liang
                (2)  Aileen Sengupta
%}
function [GI, GQ] = Rician_Fading(fd, length, SymR8, K_dB)
    % GI    : Guassian In-Phase of constellation
    % GQ 	: Guassian Quadrature of constellation
    % fd 	: doppler frequency     (Hz)
    % length: length of signal      (samples)
    % SymR8	: specified symbol rate (Symbols per Second)
    % K_dB  : Rician fading factor  (dB)
    
    samp = 1;
    [RI, RQ] = Rayleigh_KPham(fd, length, SymR8, samp);
    % RI    : Guassian In-Phase of constellation
    % RQ    : Guassian Quadrature of constellation
    m_path = 10^(-K_dB/10);    %scattered power (linear scale)
    
    RI = RI * sqrt(m_path); %NORMALIZE RICIAN-IN-PHASE IN RESPECT TO K
    RQ = RQ * sqrt(m_path); %NORMALIZE RICIAN-QUADRATURE IN RESPECT TO K
    
    DIRECT = 1 / sqrt(1 + m_path);  %NORMALIZE TOTAL POWER TO 1
    RI = RI / sqrt(1 + m_path);     %NORMALIZE 'IN-PHASE' TOTAL POWER TO 1
    RQ = RQ / sqrt(1 + m_path);     %NORMALIZE 'QUAD' TOTAL POWER TO 1
    
    GI = DIRECT + RI;
    GQ = RQ;
    G = GI + j*GQ;
    
    %PLOTS:
     %{
    figure(11)
    plot(abs(G))
    title('MAGNITUDE CHANNEL GAIN')
    
    figure(12)
    plot(angle(G))
    title('PHASE CHANNEL')
    %}
end