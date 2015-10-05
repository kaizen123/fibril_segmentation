% FibrilSegmentationDemo
clc;clear

disp('Starting fibril segmentation demo. For more information on each step, see the comments of this script file.');
disp('Start by loading data from a manually thresholded label file. Press enter to continue...');
pause;

% use LoadData_Amira (a third party script) to load label data (thresholded
% fibril regions).
[~, Data] = LoadData_Amira('sample_images/Cell1-01.Labels.am');

figure(1); clf; imshow(Data, [0 1]);
disp('These are the thresholded fibrils. These will be fed to FindRegions. Note that the proceeding dialogue comes from FindRegions. Press Enter to continue...');
pause;

% run FindRegions. FindRegions locates the centroids of each fibril, based
% on its thresholded binary image.
ImageCentroids = FindRegions(Data, 0.4, 0.9);

% save ImageCentroids as an Amira raw file, to be reviewed on Amira. See
% documentation or comments in 'SaveData_Amira.m' to see how.
disp('Saving fibril centroid data...');
SaveData_Amira('Cell1-01.ImageCentroids.raw', ImageCentroids, 'uint8');
disp('The fibril centroids are saved to a file named ''Cell1-01.ImageCentroids.raw''. Now the original slice image data will be loaded. Press enter to continue...');
pause;

% load original slice image data from Amira. this can be done from a tiff 
% or from an Amira file via LoadData_Amira. here an Amira file is loaded.
[~, origData] = LoadData_Amira('sample_images/Cell1-01.am');

figure(2); clf; imshow(origData);
disp('This is the original slice image data. These will be fed to GrowRegionsMin. Press Enter to continue...');
pause;

% run GrowRegionsMin on ImageCentroids and the original slice image. 
% GrowRegionsMin implements a region growing algorithm, growing each region
% with the lowest intensity valued pixel in its neighborhood.
FractCrit = 0.6;
MaxIntensity = 200;
MaxUniqueCollisions = 2;
MaxSameCollisions = 4;
LabelledImage = GrowRegionsMin(origData, ImageCentroids, FractCrit, MaxIntensity, MaxUniqueCollisions, MaxSameCollisions);

figure(3); clf; imshow(LabelledImage);
disp('This is the label data returned by GrowRegionsMin. This will be saved to a file named ''Cell1-01.ImageLabelled.raw''. Press enter to continue...');
pause;
fusedImage = imfuse(origData,LabelledImage, 'blend');
figure(4); clf; imshow(fusedImage);
disp('Here is the segmented image overlaid over the original.');
pause;
% save LabelledImage as an Amira raw file.
disp('Saving labelled fibril data...');
SaveData_Amira('Cell1-01.ImageLabelled.raw', ImageCentroids, 'uint8');

disp('Demo has finished.');
