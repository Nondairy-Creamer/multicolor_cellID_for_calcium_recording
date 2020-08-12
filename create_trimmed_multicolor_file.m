function align_tracked_multicolor_calcium_imaging()
    config = get_config();
    
    data_folder = uigetdir(config.panneuronal_path, 'Select the brainscanner folder');
    
    if all(data_folder == 0)
        return;
    end
    
    %% make neuropal_data_trimmed with only tracked cells marked
    alignment_path = fullfile(data_folder, 'calcium_to_multicolor_alignment.mat');
    alignment = load(alignment_path);
    
    multicolor_search = dir(fullfile(data_folder, 'multicolor*'));
    multicolor_search = multicolor_search(1); % take only the first result. Can't handle multiple multicolor folders in one file
    multicolor_cell_locations_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_ID.mat');
    multicolor_cell_locations = load(multicolor_cell_locations_path);
    
    num_multicolor_cells = length(multicolor_cell_locations.neurons.neurons);
    tracked_cell_assignments = alignment.assignments.tracked_to_multicolor_assignments_user_adjusted;
    num_tracked_cells = length(tracked_cell_assignments);
    multicolor_cell_is_tracked = false(num_multicolor_cells, 1);
    
    for nn = 1:num_tracked_cells
        % find out if this multicolor cell was assigned to a tracked cell
        if tracked_cell_assignments(nn) ~= 0
            multicolor_cell_is_tracked(tracked_cell_assignments(nn)) = true;
        end
    end
    
    % remove all multicolor cells that aren't tracked
    multicolor_cell_locations.neurons.neurons = multicolor_cell_locations.neurons.neurons(multicolor_cell_is_tracked);   
    
    %% save the files
    % copy over the existing neuropal data images
    orig_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data.mat');
    copy_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_trimmed.mat');
    copyfile(orig_path, copy_path);
    
    cell_id_save_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_trimmed_ID.mat');
    save(cell_id_save_path, '-struct', 'multicolor_cell_locations');
end