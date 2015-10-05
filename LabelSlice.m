function [ ImageData ] = LabelSlice( ImageData, dims, OrigLabel, NewLabel, Start, CutOrientation, CutLength )
%LabelSlice returns an image with the given slice of the given region labeled
%   Helper function for LabelAreas.

curX = ceil(Start.x);
curY = ceil(Start.y);

switch CutOrientation
    case 'd0'
        ImageData(find(ImageData(curX:(curX+(CutLength-1)), curY) == OrigLabel) + sub2ind(size(ImageData), curX, curY)-1) = NewLabel;
    case 'd45'
        for i=1:CutLength
            if ImageData(curX, curY) == OrigLabel
                ImageData(curX, curY) = NewLabel;
            end
            curX = curX + 1;
            curY = curY - 1;
        end
    case 'd90'
        ImageData((find(ImageData(curX, curY:(curY+(CutLength-1))) == OrigLabel)-1)*dims.height + sub2ind(size(ImageData), curX, curY)) = NewLabel;
    case 'd135'
        for i=1:CutLength
            if ImageData(curX, curY) == OrigLabel
                ImageData(curX, curY) = NewLabel;
            end
            curX = curX + 1;
            curY = curY + 1;
        end
    otherwise
        error('Not a valid cut orientation!');
end

end

