{
dir_saving = getDirectory("Choose a Directory to save");
    dir_processing = getDirectory("Choose a Directory to proess");
    list = getFileList(dir_processing);
    for(i = 0; i < list.length; i++) 
	{ run("Trainable Weka Segmentation", dir_processing + list [i]);
	  name = list [i];
      subname = substring (name,4);
      windowname = name;
      savename = "Mask_" + subname;
      selectWindow(windowname);
      run("Trainable Weka Segmentation");
      selectWindow("Trainable Weka Segmentation v3.3.2");
      call("trainableSegmentation.Weka_Segmentation.loadClassifier", "D:\\2 orignal data\\1 Arclight\\6 apply\\spiking\\classifier.model");
      call("trainableSegmentation.Weka_Segmentation.getProbability");
      selectWindow("Probability maps");
      selectWindow("Probability maps");
      run("Stack to Images");
      selectWindow("background");
      close();
     setAutoThreshold("Default dark");
    //run("Threshold...");
     setThreshold(0.9000, 1000000000000000000000000000000.0000);
     setThreshold(0.9000, 1000000000000000000000000000000.0000);
     setThreshold(0.9000, 1000000000000000000000000000000.0000);
     run("Convert to Mask");
     run("Grays");
     saveAs("TIFF", dir_saving + savename);
     selectWindow("Trainable Weka Segmentation v3.3.2");
     close();
     selectWindow(windowname);
     close();
     selectWindow(savename);
     close();
     
     
	}
}
