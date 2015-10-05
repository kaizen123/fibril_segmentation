function [ NumEdges ] = CheckNeighbors( ImageData, Label, Start, CutOrientation, CutLength )
%CheckNeighbors returns number of neighboring pixels (edges) in a slice
%   Given a list of pixel indices and a direction, check each pixel's
%   respective neighbors for a foreground pixel in the given direction

NumEdges = 0;

% round start values up so that they are integers
curX = ceil(Start.x);
curY = ceil(Start.y);

% cut algorithm: runs along the pixels of a cut in the given orientation,
% checks each pixel for neighbors
switch CutOrientation
    case 'd0'
        NumEdges = sum(ImageData(curX:(curX+(CutLength-1)), curY) == Label & ImageData(curX:(curX+(CutLength-1)), curY+1) == Label);
    case 'd45'
        newRegion = true;
        for i=1:CutLength
            if(ImageData(curX, curY) == Label && ImageData(curX + 1, curY) == Label) 
                NumEdges = NumEdges + 1;
                % in a diagonal cut, a foreground pixel preceded by a  
                % background pixel has to check two neighbors. since 
                % we check for eastern neighbors each pixel, here the
                % second check is for a southern neighbor
                if(newRegion && ImageData(curX, curY + 1)) 
                    NumEdges = NumEdges + 1;
                    newRegion = false;
                end
            elseif(ImageData(curX, curY) ~= Label)
                newRegion = true;
            end
            curX = curX + 1;
            curY = curY - 1;
        end
    case 'd90'
        NumEdges = sum(ImageData(curX, curY:(curY+(CutLength-1))) == Label & ImageData(curX+1, curY:(curY+(CutLength-1))) == Label);
    case 'd135'
        newRegion = true;
        for i=1:CutLength
            if(ImageData(curX, curY) == Label && ImageData(curX + 1, curY) == Label) 
                NumEdges = NumEdges + 1;
                % in this case, the second check is for a northern neighbor
                if(newRegion && ImageData(curX, curY - 1) == Label) 
                    NumEdges = NumEdges + 1;
                    newRegion = false;
                end
            elseif(ImageData(curX, curY) ~= Label)
                newRegion = true;
            end
            curX = curX + 1;
            curY = curY + 1;
        end
    otherwise
        error('Not a valid cut orientation!');
end

end

