clear
clc
%{
    AUTHOR: Khang Pham
    DATE:   October 20, 2022
    TITLE:  "EE5368 Project 2:
            BER simulation for different wireless 
            channel methods"
    REFERENCES: (1) Dr. Qilian Liang
                (2) Mathworks.com
%}
%PROBLEM 3:
boop = [...
0.056281951976541,...                
0.037506128358926,...
0.022878407561085,...   
0.012500818040738,...   
0.005953867147779,...   
0.002388290780933];

%FROM SNR CALIBRATION:
%PROBLEM 1:
 %{
VARsignal = 0.051992549549251; %K_dB = 7, fd = 20
VARnoise = 0.499345336061915;  %K_dB = 7, fd = 20
%}

%PROBLEM 2:
% %{
VARsignal = 2.817770686316203e-04; %K_dB = 12, fd = 100
VARnoise = 0.544908124316449;      %K_dB = 12, fd = 100
%}

% TX OUTPUT SIGNAL CONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UNIQUE WORD CONSTRUCTION(48 symbols, 96 bits):
uni = [0 0 0 0 1 1 1 1]; %generate 8 "unique" bits
unique = [uni uni uni uni uni uni]; %append 6 times for 48 "symbols"
unique_bits = [unique unique]; %two bits per symbol
    %generating unique words takes months to derive.
    %in this case, just create random bits.

%INFORMATION BITS CONSTRUCTION(250 symbols, 500 bits):
%NOTE: reduce number of bits encoded by have to achieve 1000 encoded bits
n = 250 * 2;  %COLUMNS (250 symbols, 2 bits per symbol)
information = randi([0 1], 1, n); %generate information bits

%ENCODE INFORMATION BITS(500 bits input, 1000 bits output):
% USE poly2trellis() and convenc() FUNCTIONS
% CONNECTIONS: (1) '001 011 011' = 133
%              (2) '001 111 001' = 171
LENGTHtrellis = 7; %7 SYMBOLS LENGTH TRELLIS STRUCTURE
TRELLIS = poly2trellis(LENGTHtrellis, [133 171]); %GENERATE TRELLIS
OUTPUTconvenc = convenc(information,TRELLIS); %USE convenc() FUNCTION

%GUARD BITS CONSTRUCTION:
guard = [0 0 0];
guard_bits = [guard guard]; %two bits per symbol

%BURST CONSTRUCTION (append all):
burst = [guard_bits, unique_bits, OUTPUTconvenc, guard_bits];

%QPSK MODULATION (function):
symbol = QPSK_mod(burst); %USE QPSK_mod() function

%UPSAMPLING (function):
num_samp = 16; %samples per symbol
upsamp = UPSAMPLER(symbol, num_samp); %USE UPSAMPLER() function

%PULSE SHAPING FILTER + FILTERING + TRUNCATION:
beta = 0.3;     %filter roll-off factor(given)
span = 7;       %samples/symbol and span determine filter's "taps"
sps = num_samp;
filter = rcosdesign(beta, span, sps, 'sqrt');
TXFilterOutput = conv(upsamp, filter); %BURST AFTER PULSE FORMING
TXoutput = TRUNCATOR(TXFilterOutput, filter); %USE TRUNCATOR() function

%CHANNEL SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
burst_speed = 0.5e-3;
SymR8 = length(symbol) / burst_speed;
fd = 20;        %USER INPUT(Hz)
K_dB = 7;       %USER INPUT(dB)
EbNo_dB = 1;    %USER INPUT(dB)

%GENERATE RICIAN CHANNEL:
[GI,GQ] = Rician_Fading(fd, length(TXoutput), SymR8, K_dB);
G = GI + 1j*GQ;
 %{
%TROUBLESHOOTING:
G = GI + 1j*GQ; %CHANNEL IS NORMALIZED. avg(|G|^2) = 1
figure(12)
plot(angle(G))
title('CHANNEL PHASE')
%}

%GENEARATE CHANNEL OUTPUT:
Rician_output = TXoutput .* (GI + 1j*GQ);
 %{
%TROUBLESHOOTING:
figure(101)
plot(TXoutput)
title('TXoutput')
figure(102)
plot(Rician_output)
title('Channel Output')
%}

%ADD AWGN NOISE:
EsNo_dB = EbNo_dB + 3; %for QPSK
POWERnoise = (10^(-EsNo_dB/20))*(VARsignal/VARnoise); %derived in class
    %VARsignal from channel calibration
    %VARnoise from channel calibration

noise = randn(1,length(Rician_output)) + 1j*randn(1,length(Rician_output));
noise = noise / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise = POWERnoise * noise; %correct?
CHoutput = Rician_output + noise;

% RX SIGNAL PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MATCHED FILTER:
RXfilter = rcosdesign(beta, span, sps, 'sqrt');
RXFilterOutput = conv(CHoutput, RXfilter);
RXinput = TRUNCATOR(RXFilterOutput, RXfilter); %USE TRUCATOR() FUNCTION

%DOWNSAMPLING (function):
downsamp = DOWNSAMPLER(RXinput, num_samp); %USE DOWNSAMPLER() FUNCTION

%BLOCK PHASE ESTIMATION:
[Z,G,theta]= BPE_test([downsamp],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10,...   STEP SIZE (decrease for higher estimation resolution
             angle(G));
         % OUTPUTS: (1) 'Z'     = channel compensation output
         %          (2) 'G'     = 
         %          (3) 'theta' = phase of channel

%HARDSLICER (function):
RXburst = QPSK_demod(Z); %USE QPSK_demod() FUNCTION

%BURST EXTRACTOR (function):
INFO_bits = Burst_Extractor(RXburst,...
                            length(guard_bits),...
                            length(unique_bits));

%DECODING:
LENGTHconv = 3;
DECODE = vitdec(INFO_bits,...
                TRELLIS,...
                LENGTHconv,...
                'trunc','hard');
                        
%BER CALCULATIONS:
BER = 0;
for i = 1 : length(DECODE)
    if (DECODE(i) ~= information(i))
        BER = BER + 1;
    end
end
BER = BER / length(DECODE)