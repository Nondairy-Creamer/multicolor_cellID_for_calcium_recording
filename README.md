# Multicolor cellID for Calcium Recording
NeuroPAL worms use 3 fluorophores and a panneuronal marker to enable cell segmentation and identification. They also allow for a calcium indicator for recording cell activity. This repo combines the information from the multicolor recording to assign cell identities to the neurons in the calcium recording.

## Setup
All code is in MATLAB and has been tested in 2019b and 2020a

Install the Paninski Lab NeuroPAL software. Note that it has 2 other required packages. I suggest putting Multicolor cellID for Calcium Recording, the NeuroPAL code, and the NeuroPAL code dependencies into one folder and adding that entire folder to your MATLAB path.
* My fork (preferred): https://github.com/Nondairy-Creamer/CELL_ID
* original: https://github.com/amin-nejat/CELL_ID

Download this repo and add it to your MATLAB path

Download yamlmatlab and add it to your MATLAB path
* tested version available here: https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/yamlmatlab/YAMLMatlab_0.4.3.zip
* Other versions: https://code.google.com/archive/p/yamlmatlab

**sys_config_default.yaml** contains the default values for the software. If you want to change any of the values, don't edit this file. Instead create a new text file called **sys_config.yaml** and any values you add will overwrite those in the default file or create new fields. If you are working on tigressdata the default files should be fine, if you are working from a different computer you can change the default paths to save yourself time looking for the panneuronal/multicolor files to load.

## Usage
#### NOTES:
* If you are only labeling multicolor data and not aligning it to calcium data, you only need to perform Steps 1 and 3
* If you are working on a server, you can begin work locally starting at Step 3. Copy these files to your local computer in their own folder. Note that if you want to assign more neurons (step 2) you should upload these files back to then proceed normally from step 2.
   * multicolor*/
   * calcium_to_multicolor_assignments.mat

### Step 0
Record multicolor and calcium data

Move the multicolor imaging folder in the calcium imaging brainscanner folder
* Only necessary if you are trying to label calcium data using multicolor data

### Step 1 - Initialize Multicolor Data
#### S1a - Create neuropal input from multicolor data
Run `create_multicolor_adjustment_file`
* Select the multicolor folder or a folder containing multicolor folders
* Will recursively search through the selected directory and create a multicolor adjustment file fore each
* Generates **multicolor_adjustment.mat**

#### S1b - Standardize image color and position
Run `adjust_multicolor_image`
* Generates **neuropal_data.mat**

In the GUI take the following actions:
* Click Load and select the **multicolor_adjustment.mat** file in the multicolor folder
* Crop the image before any other manipulations to increase speed.
* Standard orientation is to have the worm lying on its right side facing the left
* Click subtract background button and outline a region where there is no fluorescence
* Adjust the gamma of the green channel if necessary
* Remove outliers tool will set everything inside the region to 0. use the clear outliers button if you make a mistake
* Save
* See **README_adjust_multicolor_image.md** for more info

#### S1c - Find cell body locations of the multicolor image
Run `visualize_light`
In the GUI take the following actions
* Load the **neuropal_data.mat** from the multicolor folder into the NeuroPAL software
* Auto-Detect

### Step 2 - Assign neurons from calcium recording to the multicolor recording
Run `assign_calcium_to_multicolor`
* With the horizontal slider choose a frame that has a similar posture to the multicolor recording
* Use the rotation knob and flip x/y to get the worm to face the left with ventral cord down
* Unclick "Display Max Intensity" to allow you to scroll through z planes
* First click a neuron in the calcium image then click the corresponding neuron in the multicolor image
* You can alternate between assigning cells and multicolor identification. Each cell that is assigned will show up in the multicolor image to be identified
* Generates **calcium_to_multicolor_assignments.mat**
* Edits **neuropal_data_ID.mat** to have only assigned neurons

### Step 3 - Multicolor Cell ID
Run `visualize_light`

Load **neuropal_data.mat** from the multicolor folder

In the GUI take the following actions
* Select each neuron and try to identify it using the manuals here: https://www.hobertlab.org/neuropal/
* The example data for OH15262 can be found on tigressdata at /projects/LEIFER/neuropal_example_data
* Note that there are separate manuals for NeuroPAL w and w/o GCaMP (OH15500 and OH15262)

Run `update_assignment_labels`

You can start / stop labeling as much as you like, just make sure you call `update_assignment_labels` to update **calcium_to_multicolor_assignments.mat** which stores the labels in the same order as the calcium recording

## Documents Glossary

#### calcium_to_multicolor_assignments.mat
Generated by `assign_calcium_to_multicolor`

Edited by `update_assignment_labels`

This is the final output of this pipeline. The most important variables for the user are bolded. Contains:
* **assignments**: The link between the cell body locations in the multicolor image and the neurons tracked by the calcium extraction software
* **gui_settings**:
   * rotation/flipX/flipY: Orientation/flip set by user in `check_cell_assignment`
   * stack_ind: the last viewed frame of the video
   * jump_type: what to do when the user clicks a neuron
* **labels**: The cell ID labels (AVA, RIM, etc) for the neurons in the calcium recording
   * human_labels: labels of the cells tracked by the calcium extraction software. Order is the same as in the rows of the variables in heatData.mat
   * auto_labels: labels automatically generated and human labeled by the NeuroPAL software. Automatic labels tend to not be reliable, so we rely instead on the human labels
   * auto_confidence: The confidence of the automatic labeling from the NeuroPAL software
   * user_labeled: boolean of which cells in the multicolor image were labeled
* **locations**: The cell body locations for both the multicolor image and the calcium recording.
   * multicolor/calcium_scale: scale in microns of the multicolor/calcium image
   * calcium/multicolor/tracked_cell_locations: cell locations of the calcium/multicolor data and the cell locations tracked by calcium extraction software.
* **calcium_locations_in_multicolor**: Location of the calcium cells in the multicolor image
* **multicolor_cell_locations**: Location of all multicolor cells
* **neuropal_data**: The neuropal data, used to generate neuropal files as the user assigns / unassigns cells

#### multicolor_adjustment.mat
Generated by `create_multicolor_adjustment_file`

Edited by `adjust_multicolor_image`

Contains the multicolor data as well as the channel intensity and gamma scaling, rotation of the image, artifact removal mask, and xyz flips.

#### neuropal_data.mat
Generated by `adjust_multicolor_image`

Edited by `visualize_light` (from the NeuroPAL code)

Converts **multicolor_adjustment.mat** into a form that NeuroPAL software `visualize_light` can read and edit.

### sys_config_default.yaml
Text file containing default variables used throughout the package. Values can be superseeded or added in the user created **sys_config.yaml**

## Contact
Created by [Matt Creamer](https://www.matthewcreamer.com/) - feel free to contact me!

