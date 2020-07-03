Requirements:
NeuroPAL software
https://github.com/amin-nejat/CELL_ID


Step 1
Record multicolor and calcium data

Steps 2 and 3 can be done in parallel

Step 2a
Extract calcium traces in individual neurons
using the 3dbrain pipeline
https://github.com/leiferlab/3dbrain

Step 2b
Run create_calcium_reference.m
The progrma will create references for each .dat file in that folder and any subfolders
This generates calcium_data_average_stack.mat

Load the AML into the NeuroPAL software
Preprocessing > Artifact Removal > Manual
Draw a region around any autofluorescence in the gut and any other oddities
Auto-Detect
Auto-ID All. The IDs are random, but the software won't save cell locations without IDs
Analysis > Save ID Info (click no on pop up)

Step 3a
Run create_multicolor_adjustment_file.m on the brainscanner folder
The program will create a file for each .dat file in that folder and any subfolders
This generates multicolor_adjustment.mat

Run adjust_multicolor_image and select the multicolor_adjustment.mat file in the multicolor folder
see README_adjust_multicolor_image.md for more info
Crop the image before any other manipulations to increase speed.
Avoid using the roll worm dial unless necessary as it requires interpolation and slows the program
Standard orientation is to have the worm lying on its right side facing the left
Adjust the gamma of the green channel if necessary
Remove outliers tool will set everything outside the head to 0

Step 3b
Run neuropal software visualize_light.mlapp
Load the neuropal_input.mat into the NeuroPAL software
Gamma has already been set in adjust_multicolor_image so set this gamma correction to linear
Image > Adjust Gamma > 1
Auto-Detect
Auto-ID All
Go select each neuron and try to identify it using the manuals here:
https://www.hobertlab.org/neuropal/
Note that there are separate manuals for NeuroPAL w and w/o GCaMP (OH15500 and OH15262)
Once done:
Analysis > Save ID Info > Click yes on re-ID pop-up if you haven't recently

Step 4
Run align_multicolor_to_calcium_imaging
