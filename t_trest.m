clear
data = "nocuff2.hhm";                                %adatfájl neve

%=============================================================================
%===========================Adat betöltése====================================
%=============================================================================

data_raw = hhmbinread(data);
plot(data_raw.ecg1,'r');
hold on
plot(data_raw.press,'b');
grid on
xlabel('Idő (ms)');
ylabel('Amplitudo [Relatív egység]');
legend('ECG','Pressure');
title("Jelölje ki a használni kívánt jeltartományt!");
[x,y]=ginput(2);
close;

ecg = data_raw.ecg1(round(x(1)):round(x(2)));


for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

W = 25;                                             %Törésponti feri (Hz)
nFilt = 5;                                          %szűrő fokszáma
nNotch = 3;                                         %lyukszűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, [49 51]./(Fs/2), 'stop');   %lyukszűrő

ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);
ecg_filter = filter(b, a, ecg_mv);

qrsPos = pan_tompkins(ecg_filtfilt);                %R hullámok identifikálása
qrsLen = diff(qrsPos);                              %R hullámok távolságának számítása
qrsId = 1:1:length(ecg_filtfilt);                   %Lineáris vektor a kijelzéshez

for i = 1 : length(qrsLen)                          %Periódusidő átváltása HR értékké
    hr(i) = 60/(qrsLen(i)/1000);
end

ecg_filtfilt(end+1:end+500)=0;

ret = tPeak(ecg_filtfilt,qrsPos); 
ret(end+1:end+500)=0;
ret1 = tWave(ecg_filtfilt,ret); 


figure(2)
plot(ecg_filtfilt,'r');
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(qrsPos,ecg_filtfilt(qrsPos),'bx');             %X ekkel jelölük a megtalált R hullámokat
plot(ret1,ecg_filtfilt(ret1),'gx');             %X ekkel jelölük a megtalált R hullámokat
grid on
title("R hullám detektálás eredménye, az annotált pontok piros X-el jelölve."+"  fájl: "+data)
legend('filtfilt() szűrés');

function [t_locs] = tPeak(data,rwave)
    roi = 480;
    offset = 19;
    locMax = 0;

    for i = 1:length(rwave)
        rLoc = rwave(i);
        for k = 1:roi
            if(data(rLoc+k+offset)>locMax)
                locMax = data(rLoc+k+offset);
                t_locs(i)=rLoc+k+offset;
            end
        end
        locMax = 0;
    end
end

function [t_end] = tWave(data,twave)
    k = 0;
    diff = 0;
    for i = 1:length(twave)
        while(diff<=0 || (i+k+1)>=length(twave))
            diff = diff - data(twave(i)+k);
            k=k+1;
        end
        diff = 0;
        t_end(i) = twave(i)+k;
        k = 1;
        diff = 0;
    end
    
end

