function [ Area ] = CountArea( ImageData, Label, Start, CutOrientation, CutLength )
%CountArea returns the area of the given region in the given slice
%   CountArea counts all pixels of a certain (provided) label across a
%   slice, given the start pixel, orientation, and cut length.

Area = 0;

curX = ceil(Start.x);
curY = ceil(Start.y);

switch CutOrientation
    case 'd0'
        Area = sum(ImageData(curX:(curX+(CutLength-1)), curY) == Label);
    case 'd45'
        for i=1:CutLength
            if ImageData(curX, curY) == Label
                Area = Area + 1;
            end
            curX = curX + 1;
            curY = curY - 1;
        end
    case 'd90'
        Area = sum(ImageData(curX, curY:(curY+(CutLength-1))) == Label);
    case 'd135'
        for i=1:CutLength
            if ImageData(curX, curY) == Label
                Area = Area + 1;
            end
            curX = curX + 1;
            curY = curY + 1;
        end
    otherwise
        error('Not a valid cut orientation!');
end

end

