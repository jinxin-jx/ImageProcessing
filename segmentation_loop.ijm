{
dir_saving = getDirectory("Choose a Directory to save");
    dir_processing = getDirectory("Choose a Directory to proess");
    list = getFileList(dir_processing);
    for(i = 0; i < list.length; i++) 
	{
      open(list[i]);//Open each image;
      name = substring (list[i],4);
      savename = "Mask_" + name;
      run("Trainable Weka Segmentation");
      wait(3000);
      selectWindow("Trainable Weka Segmentation v3.3.2");
      call("trainableSegmentation.Weka_Segmentation.loadClassifier", "D:\\2 orignal data\\1 Arclight\\6 apply\\spiking\\classifier.model");
      wait (3000);
      call("trainableSegmentation.Weka_Segmentation.getProbability");
      wait (3000);
      selectWindow("Probability maps");
      run("Stack to Images");
      selectWindow("background");
      close();
     //setAutoThreshold("Default dark");
    //run("Threshold...");
     //setThreshold(0.9000, 1000000000000000000000000000000.0000);
     //setThreshold(0.9000, 1000000000000000000000000000000.0000);
     //setThreshold(0.9000, 1000000000000000000000000000000.0000);
     //run("Convert to Mask");
     //run("Grays");
     saveAs("TIFF", dir_saving + savename);
     close("*");
         
     }
}
