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
%UNIQUE WORD CONSTRUCTION:
uni = [0 0 0 0 1 1 1 1]; %generate 8 "unique" bits
unique = [uni uni uni uni uni uni]; %append 6 times for 48 "symbols"
unique_bits = [unique unique]; %two bits per symbol
    %generating unique words takes months to derive.
    %in this case, just create random bits.

%INFORMATION BITS CONSTRUCTION:
n = 500 * 2;  %COLUMNS (500 symbols, 2 bits per symbol)
information = randi([0 1], 1, n); %generate information bits

%GUARD BITS CONSTRUCTION:
guard = [0 0 0];
guard_bits = [guard guard]; %two bits per symbol

%BURST CONSTRUCTION (append all):
burst = [guard_bits, unique_bits, information, guard_bits];

%QPSK MODULATION (function):
symbol = QPSK_mod(burst); %USE QPSK_mod() function

%ALAMOUNTI ENCODING:
ODDS = symbol(1:2:end);  %s1
EVENS = symbol(2:2:end); %s2

alamounti_init = 1;
%CREATE 2x2 ALAMOUNTI MATRIX:
for i = 1 : 2 : (length(symbol))
    SYMBOL1out(i) = ODDS(alamounti_init);
    SYMBOL1out(i+1) = -(EVENS(alamounti_init))';
    
    SYMBOL2out(i) = EVENS(alamounti_init);
    SYMBOL2out(i+1) = (ODDS(alamounti_init))';
    
    alamounti_init = alamounti_init + 1;
end

%UPSAMPLING (function):
num_samp = 16; %samples per symbol
upsamp1 = UPSAMPLER(SYMBOL1out, num_samp); %USE UPSAMPLER() function
upsamp2 = UPSAMPLER(SYMBOL2out, num_samp); %USE UPSAMPLER() function

%ANTENNA OUTPUTS:
%MATCHED FILTER:
beta = 0.3;     %filter roll-off factor(given)
span = 7;       %samples/symbol and span determine filter's "taps"
sps = num_samp;
RXfilter = rcosdesign(beta, span, sps, 'sqrt');

TXoutput1 = conv(upsamp1, RXfilter);
TXoutput2 = conv(upsamp2, RXfilter);

TXoutput1 = TRUNCATOR(TXoutput1, RXfilter);
TXoutput2 = TRUNCATOR(TXoutput2, RXfilter);

% CHANNEL SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
burst_speed = 0.5e-3;
SymR8 = length(symbol) / burst_speed;
fd = 20;        %USER INPUT(Hz)
K_dB = 7;       %USER INPUT(dB)
EbNo_dB = 1;    %USER INPUT(dB)

%RICIAN CHANNEL 1:
[GI1,GQ1] = Rician_KPham(fd, length(TXoutput1), SymR8, K_dB);
G1 = GI1 + 1j*GQ1;
Rician_output1 = TXoutput1 .* G1;

%RICIAN CHANNEL 2:
[GI2,GQ2] = Rician_KPham(fd, length(TXoutput2), SymR8, K_dB);
G2 = GI2 + 1j*GQ2;
Rician_output2 = TXoutput2 .* G2;

%ADD AWGN NOISE:
EsNo_dB = EbNo_dB + 3; %for QPSK
POWERnoise = (10^(-EsNo_dB/20))*(VARsignal/VARnoise); %derived in class
    %VARsignal from channel calibration
    %VARnoise from channel calibration
noise1 = randn(1,length(Rician_output1)) + 1j*randn(1,length(Rician_output1));
noise1 = noise1 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise1 = POWERnoise * noise1; %correct?
CHoutput1 = Rician_output1 + noise1;

noise2 = randn(1,length(Rician_output2)) + 1j*randn(1,length(Rician_output2));
noise2 = noise2 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise2 = POWERnoise * noise2; %correct?
CHoutput2 = Rician_output2 + noise2;

% RX SIGNAL PROCESSING + DEMODULATOR DESIGN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MATCHED FILTER:
RXfilter = rcosdesign(beta, span, sps, 'sqrt');

RXFilterOutput1 = conv(CHoutput1, RXfilter);
RXinput1 = TRUNCATOR(RXFilterOutput1, RXfilter);

RXFilterOutput2 = conv(CHoutput2, RXfilter);
RXinput2 = TRUNCATOR(RXFilterOutput2, RXfilter);

%DOWNSAMPLING:
downsamp1 = DOWNSAMPLER(RXinput1, num_samp);
downsamp2 = DOWNSAMPLER(RXinput2, num_samp);

%ALAMOUNTI DECODER:
DEALAMOUNTI_init = 1;
DEALAMOUNTI = [];
for i = 1 : 2 : 2*length(downsamp1)
    DEALAMOUNTI(i) = downsamp1(DEALAMOUNTI_init);
    DEALAMOUNTI(i+1) = downsamp2(DEALAMOUNTI_init);
end

%BLOCK PHASE ESTIMATION:
[Z,G,theta]= BPE_test([DEALAMOUNTI],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10,...   STEP SIZE (decrease for higher estimation resolution
             0);
         % OUTPUTS: (1) 'Z'     = channel compensation output
         %          (2) 'G'     = 
         %          (3) 'theta' = phase of channel

%HARDSLICER/DEMODULATION:
RXburst = QPSK_demod(Z); %USE QPSK_demod() FUNCTION

%BURST EXTRACTOR (function):
INFO_bits = Burst_Extractor(RXburst,...
                            length(guard_bits),...
                            length(unique_bits));

%BER CALCULATIONS:
BER = 0;
for i = 1 : length(INFO_bits)
    if (INFO_bits(i) ~= information(i))
        BER = BER + 1;
    end
end
BER = BER / length(INFO_bits)

