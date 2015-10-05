function [ OptimalCut ] = FindOptimalCut( SliceArea, NumEdges, NumCuts, FuzzyRegion, Const )
%FindOptimalCut returns the optimal normalized cut of the region
%   Given a region, FindOptimalCut weighs every cut in a particular
%   orientation in an objective function of three terms: AreaDiff, or the
%   difference in the areas of each resulting partition, LengthDiffs, or
%   the number of pixels in length of the partition along the region's
%   longest axis, and TotalEdges, or the sum total of all edges removed in
%   the considered cut.
%   Each term is preceded by a tunable weight stored in Const

if NumCuts == 0
    OptimalCut = length(SliceArea);
    return
end

if mod(FuzzyRegion, 2) ~= 0
    error('FuzzyRegion must be an even value!');
end

NumSlices = length(SliceArea);

% expected partition size, calculated by the average
ExpectedPartSize = round(sum(SliceArea)/(NumCuts+1));
ExpectedPartLength = round(NumSlices/(NumCuts+1));

% generate cut locations
CutNorms = permn([-FuzzyRegion/2:(FuzzyRegion/2-1)], NumCuts);
CutNorms = cat(2, CutNorms, zeros(FuzzyRegion^NumCuts, 1));

AreaDiffs = zeros(FuzzyRegion^NumCuts, 1);
LengthDiffs = zeros(FuzzyRegion^NumCuts, 1);
TotalEdges = zeros(FuzzyRegion^NumCuts, 1);

for i=1:FuzzyRegion^NumCuts
    counter = 1;
    CutLoc = ExpectedPartLength*(1:(NumCuts+1)) + CutNorms(i, :);
    CutLoc(CutLoc>NumSlices) = NumSlices;
    CutLoc(CutLoc<=0) = 1;
    totArea = zeros(NumCuts+1, 1);
    for j=1:(NumCuts+1)
        for k = counter:min(CutLoc(j), NumSlices)
            totArea(j) = totArea(j) + SliceArea(k);
        end
        counter = k;
    end
    AreaDiffs(i) = sum((totArea-ExpectedPartSize).^2);
    LengthDiffs(i) = sum((CutNorms(i, :)).^2);
    TotalEdges(i) = sum(NumEdges(CutLoc));
end

ScaledAreaDiffs = (AreaDiffs - min(AreaDiffs))./max(1,(max(AreaDiffs) - min(AreaDiffs)));
ScaledLengthDiffs = (LengthDiffs - min(LengthDiffs))./max(1, (max(LengthDiffs) - min(LengthDiffs)));
ScaledTotalEdges = (TotalEdges - min(TotalEdges))./max(1, (max(TotalEdges) - min(TotalEdges)));

ObjFunc = Const.AreaDiffs*ScaledAreaDiffs + Const.LengthDiffs*ScaledLengthDiffs + Const.TotalEdges*ScaledTotalEdges;

[~, I] = min(ObjFunc);
OptimCutNorms = CutNorms(I, 1:NumCuts);
PartOffsets = ExpectedPartLength:ExpectedPartLength:((NumCuts)*ExpectedPartLength);
OptimalCut = OptimCutNorms + PartOffsets;

end

