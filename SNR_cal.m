%{
    AUTHOR: Khang Pham
    DATE:   December 9, 2022
    TITLE:  "SNR Calibration for Channel Simulation"
    REFERENCES: (1) Sushma Venugopal
                (2) Dr. Qilian Liang
%}
function [VARsignal,VARnoise] = SNR_cal(K_dB,fd,...
                                        LENGTHburst,...
                                        TIMEburst,...
                                        sps)
    % K_dB        : (FLOAT) Rician fading factor          (dB)
    % fd          : (FLOAT) Doppler frequency             (Hz)
    % LENGTHburst : (INTEGER) Length of burst in SYMBOLS  (#)
    % TIMEburst   : (FLOAT) Time for one burst            (seconds)
    % sps         : (INTEGER) Samplers per second, upsamp (UPSAMLES)
    
    %BURST CONSTRUCTION:
    Sym_rate = LENGTHburst / TIMEburst;
    
    %FILTER CONSTRUCTION:
    beta = 0.3;
    span = 7;
    filter = rcosdesign(beta, span, sps, 'sqrt');
    
    signal = []; %INITIALIZE SIGNAL POWER FOR EACH TEST ITERATION
    noise = []; %INITIALZE NOISE POWER FOR EACH TEST INTERATION
    
    for i = 1 : 1000 %RUN MULTIPLE ITERATIONS FOR MORE ACCURATE CALIBRATION
        uni = [0 0 0 0 1 1 1 1];
        unique = [uni uni uni uni uni uni];
        unique_bits = [unique unique];

        n = 500 * 2;
        information = randi([0 1], 1, n);

        guard = [0 0 0];
        guard_bits = [guard guard];

        input_bit = [guard_bits, unique_bits, information, guard_bits];
        
        %QPSK MODULATION:
        input_symbol = QPSK_mod(input_bit);
    
        %UPSAMPLING:
        input_symbol_upsamp = UPSAMPLER(input_symbol,sps);
        
        %PULSE SHAPING FILTER + TRUNCATION:
        Tx = conv(input_symbol_upsamp, filter);
        Tx = TRUNCATOR(Tx,filter);
        
        %CHANNEL:
        [GI,GQ] = Rician_KPham(fd,length(Tx),Sym_rate,K_dB);
        channel = GI + 1j*GQ;
        
        %TRANSMISSION:
        tempRx = [];
        for i = 1 : size(Tx,1)
            tempRx(i) = Tx(i) * channel(i);
        end
        
        %MATCHED FILTER:
        output_symbol = conv(tempRx,filter);
        output_symbol = TRUNCATOR(output_symbol,filter);
        
        %DOWNSAMPLING:
        output_symbol_downsamp = DOWNSAMPLER(output_symbol,sps);
        
        %NOISE:
        noise_temp = randn(size(output_symbol_downsamp,1)*sps,1)/sqrt(2)+...
                  1j*randn(size(output_symbol_downsamp,1)*sps,1)/sqrt(2);
        noise_awgn = conv(noise_temp,filter);
        noise_awgn = TRUNCATOR(noise_awgn,filter);
        noise_awgn_downsamp = DOWNSAMPLER(noise_awgn,sps);
        
        signal = [signal;...
                  output_symbol_downsamp];
        noise = [noise;...
                 noise_awgn_downsamp];
    end
    
    VARsignal = var(signal);
    VARnoise = var(noise);
end




