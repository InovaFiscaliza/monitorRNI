function updateFile_GeneralSettings(appGeneral, rootFolder)
    
    if ismember(appGeneral.userPath, class.Constants.userPaths)
        appGeneral.userPath = '';
    end

    try
        fileID = fopen(fullfile(rootFolder, 'Settings', 'GeneralSettings.json'), 'wt');
        fwrite(fileID, jsonencode(appGeneral, 'PrettyPrint', true));
        fclose(fileID);
    catch
    end
    
end