function [ ImageData_Labeled ] = LabelAreas( ImageData_Labeled, dims, NewLabel, s, i, CutOrientation, OptimalCut )
%LabelAreas returns an image with the given region labeled
%   Uses helper function LabelSlice

smallDimension = min([s.BoundingBox(i, 3) s.BoundingBox(i, 4)]);

switch CutOrientation
    case 'd0'
        % final partition is bounded by the bounding box
        OptimalCut(length(OptimalCut)+1) = s.BoundingBox(i, 4);
        % cut number starts from two, and j starts from the second
        % partition, because there's no need to relabel first partition
        cutNum = 2;
        for j=(OptimalCut(1)+1):s.BoundingBox(i, 4)
            if j > OptimalCut(cutNum)
                % iterate to next cut
                cutNum = cutNum + 1;
            end
            Start.x = s.BoundingBox(i, 1);
            Start.y = s.BoundingBox(i, 2) + (j - 1);
            ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd0', s.BoundingBox(i, 3));
        end
    case 'd45'
        OptimalCut(length(OptimalCut)+1) = (s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1);
        cutNum = 2;
        for j=(OptimalCut(1)+1):(s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1)
            if j > OptimalCut(cutNum)
                cutNum = cutNum + 1;
            end
            % 45 degree cut moves down the y-axis of bounding box before
            % going across the x axis
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = s.BoundingBox(i, 2) + (j - 1);
                ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd45', min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2) + (s.BoundingBox(i, 4) - 1);
                ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd45', min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    case 'd90'
        OptimalCut(length(OptimalCut)+1) = s.BoundingBox(i, 3);
        cutNum = 2;
        for j=(OptimalCut(1)+1):s.BoundingBox(i, 3)
            if j > OptimalCut(cutNum)
                cutNum = cutNum + 1;
            end
            Start.x = s.BoundingBox(i, 1) + (j - 1);
            Start.y = s.BoundingBox(i, 2);
            ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd90', s.BoundingBox(i, 4));
        end
    case 'd135'
        OptimalCut(length(OptimalCut)+1) = (s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1);
        cutNum = 2;
        for j=(OptimalCut(1)+1):(s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1)
            if j > OptimalCut(cutNum)
                cutNum = cutNum + 1;
            end
            % 135 degree cut goes up then across
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = (s.BoundingBox(i, 2) + s.BoundingBox(i, 4) - 1) - (j - 1);
                ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd135', min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2);
                ImageData_Labeled = LabelSlice(ImageData_Labeled, dims, NewLabel, (NewLabel+cutNum-1), Start, 'd135', min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    otherwise
        error('Not a valid cut orientation!');
end


end

