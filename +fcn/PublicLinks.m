function [version, Sharepoint, RFDataHub] = PublicLinks(rootFolder)

    appName = class.Constants.appName;

    [projectFolder, ...
     programDataFolder] = appUtil.Path(class.Constants.appName, rootFolder);
    fileName            = 'PublicLinks.json';

    try
        fileParser = jsondecode(fileread(fullfile(programDataFolder, fileName)));
    catch
        fileParser = jsondecode(fileread(fullfile(projectFolder,     fileName)));
    end

    version    = fileParser.VersionFile;
    Sharepoint = fileParser.(appName);
    RFDataHub  = fileParser.RFDataHub;

end