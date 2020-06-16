Requirements:
NeuroPAL software
https://github.com/amin-nejat/CELL_ID


Step 1
Record multicolor and calcium data

Steps 2 and 3 can be done in parallel

Step 2a
Extract calcium traces in individual neurons
use either the 3dbrain pipeline
https://github.com/leiferlab/3dbrain
or the pump-probe analysis pipeline
https://github.com/leiferlab/pump-probe-analysis

Step 2b
Run create_calcium_reference.m
This generates
calcium_data_average_stack.aml

Load the AML into the NeuroPAL software
Uncheck R, G, B and check W
Preprocessing > Artifact Removal > Manual
Draw a region and exclude autofluorescence in the gut and any other oddities
Auto-Detect
Auto-ID All. The IDs are random, but the software won't save cell locations without IDs
Analysis Save ID Info (click no on pop up)

Step 3a
Run convert_multicolor_to_neuropal_input.m on the multicolor folder
Run adjust_multicolor_image and select the AML file in the multicolor folder
Adjust the orientation of the image
Standard orientation is to have the worm lying on its right side facing the left
Adjust the gamma of the green channel if necessary
Select the head tool will set everything outside the head to 0

Step 3b
Load the AML into the NeuroPAL software
Gamma has already been set in adjust_multicolor_image so set this gamma correction to linear
Image > Adjust Gamma > 1
Auto-Detect
Auto-ID All
Go select each neuron and try to identify it using the manuals here:
https://www.hobertlab.org/neuropal/
Note that there are separate manuals for NeuroPAL w and w/o GCaMP (OH15500 and OH15262)
Once done:
Analysis > Save ID Info > Click yes on re-ID if you haven't recently

Step 4
Run align_multicolor_to_calcium_imaging
