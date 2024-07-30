function [versionFileLink, SCHLinks] = PublicLinks(rootFolder)

    publicLinks     = jsondecode(fileread(fullfile(rootFolder, 'Settings', 'PublicLinks.json')));
    versionFileLink = publicLinks.VersionFile;
    SCHLinks        = publicLinks.SCH;

end