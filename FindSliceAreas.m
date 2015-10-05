function [ SliceArea ] = FindSliceAreas( ImageData_Labeled, s, i, Label, CutOrientation )
%FindSliceAreas returns an n=numCuts array with the area of each slice
%   Iterates along each pixel of every cut and counts the number of labeled
%   pixels in the region's bounding box. Uses helper function CountArea.

[smallDimension] = min([s.BoundingBox(i, 3) s.BoundingBox(i, 4)]);

switch CutOrientation
    case 'd0'
        SliceArea = zeros(s.BoundingBox(i, 4), 1);
        for j=1:s.BoundingBox(i, 4)
            Start.x = s.BoundingBox(i, 1);
            Start.y = s.BoundingBox(i, 2) + (j - 1);
            SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd0', s.BoundingBox(i, 3));
        end
    case 'd45'
        SliceArea = zeros((s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1), 1);
        for j=1:(s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1)
            % 45 degree cut moves down the y-axis of bounding box before
            % going across the x axis
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = s.BoundingBox(i, 2) + (j - 1);
                SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd45', min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2) + (s.BoundingBox(i, 4) - 1);
                SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd45', min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    case 'd90'
        SliceArea = zeros(s.BoundingBox(i, 3), 1);
        for j=1:s.BoundingBox(i, 3)
            Start.x = s.BoundingBox(i, 1) + (j - 1);
            Start.y = s.BoundingBox(i, 2);
            SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd90', s.BoundingBox(i, 4));
        end
    case 'd135'
        SliceArea = zeros((s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1), 1);
        for j=1:(s.BoundingBox(i, 3) + s.BoundingBox(i, 4) - 1)            
            % 135 degree cut goes up then across
            if j <= s.BoundingBox(i, 4)
                Start.x = s.BoundingBox(i, 1);
                Start.y = (s.BoundingBox(i, 2) + s.BoundingBox(i, 4) - 1) - (j - 1);
                SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd135', min([smallDimension, j]));                
            else
                Start.x = s.BoundingBox(i, 1) + (j - s.BoundingBox(i, 4));
                Start.y = s.BoundingBox(i, 2);
                SliceArea(j) = CountArea(ImageData_Labeled, Label, Start, 'd135', min(smallDimension, (s.BoundingBox(i, 3) + s.BoundingBox(i,4) - j)));
            end
        end
    otherwise
        error('Not a valid cut orientation!');
end

end

