function locs = peakDetect(data)

trh = 0.8;
diffInput = diff(data);
avgVal = mean(diffInput);
maxVal = max(diffInput);
pkNo = 0;
peakVal = 0;
n=1;
pkFound = false;
localMax = 0;

treshold = trh*(maxVal - avgVal)+avgVal;
 
  for i = 1 : length(diffInput)
     
    if(diffInput(i)>treshold)               %hogyha átlépjük a beállított küszöbértéket, várunk amig fölötte vagyunk.
        pkFound = true;
        localMax(n) = diffInput(i);
        n=n+1;
        
    elseif(pkFound)                         %Bemásoltuk az összes küszöb fölötti dolgot a localMax ba. 
        startVal = i - n;                   %Az eredeti jelen itt léptük át a tresholdot
        pkFound = false;
        pkNo = pkNo+1;                      %számoljuk a megtalált csúcsokat
        for k = 1:length(localMax)          %ciklusban megkeressük a treshold fölötti rész maximum értékét és helyét
            if(localMax(k) > peakVal)
                peakLoc = k;                %ez lesz az offst az eredeti jelen
                peakVal = localMax(k);
            end
        end
        locs(pkNo) = startVal+peakLoc;      %Hozzáadjuk az offszetet
        k = 1;
        n = 1;
    end
  end
  
    for i = 1 : length(locs)                        %Az algoritmus a derivált fgv.csúcsait találja meg. Itt áttérünk az eredeti jelre
        z=0;
        while(data(locs(i)) <= data(locs(i)+z))     %A derivált csúcsértékétől addig lépked előre, amig talál egy csúcsot az eredeti jelen is. 
            z=z+1;
            locs(i)=locs(i)+z-1;
        end
    end 
end