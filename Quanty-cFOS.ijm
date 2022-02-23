/* e##########################################################################################################################
 * Project: Semi/Automated 2D cell counting with cFOS staining analysis optimization
 * [ Prof Rohini Kuner and Heidelberg Pain Consortium (SFB 1158) ]
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Institute of Pharmacology and Department for Anatomy and Cell Biology @ Heidelberg University
 * Email: 	carlo.beretta@uni-heidelberg.de
 * 			carlo.berri82@googlemail.com
 * Tel.: 	+49 (0) 6221 54 8682
 * 
 * Description: 
 * User can choose different methods to count in 2D positive cells in section.
 * The tool is optimized to count cFOS positive cells. The idea is to compute the z-score for the intensity values of detected cells on 
 * a specified amount of images and use these values as cutoff to decide positive and false positive cFOS cells. 
 * User can specify two input folders with the raw images and the pre-processed images or use the 2D StarDist Versatile (fluorescent nuclei) model to 
 * segment the cell in 2D. In this case only one folder will be the input for the Quanty-cFOS script.
 * With few changes in the code the user can also load a specific model pretrained on his/her data.
 * 
 * TD: 
 * 		1. Run more test and fix bugs
 * 		2. Adjust area cutoff
 * 
 * Created: 2020-04-07
 * Last update: 2021-05-19
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
	run("Set Measurements...", "area mean center perimeter limit redirect=None decimal=8");

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
// Screen location
function ScreenLocation() {

	imageWidth = getWidth();																								
	imageHeight = getHeight();
	imageReshapeWidth = screenWidth *0.5;
	imageReshapeHeight = imageWidth *10;

	imageShape = newArray(imageReshapeWidth, imageReshapeHeight);
	return imageShape;
	
}

// # 4
// Choose the input directories (Raw and Preprocessed images)
function InputDirectoryRawPM(userOutput) {

	if (userOutput[0] == true && userOutput[1] == false) {

		dirInRaw = getDirectory("Please choose the input root directory with the RAW images");
		dirInPreProcess = getDirectory("Please choose the input root directory with the PREPROCESSED images");

		// The macro check that you choose a directory and output the input path
		if (lengthOf(dirInRaw) == 0 || lengthOf(dirInPreProcess) == 0) {
		
			exit("Exit");
			
		} else {
		
			// Output the path
			text = "\nInput Raw path:\t" + dirInRaw;
			print(text);
			text = "Input Preprocessed path:\t" + dirInPreProcess;
			print(text);

			inputPath = newArray(dirInRaw, dirInPreProcess);
			return inputPath;
			
		} 

	} else if (userOutput[0] == false && userOutput[1] == true) {

		dirInRaw = getDirectory("Please choose the input root directory with the RAW images");

		// The macro check that you choose a directory and output the input path
		if (lengthOf(dirInRaw) == 0) {
		
			exit("Exit");
			
		} else {
		
			// Output the path
			text = "\nInput Raw path:\t" + dirInRaw;
			print(text);

			inputPath = dirInRaw;
			return inputPath;
			
		}
		
	}
	
}

//  # 5
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

// # 6
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

// # 7
// # Main user input setting
function UserInput() {

	ilastikPM = true;
	
	starDist = false;
	tails = 1; // Deafult 1
	
	batch = false;
	optIntSteps = 3;

	Dialog.create("Main Setting Window");
	Dialog.addMessage("Quanty-cFOS for Semi/Automated cFOS Cells Counting & Beyond", 18);
	Dialog.addMessage("____________________________________________________________________________");
	Dialog.addCheckbox("Use Pre-Processed Image (ilastik Pixel Classification)", ilastikPM);
	Dialog.addCheckbox("Run StarDist 2D (Versatile - Fluorescent Nuclei)", starDist);
	Dialog.addToSameRow();
	Dialog.addNumber("StarDist Tails Number", tails);
	Dialog.addMessage(" _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _");
	Dialog.addMessage("\n");
	Dialog.addCheckbox("Batch Analysis", batch);
	Dialog.addToSameRow();
	Dialog.addNumber("Optimization Steps (N. Images)", optIntSteps);
	Dialog.addMessage("____________________________________________________________________________");
	Dialog.addMessage("\n*Quanty-cFOS.ijm tool has been developed for Prof Rohini Kuner's lab members\n and the Heidelberg Pain Consortium (SFB 1158 - https://www.sfb1158.de/)", 11, "#001090");
	Dialog.addMessage("	 **Last Update: 2021-05-18", 11, "#001090");
	
	// Add Help button
	html = "<html>"
		+ "<style> html, body { width: 500; height: 350; margin: 10; padding: 0; border: 0px solid black; background-color: #ECF1F4; }"
		+ "<h1> <center> &#128000; Quanty-cFOS &#128000; </center> </h1>"
		+ "<h3> <section> " 
		+ "<b> Options:</b>" 
			+ "<li><i>Pre-processed Images</i>: [INPUT] Choose the input folder with the raw images and the input folder with the pre-processed images (e.g.: <a href=https://www.ilastik.org/documentation/pixelclassification/pixelclassification>ilastik pixel classification</a>)<br/><br/></li>"
			+ "<li><i>Run <a href=https://imagej.net/StarDist> StarDist 2D</a></i>: [INPUT] Choose the input folder with the raw data! The pre-trained StarDist 2D model will be use to generate the labels image."
			+ " Increase the <b> StarDist Tails Number </b> in case of out-of-memory errors. <i><b>NB:</i></b> High is the number of tails slower is the process! <br/><br/></li>"
			+ "<li><i>Batch Analysis</i>: User can decide to process the input images one-by-one with a specific setting or process the input images using the same setting <br/><br/></li>"
			+ "<li><i>Optimization Steps</i>: Number of images that the user wants to process semi-automatically or in case of cFOS counting used to compute the optimized threshold value."
			+ " NB: The user should exclude these images from the final cFOS counting or reprocess the images using the optimized threshold. Check the LOG file to find the value used<br/><br/></li>"
		+ "</h3> </section>"
		+ "</style>"
		+ "</html>";

	Dialog.addHelp(html);
	Dialog.show();

	ilastikPM = Dialog.getCheckbox();
	starDist = Dialog.getCheckbox();
	tails = Dialog.getNumber();
	batch = Dialog.getCheckbox();
	optIntSteps = Dialog.getNumber();

	userOutput = newArray(ilastikPM, starDist, tails, batch, optIntSteps);
	return userOutput;
	
}

// # 8
// Input user setting
function InputDialog(title) {
	
	roiName = "cFOS-Positive";
	
	process2D = true;
	process3D = false;
	
	cFOS = true; 
	sigma = 3;
	usercFOSThreshold = false;
	
	processSubRegions = false;
	previewMode = false;
	
	Dialog.create("User Input Setting Window");
	Dialog.addString("RoiManger ROIs Tag:", roiName, 90);
	
	Dialog.addCheckbox("2D Analysis", process2D);
	Dialog.addToSameRow();
	Dialog.addCheckbox("3D Analysis (Not Implemented)", process3D);
	
	Dialog.addCheckbox("cFOS Automated Optimization (Experimental)", cFOS);
	Dialog.addToSameRow();
	Dialog.addNumber("Sigma", sigma);
	Dialog.addCheckbox("cFOS Manual Optimization", usercFOSThreshold);

	Dialog.addCheckbox("Select Multiple Sub-Brain Regions", processSubRegions);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Allow Preview User Setting", previewMode);
	
	// Add Help button
	html = "<html>"
		+ "<style> html, body { width: 500; height: 600; margin: 10; padding: 0; background-color: #ECF1F4; }"
		+ "<h1> &#128295; Help: </h1>"
		+ "<h3> <section>" 
		+ "<b> User Input Setting:</b>" 
			+ "<li><i>Image Tag: </i> any useful information that can be used to name the ROIs in the RoiManger for the positive cells<br/><br/></li>"
			+ "<li><i>Process2D: </i> the quantification is done on the Maximum Intensity Projection<br/><br/></li>" 
			+ "<li><i>(Not implemented) Process3D: </i> the quantification is done in 3D (volxel based)<br/><br/></li>" 
			+ "<li><i>cFOS Automated Optimization</i> <b>(&#8721; MeanIntensity / nROIs)</b>: compute the mean intensity value and the standard deviation of all ROIs."
			+ " <b>[Assumption Normal Distribution]<b/> the zScore <b>(z = &#x3C7; - &#x3BC; / &#x3C3;)</b> is computed for each ROI and used to classify cFOS positive and false positive neurons."
			+ " The sigma can be changed to increase or decrease the mean intensity cutoff [e.g.: 3]. This is still under testing, please be careful and validate the counting results with ground truth data.<br/><br/></li>"
			+ "<li><i>cFOS Maual Optimization: </i> the user can manually enter the intensity value to discriminate between cFOS positive"
			+ " and false positive neurons. cFOS positive cells have a value above the threshold / cFOS false positive cells have a value below the threshold."
			+ " <b>Uncheck the cFOS optimization boxes if your goal is to count the total number of cells in the images."
			+ " The batch mode analysis can be use without any optimization step (default)</b><br/><br/></li>"
			+ "<li><i>Select Multiple Sub-Brain Regions: </i> the user can process many regions in the same input image one-by-one (Not supported for StarDist)<br/><br/></li>" 
			+ "<li><i>Preview Mode: </i> user can visualize the image to threshold, test different threshold methods and measure the area of " 
			+ "the cells to detect. This information can be use as input for the cells segmentation in the Preview Dialog box (Not supported for StarDist)<br/><br/></li>"
		+ "</h3> </section>"
		+ "</style>"
		+ "</html>";

	Dialog.addHelp(html);
  	Dialog.show();

	roiName = Dialog.getString();
	process2D = Dialog.getCheckbox();
	process3D = Dialog.getCheckbox();
	cFOS = Dialog.getCheckbox();
	sigma = Dialog.getNumber();
	usercFOSThreshold = Dialog.getCheckbox();
	processSubRegions = Dialog.getCheckbox();
	previewMode = Dialog.getCheckbox();
	
	outputDialog = newArray(roiName, process2D, process3D, cFOS, usercFOSThreshold, processSubRegions, previewMode, sigma);
	return outputDialog;
		
}

// # 9 
// Check for StarDist installation
function CheckStarDistInstallation() {
	
	List.setCommands;
	
    if (List.get("StarDist 2D") != "" && List.get("N2V predict") != "") {

    	print("> StarDist 2D and CSBDeep are installed!");
    	wait(1000);
    	print("\\Clear");
       
    } else {
    	
		print("Before to start to use the Quanty-cFOS tool you need to install the StarDist 2D and CSBDeep plugins!");
		wait(3000);
		print("1. Select Help >> Update... from the menu to start the updater");
		print("2. Click on Manage update sites. This brings up a dialog where you can activate additional update sites");
		print("3. Check the StarDist and the CSBDeep checkboxes and close the dialog. Now you should see additional jar file ready to be installed");
		print("4. Click Apply changes and restart ImageJ");
		print("5. After restarting ImageJ you should be able to run this macro with StarDist 2D enabled option");
		exit();
    	
    }

}

// # 10
// Create Intensity Threshold values plot
function PlotOptimizationValueInt(optIntArray, intensityCutOff, optIntSteps, reduceNaN) {
	
	Plot.create("Intensity Threshold Optimization", "Optimization Steps", "Intensity Threshold");
	Plot.setColor("red");
	Plot.setBackgroundColor("#ECF1F4");
	//Plot.setLimitsToFit();
	Plot.setLimits(-1, (optIntSteps+reduceNaN), 0, 255);
	Plot.add("line", optIntArray);
	Plot.add("diamond", optIntArray);
	Plot.setColor("black");  
	Plot.setFontSize(18);  
	Plot.addText("*Opt. Int. Threshold: " + intensityCutOff, 0.45, 0.5);
	Plot.setLineWidth(8);

}

// # 11
// Check ImageJ version
function CheckImageJVersion() {

	currentVersion = getVersion();
	indexFilVersion = lastIndexOf(currentVersion, "/");
	currentVersion = substring(currentVersion, indexFilVersion+1, lengthOf(currentVersion));

	if (currentVersion > "1.53c") {

		print("ImageJ version [" + currentVersion + "]\t: Not Passed");
		exit("Update ImageJ, supported version >= 1.53c");

	} else {

		print("ImageJ version:[" + currentVersion + "]\t: Passed");
		wait(3000);

	}

}

// # 12
// Check input image bit depth
// It is supported only 8 bit raw images
// User can edit this part and process images with different bit depth but without any warranty (never tested)
function CheckBitDepth() {

	// Catch raw image bit depth
	inputBitDepth = bitDepth();

	if (inputBitDepth == 16 || inputBitDepth == 32 || inputBitDepth == 24) {

		setBatchMode(true);
		exit("Input must be 8 bit!\nThe input image is " + inputBitDepth +  " bit");
		
	} else {

		print("Input Image is " + inputBitDepth + " bit\t: Passed");
		
	}

}

// #################################################
// Analysis Functions
// # 1
// Check if the input raw image is a single channel image
// Only single channel images are supported
function CheckNumberOfCh(titleRaw, titlePreProcess) {

	// Raw
	selectImage(titleRaw);

	// Get image dimensions
    getDimensions(width, height, channels, slices, frames);

	if (channels == 1) {

		print("Raw Input Image Channel Test [Ch0" + channels + "]\t: Passed" );
		
	} else {

		// Display the input image
		setBatchMode(false);

		// Output the error message
		exit("Multi-Channels RAW Images are NOT supported!");
		
	}

	// PM
	selectImage(titlePreProcess);

	// Get image dimensions
    getDimensions(width, height, channels, slices, frames);

	if (channels == 1) {

		print("Pre-porcessed Images Channel Test [Ch0" + channels + "]\t: Passed" );
		
	} else {

		// Display the input image
		setBatchMode(false);

		// Output the error message
		exit("Multi-Channels Pre-porcessed Images are NOT supported!");
		
	}

}

// # 2
// Compute the MIP
function ComputeStack(inputTitleRaw, inputTitlePreProcess, process2D, process3D) {

	// Raw
	selectImage(inputTitleRaw);

	// Get image dimensions
    getDimensions(width, height, channels, slices, frames);

	if (slices > 1 && process2D == true && process3D == false) {

		// Compute the MIP
		run("Z Project...", "projection=[Max Intensity]");

		// Get MIP title
		titleRaw = getTitle();

		// Close the input raw image
		selectImage(inputTitleRaw);
		close(inputTitleRaw);

	} else if (slices > 1 && process2D == false && process3D == true ) {

		// Run the 3D analysis (Not implemented)
		
		
	} else {

		// The input image is already a MIP or the user choose the 3D analysis
		titleRaw = getTitle();

	}

	// PM
	selectImage(inputTitlePreProcess);

	// Get image dimensions
    getDimensions(width, height, channels, slices, frames);

	if (slices > 1 && process2D == true && process3D == false) {

		// Compute the MIP
		run("Z Project...", "projection=[Max Intensity]");

		// Get MIP title
		titlePreProcess = getTitle();

		// $$$$$$$$ To Test $$$$$$$$
		run("Median...", "radius=3");

		// Close the input PM image
		selectImage(inputTitlePreProcess);
		close(inputTitlePreProcess);

	} else if (slices > 1 && process2D == false && process3D == true) {

		// Run the 3D analysis (Not implemented)
			
		
	} else {

		// The input image is already a MIP or the user choose the 3D analysis
		titlePreProcess = getTitle();

		// $$$$$$$$ To Test $$$$$$$$
		run("Median...", "radius=3");

	}

		inputTitle = newArray(titleRaw, titlePreProcess);
		return inputTitle;

}

// # 3
// Print summary function (Modified from ImageJ/Fiji Macro Documentation)
function sfprintsf(textSummary) {

	titleSummaryWindow = "Summary Window";
	titleSummaryOutput = "["+titleSummaryWindow+"]";
	outputSummaryText = titleSummaryOutput;
	
	if (!isOpen(titleSummaryWindow)) {

		// Create the results window
		run("Text Window...", "name="+titleSummaryOutput+" width=90 height=20 menu");
		
		// Print the header and output the first line of text
		print(outputSummaryText, "% Input Image File Name\t" + "% ROI Name Selected\t" + "% Total Number of Cells Counted\t" + "% cFOS Positive Cells Counted\t" + "% cFOS FALSE Positive Cells Counted\t" + "% cFOS Intensity Threshold\t" + "% cFOS Area Cutoff\t" +  "\n");
		print(outputSummaryText, textSummary +"\n");

		// Minimize the Summary window
		eval("script","f = WindowManager.getFrame('Summary Window'); f.setLocation(0,0); f.setSize(10,10);");																															
	
	} else {

		print(outputSummaryText, textSummary +"\n");
		
	}

}

// # 4
// Store the center of mass of each detected object in a table
function GetCenterOfMass() {
	
	// Run measure 
	roiManager("deselect");
	roiManager("show none");
	roiManager("show all with labels");
	roiManager("Measure");

	// Preallocate variables
	xM = newArray(nResults);
	yM = newArray(nResults);
	mean = newArray(nResults);
	cFOS_State = newArray(nResults);

	if (nResults != 0) {

		for (row = 0; row < nResults; row++) {
		
			xM[row] = getResult("XM", row);
			yM[row] = getResult("YM", row);
			mean[row] = getResult("Mean", row);

			if (mean[row] > 60) {

				mean[row] = 1;
				cFOS_State[row] = "Positive";
				
			} else {

				mean[row] = 4;
				cFOS_State[row] = "Negative";
				
			}
	
		}

		// Create a summary table with the X and Y center of mass coordinate of each detected object
		Table.create("CentroidArray");
		Table.setLocationAndSize(0, 0, 1, 1);
		Table.setColumn("XM", xM);
		Table.setColumn("YM", yM);
		Table.setColumn("ID", mean);
		Table.setColumn("State", cFOS_State);

		// Save and close the table
		Table.save(dirOut + "CenterOfMass_" + title + "_ROI_0" + nSubregion + ".csv");

		// Close the results table and the center of mass table
		selectWindow("Results");
		run("Close");
		selectWindow("CentroidArray");
		run("Close");

	}
	
}
// # 5
// The user can specify the best threshold and the lower size of the objects to segment (area in pixel^2 or um^2)
// It works only with pre-processed option
function PreviewSetting() {

	// User can choose the best threshold and the object size
	run("Threshold...");
	setTool("oval");

	// User can enter the best threshold test it and the area in pixel^2
	thresholdType = "Default";
	pixelArea = 30;
	Dialog.createNonBlocking("User Settings...");
	Dialog.addString("Threshold type", thresholdType, 30);
	Dialog.addNumber("Process cells larger then: (Area / in pixels^2)", pixelArea)
	
	// Add Help button
	html = "<html>"
		+ "<style> html, body { width: 500; height: 250; margin: 10; padding: 0; background-color: #ECF1F4; }"
		+ "<h2> &#128295; Help: </h2>"
		+ "<h3>"
		+ "<b> <br/>User Input Setting:<br/> </b>"
		+ "<li> <i>Intensity Threshold: </i> User can test different thresholds for cell segmentation </li>"
		+ "<li> <i>Min Size (pixel^2): </i> Check the size of your cells by drawing a circle around the cell and press 'M' to measure the area </li>"        
		+ "</h3>"
		+ "</style>"
		+ "</html>";

	Dialog.addHelp(html);
  	Dialog.show();

	pixelArea = Dialog.getNumber();
	thresholdType = Dialog.getString();
	userSetting = newArray(thresholdType, pixelArea);

	// Close the results window and the threshold window
	if (isOpen("Results")) {

		// Close the results image
		selectWindow("Results");
		run("Close");
					
	}

	if (isOpen("Threshold")) {

		// Close the results image
		selectWindow("Threshold");
		run("Close");
					
	}	

	// Clear selection
	run("Select None");

	// Return the user setting
	return userSetting;

}

// # 6
// Automated threshold optimization for intensity and cell area
function AutomatedThresholdEstimation(sigma) {

	// Compute the mean intensity value for cFOS positive segemneted cells
	selectImage(titleRaw);
	run("Median...", "radius=2");
	
	// ROI Manager length
	count = roiManager("count");

	// Initialize variable
	sumIntValue = 0;
	sumArea = 0;
	meanAreaArray = newArray(count);
	meanArrayIntensity = newArray(count);
	sumPwerMeanInt = 0;
	sumPwerMeanArea = 0;

	if (count > 0) {
	
		for (jj = 0; jj < roiManager("count"); jj++) {

			// Select each ROI in the roiManger
			roiManager("select", jj);
	
			// Measure the mean intensity and area in the ROI
			List.setMeasurements(jj);
			getMeanIntValue = List.getValue("Mean");
			getMeanArea = List.getValue("Area");
			sumIntValue += getMeanIntValue;
			meanArrayIntensity[jj] = getMeanIntValue;
			sumArea += getMeanArea;
			meanAreaArray[jj] = getMeanArea;
	
			// Clear the list
			List.clear();

		}

		// Compute the std of the intensity and area
		meanInt = sumIntValue / (count+1);
		meanArea = sumArea / (count+1);
		
		for (ss = 0; ss < roiManager("count"); ss++) {

			diffMeanInt = meanArrayIntensity[ss] - meanInt;
			powerMeanInt = pow(diffMeanInt, 2);
			sumPwerMeanInt += powerMeanInt;

			diffMeanArea = meanAreaArray[ss] - meanArea;
			powerMeanArea = pow(diffMeanArea, 2);
			sumPwerMeanArea += powerMeanArea;
			
		}
		
		// Check point
		intensitySTD = sqrt(sumPwerMeanInt / count);
		areaSTD = sqrt(sumPwerMeanArea / count);

		// Mean intensity z scopre analysis (zScore = Xi - U / S)
		// Mean area on two fold the std
		positiveScore = 0;
		countPositiveInt = 0;
		sumSignScore = 0;
		countPositiveArea = 0;
		twoSTDAreaCutOff = 0;
		
		for (zz = 0; zz < roiManager("count"); zz++) {

			zScore = (meanArrayIntensity[zz] - meanInt) / intensitySTD;

			if ((zScore > (sigma*-1) && zScore < sigma) && meanAreaArray[zz] <= 2*areaSTD) {
				
				countPositiveInt += 1;
				positiveScore += meanArrayIntensity[zz];
				sumSignScore += zScore;

				if (meanAreaArray[zz] <= areaSTD) {
					
					countPositiveArea += 1;
					twoSTDAreaCutOff += meanAreaArray[zz];
					
				} 

				// In case the objs area of all cells is above the area STD use the area STD as cutoff
				if (countPositiveArea == 0) {

					countPositiveArea = 1;
					twoSTDAreaCutOff = areaSTD;
				
				}
				
			}

			/*
			if (meanAreaArray[zz] <= areaSTD) {

				countPositiveArea += 1;
				twoSTDAreaCutOff += meanAreaArray[zz];
	
			} 

			// In case the objs area of all cells is above the area STD use the area STD as cutoff
			if (countPositiveArea == 0) {

				countPositiveArea = 1;
				twoSTDAreaCutOff = areaSTD;
				
			}
			*/
		}

		// Output the cutoff for intensity and area
		intensityCutOff =  positiveScore / countPositiveInt;
		probabiltyScore = sumSignScore / countPositiveInt;
		areaCutOff = twoSTDAreaCutOff / countPositiveArea;

		/*
		// Output the z score probability for the value in the range 
		if (probabiltyScore > 0) {

			print("z-score intensity probability:", 1 - probabiltyScore);

			
		} else if (probabiltyScore < 0) {

			print("z-score intensity probability:", 1 - sqrt(pow(probabiltyScore, 2)));
			
		} else {

			print("z-score intensity probability:", 1);
			
		}
		*/
		
	}

	cutOffValues = newArray(intensityCutOff, areaCutOff);
	return cutOffValues;
	
}

// # 7 (TO OPTIMIZE)
// Count cells in 2D
function CellCount2D(cFOS, usercFOSThreshold, title, roiName, width, height, slices, titleRaw, dirOut, dirOutRoot, nSubregion, thresholdType, smallerObjSize, batch, i, optIntArray, optAreaArray, optIntSteps, sigma, reduceNaN) {

	// Select preprocessed image
	// The last active image in the macro
	// dirOutRoot is passed but not used.

	// Threshold the image in case the user chose ilastikPM
	if (userOutput[0] == true && userOutput[1] == false) {

		// Convert into binary
		setAutoThreshold(thresholdType + " dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");

		// Binary operations
		run("Fill Holes");
		run("Watershed");

		// Get the positive cells and create a new image
		run("Analyze Particles...", "size=["+smallerObjSize+"]-Infinity exclude clear add");
		newImage("clear", "8-bit black", width, height, slices);
		roiManager("Show None");
		roiManager("Show All");
		roiManager("Fill");

		// Threshold PM or starDist image
		selectedTitle = getTitle();
		selectImage(selectedTitle);

	} else if (userOutput[0] == false && userOutput[1] == true) {

		run("Duplicate...", "title=stardistRunningImage");
		selectedTitle = getTitle();
		selectImage(selectedTitle);
		
	}

	// # Condition 1
	if (cFOS == true && usercFOSThreshold == false) {

		count = roiManager("count");

		// Initialize Variables
		cFOSPositive = 0;
		cFOSFalsePoistive = 0;

		if (count > 0) {

			// Store the center of mass of each detected object in a table and save the table
			// GetCenterOfMass();
			// Compute automated mean intensity cutoff value (see batch processing and optimization steps)
			if (batch == false) {

				cutOffValues = AutomatedThresholdEstimation(sigma);
				intensityCutOff = cutOffValues[0];
				areaCutOff = cutOffValues[1];
				print("cFOS Optimization - Automated Mean Intensity CutOff:\t" + intensityCutOff + " - Sigma value equal to: " + sigma);
				print("cFOS Optimization - Automated Area CutOff:\t" + areaCutOff);

			} else if (batch == true) {

				if (i < optIntSteps) {

					cutOffValues = AutomatedThresholdEstimation(sigma);
					intensityCutOff = cutOffValues[0];
					areaCutOff = cutOffValues[1];
					//optIntArray[i] = intensityCutOff;
					//optAreaArray[i] = areaCutOff;
					print("Running Intensity CutOff Optimization!" + " Value: " + intensityCutOff + " - Sigma value equal to: " + sigma);
					print("Running Area CutOff Optimization!" + " Value: " + areaCutOff);

					// Do not include NaN for the intensity and area cutoff calculation
					if (!isNaN(intensityCutOff) || !isNaN(areaCutOff)) {
						
						optIntArray[i] =  intensityCutOff;
						optAreaArray[i] = areaCutOff;

					} else {

						reduceNaN += 1;
						print("Reducing count: " + reduceNaN);
						
					}
	
				} else {
				
					for (l = 0; l < optIntSteps; l++) {
						
						optValue += optIntArray[l];
						optArea += optAreaArray[l];
						
					}
					
					//intensityCutOff = AutomatedThresholdEstimation();
					optIntSteps = optIntSteps - reduceNaN;
					//print("Intensity CutOff Optimization Ended!" + " It will use value: " + optValue /optIntSteps);
					print("Batch cFOS Optimization - Automated Mean Intensity CutOff:\t" + optValue /optIntSteps);
					intensityCutOff = optValue /optIntSteps;

					if (i == (optIntSteps + reduceNaN)) {

						PlotOptimizationValueInt(optIntArray, intensityCutOff, optIntSteps, reduceNaN);
						plotIntTitle = getTitle();
					
					}

					// Area cutoff
					//print("Area CutOff Optimization Ended!" + " It will use value: " + optArea /optIntSteps);
					print("Batch cFOS Optimization - Automated Area CutOff:\t" + optArea /optIntSteps);
					areaCutOff = optArea /optIntSteps;
						
				}
				
			}

			for (jj = 0; jj < count; jj++) {

				// Select each ROI in the roiManger
				selectImage(titleRaw);
				roiManager("select", jj);
	
				// Measure the mean intensity in the ROI
				List.setMeasurements(jj);
				getMeanIntValue = List.getValue("Mean");
				getMeanAreaValue = List.getValue("Area");

				// Intensity selection by mean intensity value
				if (getMeanIntValue <= intensityCutOff || getMeanAreaValue <= areaCutOff) {

					// Change the ROI color according to the class (red = false positive)
					roiManager("Set Color", "red"); 
					
					// Select ROI image
					selectImage(selectedTitle);
					roiManager("select", jj);

					// Set the value for the false positive to 50
					run("Set...", "value=50");

					// Count the false positive cFos Neurons
					cFOSFalsePoistive += 1;

				} else if (getMeanIntValue > intensityCutOff || getMeanAreaValue > areaCutOff) {

					// // Change the ROI color according to the class (green = positive)
					roiManager("Set Color", "green"); 

					// Select ROI image
					selectImage(selectedTitle);
					roiManager("select", jj);

					// Set the value for the positive cell to 255 and give a unique file name tag (useful for the user later on)
					run("Set...", "value=255");
					roiManager("rename", roiName + "_" + jj)

					// Count the positive cFOS Neurons
					cFOSPositive += 1;
				}	
	
				// Clear the list
				List.clear();

			}

			// Store the center of mass of each detected object in a table and save the table and apply the LUT for display reason
			selectImage(selectedTitle);
			GetCenterOfMass();
			roiManager("Show All without labels");
			roiManager("show none");
			run("mpl-inferno");

			// Save and close the statistic image
			saveAs("Tiff", dirOut + "DisplayCellCount_" + title + "_ROI_0" + nSubregion);
			selectedTitle = getTitle();
			close(selectedTitle);

			// Save the roiManger
			roiManager("Sort");
			roiManager("Save", dirOut + title + "_ROI_0" + nSubregion + ".zip");

			// Output the statistic
			textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + count + "\t" + cFOSPositive + "\t" + cFOSFalsePoistive + "\t" + intensityCutOff + "\t" + areaCutOff;
			sfprintsf(textSummary);

		} else {

			// Output the statistic
			textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN";
			sfprintsf(textSummary);

			// Close the new image
			selectImage(selectedTitle);
			close(selectedTitle);
			
		}

	// # Condition 2
	} else if (cFOS == false && usercFOSThreshold == true) {

		// Easy to naviagte
		setTool("hand");
		
		count = roiManager("count");

		// Initialize Variables
		cFOSPositive = 0;
		cFOSFalsePoistive = 0;

		if (count > 0) {
			
			// Compute automated mean intensity cutoff value
			if (batch == false ) {

				// Create the combine raw / binary image
				// This should help the user in choosing the right intensity cutoff
				selectImage(titleRaw);	
				run("Duplicate...", "title=CombineRaw");
				titleRawComb = getTitle();
				selectImage(selectedTitle);
				run("Duplicate...", "title=CombineSelected");
				resetMinAndMax();
				run("8-bit"); // Temporary solution
				titleSelectedComb = getTitle();
				run("Combine...", "stack1=["+titleRawComb+"] stack2=["+titleSelectedComb+"]");
				titleRawSelComb = getTitle();
	
				// Add text as overlay
				// The text size could be adjusted according to the image size
				halfWidth = getWidth() /2;
				setFont("Arial" , 20);
				setColor("lightGray");
				drawString("Binary/Labeled Cell Segmentation (Not for Threshold)", halfWidth+20, 30);
				drawString("Adjust the threshold to identify the positive cells", 20, 30);
				
				// User can enter the mean intensity value for cFOS positive neurons
				// The automated threshold estimation function is computed to suggest a starting value
				selectImage(titleRaw);
				getMinAndMax(min, max); // Use to set the threshold max value
				cutOffValues = AutomatedThresholdEstimation(sigma);
				intensityCutOff = cutOffValues[0];
				areaCutOff = cutOffValues[1];

				// Display the combine image
				selectImage(titleRawSelComb);
				
				// [0] and [1]
				imageShape = ScreenLocation();
				setBatchMode("show");
				setTool("wand");
				setLocation(0, 100, imageShape[0], imageShape[1]);
				
				// Open the threshold window
				// The threshold windows can be used to choose the intensity values for cFOS positive neurons
				run("Threshold...");
				setThreshold(intensityCutOff, max); // TO DO: Check for NaN
				
				// Create an input dialog box
				Dialog.createNonBlocking("User Settings...");
				Dialog.addNumber("cFOS Mean Intensity Value (suggested):", intensityCutOff);
				Dialog.addNumber("cFOS Area Value (suggested):", areaCutOff);
		
				// Add Help button
				html = "<html>"
					+ "<style> html, body { width: 500; height: 250; margin: 10; padding: 0; background-color: #ECF1F4; }"
					+ "<h2> &#128295; Help: </h2>"
					+ "<h3>"
					+ "<b> <br /> Tips <br /> </b>" 
					+ "<li/> <i>Intensity Threshold:</i> adjust the threshold to find the best value for cFOS positive cells (left image).\n"
					+ "The right image shows the segmentation result (binary or labeled image).\n"
					+ "The suggested intensity threshold value displayed in the dialog box is computed by the automated cFOS optimization algorithm on the current open image</li>"
					+ "<li/> <i>Cell Area Cutoff: adjust the min size area cutoff for cFOS positive cells. If the raw image is calibrated the area in um^2</i></li>"
					+ "</h3>"
					+ "</style>"
					+ "</html>";
					
				Dialog.addHelp(html);
				Dialog.setLocation(screenWidth /2, 100);
	  			Dialog.show();
	
				// Return the user intensity cutoff value
				intensityCutOff = Dialog.getNumber();
				areaCutOff =  Dialog.getNumber();
	
				// Hide the raw image
				wait(1000);
				setBatchMode("hide");
	
				// Close the threshold window
				if (isOpen("Threshold")) {
	
					selectWindow("Threshold");
					run("Close");
						
				}	
	
				// Close the combine image
				selectImage(titleRawSelComb);
				close(titleRawSelComb);
	
				// Print the intensity value entered by the user
				print("cFOS Optimization - Manual Mean Intensity CutOff:\t" + intensityCutOff);
				print("cFOS Optimization - Manual Area CutOff:\t" + areaCutOff);

			} else if (batch == true) {

				if (i < optIntSteps) {

					// Create the combine raw / binary image
					// This should help the user in choosing the right intensity cutoff
					selectImage(titleRaw);	
					run("Duplicate...", "title=CombineRaw");
					titleRawComb = getTitle();
					selectImage(selectedTitle);
					run("Duplicate...", "title=CombineSelected");
					resetMinAndMax();
					run("8-bit"); // Temporary solution
					titleSelectedComb = getTitle();
					run("Combine...", "stack1=["+titleRawComb+"] stack2=["+titleSelectedComb+"]");
					titleRawSelComb = getTitle();
		
					// Add text as overlay
					halfWidth = getWidth() /2;
					setFont("Arial" , 20);
					setColor("lightGray");
					drawString("Binary/Labeled Cell Segmentation (Not for Threshold)", halfWidth+20, 30);
					drawString("Adjust the threshold to identify the positive cells", 20, 30);
					
					// User can enter the mean intensity value for cFOS positive neurons
					// The automated threshold estimation function is computed to give an estimation
					selectImage(titleRaw);
					getMinAndMax(min, max); // Use to set the threshold max value
	
					cutOffValues = AutomatedThresholdEstimation(sigma);
					intensityCutOff = cutOffValues[0];
					areaCutOff = cutOffValues[1];
	
					// Display the combine image
					selectImage(titleRawSelComb);
					
					// [0] and [1]
					imageShape = ScreenLocation();
					setBatchMode("show");
					setTool("wand");
					setLocation(0, 100, imageShape[0], imageShape[1]);
					
					// Open the threshold window
					// The threshold windows can be used to choose the intensity values for cFOS positive neurons
					run("Threshold...");
					setThreshold(intensityCutOff, max);
					
					// Create an input dialog box
					Dialog.createNonBlocking("User Settings...");
					Dialog.addNumber("cFOS Mean Intensity Value (suggested):", intensityCutOff);
					Dialog.addNumber("cFOS Area Value (suggested):", areaCutOff);
			
					// Add Help button
					html = "<html>"
						+ "<style> html, body { width: 500; height: 250; margin: 10; padding: 0; background-color: #ECF1F4; }"
						+ "<h2> &#128295; Help: </h2>"
						+ "<h3>"
						+ "<b> <br /> Tips <br /> </b>" 
						+ "<li/> <i>Intensity Threshold:</i> adjust the threshold to find the best value for cFOS positive cells (left image).\n"
						+ "The right image shows the segmentation result (binary or labeled image).\n"
						+ "The suggested intensity threshold value displayed in the dialog box is computed by the automated cFOS optimization algorithm on the batch images (average value)</li>"
						+ "<li/> <i>Cell Area Cutoff: adjust the min size area cutoff for cFOS positive cells. If the raw image is calibrated the area in um^2</i></li>"
						+ "</h3>"
						+ "</style>"
						+ "</html>";
						
					Dialog.addHelp(html);
					Dialog.setLocation(screenWidth /2, 100);
		  			Dialog.show();
	
					// Return the user intensity cutoff value
					intensityCutOff = Dialog.getNumber();
					optIntArray[i] = intensityCutOff;
					areaCutOff = Dialog.getNumber();
					optAreaArray[i] = areaCutOff;
					
					print("Cutoff Intensity Optimization Started!" + " Value: " + intensityCutOff);
					print("Cutoff Area Optimization Started!" + " Value: " + areaCutOff);

					// Hide the raw image
					wait(1000);
					setBatchMode("hide");
	
					// Close the threshold window
					if (isOpen("Threshold")) {
	
						selectWindow("Threshold");
						run("Close");
						
					}	
	
					// Close the combine image
					selectImage(titleRawSelComb);
					close(titleRawSelComb);
	
				} else {
				
					for (l = 0; l < optIntSteps; l++) {
						
						optValue += optIntArray[l];
						optArea += optAreaArray[l];
						
					}
					
					//intensityCutOff = AutomatedThresholdEstimation();
					//print("Intensity CutOff Optimization Ended!" + " It will use value: " + optValue /optIntSteps);
					print("Batch cFOS Optimization - Automated Mean Intensity CutOff:\t" + optValue /optIntSteps);
					intensityCutOff = optValue /optIntSteps;
					//print("Area CutOff Optimization Ended!" + " It will use value: " + optArea /optIntSteps);
					print("Batch cFOS Optimization - Automated Area CutOff:\t" + optArea /optIntSteps);
					areaCutOff = optArea /optIntSteps;
					
				}
	
			}
			
			// Store the center of mass of each detected object in a table and save the table
			// GetCenterOfMass();
			for (jj = 0; jj < count; jj++) {

				// Select each ROI in the roiManager
				selectImage(titleRaw);
				roiManager("select", jj);
	
				// Measure the mean intensity in the ROI
				List.setMeasurements(jj);
				getMeanIntValue = List.getValue("Mean");
				getMeanAreaValue = List.getValue("Area");

				// Intensity selection by mean intensity value
				if (getMeanIntValue <= intensityCutOff  || getMeanAreaValue <= areaCutOff) {

					// Change the ROI color according to the class (red = false positive)
					roiManager("Set Color", "red"); 
					
					// Select ROI image
					selectImage(selectedTitle);
					roiManager("select", jj);

					// Set the value for the false positive to 50
					run("Set...", "value=50");

					// Count the fasle positive cFos Neurons
					cFOSFalsePoistive += 1;

				} else if (getMeanIntValue > intensityCutOff || getMeanAreaValue > areaCutOff) {

					// // Change the ROI color according to the class (green = positive)
					roiManager("Set Color", "green"); 

					// Select ROI image
					selectImage(selectedTitle);
					roiManager("select", jj);
					
					// Set the value for the positive cell to 255 and give a unique file name tag (useful for the user later on)
					run("Set...", "value=255");
					roiManager("rename", roiName + "_" + jj)

					// Count the positive cFOS Neurons
					cFOSPositive += 1;
				}	
	
				// Clear the list
				List.clear();

			}

			// Store the center of mass of each detected object in a table and save the table amnd apply the LUT for display reason
			selectImage(selectedTitle);
			GetCenterOfMass();
			roiManager("Show All without labels");
			roiManager("show none");
			run("mpl-inferno");

			// Save and close the statistic image
			saveAs("Tiff", dirOut + "DisplayCellCount_" + title + "_ROI_0" + nSubregion);
			selectedTitle = getTitle();
			close(selectedTitle);

			// Save the roiManger
			roiManager("Sort");
			roiManager("Save", dirOut + title + "_ROI_0" + nSubregion + ".zip");

			// Output the statistic
			textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + count + "\t" + cFOSPositive + "\t" + cFOSFalsePoistive + "\t" + intensityCutOff + "\t" + areaCutOff;
			sfprintsf(textSummary);

		} else {

			// Output the statistic
			textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN";
			sfprintsf(textSummary);

			// Close the new image
			selectImage(selectedTitle);
			close(selectedTitle);
			
		}
		
	// # Condition 3
	// This can be used to count all the detected objects in an image without intensty threshold cutoff
	} else if (cFOS == false && usercFOSThreshold == false) { 

		if (batch == true) {

			// Min&Max Area Cutoff
			cutOffValues = AutomatedThresholdEstimation(sigma);		
			areaCutOff = cutOffValues[1];
			maxCutOff = areaCutOff * 3;
			minCutOff = areaCutOff / 3;

			// Initialize variable
			count = 0;

			for (jj = 0; jj < roiManager("count"); jj++) {

				// Select each ROI in the roiManager
				selectImage(titleRaw);
				roiManager("select", jj);
	
				// Measure the mean intensity in the ROI
				List.setMeasurements(jj);
				getMeanAreaValue = List.getValue("Area");

				// Intensity selection by mean intensity value
				if (getMeanAreaValue > maxCutOff || getMeanAreaValue < minCutOff) {

					// Input image
					selectImage(selectedTitle);

					// Change the ROI color according to the class (red = false positive)
					roiManager("Set Color", "red"); 
					
					// Select ROI image	
					roiManager("select", jj);

					// Set the value for the false positive to 50
					run("Set...", "value=50");

				} else if (getMeanAreaValue <= maxCutOff || getMeanAreaValue >= minCutOff) {

					// Input image
					selectImage(selectedTitle);

					// Change the ROI color according to the class (green = positive)
					roiManager("Set Color", "green"); 

					// Select ROI image
					roiManager("select", jj);

					// Set the value for the positive cell to 255 and give a unique file name tag (usefull for the user later on)
					run("Set...", "value=255");
					roiManager("rename", "Count_" + jj)

					// Count the positive cFOS Neurons
					count += 1;
				
			}	
	
				// Clear the list
				List.clear();

			}

			// Get the count
			if (count > 0) {
		
				// Select the ROI image 
				// Store the center of mass of each detected object in a table and save the table
				selectImage(selectedTitle);
				GetCenterOfMass();
				roiManager("Show All without labels");
				roiManager("show none");
				run("mpl-inferno");

				// Save and close the statistic image
				saveAs("Tiff", dirOut + "DisplayCellCount_" + title + "_ROI_0" + nSubregion);
				selectedTitle = getTitle();
				close(selectedTitle);

				// Save the roiManger
				roiManager("Save", dirOut + title + "_ROI_0" + nSubregion + ".zip");

				// Output the statistic
				textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + count + "\t" + "NAN\t" + "NAN\t" + "NAN\t" + minCutOff + " - " + maxCutOff + "\t";
				sfprintsf(textSummary);
							
			} else {

				// Output the statistic
				textSummary = "" + title + "\t" + roiName + "_ROI_0" + nSubregion + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN" + "\t" + "NaN";
				sfprintsf(textSummary);

				// Close the new image
				selectImage(selectedTitle);
				close(selectedTitle);
	
			}

		} else {

			exit("Error: Please run Quanty-cFOS with the Batch Analysis box checked");
			
		}

	// # Condition 4
	} else {

		// Close the macro if the user input an invalid setting
		exit("Invalid User Setting!");

	}

	return reduceNaN;

}

// # 8
// Use the preprocessed image or run starDist to segment the objects
// To add: Run on your own pretrained model
function RunStarDist(usePreProcessedImg, runStarDist, tails, dirInPreProcess, fileListPreProcess, i, inputTitleRaw, inputTitlePreProcess, process2D, process3D, width, height, slices, title) {

	// Run the 2D StarDist or open the ilastik PM
	if (usePreProcessedImg == true && runStarDist == false && process2D == true) {
				
		// Open the input PM image
		open(dirInPreProcess + fileListPreProcess[i]);
		inputTitlePreProcess = getTitle();
		print("Opening:\t" + inputTitlePreProcess);

		// Function: Compute the MIP in case the input image is a z-stack
        inputTitle = ComputeStack(inputTitleRaw, inputTitlePreProcess, process2D, process3D);
        titleRaw = inputTitle[0];
        titlePreProcess = inputTitle[1];
				
	} else if (usePreProcessedImg == false && runStarDist == true && process2D == true) {
				
		selectImage(inputTitleRaw);
		
		if (nSlices > 1) {

			// Compute the MIP
			run("Z Project...", "projection=[Max Intensity]");
			
			// Get MIP title
			rename("SD_" + i);
			stardistInput = getTitle();

			// Close the input raw image
			selectImage(inputTitleRaw);
			close(inputTitleRaw);

		} else {

			rename("SD_" + i);
			stardistInput = getTitle();
			
		}

		// Output both doesn't work
		// The work around is to save the ROIs in the roiManager and rebuild the label image
		// It can be add the option to import the own StarDist model
		run("Command From Macro", "command=de.csbdresden.stardist.StarDist2D args=['input':'"+ stardistInput +"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'ROI Manager', 'nTiles':'"+ tails +"', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'] process=false");
		newImage("StarDist", "16-bit black", width, height, slices);
		rename(title + "SD" + ".tif");
		titlePreProcess = getTitle();
		print("StarDist output:\t" + titlePreProcess);

		// Create the output label image from the roiManager
		for (k = 0; k < roiManager("count"); k++) {

			roiManager("select", k);
			run("Set...", "value=["+(k+1)+"]");
	
		}

		// Show the image
		roiManager("Show All");
		roiManager("Show None");
		resetMinAndMax();

		// Update the file name
		selectImage(stardistInput);
		rename(title + ".tif");
		titleRaw = getTitle();
				
	}

	processedImages = newArray(titleRaw, titlePreProcess);
	return processedImages;
	
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

// # 4
// Close Memory window
function CloseMemoryWindow() {
	
	if (isOpen("Memory")) {
		
		selectWindow("Memory");
		run("Close", "Memory");
		
	} else {
		
		print("Memory window has not been found!");
	
	}
	
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
macro QuantycFOS {

	// StartUp functions
	// 1.
	Setting();
	
	// 2.
	CloseAllWindows();

	// 3.
	CheckImageJVersion();

	// Display memory usage
	// doCommand("Monitor Memory...");

	// Get the starting time
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// Let user choose what type of inputs want to use
	userOutput = UserInput();

	// 4. Function choose the input root directory
	inputPath = InputDirectoryRawPM(userOutput);
	usePreProcessedImg = userOutput[0];
	runStarDist = userOutput[1];
	tails = userOutput[2];
	batch = userOutput[3];
	
	if (usePreProcessedImg == true && runStarDist == false) {

		// Input directory raw and preprocessed images
		dirInRaw = inputPath[0];
		dirInPreProcess = inputPath[1];

		// Get the list of file in the raw and PM input directory
		fileListRaw = getFileList(dirInRaw);
		fileListPreProcess = getFileList(dirInPreProcess);
	
	} else if (usePreProcessedImg == false && runStarDist == true) {

		// Check if StarDist plugin is installed 
		CheckStarDistInstallation();

		dirInRaw = inputPath;
		fileListRaw = getFileList(dirInRaw);
		fileListPreProcess = getFileList(dirInRaw);
		dirInPreProcess = inputPath;
		
	}

	// Batch optimization steps
	optIntSteps = userOutput[4];

	if (optIntSteps > fileListRaw.length && batch == true) {

		CloseROIsManager();
		exit("### Error ###\nThe number of <Optimization Steps> is larger then the number of input images!\nTip: Reduce the number of optimization steps!");

	} else {
		
		optIntArray = newArray(optIntSteps);
		optAreaArray = newArray(optIntSteps);

	}

	// Use the raw input path as output path
	outputPath = dirInRaw;

	// 5. Create the output root directory in the input path
	dirOutRoot = OutputDirectory(outputPath, year, month, dayOfMonth, second);

	if (!File.exists(dirOutRoot)) {	
		
		File.makeDirectory(dirOutRoot);
		text = "Output path:\t" + dirOutRoot;
		print(text);
	
	} 

	// 6.
	OpenROIsManager();

	// Do not display the images
	setBatchMode(true);

	// Initialize Variables
	reduceNaN = 0;

	// Open the file located in the input directory
	for (i=0; i<fileListRaw.length; i++) {

		// Check the input file format .tiff / .tif
		if (endsWith(fileListRaw[i], '.tiff') || endsWith(fileListRaw[i], '.tif') || endsWith(fileListPreProcess[i], '.tiff') || endsWith(fileListPreProcess[i], '.tif')) {

			// Update the user
			print("\nProcessing file:\t\t" +(i+1));

			// Open the input raw image
			open(dirInRaw + fileListRaw[i]);
			inputTitleRaw = getTitle();
			print("Opening:\t" + inputTitleRaw);

			// TO DO Remove selection if present
			run("Select None");

			// Get input image dimentions
			width = getWidth();
			height = getHeight();
			slices = nSlices();

			// Check bit depth
			CheckBitDepth();
			
            // Remove file extension .tiff / tiff
            dotIndex = lastIndexOf(inputTitleRaw, ".");
            title = substring(inputTitleRaw, 0, dotIndex);

			// User Input Setting
			// User can choose to specify the parameters each time or run the same setting on all the input images
			if (batch == false) {
				
            	outputDialog = InputDialog(title);
				roiName = outputDialog[0];
				process2D = outputDialog[1]; 
				process3D = outputDialog[2]; 
				cFOS = outputDialog[3]; 
				usercFOSThreshold = outputDialog[4];
				processSubRegions = outputDialog[5];
				previewMode = outputDialog[6]; 
				sigma = outputDialog[7];

			} else if (batch == true && i == 0) {

				outputDialog = InputDialog(title);
				roiName = outputDialog[0];
				process2D = outputDialog[1]; 
				process3D = outputDialog[2]; 
				cFOS = outputDialog[3]; 
				usercFOSThreshold = outputDialog[4];
				processSubRegions = outputDialog[5];
				previewMode = outputDialog[6];
				sigma = outputDialog[7];
				
			} else if (batch == true && i > 0) {

				roiName = outputDialog[0];
				process2D = outputDialog[1]; 
				process3D = outputDialog[2]; 
				cFOS = outputDialog[3]; 
				usercFOSThreshold = outputDialog[4];
				processSubRegions = outputDialog[5];
				previewMode = outputDialog[6];
				sigma = outputDialog[7];
				
			}

			// Use the preprocessed image or run StarDist 2D
			inputTitlePreProcess = "passString";
			processedImages = RunStarDist(usePreProcessedImg, runStarDist, tails, dirInPreProcess, fileListPreProcess, i, inputTitleRaw, inputTitlePreProcess, process2D, process3D, width, height, slices, title);
			titleRaw = processedImages[0];
			titlePreProcess = processedImages[1];

			// Function: For now, the input images as to be ONE Channel z-stack or MIP
			CheckNumberOfCh(titleRaw, titlePreProcess);

            // From here minimize the Log Window
			eval("script","f = WindowManager.getFrame('Log'); f.setLocation(0,0); f.setSize(10,10);");	

            // Check if the output directory already exists
			if (File.exists(dirOutRoot)) {
						
				// Create the image and the analysis output directory inside the output root directory
				dirOut = dirOutRoot + "0" + (i+1) + "_" + title + File.separator;
				File.makeDirectory(dirOut);
	
			}

			// User can test different threshold methods and measure cell size
			if (previewMode == true && usePreProcessedImg == true && runStarDist == false) {

				// Show the image
				setBatchMode("show");

				// Set image location 
				imageShape = ScreenLocation();
				setLocation(0, 0, imageShape[0], imageShape[1]);

				// Preview function
				userSetting = PreviewSetting();
				thresholdType = userSetting[0];
				smallerObjSize = userSetting[1];
				
				// Hide the image
				setBatchMode("hide");

				// Output the user setting
				print("User choose custom setting: Threshold type << "  + thresholdType + " >> / Min size area << " + smallerObjSize + " pixels^2 >>");
				
			} else {

				if (runStarDist == true) {

					// Output the user setting
					print("User choose StarDist 2D Model with " + tails + " tails");

					// Not used
					thresholdType = "";
					smallerObjSize = 0;

				} else {

					// Default threshold and min size area filter
					thresholdType = "Default";
					smallerObjSize = 30;

					// Output the user setting
					print("User choose default setting: Threshold type  << "  + thresholdType + " >> / Min size area << " + smallerObjSize + " pixels^2 >>");
				}
				
			}

			// Count positive cells in multiple subregions or use the full image
			if (processSubRegions == true && usePreProcessedImg == true && runStarDist == false) {

				// Set selectROI to true and preallocate subregion count
				selectROI = true;
				nSubregion = 0;
				
				// Repeat the subregion selection until user press "No"
				while (selectROI == true) {
		
					// User ROI selection
					// Deafult tool
					setTool("polygon");

					// Use for name the region of interest selected by user
					nSubregion += 1;
	
					// Select the input raw image and display it
					selectImage(titleRaw);
					setBatchMode("show");

					// [0] and [1]
					imageShape = ScreenLocation();
					setLocation(0, 0, imageShape[0], imageShape[1]);
				
					// Let the user choose if he/she wants to process a subregion or the entire image
					waitForUser("Please choose the brain region to process!");
	
					// Hide the displied image
					setBatchMode("hide");

					// Add overlay selection to help the user to identify a new region of interest at the next iteration
					// Remove selection
					type = selectionType();

					// Rectangle, Oval, Polygon and Freehand selection are supported
					if (type == 0 || type == 1 || type == 2 || type == 3) {
						
						run("Add Selection...");
						run("Select None");
						
					}
					
					// Select the preprocessed image for the quantification
					selectImage(titlePreProcess);
			
					// Highlight the ROI
					run("Duplicate...", "title=Process duplicate");
					processTitle = getTitle();
					run("Restore Selection");

					// 2D Analysis
					if (process2D == true && process3D == false) {

						// Select the image with the ROI
						selectImage(processTitle);

						// Process only the objs. inside the user roi
						run("Clear Outside");

						// 2D Cell Count
						reduceNaN = CellCount2D(cFOS, usercFOSThreshold, title, roiName, width, height, slices, titleRaw, dirOut, dirOutRoot, nSubregion, thresholdType, smallerObjSize, batch, i, optIntArray, optAreaArray, optIntSteps, sigma, reduceNaN);

						// Close the image use for the counting
						selectImage(processTitle);
						close(processTitle);

					// 3D Analysis
					} else if (process2D == false && process3D == true) {

						// Could go the 3D count 

						// Process only the objs. inside the user roi
						run("Clear Outside", "stack");

						// TO BE DONE
						exit("TO BE DONE!");
						
					} else {

						exit("Invalid Input Setting!");
					
					}

					// Clear the roiManger
					roiManager("reset");

					// Ask the user to select a new ROI
					selectROI = getBoolean("Do you want to process a different brain area?");

					// Easy to naviagte
					setTool("hand");
	
				}	

			} else if (processSubRegions == false) {

				// Preallocate subregion count
				nSubregion = 0;
				
				// Select the preprocessed image for the quantification
				selectImage(titlePreProcess);

				// 2D Analysis
				if (process2D == true && process3D == false) {

					// 2D Cell Count
					reduceNaN = CellCount2D(cFOS, usercFOSThreshold, title, roiName, width, height, slices, titleRaw, dirOut, dirOutRoot, nSubregion, thresholdType, smallerObjSize, batch, i, optIntArray, optAreaArray, optIntSteps, sigma, reduceNaN);

				// 3D Analysis
				} else if (process2D == false && process3D == true) {

					// TO BE DONE
					exit("TO BE DONE!");
						
				} else {

					exit("Invalid Input Setting: Please choose Process2D or Process3D!");
					
				}

				// Clear the roiManger
				roiManager("reset");

			} else if (processSubRegions == true && usePreProcessedImg == false && runStarDist == true) {

				// Region selection works is not possible in StarDist mode
				// This is done because is not computationally efficient
				print("Processing SubRegions using StarDist is NOT supported");
				print("Please select before the ROI and run again the Quanty_cFOS tool!");
				
			}

		// Close all the open images
		selectImage(titleRaw);
		close(titleRaw);
		selectImage(titlePreProcess);
		close(titlePreProcess);
			
		} else {

			// Update the user
			print("Skypped: Input file format not supported: " + fileListRaw[i]);

		}

	}

	// Update the user 
	text = "\nNumber of file processed:\t\t" + (fileListRaw.length + fileListPreProcess.length) /2;
	print(text);
	text = "\n%%% Congratulation your file have been successfully processed %%%";
	print(text);
	
	// End functions
	SaveStatisticWindow(dirOutRoot);
	CloseROIsManager();
	CloseLogWindow(dirOutRoot);
	// CloseMemoryWindow();
	
	// Display the images
	setBatchMode(false);
	showStatus("Completed");
	
}