function [ fid ] = SaveData_Amira( Filename, Data, DataType )
%SaveData_Amira writes an image matrix into an Amira compatible raw file
%   To use with Amira:
%       (1) save with file extension '.raw' and data type 'uint8'. if >255 
%           labels, change data type size accordingly
%       (2) in Amira, load as 'raw' file in specified data type with image
%           dimensions in Project View
%       (3) right click on file in Project View. in menu, go to Convert>
%           Convert Image Type, and choose (data type)-bit Label in 
%           'Properties' window
%       (4) open in segmentation

if(exist(Filename, 'file') == 2)
    overwrite = '';
    while(~strcmpi(overwrite, 'n') && ~strcmpi(overwrite, 'y') && ~strcmpi(overwrite, 'no') && ~strcmpi(overwrite, 'yes'))
        overwrite = input('File name already exists. Overwrite? [Y N] ', 's');
    end
    if(strcmpi(overwrite, 'n') || strcmpi(overwrite, 'no'))
        error('Save aborted.');
        return
    end
end

Data = transpose(Data);

fid = fopen(Filename, 'w');
fwrite(fid, Data, DataType, 'ieee-le');

fclose(fid);

return

end

