// author: ORION-CIRB

requires("1.54");

// Get images list
inDir = getDirectory("Choose images directory");
list = getFileList(inDir);

// Generate a dialog box
channels = newArray("0", "1", "2");
methods = getList("threshold.methods");
Dialog.create("Parameters");
Dialog.addMessage("Select channels");
Dialog.addChoice("bCat:", channels, channels[0]);
Dialog.addChoice("pPAX:", channels, channels[1]);
Dialog.addMessage("Select thresholding methods");
Dialog.addChoice("bCat:", methods, methods[15]);
Dialog.addChoice("pPAX:", methods, methods[11]);
Dialog.addHelp("https://github.com/orion-cirb/bCat_pPAX.git");
Dialog.show();
bCatChannel = Dialog.getChoice();
pPaxChannel = Dialog.getChoice();
bCatMethod = Dialog.getChoice();
pPaxMethod = Dialog.getChoice();

setBatchMode(true);

// Create output folder
outDir = inDir + "Results"+ File.separator();
if (!File.isDirectory(outDir)) {
	File.makeDirectory(outDir);
}

// Write headers in results file
resultsFile = File.open(outDir + "results.csv");
print(resultsFile,"Image name\tbCat area\tpPAX area in bCat\tpPAX area out of bCat\n");

setForegroundColor(0, 0, 0);
setBackgroundColor(255, 255, 255);
run("Set Measurements...", "area redirect=None decimal=3");

for (i = 0; i < list.length; i++) {
  	if (endsWith(list[i], ".tif")) {	 
  	  	file = inDir + list[i];
  	  	name = list[i];
  	  	rootName = File.getNameWithoutExtension(list[i]); 
  	  
  	  	// Open bCat and pPAX channels (channel 3 and 4 respectively)
  	  	run("Bio-Formats Importer", "open=["+file+"] autoscale color_mode=Default rois_import=[ROI manager] specify_range split_channels");
  	  	
  	  	// Process bCat channel
  	  	bCatImage = name+" - C="+bCatChannel;
  	  	selectWindow(bCatImage);
  	  	run("Gaussian Blur...", "sigma=4");
  	  	setAutoThreshold(bCatMethod+" dark");
  	  	setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Median...", "radius=4");
		run("Create Selection");
		List.setMeasurements();
		bCatArea = List.getValue("Area");

		// Process pPAX channel
		pPaxImage = name+" - C="+pPaxChannel;
		selectWindow(pPaxImage);
		run("Median...", "sigma=2");
  	  	setAutoThreshold(pPaxMethod+" dark");
  	  	setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Median...", "radius=2");
		run("Duplicate...", "title=pPaxIn");
		run("Restore Selection");
		run("Duplicate...", "title=pPaxOut");
		run("Restore Selection");

		// pPax into bCat
		selectWindow("pPaxIn");
		run("Clear Outside");
		run("Select None");
		run("Create Selection");
		List.setMeasurements();
		pPaxInArea = List.getValue("Area");
		
		// pPax out of bCat
		selectWindow("pPaxOut");
		run("Clear");
		run("Select None");
		run("Create Selection");
		List.setMeasurements();
		pPaxOutArea = List.getValue("Area");
  	  	print(resultsFile, rootName+"\t"+bCatArea+"\t"+pPaxInArea+"\t"+pPaxOutArea+"\n");

  	  	// Save results image
  	  	run("Merge Channels...", "c1=[&bCatImage] c2=[&pPaxImage] create");
		saveAs("Tiff", outDir+name);
		close("*");
	}
}

File.close(resultsFile);
setBatchMode(false);
showStatus("Analysis done!");
