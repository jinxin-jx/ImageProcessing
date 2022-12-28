{
dir_saving = getDirectory("Choose a Directory to save");
    dir_processing = getDirectory("Choose a Directory to proess");
    list = getFileList(dir_processing);
    for(i = 0; i < list.length; i++) 
	{ open(list[i]);//Open each image;
      run("Z Project...", "projection=[Average Intensity]");
      saveAs("Tiff", dir_saving + getTitle);
      close();
      close();
	}
}
