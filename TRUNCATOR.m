%{
    AUTHOR: Khang Pham
    DATE:   December 1, 2022
    TITLE:  "Trucator"
    NOTES:  (1) Performs (L-1)/2 truncation on both sides after conv()
            (2) L = discrete length of filter
%}
function [TRUNKoutput] = TRUNCATOR(signal, filter)
    % 'signal' = (VECTOR) DT-domain signal being filtered
    % 'filter' = (VECTOR) DT-domain filter after filter construction
    
    % REMOVE (L-1)/2 FROM OUTPUT ON BOTH SIDES:
        % we want original length of our signal before pulse-shaping
        % (TRANSMIT LENGTH) = (FILTER LENGTH) + (UPSAMPLED) - 1
    
    filterLength = length(filter); %VALUE FOR 'L'
    transmit_length = length(signal);
    cutOff1 = (filterLength - 1) / 2;                   %CUTOFF POSITION 1
    cutOff2 = transmit_length - (filterLength - 1)/2;   %CUTOFF POSITION 2

    TRUNKoutput = []; %pulse = zeros(1, length(upsamp)); %INITIALIZE PULSE
    initPULSE = 1;
    for L = cutOff1 + 1 : cutOff2
    %for L = cutOff1 : cutOff2 - 1               %range of WANTED signal
        TRUNKoutput(initPULSE) = signal(L);  %START pulse(i) ASSIGNMENT
        initPULSE = initPULSE + 1;
    end
end