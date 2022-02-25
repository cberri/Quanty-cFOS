# Quanty-cFOS for ImageJ/Fiji

The Quanty-cFOS.ijm is a flexible and reproducible ImageJ/Fiji tool to count cFOS labelled cells or more generally to count any cell maker in 2D fluorescent images or on Maximum Intensity Projections (MIP). For flexibility reasons this tool is implemented as macro-set (IJ1) for Image/Fiji (version 1.53c)

The Quanty-cFOS tool uses two different cell detection methods:

1.  ***StarDist 2D***: ImageJ/Fiji plugin based on the *Versatile* (Fluorescent-Nuclei) interference applied on the raw images ( https://imagej.net/StarDist). The model can be easily customized and imported in ImageJ/Fiji by training your own StarDist Neural Network. Please check the StarDist Jupyter Notebook (https://github.com/maweigert/neubias_academy_stardist)
2.  ***ilastik Pixel Classification Workflow***: The probability map can be generated using the *Pixel Classification* workflow in the *ilastik* software (open source) and loaded in addition to the raw images (https://www.ilastik.org/documentation/pixelclassification/pixelclassification)

The user can decide which method is more suitable to process the input raw images. It is recommended to start with the StarDist 2D *Versatile* model and switch to the ilastik pixel classification workflow only if the detection is not accurate enough or the structures of interest are not convex objects

The Quanty-cFOS tool is not only about cell detection but it uses the *z-score* computed on the intensity of each detected cell to optimize the count of cFOS true and false cells. Indeed, it is a two steps workflow: 

1. All imaged cells detection by *StarDist* or *ilastik*
2. cFOS cell true or false decision based on the *z-score intensity cutoff* on the raw images



## cFOS Automated Intensity Count (Experimental)

cFOS staining is known to work differently depending on many experimental factors that might include fixation, antibody type and batch, section thickness... . cFOS neurons manual count is extremely time consuming and can differ between people depending on the decision criteria. The cFOS automated intensity count can be used to significantly speed up the counting process and further reduce the human count bias

The cFOS automated count algorithm computes the mean intensity value and the mean standard deviation of each segmented cell in the image, average these two values and compute the z-score (Z)

![formula_1645614101](static/formula_1645614101.jpg)

*where:*	![xi_1645613569](static/xi_1645613569.jpg)is the single cell intensity,
			   ![mu_1645613934](static/mu_1645613934.jpg) is the mean cell intensity,
			   ![sigma_1645613989](static/sigma_1645613989.jpg) is the standard deviation.

The user can input the range of standard deviations (sigma) to decide the optimal cutoff for cFOS cell count. The cutoff optimization is critical to gain an accurate and robust cells number estimation. Indeed, we suggest to annotate manually few images and run the MATLAB correlation analysis provided with the Quanty-cFOS (`\validation\CorrelationAnalysis.mlx`) to estimate how the automated intensity cutoff correlate with human counts (see also the ValidationTable.xlsx file as example). The manual count can be performed using your favorite tool or by running the following IJ1 script: https://github.com/cberri/cFOS_ManualAnnotations_ImageJ-Fiji



## Step-by-step Quanty-cFOS Analysis with StarDist 2D

1. Clone the Quanty-cFOS repository in your favorite folder:

   `git clone https://github.com/cberri/Quanty-cFOS.git`

2. Drag and drop on the ImageJ/Fiji main window the *Quanty-cFOS.ijm* file

3. The ImageJ/Fiji *Macro Interpreter* window opens

4. Press *Run*

   **NB:** If all the required plugins are properly installed you are ready to use the Quanty-cFOS tool, otherwise you will get instructions in the Log window about what is missing and it needs to be installed. Old version of ImageJ/Fiji can output different error messages. If this is the case, please update ImageJ/Fiji to the latest version or download and install the latest release 

5. The Quanty-cFOS *Main Setting Window* pops up and the user can decide the detection settings. Please check the *Help* to get familiar with the different options. A starting setting to run Quanty-cFOS can be:

   - Uncheck *Use Pre-Processed Image* and check *Run StarDist 2D*

   - In case of large images increase the *StarDist Tails Number*

   - *Batch Analysis* and *Optimization Steps* allow to decide how many images will interactively pop up to the user and in case of *cFOS Automated Optimization* (see below), the number of images used to compute the intensity threshold cutoff for cFOS true positive and false positive cells. A recommendation for starting is to leave the box unchecked and proceed to the next step by pressing *OK*

<p align="center">
  <img width="483" height="334" src="https://github.com/cberri/Quanty-cFOS/blob/main/static/main_setting.png">
</p>
   
6. The *Input Dialog Box* pops up and the user can specify the input directory with the raw images to process. The input raw images need to have one channel as MIP or z-stacks. In case of a z-stack, the Quanty-cFOS computes the MIP and start the 2D cell segmentation. To test the Quanty-cFOS you can use the sample images provided together with the tool (`\samples`). The *User Input Setting Window* pops up. Please check the *Help* to get familiar with the different options. *Tip*: starting with the default setting can give already decent counts

<p align="center">
  <img width="623" height="187" src="static/user_input_setting.png">
</p>

7. Press *OK*, the first image will be processed and the *User Input Setting Window* pops up again, every time a new image is processed. To automate further the counting and do not display the *User Input Setting* dialog box for each image the user can rerun the Quanty-cFOS tool. In this case, the user can check in the *Main Setting Windows* the *Batch Analysis* and set the *Optimization Steps* to the number of images listed in the input raw directory (*e.g.:* 10 Images = 10 Optimization Steps)

8. The Quanty-cFOS output is a folder with sub-folders for each raw image processed. Each sub-folder has the same name of the input image and contains:

- A *csv* file with the Center of Mass of each detected cell (X, Y, ID, State)

- A labeled image that displays in yellow the cFOS true positive cells (ID 255) and in purple the cFOS false positive cells (ID 50)

- The roiManager ROIs with cFOS true positive cells highlighted (see User Input Setting *RoiManager ROIs Tag* function in the Help)

9. The summary counts are saved in the main directory in the *SummaryMeasurements.cs*v file (tab separator) and the *Log.txt* file contains the user settings used for the analysis

   

## Step-by-step Quanty-cFOS Analysis with ilastik Pixel Classification Workflow

1. Open ilastik and create an ilastik pixel classification project. Read the ilastik documentation to learn more https://www.ilastik.org/documentation/pixelclassification/pixelclassification

2. In the ilastik *Export Settings* choose as source *Probabilities*. Click on *Choose Export Image Settings..*. and follow the ilastik documentation to export the probability map of the foreground class (label). it is recommended to convert the data to the same bit depth of the raw images (typically unsigned 8 bits or unsigned 16 bits ) and check the box *Renormalize [min,max] from*. The input file format for the ilastik probability map images in Quanty-cFOS is tiff. The output file format can be specified in the *Output File Info* menu. If you choose *HDF5* (strongly recommended for large images) the images can be converted in tiff using the ilastik ImageJ/Fiji plugin (Import HDF5 and save as multipage tiff). More information can be also found here: https://www.ilastik.org/documentation/fiji_export/plugin

3. Open ImageJ/Fiji, drag and drop the Quanty-cFOS.ijm file and press *Run*

4. The Quanty-cFOS *Main Setting Window* pops up and the user can decide the detection method. The ilastik option is the default (*Use Pre-Processed Image*). We have tested ilastik pixel classification but any preprocessing or enhancing method could be suitable

5. Press *Run*

6. The *User Input Setting Window* pops up, the user can choose the raw images input directory and press *OK*. By choosing the ilastik detection method a second dialog box pop up and the user can specify the ilastik probability map input directory. It is very important that the raw and the probability map images have a similar file name and the number of files must be the same in the two input directories

7. The process continues as described for Quanty-cFOS with StarDist

   

## Quanty-cFOS: *cFOS Manual Optimization*

A crucial step in the automated cFOS count is the intensity threshold value used to decide the cutoff, in particular, if the images are very different from each other. To help users in testing different thresholds and optimize their cells count, we implemented the cFOS Manual Optimization function. By selecting this, the user can get a preview of each image during the analysis and manually choose different intensity threshold values for true positive cFOS cells. Moreover, different size filters can be applied to remove small, detected particles in the images. The number of images previewed is specified using the *Batch Analysis* option in combination with the *Optimization Steps*. Indeed, only these images are used for testing different thresholds and the average intensity value of these thresholds is applied on all the following images in the input raw directory



## Quanty-cFOS: Cell Batch Count without *cFOS Optimizations*

All cell counts is possible and can be achieved by unchecking the *cFOS Automated Optimization* and the *cFOS Manual Optimization*. In this way all the cells in the image are counted without an intensity threshold cutoff optimization. Only a size cutoff filter (based on cell area) is applied using 3 folds below and above the area standard deviation of the cells in the image. This option is supported only with *Batch Analysis* option and it doesn't use any *Optimization Steps* (process all the images in the input directory one-by-one)
