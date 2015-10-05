function [ ImageData_Labeled, s, newLabelCounter ] = CutRegions( ImageData, dims, Size, Connectivity, LabelStart, OptimalCutConst )
%CutRegions returns an image with all large regions cut and labeled
%   Detailed explanation goes here

% if connectivity of regions is 8, see if reducing it to 4 will
% automatically solve some cuts
if Connectivity == 8
    [CC, s] = FindCC_RegionProps(ImageData, 4);
    % do not include trivially small regions where s.Area <= 3 (arbitrary
    % guess that may need to be turned into a tweakable parameter)
    DisconnectedRegions = CC.PixelIdxList(s.Eccentricity < 0.9 & s.Area > 3 & s.Area < Size.UpBound);
    ScrapRegions = find(s.Area <= 3);
    for i=1:length(DisconnectedRegions)
        ImageData(DisconnectedRegions{i}) = 0;
    end
    for i=1:length(ScrapRegions)
        ImageData(CC.PixelIdxList{ScrapRegions(i)}) = 0;
    end
end

[CC, s] = FindCC_RegionProps(ImageData, Connectivity);
ImageData_Labeled_Transposed = transpose(ImageData);

newLabelCounter = 1;

for i=1:length(s.Orientation)
    [subX, subY] = ind2sub([dims.width dims.height], CC.PixelIdxList{i});
    PixelTransposeIdx = sub2ind([dims.height dims.width], subY, subX);
    ImageData_Labeled_Transposed(PixelTransposeIdx) = newLabelCounter;
    
    % find which side of the bounding box is smaller
    [smallDimension] = min([s.BoundingBox(i, 3) s.BoundingBox(i, 4)]);
    
    % angle thresholds for the cuts should also be tweaked (right now they
    % are evenly split, but some intuition says that maybe the diagonal cut
    % should be more favored)
    
    % note: angles are w.r.t. the horizontal axis, and where the positive
    % y-axis is up, even though the positive y-axis points down in images
    % (very confusing, yes)
    if (s.Orientation(i) <= -67.5 || s.Orientation(i) > 67.5)
        CutOrientation = 'd0';
        NumEdges = zeros(s.BoundingBox(i, 4), 1);
        for j=1:s.BoundingBox(i, 4)
            Start.x = s.BoundingBox(i, 1);
            Start.y = s.BoundingBox(i, 2) + (j - 1);
            NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, s.BoundingBox(i, 3));
        end
    elseif (s.Orientation(i) > -67.5 && s.Orientation(i) <= -22.5)
        CutOrientation = 'd45';
        NumEdges = zeros((s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1), 1);
        for j=1:(s.BoundingBox(i, 3) + s.BoundingBox(i,4) - 1)
            % 45 degree cut moves down the y-axis of bounding box before
            % going across the x axis
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = s.BoundingBox(i, 2) + (j - 1);
                NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2) + (s.BoundingBox(i, 4) - 1);
                NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    elseif (s.Orientation(i) > -22.5 && s.Orientation(i) < 22.5)
        CutOrientation = 'd90';
        NumEdges = zeros(s.BoundingBox(i, 3), 1);
        for j=1:s.BoundingBox(i, 3)
            Start.x = s.BoundingBox(i, 1) + (j - 1);
            Start.y = s.BoundingBox(i, 2);
            NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, s.BoundingBox(i, 4));
        end
    elseif (s.Orientation(i) > 22.5 && s.Orientation(i) <= 67.5)
        CutOrientation = 'd135';
        NumEdges = zeros((s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1), 1);
        for j=1:(s.BoundingBox(i, 3) + s.BoundingBox(i,4) - 1)            
            % 135 degree cut goes down then across
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = (s.BoundingBox(i, 2) + s.BoundingBox(i, 4) - 1) - (j - 1);
                NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2);
                NumEdges(j) = CheckNeighbors(ImageData_Labeled_Transposed, newLabelCounter, Start, CutOrientation, min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    else
        error('cutRegion: Region orientation check fell through!');
    end
    
    SliceArea = FindSliceAreas(ImageData_Labeled_Transposed, s, i, newLabelCounter, CutOrientation);
    
    %[NumEdges_Sorted Idx] = sort(NumEdges, 'ascend');
    
    % we assume there at least needs to be one cut, or two partitions
    if s.Area < Size.MedBound
        NumPartitions = 1;
    else
        NumPartitions = max(2, min(floor(s.MajorAxisLength(i) / Size.AvgMajorAxisLength), 4));
    end
    
    % select best cut location based on objective function minimizing three
    % terms:
    % distance from expected cut location, difference from expected
    % partition area, and number of edges
    
    if NumPartitions > 1
        OptimalCut = FindOptimalCut(SliceArea, NumEdges, NumPartitions-1, 6, OptimalCutConst);
        ImageData_Labeled_Transposed = LabelAreas(ImageData_Labeled_Transposed, dims, newLabelCounter, s, i, CutOrientation, OptimalCut);
    end
    
    newLabelCounter = newLabelCounter + NumPartitions;
    
end

ImageData_Labeled = transpose(ImageData_Labeled_Transposed);

% if using 8-connected image, re-introduce the disconnected regions from
% before
if Connectivity == 8
    for i=1:length(DisconnectedRegions)
        ImageData_Labeled(DisconnectedRegions{i}) = newLabelCounter;
        newLabelCounter = newLabelCounter + 1;
    end
end

%figure, imshow(ImageData_Labeled)

stats = regionprops(ImageData_Labeled, 'Centroid', 'PixelIdxList');

s = struct('Centroid', cat(1, stats.Centroid), 'PixelIdxList', cat(1, stats.PixelIdxList));

end


        
