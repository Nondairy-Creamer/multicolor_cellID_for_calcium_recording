function align_multicolor_to_calcium_imaging()
    % before running this code, make sure you have extracted calcium traces
    % and cell ID locations. See README
    
    %% parameters
    % to align the multicolor to calcium, it helps to average several
    % frames of calcium data together to increase the exposure time
    time_to_average = 2; % seconds
    
    
    % multicolor to calcium alignment
    % cell bodies that have no neighbors closer than distance_threshold
    % will be removed, then the cell body locations are aligned again
    % if distance_threshold is empty, the cell body locations will only be
    % registered once without removing any neurons
    distance_threshold = 3;
    
    % after identities linking multicolor to calcium data, we remove links
    % that are too far apart from 
    max_allowed_assignment_distance = 5;
    
    % the neuroPAL_alignment can plot some figures showing assignments
    plot_alignment_figures = false;
    
    %% select multicolor folder and calcium data folder
    % multicolor
    multicolor_folder = uigetdir([], 'select the multicolor imaging folder');
    
    % calcium
    calcium_folder = uigetdir([], 'select the calcium imaging folder');
    
    %% get the average 
    average_stack = create_average_stack(calcium_folder);
    
    %% find the cell body locations
    
    %% read cell body locations
    fixed_in = readmatrix('/home/mcreamer/Documents/fake_aml/20200130/first_2_sec/neuropal_data_calcium_backSub_single.csv');
    fixed_points = fixed_in(:, 6:8);
    
    adjusted_in = readmatrix('/home/mcreamer/Documents/data_sets/neuropal/creamer/20200130/multicolorworm_20200130_145049/neuropal_data_mixed.csv');
    adjusted_points = adjusted_in(:, 6:8);
    adjusted_points(:, 3) = adjusted_points(:, 3) * 33/50;
    adjusted_points = adjusted_points(:, [2, 1, 3]);
    
    %% align multicolor and calcium imaging
    save_path = calcium_folder;
    neuroPAL_alignment(fixed_points, adjusted_points, save_path, distance_threshold, max_allowed_assignment_distance, plot_alignment_figures)
    
    %% align calcium multicolor cell bodies and our cell bodies
    
    
    %% create a spreadsheet with cell body locations and IDs


end