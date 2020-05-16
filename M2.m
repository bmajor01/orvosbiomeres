clear
addpath("/home/bela/Desktop/bme/szgepgyak/ekg/mit/Felvetelek");

%=============================================================================
%=========================Beállítandó paraméterek:============================
%=============================================================================

data = "nagyzaj1.hhm";                                %adatfájl neve

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

ecg = data_raw.ecg1(x(1):x(2));
ppg = data_raw.ppgl_nir(x(1):x(2));
press = data_raw.press(x(1):x(2));

%=============================================================================
%===========================Mért értékek átváltása============================
%=============================================================================

for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

for i = 1 : length(ppg)                  %A mandzsetta nyomásértékének átváltása mmhg-be
    press_mmhg(i) = (press(i) - 175)/15.5;
end

%=============================================================================
%=============================================================================
%=============================================================================



%=============================================================================
%=====================ECG szűrések============================================
%=============================================================================

W = 25;                                             %Törésponti feri (Hz)
nFilt = 10                                          %szűrő fokszáma
nNotch = 4;                                         %lyukszűrő fokszáma
f0 = 50;
bandwidth = 10;

notchFilt = [(f0-(bandwidth/2)),(f0+(bandwidth/2))];


Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, notchFilt./(Fs/2), 'stop');   %lyukszűrő

ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);
ecg_filter = filter(b, a, ecg_mv);

%=============================================================================
%=====================ECG csúcsdetektálás=====================================
%=============================================================================


qrsPos = pan_tompkins(ecg_filtfilt);                %R hullámok identifikálása
qrsLen = diff(qrsPos);                              %R hullámok távolságának számítása
qrsId = 1:1:length(ecg_filtfilt);                   %Lineáris vektor a kijelzéshez

for i = 1 : length(qrsLen)                          %Periódusidő átváltása HR értékké
    hr(i) = 60/(qrsLen(i)/1000);
end

%Légzés frekvencia számolása
hr(end+1) = hr(end);

t = 1:1:length(ecg_filtfilt);
legzes=interp1(qrsPos,hr,t,'spline');
legzesDiff=diff(legzes);
[pks,locs] = findpeaks(legzesDiff, 'MinPeakDistance',1000);
legzesLen=diff(locs);

for i = 1 : length(legzesLen)                          %Periódusidő átváltása HR értékké
    legzesFr(i) = 60/(legzesLen(i)/1000);
end

ecg_spectrum = fft(ecg_filtfilt);
n = length(ecg_spectrum);                       % Mintaszám
f = (0:n-1)*(Fs/n);                             % Frekvencia tartomány számítás (dokumentáció alapján)
powerEcg = abs(ecg_spectrum).^2/n;              % Teljesítmény spektrum számítás a komplex fft-ből

ppg_nodc = ppg-mean(ppg);
ppg_filtfilt = filtfilt(b, a, ppg_nodc);
ppg_spectrum = fft(ppg_filtfilt);
n = length(ppg_spectrum);                       % Mintaszám
f = (0:n-1)*(Fs/n);                             % Frekvencia tartomány számítás (dokumentáció alapján)
powerPpg = abs(ppg_spectrum).^2/n;              % Teljesítmény spektrum számítás a komplex fft-ből

figure(1)
plot((ecg_notch),'r');
grid on
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(ecg_filtfilt,'g');
hold on
plot(ecg_mv,'b');
grid on
legend("notch szűrés, sávszélesség:"+ bandwidth +" fokszám:"+ nNotch ,"aluláteresztő szűrés, fokszám:"+ nFilt+" Vágási fr: "+ W,"eredeti jel");
title("Különböző szűrési algoritmusok összehasonlítása.  fájl: "+data);

figure(2)
plot(ecg_filtfilt,'r');
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(qrsPos,ecg_filtfilt(qrsPos),'bx');             %X ekkel jelölük a megtalált R hullámokat
grid on
title("R hullám detektálás eredménye, az annotált pontok piros X-el jelölve."+"  fájl: "+data)
legend('filtfilt() szűrés');

figure(3)
plot(hr);
xlabel('Idő (ms)');
ylabel('HR (1/min)');
grid on
title("Szívfrekvencia (HR): " + round(mean(hr),1) + ", Max. HR: " + round(max(hr),1) + ", Min. HR: " + round(min(hr),1)+" Szórás: "+round(mad(hr),1)+" fájl: "+data);
legend('Szívfrekvencia');

figure(4);
plot(legzesDiff);
hold on
scatter(locs,pks);
title("Légzési frekvencia: " + round(mean(legzesFr),1) + ", Max. légzés: " + round(max(legzesFr),1) + ", Min. légzés: " + round(min(legzesFr),1)+" Szórás: "+round(mad(hr),1)+" fájl: "+data);

figure(5)
plot(f,powerEcg);
axis([0 55 0 inf]);
grid on
xlabel('Frekvencia');
ylabel('Teljesítmény');
title("Az ECG jel teljesítmény spektruma"+"  fájl: "+data);

figure(6)
plot(ppg_filtfilt,'r');
hold on
plot(ecg_filtfilt*1000,'b');
grid on
xlabel('Idő (ms)');
ylabel('Amplitudo [Relatív egység]');
legend('PPG','ECG');
title("PPG jel, aluláteresztő szűrővel."+"  fájl: "+data);

figure(7)
plot(f,powerPpg)
axis([0 55 0 inf]);
grid on
xlabel('Frekvencia');
ylabel('Teljesítmény');
title("A PPG jel teljesítmény spektruma"+"  fájl: "+data);

figure(8)
plot(press_mmhg,'r');
grid on
xlabel('Idő');
ylabel('Nyomás [mmHg]');
title("A mandzsetta nyomása"+"  fájl: "+data);

figure(9)
plot(ecg_notch,'r');
grid on
xlabel('Idő');
ylabel('feszültség (mv)');
title("ECG jel 50Hz lyukszűrővel"+"  fájl: "+data);