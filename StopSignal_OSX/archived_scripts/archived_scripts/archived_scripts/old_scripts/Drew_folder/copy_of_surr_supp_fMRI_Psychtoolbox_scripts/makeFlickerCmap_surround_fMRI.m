function cmap = makeFlickerCmap_surround(display, params)if isfield(params,'stimulusDuration')    params.duration = params.stimulusDuration;endnFrames = getFrames(display, params.duration);[lowCol, highCol] = getFreeColors(display);cmap = zeros(display.numColors,3,nFrames);time = linspace(0, params.duration, nFrames+1);time = time(1:nFrames);numColors = highCol - lowCol + 1;maxColor = display.maxGunVal;midCol = (lowCol + highCol)/2;x = linspace(-0.5, 0.5, numColors)';frameCount = 0;for t = time;	frameCount = frameCount + 1;    f = (sin(2*pi*(params.temporalFrequency*t + params.temporalPhase))) * (numColors-1) .* x + midCol;    cmap(lowCol+1:highCol+1, :, frameCount) = round(f*ones(1, 3));    cmap(:,1:3,frameCount) = insertReservedCols(display, cmap(:,1:3,frameCount));    cmap(:,1:3,frameCount) = display.gammaTable(cmap(:,1:3,frameCount)+1);    tmp(frameCount) = cmap(100,1,frameCount);    tmp2(frameCount) = cmap(250,1,frameCount);end%cmap(lowCol+1:highCol+1, 1:3, nFrames+1) = midCol;%cmap(:, 1:3, nFrames+1) = insertReservedCols(display, cmap(:, 1:3, nFrames+1));%cmap(:, 1:3, nFrames+1) = display.gammaTable(cmap(:, 1:3, nFrames+1)+1);%plot change in color map values over a single cycle% figure% tmp(nFrames) = cmap(100,1,nFrames);% tmp2(nFrames) = cmap(250,1,nFrames);% plot(tmp);% hold on% plot(tmp2,'r');% tmp3 = zeros(1,nFrames)+cmap(100,1,nFrames);% plot(tmp3,'g');