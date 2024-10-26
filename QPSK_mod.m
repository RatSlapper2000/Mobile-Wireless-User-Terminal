%{
    AUTHOR: Khang Pham
    DATE:   December 1, 2022
    TITLE:  "QPSK Modulator"
%}
function [MODoutput] = QPSK_MOD(BITSin)
    MODoutput = [];
    symbol_array = 1; %init array assignment for MODoutput(k)
    for i = 1 : 2 : length(BITSin)
        if BITSin(i) == 0 && BITSin(i+1) == 0
            MODoutput(symbol_array) = 1;
        end
        if BITSin(i) == 0 && BITSin(i+1) == 1
            MODoutput(symbol_array) = 1j;
        end
        if BITSin(i) == 1 && BITSin(i+1) == 1
            MODoutput(symbol_array) = -1;
        end
        if BITSin(i) == 1 && BITSin(i+1) == 0
            MODoutput(symbol_array) = -1j;
        end
        symbol_array = symbol_array + 1; %increment to assign symbol(k+1)
    end
end