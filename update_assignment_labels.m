function update_assignment_labels()
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');
    
    if all(data_folder == 0)
        return;
    end
    
    full_assignment_path = fullfile(data_folder, 'calcium_to_multicolor_alignment.mat');
    trimmed_assignment_path = fullfile(data_folder, 'calcium_to_multicolor_alignment_trimmed.mat');
    
    %% check if either type of assignment file exists
    % then update them with the most recent multicolor data
    if exist(full_assignment_path, 'file')
        update_assignments(data_folder, false);
    end
    
    if exist(trimmed_assignment_path, 'file')
        update_assignments(data_folder, true);
    end
end

function update_assignments(data_folder, is_trimmed)
    if is_trimmed
        file_append = '_trimmed';
    else
        file_append = '';
    end
    
    % load in the assignment and multicolor data
    assignment_path = fullfile(data_folder, ['calcium_to_multicolor_alignment' file_append '.mat']);
    multicolor_search = dir(fullfile(data_folder, 'multicolor*'));
    multicolor_search = multicolor_search(1); % take only the first result. Can't handle multiple multicolor folders in one file
    cell_id_path = fullfile(multicolor_search.folder, multicolor_search.name, ['neuropal_data' file_append '_ID.mat']);
    
    previous_assignment = load(assignment_path);
    [~, human_labels, auto_labels, user_labeled, auto_confidence] = read_cell_locations(cell_id_path);
    
    % make sure the assignment data and multicolor data are from the same
    % dataset. Doesn't cover all bases, but check that they have the same
    % number of neurons
    num_labels = length(previous_assignment.labels.multicolor_human_labels);
    num_multicolor_neurons = length(human_labels);
    
    if num_labels ~= num_multicolor_neurons
        error('number of neurons in the neuropal data and number of neurons in your assignment file are not equal. Run align_multicolor_to_calcium_imaging or align_tracked_multicolor_to_calcium_imaging.');
    end
    
    % update the assignment file and save it
    output_assignment = previous_assignment;
    output_assignment.labels.multicolor_human_labels = human_labels;
    output_assignment.labels.multicolor_auto_labels = auto_labels;
    output_assignment.labels.user_labeled = user_labeled;
    output_assignment.labels.auto_confidence = auto_confidence;
    
    for nn = 1:length(output_assignment.labels.tracked_human_labels)
        if output_assignment.assignments.tracked_to_multicolor_assignments(nn) ~= 0
            output_assignment.assignments.tracked_human_labels{nn} = human_labels{output_assignment.assignments.tracked_to_multicolor_assignments(nn)};
            output_assignment.assignments.tracked_auto_labels{nn} = auto_labels{output_assignment.assignments.tracked_to_multicolor_assignments(nn)};
        else
            output_assignment.assignments.tracked_human_labels{nn} = '';
            output_assignment.assignments.tracked_auto_labels{nn} = '';
        end
    end
    
    save(assignment_path, '-struct', 'output_assignment');
end