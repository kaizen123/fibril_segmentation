function [ CC, s ] = FindCC_RegionProps( Data, Connectivity )
%FINDCC_REGIONPROPS returns CC->connected components list, and s->region
%properties array of image Data with specified Connectivity

CC = bwconncomp(Data, Connectivity);
stats = regionprops(CC, Data, 'Area', 'BoundingBox', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Centroid');
s = struct('Area', cat(1, stats.Area), 'BoundingBox', cat(1, stats.BoundingBox), 'Eccentricity', cat(1, stats.Eccentricity), 'MajorAxisLength', cat(1, stats.MajorAxisLength), 'MinorAxisLength', cat(1, stats.MinorAxisLength), 'Orientation', cat(1, stats.Orientation), 'Centroid', cat(1, stats.Centroid));

end

