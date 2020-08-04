function config = get_config()
    % read in the variables from 
    config = ReadYaml('sys_config_default.yaml');
    
    update_path = 'sys_config.yaml';
    if exist(update_path, 'file')
        config_new = ReadYaml(update_path);
        
        new_fieldnames = fieldnames(config_new);

        for nn = 1:length(new_fieldnames)
            config.(new_fieldnames{nn}) = config_new.(new_fieldnames{nn});
        end
    end
end