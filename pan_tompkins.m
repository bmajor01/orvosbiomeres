%qrs=pan_tompkins(ekg)
%Csordas  Peter 07.03.26
%Pan Tompkins QRS detektor
% fs: optional - sampling freq in Hz - default is 1000
function qrs=pan_tompkins(ekg,fs)
    if 1==nargin
        fs=1000;
    end
    fsh=fs/2;
    
    %Signal processing
    [b,a]=butter(5,5/fsh,'high'); ekgf=filtfilt(b,a,ekg);                                   %Filtering 5-22 Hz
    [b,a]=butter(5,22/fsh); ekgf=filtfilt(b,a,ekgf);
    ekgd(1:length(ekgf),1)=0;                                                                 %Differentiate
    ekgd(3:end-2)= (-ekgf(1:end-4) -2*ekgf(2:end-3) +2*ekgf(4:end-1) + ekgf(5:end) );        
    %ekgp=abs(ekgd);                                                                         %Taking absolute value
    ekgp=ekgd.^2;
    N=round(150*fs/1000);
    ekgp=filter(ones(1,N)/N,1,ekgp);                                                      %150 ms Moving average

    
    %Peak detection
    tmp0=diff(ekgp);
    tmp1=ekgp.*([0; tmp0]>0).*([tmp0; 0]<0);
    peak_locations=find(tmp1); 

    %Ignore all peaks that precede or follow larger peaks by less than 200 ms.
    Tmin=round(200*fs/1000);
    tmp0=find(diff(peak_locations)<Tmin);
    while ~isempty(tmp0)
        tmp1=ekgp(peak_locations(tmp0))-ekgp(peak_locations(tmp0+1));
        peak_locations(tmp0+(tmp1>0))=0; peak_locations=nonzeros(peak_locations);
        tmp0=find(diff(peak_locations)<Tmin);
    end

%figure; plot(ekgp); linmark(peak_locations,'''k''');

%     tmp0=ekg(peak_locations);
%     idx=find((tmp0>500) & (tmp0<3500)); % A kiules nem csucs
%     peak_locations=peak_locations(idx);
    
    qrs=1;
    peak=ekgp(peak_locations);
    
    %Initial estimations
    SPKI=min(peak(1:10));
    NPKI=0;
    RRint(1:8)=360*fs/1000;
    
    for j=1:length(peak_locations)
        rr=mean(RRint);
        THRI=NPKI+0.35*(SPKI-NPKI); %Az eredeti algoritmusban 0.25 a kuszob
        rrnew=peak_locations(j)-qrs(end);
        %If the peak is larger than the detection threshold call it a QRS complex,or If no QRS has been detected within 1.5 R-to-R intervals, there was a peak that was larger than half the detection threshold, and the peak followed the preceding detection by at least 360 ms, classify that peak as a QRS complex.
        if peak(j)>THRI || (peak(j)>THRI/2 && rrnew>max(1.66*rr,360*fs/1000) )
                            
            %T szures, ha <360 az rr
            if rrnew<(360*fs/1000)
                tmp0=diff(ekgp(qrs(end):peak_locations(j)));
                if max(tmp0)<-0.8*min(tmp0)
                  NPKI=(7*NPKI+peak(j))/8;
                  continue;
                end
            end
            noise_cntr=0; %CsP
            qrs(end+1)=peak_locations(j);
            if (peak(j)>THRI)
                SPKI=(7*SPKI+peak(j))/8;
            else
                SPKI=(3*SPKI+peak(j))/4;
            end
            if rrnew>0.92*rr && rrnew<1.16*rr
                RRint=[RRint(2:end) rrnew];
            end                        
        else    %otherwise call it noise.
            NPKI=(7*NPKI+peak(j))/8;
            noise_cntr=noise_cntr+1; %CsP nagy QRS-nek vett csucs miatt SPKI elszallt? - fokozatos csokkentes
            if noise_cntr>3
                SPKI=7*SPKI/8;
            end
        end
    end
    qrs=qrs(3:end);
    
    %Csúcsba tolás
    for j=1:length(qrs)
        tmp0=max(1,qrs(j)-100); 
        tmp1=min(length(ekgf),qrs(j)+100);
        tmp1=ekgf(tmp0:tmp1); tmp1=find(tmp1==max(tmp1)); tmp1=tmp1(1);
        qrs(j)=tmp0+tmp1-1;
    end
    
    if size(ekg,1)>1
        qrs=qrs'; %return the same type, as input
    end
    
  
    
