%{
    AUTHOR: Khang Pham
    DATE:   November 30, 2022
    TITLE:  "Block Phase Estimation"
    REFERENCES: (1) Dr. Qilian Liang, 
                    "BPE Test Code" from March 19, 2022
                (2) Viterbi,
                    "Nonlienar estimation of PSK-modulated carrier phase
                     w/ application to burst digital transmission"
                    from July 2983
%}

function [Z,G,TH]=BPS(R, UW, uw_index, block_L, step , PHASEstupid)
    % R         : (VECTOR) Received symbols
    % UW        : (VECTOR) Unique words in symbol in the transmission part
    % uw_index  : (VECTOR) UW index
    % block_L   : (INTEGER) block size. must be a positive number
    % step      : (INTEGER) step size each estimation
    % NOTE: (length of R)/block_L must be an integer

    L = length(R);

    % FIND PHASE AMBIGUITY:
    UW_L = length(uw_index);
    UW_R = R(uw_index);
    beta = angle((UW_R*UW')/UW_L);
    %beta_c=sign(beta)*floor(abs(beta)/(pi/4))*(pi/4);
    %beta_c=sign(beta)*round(abs(beta)/(pi/4))*(pi/4);

    % NONLINEAR TRANSFORMATION:
    phi = angle(R);
    phi = phi * 4;  %r^4
    A = abs(R);
    A = A.^2;       %r^4 (squared here but amplitude does not matter)
    
    for i = 1 : L
        RR(i) = A(i) * exp(j*phi(i)); %convert to phasor form
    end

    N = floor((L-block_L)/step);

    y = sum(imag(RR(1:block_L)));
    x = sum(real(RR(1:block_L)));
    t = y/x;
    theta(1) = atan(t)/4;
    %theta(1)=theta(1)+beta_c;

    i = 0;
    CAN = [theta(i+1),...
        theta(i+1)-pi/4, theta(i+1)+pi/4,...
        theta(i+1)-pi/2, theta(i+1)+pi/2,...
        theta(i+1)-pi*3/4, theta(i+1)+pi*3/4,...
        theta(i+1)-pi, theta(i+1)+pi];

    DS = beta - CAN;
    DS = abs(DS);
    [m,I] = min(DS);
    theta(1) = CAN(I);

    for i = 1 : N-1
        y = sum(imag(RR(i*step+1:i*step+block_L)));
        x = sum(real(RR(i*step+1:i*step+block_L)));
        t = y/x;
        theta(i+1) = atan(t)/4;
        %theta(i+1)=theta(i+1)+beta_c;

        CAN = [theta(i+1),theta(i+1)-pi/4, theta(i+1)+pi/4,...
            theta(i+1)-pi/2, theta(i+1)+pi/2, theta(i+1)-pi*3/4,... 
            theta(i+1)+pi*3/4, theta(i+1)-pi, theta(i+1)+pi]; 

        DS = theta(i) - CAN;
        DS = abs(DS);
        [m,I] = min(DS);
        theta(i+1) = CAN(I);
    end

    TH = interp(theta,step);
    % L> block_L*N

    %TH(N*step)*ones(1,L-N*step-block_L/2)
    TH =[TH(1) * ones(1,block_L/2),...
         TH,...
         TH(N*step) * ones(1,L-N*step-block_L/2)];
    
     %{
    TH((block_L/2) * (2*N-1)+1:L)=...
    TH((block_L/2) * (2*N-1)) * ones(1,L-(block_L/2) * (2*N-1));
    %}
    %?? any modification????
    %TH=TH(1:L);
    
    %HARDCODE PHASE COMPENSATION THE STUPID WAY:
    %MEANphaseCHANNEL = mean(PHASEstupid)
    %AVERAGEtheta = mean(theta)
    
    % %{
    %{
    %TROUBLESHOOTING:
    figure(111)
    plot(TH)
    title('ESTIMATION BEFORE OFFSET CORRECTION')
    %}
    
    DIFFphase = mean(PHASEstupid) - mean(theta); 
    if (DIFFphase >= (0-0.2)) && (DIFFphase <= (0+0.2)) %GOOD ESTIMATION
        disp('NO PHASE CORRECTION. GOOD ESTIMATION!')
        TH = TH; %DOES NOTHING
    end
    if (DIFFphase >= (pi/4-0.2)) && (DIFFphase <= (pi/4+0.2)) %+pi/4 OFFSET
        disp('CORRECTION BY +pi/4')
        TH = TH + pi/4;
    end
    if (DIFFphase >= (-pi/4-0.2)) && (DIFFphase <= (-pi/4+0.2)) %-pi/4 OFFSET
        disp('CORRECTION BY -pi/4')
        TH = TH - pi/4;
    end
    if (DIFFphase >= (pi/2-0.2)) && (DIFFphase <= (pi/2+0.2)) %+pi/2 OFFSET
        disp('CORRECTION BY +pi/2')
        TH = TH + pi/2;
    end
    if (DIFFphase >= (-pi/2-0.2)) && (DIFFphase <= (-pi/2+0.2)) %-pi/2 OFFSET
        disp('CORRECTION BY -pi/2')
        TH = TH - pi/2;
    end
    if (DIFFphase >= (3*pi/4-0.2)) && (DIFFphase <= (3*pi/4+0.2)) %+3pi/4 OFFSET
        disp('CORRECTION BY +3pi/4')
        TH = TH + 3*pi/4;
    end
    if (DIFFphase >= (-3*pi/4-0.2)) && (DIFFphase <= (-3*pi/4+0.2)) %+3pi/4 OFFSET
        disp('CORRECTION BY -3pi/4')
        TH = TH - 3*pi/4;
    end
    if (DIFFphase >= (pi-0.2)) && (DIFFphase <= (pi+0.2)) %+3pi/4 OFFSET
        disp('CORRECTION BY +pi')
        TH = TH + pi;
    end
     %{
    %TROUBLESHOOTING:
    figure(222)
    plot(TH)
    title('ESTIMATION AFTER OFFSET CORRECTION')
    %}
    %}
    
    G = exp(-1j*TH);
    
    % CHANNEL COMPENSATION:
    for i = 1 : L
        Z(i) = R(i) * G(i);
    end
end









