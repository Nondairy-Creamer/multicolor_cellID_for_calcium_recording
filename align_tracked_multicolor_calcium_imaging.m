function align_tracked_multicolor_calcium_imaging()
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');
    
    if all(data_folder == 0)
        return;
    end
    
    %% align the neuropal_data file to the calcium image
    align_multicolor_to_calcium_imaging(data_folder, true);
    
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
    alignment.labels.multicolor_human_labels =  alignment.labels.multicolor_human_labels(multicolor_cell_is_tracked);
    alignment.labels.multicolor_auto_labels =  alignment.labels.multicolor_auto_labels(multicolor_cell_is_tracked);
    alignment.labels.user_labeled =  alignment.labels.user_labeled(multicolor_cell_is_tracked);
    alignment.labels.auto_confidence =  alignment.labels.auto_confidence(multicolor_cell_is_tracked);
    alignment.locations.multicolor_cell_locations =  alignment.locations.multicolor_cell_locations(multicolor_cell_is_tracked, :);
    alignment.assignments.calcium_to_multicolor_assignments =  alignment.assignments.calcium_to_multicolor_assignments(multicolor_cell_is_tracked);
    
    new_multicolor_ids = cumsum(multicolor_cell_is_tracked);
    new_multicolor_ids(~multicolor_cell_is_tracked) = 0;
    
    % update assignment IDs
    for nn = 1:num_tracked_cells
        if alignment.assignments.tracked_to_multicolor_assignments(nn) ~= 0
            alignment.assignments.tracked_to_multicolor_assignments(nn) = new_multicolor_ids(alignment.assignments.tracked_to_multicolor_assignments(nn));
        end
        
        if alignment.assignments.tracked_to_multicolor_assignments_user_adjusted(nn) ~= 0
            alignment.assignments.tracked_to_multicolor_assignments_user_adjusted(nn) = new_multicolor_ids(alignment.assignments.tracked_to_multicolor_assignments_user_adjusted(nn));
        end
    end
    
    for nn = 1:length(alignment.assignments.calcium_to_multicolor_assignments)
        if alignment.assignments.calcium_to_multicolor_assignments(nn) ~= 0
            alignment.assignments.calcium_to_multicolor_assignments(nn) = new_multicolor_ids(alignment.assignments.calcium_to_multicolor_assignments(nn));
        end
    end
    
    %% save the files
    % copy over the existing neuropal data images
    orig_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data.mat');
    copy_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_trimmed.mat');
    copyfile(orig_path, copy_path);
    
    alignment_save_path = fullfile(data_folder, 'calcium_to_multicolor_alignment_trimmed.mat');
    cell_id_save_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_trimmed_ID.mat');
    save(alignment_save_path, '-struct', 'alignment');
    save(cell_id_save_path, '-struct', 'multicolor_cell_locations');
end