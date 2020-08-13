function update_assignment_labels()
    config = get_config();

    data_folder = uigetdir(config.panneuronal_path, 'Select the brainscanner folder');
    
    if all(data_folder == 0)
        return;
    end
    
    % load in the assignment and multicolor data
    assignment_path = fullfile(data_folder, 'calcium_to_multicolor_alignment.mat');
    multicolor_search = dir(fullfile(data_folder, 'multicolor*'));
    multicolor_folder = fullfile(multicolor_search(1).folder, multicolor_search(1).name); % take only the first result. Can't handle multiple multicolor folders in one file

    trimmed_neuropal_path = fullfile(multicolor_folder, 'neuropal_data_trimmed.mat');
    
    % if the trimmed file exists, use that
    if exist(trimmed_neuropal_path, 'file')
        is_trimmed = true;
        cell_id_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_trimmed_ID.mat');

    else
        is_trimmed = false;
        cell_id_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_ID.mat');
    end
    
    % load in the assignment
    previous_assignment = load(assignment_path);
    [~, human_labels, auto_labels, user_labeled, auto_confidence] = read_cell_locations(cell_id_path);
    
    % update the assignment file and save it
    output_assignment = previous_assignment;
        
    if is_trimmed
        % only assigned neurons were included in the trimmed multicolor
        % therefore the ID in the trimmed multicolor is the order ranking
        % of the original ID. Add 0 to ensure its included
        [~, ~, ranking] = unique([0; previous_assignment.assignments.tracked_to_multicolor_assignments_user_adjusted]);
        
        % subtract 1 so that 0 gets 0 rank and get rid of that first entry
        % where we added the zero
        tracked_to_multicolor_assignments = ranking(2:end) - 1;
        
        % update the untrimmed neuropal_data with any cell_ids assigned to the
        % trimmed neuropal incase it gets deleted
        untrimmed_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_ID.mat');
        trimmed_neuropal = load(cell_id_path);
        untrimmed_neuropal = load(untrimmed_path);
        for cc = 1:length(tracked_to_multicolor_assignments)
            untrimmed_id = previous_assignment.assignments.tracked_to_multicolor_assignments_user_adjusted(cc);
            trimmed_id = tracked_to_multicolor_assignments(cc);
            
            if trimmed_id ~= 0
                untrimmed_neuropal.neurons.neurons(untrimmed_id) = trimmed_neuropal.neurons.neurons(trimmed_id);
            end
        end
        
        save(untrimmed_path, '-struct', 'untrimmed_neuropal');
    else
        tracked_to_multicolor_assignments = previous_assignment.assignments.tracked_to_multicolor_assignments_user_adjusted;
    end
    
    % update all the cell id labels
    output_assignment.labels.multicolor_human_labels = human_labels;
    output_assignment.labels.multicolor_auto_labels = auto_labels;
    output_assignment.labels.user_labeled = user_labeled;
    output_assignment.labels.auto_confidence = auto_confidence;

    for nn = 1:length(tracked_to_multicolor_assignments)
        if tracked_to_multicolor_assignments(nn) ~= 0
            output_assignment.labels.tracked_human_labels{nn} = human_labels{tracked_to_multicolor_assignments(nn)};
            output_assignment.labels.tracked_auto_labels{nn} = auto_labels{tracked_to_multicolor_assignments(nn)};
        else
            output_assignment.labels.tracked_human_labels{nn} = '';
            output_assignment.labels.tracked_auto_labels{nn} = '';
        end
    end
    
    save(assignment_path, '-struct', 'output_assignment');
end