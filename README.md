# Multicolor cellID for Calcium Recording
NeuroPAL worms use 3 fluorophores and a panneuronal marker to enable cell segmentation and identification. They also allow for a calcium indicator for recording cell activity. This repo combines the information from the multicolor recording to assign cell identities to the neurons in the calcium recording. All code is in MATLAB.

## Setup
Currently, we are using my forked version of the Paninski Lab NeuroPAL software.
https://github.com/Nondairy-Creamer/CELL_ID

I have put the changes from my fork into a pull request, and if it gets accepted we can switch over to the main repo here to get future updates.
https://github.com/amin-nejat/CELL_ID

## Usage
### Step 0a
Record multicolor and calcium data
Move the multicolor imaging folder in the calcium imaging "brainscanner" folder

### Step 0b
Add NeuroPAL and dependencies to MATLAB path
Add multicolor_cellID_for_calcium_recording to MATLAB path

### Steps 1 and 2 can be done in parallel
### Step 1a
Extract calcium traces in individual neurons
using the 3dbrain pipeline
https://github.com/leiferlab/3dbrain

### Step 1b
Run `create_calcium_reference` and select the brainscanner folder
This generates calcium_data_average_stack.mat

Run `visualize_light`
In the GUI take the following actions
* Load the calcium_data_average_stack.mat into the NeuroPAL software
* Preprocessing > Artifact Removal > Manual
* Draw a region around any autofluorescence in the gut and any other oddities
* Auto-Detect
* Auto-ID All. The IDs are random, but the software won't save cell locations without IDs
* Analysis > Save ID Info (click no on pop up)

### Step 2a
Run `create_multicolor_adjustment_file` and select the multicolor folder
This generates multicolor_adjustment.mat

Run `adjust_multicolor_image` and select the multicolor_adjustment.mat file in the multicolor folder
see README_adjust_multicolor_image.md for more info
In the GUI take the following actions:
* Crop the image before any other manipulations to increase speed.
* Avoid using the roll worm dial unless necessary as it requires interpolation and slows the program
* Standard orientation is to have the worm lying on its right side facing the left
* Adjust the gamma of the green channel if necessary
* Remove outliers tool will set everything inside the region to 0

### Step 2b
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
* Neurons that were tracked by the calcium recording software are displayed on the calcium Recording
* Clicking on a neuron in the calicum image will highight the neuron it is paired to in the multicolor Recording
* Click on the neuron in the multicolor recording to assign it to the highlighted neuron in the calcium recording

## Contact
Created by [Matt Creamer](https://www.matthewcreamer.com/) - feel free to contact me!
