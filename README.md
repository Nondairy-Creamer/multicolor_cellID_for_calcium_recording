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

**sys_config_default.yaml** contains the default values for the software. If you want to change any of the values, don't edit this file. Instead **create sys_config.yaml** and any values you add will overwrite those in the default file or create new fields. If you are working on tigressdata the default files should be fine, if you are working from a different computer you can change the default paths to save yourself time looking for the panneurona/multicolor files to load.

## Usage
#### NOTES:
* Steps 1 and 2 can be performed in parallel for immobilized worms. For moving worms they should be performed sequentially.
* If you are only labeling multicolor data and not aligning it to calcium data, you only need to perform Steps 1 and 4
* If you re-run calcium extraction and want to apply your cell IDs to the new calcium traces you only need to perform Step 3 and run `update_assignment_labels`. All your cell ID information is saved and will be applied to the newly tracked cells.
* We have 2 images of the worm and 3 sets of cell point clouds that are being aligned
   * Multicolor: Cell bodies identified using the multicolor image
   * Calcium: All cell bodies segmented from the calcium recording
   * Tracked: Cells from the calcium recording that we have followed across time. These cells are a subset of all calcium cells
* If you are working on a server, you can begin work locally starting at step S2b at "Run `visualize_light`". Copy these files to your computer and continue from the visualize_light command
   * multicolor*/
   * calcium_data_average_stack.mat
   * heatData.mat
   * hiResData.mat
   * PointsStats2.mat

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

Run `adjust_multicolor_image`
* Generates **neuropal_data.mat**

In the GUI take the following actions:
* Click Load and select the **multicolor_adjustment.mat** file in the multicolor folder
* Crop the image before any other manipulations to increase speed.
* Attempt to crop so that the same neurons are visible in the multicolor worm as in the calcium reference. This will significantly improve assignment to the calcium recording
* Standard orientation is to have the worm lying on its right side facing the left
* Click subtract background button and outline a region where there is no fluorescence
* Adjust the gamma of the green channel if necessary
* Remove outliers tool will set everything inside the region to 0. use the clear outliers button if you make a mistake
* Save
* See **README_adjust_multicolor_image.md** for more info

#### S1b - Find cell body locations of the multicolor image
Run `visualize_light`
In the GUI take the following actions
* Load the **neuropal_data.mat** from the multicolor folder into the NeuroPAL software
* Auto-Detect

### Step 2 - Make a Calcium Reference Image
#### S2a - Extract calcium traces
Extract calcium traces in individual neurons
using the 3dbrain pipeline
https://github.com/leiferlab/3dbrain

#### S2b - Extract cell body locations of calcium image
Run `create_calcium_reference`
* Select the brainscanner folder or a folder containing brainscanner folders
* Generates **calcium_data_average_stack.mat**

In the GUI take the following actions:
* Click load and select the brainscanner folder
* For immobilized worms: Simply choose the number of frames to average together
* For moving worms: scroll through the frame slider on the bottom to find a frame where the posture of the worm matches the multicolor image on the right. If you don't see a multicolor image on the right make sure you completed Step 1
* Use the rotation knob and x/y flip buttons to make sure the posture aligns with the multicolor worm. Note that these knobs won't change the data, they are only for viewing convenience.
* Choose how many frames to average. More frames will reduce noise, but if the worm is moving fast it will blur the neurons making cell assignment difficult. Default of 1 frame.
* Save

Run `visualize_light`
In the GUI take the following actions
* Load the **calcium_data_average_stack.mat** into the NeuroPAL software
* Preprocessing > Artifact Removal > Manual
* Draw a region around any autofluorescence in the gut and any other oddities
* Auto-Detect

### Step 3 - Align the Multicolor Labels with the Calcium Recording
#### S3a - Perform alignment
Run `align_multicolor_to_calcium_imaging`
The first two output files contain data for all the cell bodies found in the multicolor and calcium images
* Generates **neuropal_data.mat**
* Generates **calcium_to_multicolor_alignment**

#### S3b - Validate assignments
Note: This optional but recommended (default accuracy ~85%)

Run `check_cell_assignment`
* Displays neurons that were tracked by the calcium recording segmentation software on the left
* Displays neurons segmented in the multicolor worm on the right
* Clicking on a neuron in the calcium image will highlight the neuron it is assigned to in the multicolor Recording
* Clicking on the neuron in the multicolor recording will assign it to the currently highlighted neuron in the calcium recording

#### S3c - Remove multicolor cells that were not tracked in calcium Recording
Note: This is optional but recommended. If you only care about labeling cells for calcium data using these files will save you time.

Run `create_trimmed_multicolor_file`
* Generates **neuropal_data_trimmed.mat**

### Step 4 - ID Neurons
Run `visualize_light`
#### Option 1: If you try to label all cell bodies (default)
Load **neuropal_data.mat**

#### Option 2: If you only want to label neurons tracked by the calcium segmentation
Load **neuropal_data_trimmed.mat**

#### Cell ID
In the GUI take the following actions
* Auto-ID All
Select each neuron and try to identify it using the manuals here: https://www.hobertlab.org/neuropal/
* The example data for OH15262 can be found on tigressdata at /projects/LEIFER/neuropal_example_data
* Note that there are separate manuals for NeuroPAL w and w/o GCaMP (OH15500 and OH15262)

Whenever you finish call `update_assignment_labels` to update **calcium_to_multicolor_alignment.mat**

## Documents Glossary
#### calcium_data_average_stack.mat
Generated by `create_calcium_reference`
An average of the first n frames of the calcium recording. This is used to get the cell body locations of the calcium recording to align to the multicolor recording. File is in a format that the NeuroPAL software `visualize_light` can read. **.csv** has the cell body locations found by the NeuroPAL software and **\_ID.mat** has the cell body locations that NeuroPAL reads in.

#### calcium_to_multicolor_alignment.mat
Generated by `align_multicolor_to_calcium_imaging`

Edited by `check_cell_assignment` and `update_assignment_labels`

This is the final output of this pipeline. The most important variables for the user are bolded. Contains:
* **assignments**: The link between the cell body locations in the multicolor image and the neurons tracked by the calcium extraction software
   * calcium_to_multicolor_assignments: all cell bodies in the calcium recording to all cell bodies in the multicolor recording
   * tracked_to_multicolor_assignments: automatic assignment of cells tracked in the calcium recording to the cell bodies in the multicolor recording
   * **tracked_to_multicolor_assignments_user_adjusted**: User labeled assignment of cells tracked in the calcium recording to the cell bodies in the multicolor recording. set by `check_cell_assignment`
   * user_assigned_cells: which cells the user manually assigned using `check_cell_assignment`
   * rotation/flipX/flipY: Orientation/flip set by user in `check_cell_assignment`
* **calcium_data**: This is the extracted calcium traces for the labeled cells, comes from headData.mat extracted by the 3d Brain pipeline. This is saved because it is fairly small and keeps the labels linked to data even if you run other analysis that change heatData.mat
   * **r/gRaw**: the raw fluorescence values of the red/green channel in the cell body of the neuron over time
   * **Ratio2**: Activity of each cell over time. This is some normalization of the green channel by red performed by the 3d Brain pipeline.
* **labels**: The cell ID labels (AVA, RIM, etc) for the neurons in the calcium recording
   * **tracked_human_labels**: labels of the cells tracked by the calcium extraction software. Order is the same as in the rows of the variables in heatData.mat
   * tracked_auto_labels: labels automatically generated and human labeled by the NeuroPAL software. Automatic labels tend to not be reliable, so we rely instead on the human labels
   * multicolor_human/auto_labels: same as tracked, but is labels for all cells in the multicolor image. If you are using a trimmed multicolor image (see Step 3c), these are the labels from that image.
   * user_labeled: boolean of which cells in the multicolor image were labeled
   * auto_confidence: confidence of labeling by the automatic software, not reliable at the moment
* **locations**: The cell body locations for both the multicolor image and the calcium recording.
   * multicolor/calcium_scale: scale in microns of the multicolor/calcium image
   * calcium/multicolor/tracked_cell_locations: cell locations of the calcium/multicolor data and the cell locations tracked by calcium extraction software.

#### multicolor_adjustment.mat
Generated by `create_multicolor_adjustment_file`

Edited by `adjust_multicolor_image`

Contains the multicolor data as well as the channel intensity and gamma scaling, rotation of the image, artifact removal mask, and xyz flips.

#### neuropal_data.mat
Generated by `adjust_multicolor_image`

Edited by `visualize_light` (from the NeuroPAL code)

Converts **multicolor_adjustment.mat** into a form that NeuroPAL software `visualize_light` can read and edit.

#### neuropal_data_trimmed.mat
Generated by `align_tracked_multicolor_imaging`

Edited by `visualize_light` (from the NeuroPAL code)

Same as **neuropal_data.mat** but only contains neurons tracked by the calcium segmentation software

### sys_config_default.yaml
Text file containing default variables used throughout the package. Values can be superseeded or added in the user created **sys_config.yaml**

## Contact
Created by [Matt Creamer](https://www.matthewcreamer.com/) - feel free to contact me!
