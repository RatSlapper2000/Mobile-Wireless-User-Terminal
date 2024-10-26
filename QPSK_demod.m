%{
    AUTHOR: Khang Pham
    DATE:   December 1, 2022
    TITLE:  "QPSK Demodulator/Hardslicer" 
%}
function [RXburst] = QPSK_demod(SYMBOLSin)
    RXburst = [];
    m = 1;
    for i = 1 : 2 : (2*length(SYMBOLSin) - 1)
        angl = angle(SYMBOLSin(m));
        
        if (angl >= -pi/4) && (angl < pi/4)%          +1
            RXburst(i)   = 0;
            RXburst(i+1) = 0;
        end
        if (angl >= pi/4) && (angl < 3*pi/4)%         +j
            RXburst(i)   = 0;
            RXburst(i+1) = 1;
        end
        if ((angl >= 3*pi/4) && (angl <= pi))||...    -1
           ((angl < -3*pi/4) && (angl > -pi))
            RXburst(i)   = 1;
            RXburst(i+1) = 1;
        end
        if (angl >= -3*pi/4) && (angl < -pi/4)%       -j
            RXburst(i)   = 1;
            RXburst(i+1) = 0;
        end
        m = m + 1;
    end
end