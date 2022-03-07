/* e##########################################################################################################################
 * Project: Semi/Automated 2D cell counting with cFOS intansity threshold optimization
 * [ Prof Rohini Kuner and Heidelberg Pain Consortium (SFB 1158) ]
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Institute of Pharmacology and Department for Anatomy and Cell Biology @ Heidelberg University
 * Email: 	carlo.beretta@uni-heidelberg.de
 * 			carlo.berri82@googlemail.com
 * 
 * Description: extract intensity value and raw images pixel size.
 * This script has been used to prepare figure 1
 * 
 * ##########################################################################################################################
 */

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// #################################################
// StartUp Functions
// # 1
function Setting() {
	
	// Set the Measurements parameters
	run("Set Measurements...", "mean standard modal min median limit redirect=None decimal=8");

	// Set binary background to 0 
	run("Options...", "iterations=1 count=1 black");

	// General color setting
	run("Colors...", "foreground=white background=black selection=yellow");

}

// # 2 
// Close all the open images
function CloseAllWindows() {
	
	while (nImages > 0) {
		
		selectImage(nImages);
		close();
		
	}
	
}

// # 3
// Choose the input directories (Raw and Preprocessed images)
function InputDirectory() {

	dirIn = getDirectory("Please choose the input root directory with the RAW images");

	// The macro check that you choose a directory and output the input path
	if (lengthOf(dirIn) == 0) {
		
		exit("Exit");
			
	} else {
		
		// Output the path
		text = "\nInput Raw path:\t" + dirIn;
		print(text);
		
		// Return dirIn
		return dirIn;
			
	} 

}

//  # 4
// Output directory
function OutputDirectory(outputPath, year, month, dayOfMonth, second) {

	// Use the dirIn path to create the output path directory
	dirOutRoot = outputPath;

	// Change the path 
	lastSeparator = lastIndexOf(dirOutRoot, File.separator);
	dirOutRoot = substring(dirOutRoot, 0, lastSeparator);
	
	// Split the string by file separator
	splitString = split(dirOutRoot, File.separator); 
	for(i=0; i<splitString.length; i++) {

		lastString = splitString[i];
		
	} 

	// Remove the end part of the string
	indexLastSeparator = lastIndexOf(dirOutRoot, lastString);
	dirOutRoot = substring(dirOutRoot, 0, indexLastSeparator);

	// Use the new string as a path to create the OUTPUT directory.
	dirOutRoot = dirOutRoot + "MacroResults_" + year + "-" + (month+1) + "-" + dayOfMonth + "_0" + second + File.separator;
	return dirOutRoot;
	
}

// # 5
// Open the ROI Manager
function OpenROIsManager() {
	
	if (!isOpen("ROI Manager")) {
		
		run("ROI Manager...");
		
	} else {

		if (roiManager("count") == 0) {

			print("Warning! ROI Manager is already open and it is empty");

		} else {

			print("Warning! ROI Manager is already open and contains " + roiManager("count") + " ROIs");
			print("The ROIs will be deleted!");
			roiManager("reset");
			
		}
		
	}
	
}

// # 6
// Print summary function (Modified from ImageJ/Fiji Macro Documentation)
function sfprintsf(textSummary) {

	titleSummaryWindow = "Summary Window";
	titleSummaryOutput = "["+titleSummaryWindow+"]";
	outputSummaryText = titleSummaryOutput;
	
	if (!isOpen(titleSummaryWindow)) {

		// Create the results window
		run("Text Window...", "name="+titleSummaryOutput+" width=90 height=20 menu");
		
		// Print the header and output the first line of text
		print(outputSummaryText, "% File Id\t" + "% Input Raw Image File Name\t" + "% Mean Intensity Raw\t" + "% Std Intensity Raw\t" + "% Min Intensity Raw\t" + "% Max Intensity Raw\t" + "% Mode Intensity Raw\t" + "% Pixel Size\t" + "% Unit\t" + "% Mean Intensity Background\t" + "% Std Intensity Background" + "\n");
		print(outputSummaryText, textSummary +"\n");
	
	} else {

		print(outputSummaryText, textSummary +"\n");
		
	}

}

// #################################################
// End Functions
// # 1
function SaveStatisticWindow(dirOutRoot) {

	// Save the SummaryWindow and close it
	selectWindow("Summary Window");
	saveAs("Text", dirOutRoot + "SummaryMeasurements"+ ".csv");
	run("Close");
	
}

// # 2
// Close the ROI Manager 
function CloseROIsManager() {
	
	if (isOpen("ROI Manager")) {
		
		selectWindow("ROI Manager");
     	run("Close");
     	
	} else {
     	
     	print("ROI Manager window has not been found");
     	
	}	
     
}

// # 3
// Save and close Log window
function CloseLogWindow(dirOutRoot) {
	
	if (isOpen("Log")) {
		
		selectWindow("Log");
		saveAs("Text", dirOutRoot + "Log.txt"); 
		run("Close");
		
	} else {

		print("Log window has not been found");
		
	}
	
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
macro ImageQualityControl {

	// StartUp functions
	Setting();
	CloseAllWindows();

	// Get the starting time
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// Chosse teh input raw dirctory
	dirIn = InputDirectory();
	
	// List the file in the input root directory
	fileList = getFileList(dirIn);

	// Use the raw input path as output path
	outputPath = dirIn;

	// Create the output root directory in the input path
	dirOutRoot = OutputDirectory(outputPath, year, month, dayOfMonth, second);

	if (!File.exists(dirOutRoot)) {	
		
		File.makeDirectory(dirOutRoot);
		text = "Output path:\t" + dirOutRoot;
		print(text);
	
	} 

	// Open the roiManager
	OpenROIsManager();

	// Do not display the images
	setBatchMode(true);

	// Open the file located in the input directory
	for (i=0; i<fileList.length; i++) {

		// Check the input file format .tiff / .tif
		if (endsWith(fileList[i], '.tiff') || endsWith(fileList[i], '.tif')) {

			// Update the user
			print("\nProcessing file:\t\t" +(i+1));

			// Open the input raw image
			open(dirIn + fileList[i]);
			inputTitle = getTitle();
			print("Opening:\t" + inputTitle);
			
            // Remove file extension .tiff / tiff
            dotIndex = lastIndexOf(inputTitle, ".");
            title = substring(inputTitle, 0, dotIndex);
            
            // Measurements
            // 1. Image mean intensity
            meanImageIntensity = getValue("Mean");
            
            // 2. Image STD
            stdImageIntensity = getValue("StdDev");
            
            // 3. Image min and max
            minImageIntensity = getValue("Min");
            maxImageIntensity = getValue("Max");
            
            // 4. Image mode
            modeImageIntensity = getValue("Mode");
            
            // 5. Image pixel size
            getPixelSize(unit, pixelWidth, pixelHeight);
            
            // 6. Background estimation
            run("Duplicate...", " ");
			run("Gaussian Blur...", "sigma=30");
			rawBackground = getTitle();
            
            // 6a. Background Mean
            meanBackgroundIntensity = getValue("Mean");

            // 6b background Std
            stdBackgroundIntensity = getValue("StdDev");
            
            textSummary = "0" + (i+1) + "\t" + title + "\t" + meanImageIntensity + "\t" + stdImageIntensity  + "\t" + minImageIntensity + "\t" + maxImageIntensity + "\t" + modeImageIntensity + "\t" + pixelWidth + "\t" + unit + "\t" + meanBackgroundIntensity + "\t" + stdBackgroundIntensity;
            sfprintsf(textSummary);
            
            // Close the open images
            selectImage(inputTitle);
            close(inputTitle);
            selectImage(rawBackground);
            close(rawBackground);
            
		}
		
	}

	// Update the user 
	text = "\nNumber of file processed:\t\t" + (fileList.length);
	print(text);
	text = "\n%%% Congratulation your file have been successfully processed %%%";
	print(text);
	
	// End functions
	SaveStatisticWindow(dirOutRoot);
	CloseROIsManager();
	CloseLogWindow(dirOutRoot);
	
	// Display the images
	setBatchMode(false);
	showStatus("Completed");
	
}