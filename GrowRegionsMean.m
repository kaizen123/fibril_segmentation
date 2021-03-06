function [ OutputImage ] = GrowRegionsMean( ImageData, ImageCentroids, FractCrit, MaxDist, UniqueCols, SameCols)
%GrowRegionsMean returns an image array obtained via a region growing 
%algorithm that selects pixels based on similarity to the regional mean
%   
%   Region growth is controlled by an objective function with two terms.
%   The first is an error term that measures the difference between an
%   neighboring pixel and the regional mean. The second is a measure of
%   the rectilinear distance between the considered pixel and the seed
%   center. This (second) term is weighed by the CONST 'FIFO_WEIGHT'.
%   Intuitively, the larger the value of FIFO_WEIGHT, the more circular the
%   resulting region will be.
%   FIFO_WEIGHT should be larger if there is greater confidence that the
%   fibril seeds (centroids) lie close to the actual fibril centers.
%   Conversely, if the centroid-finding algorithm did not mark centers very
%   well, FIFO_WEIGHT should be set lower.

%   Specifically, the second term approximates rectilinear distance by 
%   counting the number of times the neighbor check loop (labeled
%   NEIGHBORHOOD CHECK LOOP) is run. Each neighbor visited by the nth
%   iteration of the loop is assigned the value n in its Neighborhoods
%   array. This way, the pixels discovered first (and closer to the center)
%   are prioritized over the pixels discovered later. Hence FIFO (first in
%   first out).

%   NOTE: GrowRegionsMean differs from GrowRegionsMin by one if the terms 
%   in its objective function. Both have a (tunable) term controlling the
%   circularity of the resulting region, but while GrowRegionsMin
%   considers pixels simply by their intensity (minimum intensity--stemming
%   from the intuition that fibril centers are darker than the background--
%   GrowRegionsMean considers them by their difference from the calculated
%   regional mean. GrowRegionsMin only works with fibrils (or similar
%   situations).

% NOTE: ONLINE EXPERTS HAVE SAID THAT IND2SUB AND SUB2IND ARE SLOWER THAN
% MANUAL IMPLEMENTATIONS THAT CONVERT LINEAR INDICES TO X- Y- COORDINATES (AND 
% VICE VERSA). IF SPEED EVER BECOMES AN ISSUE, THEY CAN BE REPLACED. CURRENTLY
% THEY ARE USED FOR READABILITY.

% ------
% CONSTS
% ------
INIT_NEIGHBORHOOD_SIZE = UniqueCols*SameCols+1;
INIT_COLLISION_LIST_LENGTH = 10;
FIFO_WEIGHT = 20;

% -------------
% SANITY CHECKS
% -------------
if (FractCrit < 0 || FractCrit > 1)
    error('GrowRegions: FractCrit (crit. threshold) must be between 0 and 1!');
end

NumCentroids = sum(sum(ImageCentroids == 1));

if NumCentroids ~= sum(sum(ImageCentroids))
    error('GrowRegions: ImageData should be binary image containing only 0s and 1s!');
end

ImSize = size(ImageData);

if ImSize ~= size(ImageCentroids)
    error('GrowRegions: ImageData size and CentroidImage size not equal!');
end

% --------------
% INITIALIZATION
% --------------

% image storing spatial data, also eventually function output
OutputImage = zeros(ImSize); 

NeighborhoodSize = INIT_NEIGHBORHOOD_SIZE;

% 3D array containing neighborhood information of each region:
% 1st dim: region ID (1 ~ NumCentroids)
% 2nd dim: neighbor ID (1 ~ NeighborhoodSize <- variable)
% 3rd dim: 3 parameters:
%   idx = 1,2: x,y coords of neighbor pixel
%   idx = 3: intensity of neighbor pixel
%   idx = 4: neighborhood check iteration number when pixel was added
Neighborhoods = zeros(NumCentroids, NeighborhoodSize, 4);

% collisions stored in separate array b/c # of collisions can be highly
% variable and may cause 3D neighborhood array to become unnecessarily
% large
CollisionListLength = INIT_COLLISION_LIST_LENGTH;
Collisions = zeros(NumCentroids, CollisionListLength);

% 2D (static length) array containing following information (of each region):
% idx = 1,2: x, y coords of newest pixel
% idx = 3: mean intensity of all constituent pixels (regmean)
% idx = 4: size/area of region (regsize)
% idx = 5: binary value, indicating whether region growth has finished
% idx = 6: number of neighbors, or length(Neighborhood(i,:))
% idx = 7: number of collisions, or length(Collisions(i))
% idx = 8: number of neighborhood check iterations
RegInf = zeros(NumCentroids,8);

% count of # of finished regions
NumFinishedRegions = 0;

% neighbor locations
NbLoc=[-1 0; 1 0; 0 -1;0 1];

% label centroids in CentroidImage with unique values (1 ~ NumCentroids),
% add them to RegInf(:, 1:2), and find first set of neighbors
centroids = find(ImageCentroids);
for i=1:NumCentroids
    % label OutputImage
    OutputImage(centroids(i)) = i;
    % update new pixel coords
    [RegInf(i, 1), RegInf(i, 2)] = ind2sub(ImSize,centroids(i));
    % update regmean
    RegInf(i, 3) = ImageData(centroids(i));
    % update regsize
    RegInf(i, 4) = 1;
    
    % CHECK NEIGHBORHOOD LOOP
    editedNeighborhood = false;
    % count number of times loop is executed,
    numChecks = RegInf(i,8);
    for j=1:4
        xn = RegInf(i,1) + NbLoc(j,1);
        yn = RegInf(i,2) + NbLoc(j,2);

        % neighbor pixel only valid if inside image bounds, if not, skip it
        if (xn < 1 || yn < 1 || xn > ImSize(1) || yn > ImSize(2))
            continue;
        end

        % extract neighbor pixel label
        NbLabel = OutputImage(xn,yn);
        % extract neighbor pixel intensity
        NbVal = ImageData(xn,yn);

        % get pointer to last neighbor in Neighboorhoods array
        NbPos = RegInf(i,6);

        % check if neighbor pixel is unclaimed; if so, add it to
        % neighborhood
        if NbLabel == 0
            editedNeighborhood = true;
            % increment to first empty neighbor cell
            NbPos = NbPos + 1;
            % add this neighbor to neighborhood
            %Neighborhoods(i,NbPos,:) = [xn,yn,NbVal];
            Neighborhoods(i,NbPos,1) = xn;
            Neighborhoods(i,NbPos,2) = yn;
            Neighborhoods(i,NbPos,3) = NbVal;
            Neighborhoods(i,NbPos,4) = numChecks + 1;
            % label it--
            % neighbors are labeled as n + regLabel, where n is the
            % total number of seeded regions, and regLabel is the
            % current region's label
            OutputImage(xn,yn) = NumCentroids + i;
            % update number of neighbors
            RegInf(i,6) = NbPos;

            % resize Neighborhoods array if too small
            % QUESTION: must all 2nd dimension vectors be resized, or
            % can just this current one be resized independently?
            if NbPos >= NeighborhoodSize
                NeighborhoodSize = 2*NeighborhoodSize;
                Neighborhoods(:,(NbPos+1):NeighborhoodSize,:) = 0;
            end

        % if claimed as neighbor of another region, increment
        % Collisions array
        elseif (NbLabel > NumCentroids && NbLabel <= 2*NumCentroids && NbLabel ~= (NumCentroids+i))
            % mark pixel as "contested pixel"
            OutputImage(xn,yn) = 2*NumCentroids+i;
            
            % get pointer for new collision position in Collision array
            ColPos = RegInf(i,7) + 1;
            % add the particular region ID of claimed pixel
            % note: region ID ranges from n ~ 2n, where n=NumCentroids
            Collisions(i,ColPos) = NbLabel - NumCentroids;
            % update number of collisions
            RegInf(i,7) = ColPos;
            
            % do same for opposing pixel
            ColPos2 = RegInf(NbLabel-NumCentroids,7);
            Collisions(NbLabel-NumCentroids,ColPos2) = i;
            RegInf(NbLabel-NumCentroids,7) = ColPos2 + 1;
            
            % resize Collisons array if too small
            if ColPos >= CollisionListLength || ColPos2 >= CollisionListLength
                CollisionListLength = 2*CollisionListLength;
                Collisions(:,(ColPos+1):CollisionListLength) = 0;
            end

        % if already a neighbor, already part of region, or contested,
        % skip
        elseif NbLabel == (NumCentroids+i) || NbLabel == i || NbLabel > 2*NumCentroids
            continue;

        % if not above two (three) cases, something's seriously wrong
        else
            error('GrowRegions: Sanity check failed. Something''s wrong!');
        end
    end
    
    % if neighborhood checked, increment iteration count
    if editedNeighborhood
            RegInf(i,8) = numChecks + 1;
    end
end

totalImageElems = numel(ImageData);
totRegSize = 0;

numFors = 0;
numWhiles = 0;

% ---------
% MAIN LOOP
% ---------

% grow each seeded region simultaneously until the number of finished
% regions passes a critical threshold (FractCrit)
while (NumFinishedRegions < FractCrit*NumCentroids && totRegSize < totalImageElems)
    % total region size, used for algorithm stop criteria
    totRegSize = 0;
    % iterate across all unfinished regions
    for i=find(~RegInf(:,5))'
        % extract important values describing region
        NbPos = RegInf(i,6);
        RegMean = RegInf(i,3);
        
        % find neighbor with most similar intensity to regmean
        % RegDist: max distance of region, or max(pixvals - regmean)
        % NOTE: would NbPos (left over from prev loop) still be the number
        % of neighbors? If not, clear 'remove neighbor' step too!!
        [Intensity, I] = min(abs(Neighborhoods(i,1:NbPos,3)-RegInf(i,3)).*Neighborhoods(i,1:NbPos,4).*FIFO_WEIGHT);
        
        % extract x and y coordinates
        xnew = Neighborhoods(i,I,1);
        ynew = Neighborhoods(i,I,2);
        
        % make sure the new pixel is not contested
        while OutputImage(xnew,ynew) > 2*NumCentroids
            % remove neighbor
            Neighborhoods(i,I,:) = Neighborhoods(i,RegInf(i,6),:);
            RegInf(i,6) = RegInf(i,6) - 1;
            % find next best pixel
            [Intensity, I] = min(Neighborhoods(i,1:NbPos,3));
            xnew = Neighborhoods(i,I,1);
            ynew = Neighborhoods(i,I,2);
        end
        
        % if RegDist lies within our threshold, add it to the region
        if Intensity <= MaxDist
            % extract regsize
            RegSize = RegInf(i,4);
            % label it
            OutputImage(xnew, ynew) = i;
            % update newest pixel coords
            RegInf(i,1:2) = Neighborhoods(i,I,1:2);
            % update regmean: (regmean*regsize+intensity(neighbor))/(regsize+1)
            RegInf(i,3) = (RegMean*RegSize+Neighborhoods(i,I,3))/(RegSize+1);
            % update regsize
            RegInf(i,4) = RegSize + 1;
            % remove pixel from neighborhood and decrement neighbor count
            Neighborhoods(i,I,:) = Neighborhoods(i,NbPos,:);
            RegInf(i,6) = NbPos - 1;
            
            %for Neighborhood check purposes
            editedNeighborhood = false;
            numChecks = RegInf(i,8);
            
            % add neighbors of new pixel
            % this is the same loop as in the OutputImage initialization
            % above; since this loop is (relatively) simple but called so
            % often(and manipulates so many large arrays), I figured it
            % would be better to minimize overhead and leave it in the
            % function than to create a separate one with it
            for j=1:4
                xn = RegInf(i,1) + NbLoc(j,1);
                yn = RegInf(i,2) + NbLoc(j,2);
                if (xn < 1 || yn < 1 || xn > ImSize(1) || yn > ImSize(2))
                    continue;
                end
                NbLabel = OutputImage(xn,yn);
                NbVal = ImageData(xn,yn);
                if NbVal == 0
                    error('Invalid NbVal extraction (NbVal cannot be zero)!');
                end
                NbPos = RegInf(i,6);
                if NbLabel == 0
                    editedNeighborhood = true;
                    NbPos = NbPos + 1;
                    Neighborhoods(i,NbPos,1) = xn;
                    Neighborhoods(i,NbPos,2) = yn;
                    Neighborhoods(i,NbPos,3) = NbVal;
                    Neighborhoods(i,NbPos,4) = numChecks + 1;
                    OutputImage(xn,yn) = NumCentroids + i;
                    RegInf(i,6) = NbPos;
                    if NbPos >= NeighborhoodSize
                        NeighborhoodSize = 2*NeighborhoodSize;
                        Neighborhoods(:,(NbPos+1):NeighborhoodSize,:) = 0;
                    end
                elseif (NbLabel > NumCentroids && NbLabel <= 2*NumCentroids && NbLabel ~= (NumCentroids+i))
                    OutputImage(xn,yn) = 2*NumCentroids+i;
                    ColPos = RegInf(i,7) + 1;
                    Collisions(i,ColPos) = NbLabel - NumCentroids;
                    RegInf(i,7) = ColPos;
                    ColPos2 = RegInf(NbLabel-NumCentroids,7) + 1;
                    Collisions(NbLabel-NumCentroids,ColPos2) = i;
                    RegInf(NbLabel-NumCentroids,7) = ColPos2;
                    if ColPos >= CollisionListLength || ColPos2 >= CollisionListLength
                        CollisionListLength = 2*CollisionListLength;
                        Collisions(:,(ColPos+1):CollisionListLength) = 0;
                    end
                elseif NbLabel == (NumCentroids+i) || NbLabel == i || NbLabel > 2*NumCentroids
                    continue;
                else
                    error('GrowRegions: Sanity check failed. Something''s wrong!');
                end
            end
            if editedNeighborhood
                RegInf(i,8) = numChecks + 1;
            end
        end
        
        % update total region size count
        totRegSize = totRegSize + RegInf(I,4);
        
        % check for fulfillment of stop growth criteria 
        if (Intensity > MaxDist || ...
                length(unique(Collisions(i,1:RegInf(i,7)))) > UniqueCols || ...
                length(find(Collisions(i,1:RegInf(i,7))==mode(Collisions(i,1:RegInf(i,7))))) > SameCols)
            RegInf(i,5) = 1;
            NumFinishedRegions = NumFinishedRegions + 1;
        end
        
        numFors = numFors+1;
    end
    
    numWhiles = numWhiles+1;
end

OutputImage(OutputImage>NumCentroids) = 0;

OutputImage(OutputImage>0) = 1;

OutputImage(ImageCentroids>0) = 2;

end

