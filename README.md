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
Load the AML into the NeuroPAL software and extract cell location and cell identity

Step 3a
Run convert_multicolor_to_neuropal_input.m on the multicolor folder
Run adjust_multicolor_image and select the multicolor folder
Adjust the orientation of the image
Standard orientation is to have the worm lying on its right side facing the left
Adjust the gamma of the green channel if necessary

Step 3b
Load the AML into the NeuroPAL software and extract cell location and cell identity
https://github.com/amin-nejat/CELL_ID

Step 4
Run align_multicolor_to_calcium_imaging
