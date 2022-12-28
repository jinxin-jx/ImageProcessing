function[theFiles] = file_open(format,files_pathway)
%file_open  open and read the all the files with designated file pattern
%requires the designated format and files_pathway


% Check to make sure that folder actually exists.  Warn user if it doesn't.
if ~isdir(files_pathway)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', files_pathway);
  uiwait(warndlg(errorMessage));
  return;
end
% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(files_pathway, strcat('*.',format)); % Change to whatever pattern you need.
theFiles = dir(filePattern);


%prepare for the mat output
for p = 1 : length(theFiles)
  baseFileName = theFiles(p).name;
  fullFileName = fullfile(files_pathway, baseFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
 
end
end