function update_assignment_labels(data_folder_in)
    config = get_config();

    if nargin < 1
        data_folder_in = uigetdir(config.data_location, 'Select the brainscanner folder');
    end
    
    if all(data_folder_in == 0)
        return;
    end

    % find all multicolor folders
    panneuronal_folders = dir(fullfile(data_folder_in, '**', 'calcium_to_multicolor_assignments.mat'));
    
    num_files = length(panneuronal_folders);
    
    if num_files > config.num_files_check
        answer = questdlg(['This will update ' num2str(num_files) ' files, would you like to continue?'], 'Number of files to create', 'yes', 'no', 'no');
        
        if strcmp(answer, 'no') || isempty(answer)
            return;
        end
    end
    
    for ff = 1:num_files
        try
            data_folder = panneuronal_folders(ff).folder;
            
            % load in the assignment and multicolor data
            assignment_path = fullfile(data_folder, 'calcium_to_multicolor_assignments.mat');
            multicolor_search = dir(fullfile(data_folder, 'multicolor*'));
            cell_id_path = fullfile(multicolor_search.folder, multicolor_search.name, 'neuropal_data_ID.mat');
            cell_ids = load(cell_id_path);
            % load in the assignment
            previous_assignment = load(assignment_path);
            
            human_labels = cat(1, cell_ids.neurons.neurons.annotation);
            auto_labels = cat(1, cell_ids.neurons.neurons.deterministic_id);
            user_labeled = cat(1, cell_ids.neurons.neurons.position);
            auto_confidence = cat(1, cell_ids.neurons.neurons.annotation_confidence)==1;
                
            % update the assignment file and save it
            output_assignment = previous_assignment;
            
            % neuropal data only includes only points that have been
            % assigned, so pair down to the the indicies of the multicolor
            % cells that have been assigned
            [~, ~, trimmed_assignments] = unique([0; previous_assignment]);
            trimmed_assignments = trimmed_assignments(2:end) - 1;
            
            % update all the cell id labels
            for nn = 1:length(trimmed_assignments)
                this_assignment = trimmed_assignments(nn);
                if this_assignment ~= 0
                    output_assignment.labels.human_labels{nn} = human_labels{this_assignment};
                    output_assignment.labels.auto_labels{nn} = auto_labels{this_assignment};
                    output_assignment.labels.user_labeled(nn) = user_labeled(this_assignment);
                    output_assignment.labels.auto_confidence{nn} = auto_confidence(this_assignment);
                    
                    output_assignment.neuropal_data.neurons.neurons(this_assignment) = cell_ids.neurons.neurons(this_assignment);
                else
                    output_assignment.labels.tracked_human_labels{nn} = '';
                    output_assignment.labels.tracked_auto_labels{nn} = '';
                    output_assignment.labels.user_labeled(nn) = false;
                    output_assignment.labels.auto_confidence{nn} = 0;
                end
            end

            save(assignment_path, '-struct', 'output_assignment');
        catch err
            disp(err);
            warning(['error in folder ' panneuronal_folders(ff).folder ' ignoring and trying next folder']);
        end
    end
end