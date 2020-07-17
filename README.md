# Multicolor cellID for Calcium Recording
NeuroPAL worms use 3 fluorophores and a panneuronal marker to enable cell segmentation and identification. They also allow for a calcium indicator for recording cell activity. This repo combines the information from the multicolor recording to assign cell identities to the neurons in the calcium recording. All code is in MATLAB.

## Setup
Download this repo and add it to your MATLAB path

Download my forked version of the the Paninski Lab NeuroPAL software. I suggest putting the code and its dependencies into one folder and adding that entire folder to your MATLAB path
https://github.com/Nondairy-Creamer/CELL_ID

Although we are currently using my fork, I have put the changes from my fork into a pull request. if it gets accepted we can switch over to the main repo here to get future updates.
https://github.com/amin-nejat/CELL_ID

## Usage
NOTE: Steps 1 and 2 can be performed in parallel

### Step 0
Record multicolor and calcium data
Move the multicolor imaging folder in the calcium imaging "brainscanner" folder

### Step 1
#### S1a
Extract calcium traces in individual neurons
using the 3dbrain pipeline
https://github.com/leiferlab/3dbrain

#### S1b
Run `create_calcium_reference`
* select the brainscanner folder
* generates calcium_data_average_stack.mat

Run `visualize_light`
In the GUI take the following actions
* Load the calcium_data_average_stack.mat into the NeuroPAL software
* Preprocessing > Artifact Removal > Manual
* Draw a region around any autofluorescence in the gut and any other oddities
* Auto-Detect
* Auto-ID All. The IDs are random, but the software won't save cell locations without IDs
* Analysis > Save ID Info (click no on pop up)

### Step 2
#### S2a
Run `create_multicolor_adjustment_file`
* select the multicolor folder
* generates multicolor_adjustment.mat

Run `adjust_multicolor_image`
* select the multicolor_adjustment.mat file in the multicolor folder
* generates neuropal_input.mat

In the GUI take the following actions:
* Crop the image before any other manipulations to increase speed.
* Avoid using the roll worm dial unless necessary as it requires interpolation and slows the program
* Standard orientation is to have the worm lying on its right side facing the left
* Adjust the gamma of the green channel if necessary
* Remove outliers tool will set everything inside the region to 0
* see README_adjust_multicolor_image.md for more info

#### S2b
Run `visualize_light`
In the GUI take the following actions
* Load the neuropal_input.mat from the multicolor folder into the NeuroPAL software
* Remove any artifacts not removed in Step 2a
* Auto-Detect
* Auto-ID All

Select each neuron and try to identify it using the manuals here: https://www.hobertlab.org/neuropal/
* Note that there are separate manuals for NeuroPAL w and w/o GCaMP (OH15500 and OH15262)

Once you are finished IDing:
* Analysis > Save ID Info > Click yes on re-ID pop-up if you haven't recently

### Step 3
Run `align_multicolor_to_calcium_imaging`
* NOTE: You can continue to perform **Step 2b** and **Step 3** as you identify more neurons

Optional: run `check_cell_assignment` to check the assignments between multicolor and calcium imaging.
* Displays neurons that were tracked by the calcium recording segmentation software on the left
* Displays neurons segmented in the multicolor worm on the right
* Clicking on a neuron in the calcium image will highlight the neuron it is assigned to in the multicolor Recording
* Clicking on the neuron in the multicolor recording will assign it to the currently highlighted neuron in the calcium recording

## Contact
Created by [Matt Creamer](https://www.matthewcreamer.com/) - feel free to contact me!
