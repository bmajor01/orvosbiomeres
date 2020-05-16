function [avg,med] = averageEcg(data,preTrigger)

peaks = pan_tompkins(data);
medianLen = round(median(diff(peaks)));
avg = 0;

for i = 1 : length(peaks)-1

    
    cycle = data(round(peaks(i)- preTrigger) : round(peaks(i+1) - preTrigger));
     
    if length(cycle) == medianLen
        med = cycle;
    end
    
    avg = avg + resample (cycle,medianLen,length(cycle));
end

avg = avg/i;
disp ("Átlagolt minták száma: "+i);