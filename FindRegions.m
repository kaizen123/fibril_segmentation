function [ ImageCentroids ] = FindRegions( ImageData, LowPercentile, UpPercentile )
%FindRegions returns an image seeded with the centroids of each fibril
%   FindRegions splits the seeding problem three ways, and tackles each
%   separately. First, the image is analyzed for connected components.
%   These components are then categorized into three regions: large regions
%   describing multiple fibrils, medium regions describing exactly one
%   fibril, and small regions where one fibril can be described by multiple
%   regions.

%   The first is solved by a simplified normalized cut algorithm. The
%   second simply by a centroid-finding algorithm (regionprops). The
%   last uses a combination of a convolution kernel and a local maxima search

% debug mode stops the algorithm at multiple points to display key
% information
debug = true;

if debug
    disp('Debug mode is on. To turn off, set the variable to ''false'' inside FindRegions. Press Enter to continue...');
    pause; 
end

%
% SET CONSTS FOR OPTIMAL CUT:
% AreaDiffs, LengthDiffs, and TotalEdges weigh the importance of reducing
% total differences in area, total differences in length, and total cut
% edges over all the partitions
%
OptimalCutConst = struct('AreaDiffs', 1, 'LengthDiffs', 1, 'TotalEdges', 1);

[CC_4, s_4] = FindCC_RegionProps(ImageData, 4);
[Area_sorted, I] = sort(s_4.Area);

dims.width = CC_4.ImageSize(1);
dims.height = CC_4.ImageSize(2);

% find (tweakable) upper, median, and lower bound measures thresholded 
% fibril region, found via percentage of total area
curArea = 0;
totalArea = sum(Area_sorted);
i = 1;
while(curArea < totalArea * LowPercentile)
    curArea = curArea + Area_sorted(i);
    i = i + 1;
end
LowBoundIdx = i;
Size.LowBound = Area_sorted(i);

if debug
    disp(['LowPercentile found the cumulative area exceeding ' num2str(LowPercentile*100) '% total area to be the ' num2str(i) 'th region with area ' num2str(Size.LowBound) '. Press Enter to continue...']);
    pause;
end

while(curArea < totalArea * 0.5)
    curArea = curArea + Area_sorted(i);
    i = i + 1;
end
Size.MedBound = Area_sorted(i);
MedBoundIdx = i;

if debug
    disp(['Median found the cumulative area exceeding 50% total area to be the ' num2str(i) 'th region with area ' num2str(Size.MedBound) '. Press Enter to continue...']);
    pause;
end

while(curArea < totalArea * UpPercentile)
    curArea = curArea + Area_sorted(i);
    i = i + 1;
end
% sizeUpBound = Area_sorted(round(numel(Area_sorted) * UpPercentile));
Size.UpBound = Area_sorted(i);
UpBoundIdx = i;

if debug
    disp(['UpPercentile found the cumulative area exceeding ' num2str(UpPercentile*100) '% total area to be the ' num2str(i) 'th region with area ' num2str(Size.UpBound) '. Press Enter to continue...']);
    pause;
end

Size.AvgMajorAxisLength = mean(s_4.MajorAxisLength(I(MedBoundIdx:UpBoundIdx)));

ImageData_NoLarge = HighlightRegions(ImageData, CC_4, find(s_4.Eccentricity >= 0.9 & s_4.Area >= Size.MedBound), 0);
PixelIdxList_Large_4 = CC_4.PixelIdxList(s_4.Eccentricity >= 0.9 & s_4.Area >= Size.MedBound);

if debug
    % display the resulting image
    figure(1); clf; imshow(ImageData_NoLarge, [0 1]);
    disp('This is the image with highly eccentric and large 4-connected regions removed. Press Enter to continue...');
    pause;
end

[CC_NoLarge_8, s_NoLarge_8] = FindCC_RegionProps(ImageData_NoLarge, 8);

ImageData_NoLarge = HighlightRegions(ImageData_NoLarge, CC_NoLarge_8, find(s_NoLarge_8.Eccentricity >= 0.9 & s_NoLarge_8.Area >= Size.MedBound), 0);
PixelIdxList_Large_8 = CC_NoLarge_8.PixelIdxList(s_NoLarge_8.Eccentricity >= 0.9 & s_NoLarge_8.Area >= Size.MedBound);

if debug
    figure(2); clf; imshow(ImageData_NoLarge, [0 1]);
    disp('This is the image with highly eccentric and large 8-connected regions removed. Press Enter to continue...');
    pause;
end

ImageData_NoMedium = HighlightRegions(ImageData_NoLarge, CC_NoLarge_8, find(s_NoLarge_8.Eccentricity < 0.9 & s_NoLarge_8.Area >= Size.LowBound | s_NoLarge_8.Area <= 2), 0);
PixelIdxList_Medium = CC_NoLarge_8.PixelIdxList(s_NoLarge_8.Eccentricity < 0.9 & s_NoLarge_8.Area >= Size.LowBound);

if debug
    figure(3); clf; imshow(ImageData_NoMedium, [0 1]);
    disp('This is the image with medium sized 8-connected regions and <=2 pixel sized islands removed. Press Enter to continue...');
    pause;
end

newLabelCounter = 1;

% generate centroid image
ImageCentroids = zeros(dims.width, dims.height);

% -----------------------
% SMALL REGION PROCESSING
% -----------------------

convKernel(1:5, 1:5) = 1;

ConvolvedImage_NoMedium = imfilter(ImageData_NoMedium, convKernel, 'conv');
regMax_NoMedium = imregionalmax(ConvolvedImage_NoMedium, 4);

[~, s_regmax] = FindCC_RegionProps(regMax_NoMedium, 4);

% populate centroid image with small region centroids
for i=1:length(s_regmax.Centroid)
    ImageCentroids(round(s_regmax.Centroid(i, 2)), round(s_regmax.Centroid(i, 1))) = 1;
end

if debug
figure(4); clf; imshow(ImageCentroids, [0 1]);
disp('This is the centroid map of the previous image. Press Enter to continue...');
pause;
end

% ------------------------
% MEDIUM REGION PROCESSING
% ------------------------

Data_MedRegions = zeros(dims.width, dims.height);

for i=1:length(PixelIdxList_Medium)
    Data_MedRegions(PixelIdxList_Medium{i}) = newLabelCounter + i - 1;
end

newLabelCounter = newLabelCounter + length(PixelIdxList_Medium);

[~, s_Med] = FindCC_RegionProps(Data_MedRegions, 8);

% populate centroid image with medium region centroids
for i=1:length(s_Med.Centroid)
    ImageCentroids(round(s_Med.Centroid(i, 2)), round(s_Med.Centroid(i, 1))) = 1;
end

if debug
    figure(5); clf; imshow(ImageCentroids, [0 1]);
    disp('This is the centroid map updated with medium region centers. Press Enter to continue...');
    pause;
end


% -----------------------
% LARGE REGION PROCESSING
% -----------------------

% generate image of large regions from PixelIdxList
Data_LargeRegions_4 = zeros(dims.width, dims.height);
Data_LargeRegions_8 = zeros(dims.width, dims.height);

for i=1:length(PixelIdxList_Large_4)
    Data_LargeRegions_4(PixelIdxList_Large_4{i}) = 1;
end
for i=1:length(PixelIdxList_Large_8)
    Data_LargeRegions_8(PixelIdxList_Large_8{i}) = 1;
end

[~, s_LR4, newLabelCounter] = CutRegions(Data_LargeRegions_4, dims, Size, 4, newLabelCounter, OptimalCutConst);
[~, s_LR8] = CutRegions(Data_LargeRegions_8, dims, Size, 8, newLabelCounter, OptimalCutConst);

% populate centroid image with large region centroids
for i=1:length(s_LR4.Centroid)
    ImageCentroids(round(s_LR4.Centroid(i, 2)), round(s_LR4.Centroid(i, 1))) = 1;
end
for i=1:length(s_LR8.Centroid)
    ImageCentroids(round(s_LR8.Centroid(i, 2)), round(s_LR8.Centroid(i, 1))) = 1;
end

if debug
    figure(6); clf; imshow(ImageCentroids, [0 1]);
    disp('This is the centroid map updated with partitioned large region centers. FindRegions has completed.');
    pause;
end

end

