function [ Data ] = HighlightRegions( Data, CC, RegionIdx, HighlightVal )
%HighlightRegions returns an image with the selected pixels highlighted
%   Pixels are fed by their RegionIdx, which is the pixel location in
%   singular array format


if(isfloat(HighlightVal))
    for x=(1:numel(RegionIdx))
        Data(CC.PixelIdxList{RegionIdx(x)}) = HighlightVal;
    end
else
    for x=(1:numel(RegionIdx))
        Data(CC.PixelIdxList{RegionIdx(x)}) = 3*x;
    end
end

end

