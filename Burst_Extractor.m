%{
    AUTHOR: Khang Pham
    DATE:   December 10, 2022
    TITLE:  "INFORMATION BURST EXTRACTOR"
%}
function [INFO] = Burst_Extractor(burst, LENGTHguard, LENGTHunique)
    % burst        = (VECTOR) burst input to be processed
    % LENGTHguard  = (INTEGER) number of BITS in 1 guard
    % LENGTHunique = (INTEGER) number of BITS in unique word
    
    %OBJECT-ORIENTED METHOD:
    % %{
    INFO = [];
    INFO_array = 1; %INIT ARRAY VALUES TO ASSIGN INFO()
    start = LENGTHguard + LENGTHunique + 1; %start of info bits
    stop = length(burst) - LENGTHguard;     %stop of info bits
    for i = start : stop
        INFO(INFO_array) = burst(i);
        INFO_array = INFO_array + 1;
    end
    %}
    
    %THE STUPID METHOD:
     %{
    INFO = burst(LENGTHguard+LENGTHunique+1 : end-LENGTHguard);
    %}
    
end