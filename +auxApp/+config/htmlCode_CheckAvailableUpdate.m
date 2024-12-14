function [htmlContent, stableVersion, updatedModule] = htmlCode_CheckAvailableUpdate(appGeneral, rootFolder)

    try
        % Versão instalada no computador:
        appName          = class.Constants.appName;
        presentVersion   = struct(appName,     appGeneral.AppVersion.(appName).version, ...
                                  'RFDataHub', appGeneral.AppVersion.RFDataHub); 
        
        % Versão estável, indicada nos arquivos de referência (na nuvem):
        [GeneralURL, ~, rfdatahubURL] = fcn.PublicLinks(rootFolder);
        generalVersions  = webread(GeneralURL,           weboptions("ContentType", "json"));
        rfdatahubVersion = webread(rfdatahubURL.Release, weboptions("ContentType", "json"));

        stableVersion    = struct(appName,     generalVersions.(appName).Version, ...
                                  'RFDataHub', rfdatahubVersion.rfdatahub);
        
        % Validação:
        updatedModule    = {};
        if isequal(presentVersion, stableVersion)
            msgWarning   = 'O appAnalise e os seus módulos - fiscaliza e RFDataHub - estão atualizados.';
            
        else            
            nonUpdatedModule = {};
            if strcmp(presentVersion.(appName), stableVersion.(appName))
                updatedModule(end+1)    = {appName};
            else
                nonUpdatedModule(end+1) = {appName};
            end

            if isequal(presentVersion.RFDataHub, stableVersion.RFDataHub)
                updatedModule(end+1)    = {'RFDataHub'};
            else
                nonUpdatedModule(end+1) = {'RFDataHub'};
            end

            dataStruct    = struct('group', 'VERSÃO INSTALADA', 'value', presentVersion);
            dataStruct(2) = struct('group', 'VERSÃO ESTÁVEL',   'value', stableVersion);
            dataStruct(3) = struct('group', 'SITUAÇÃO',         'value', struct('updated', strjoin(updatedModule, ', '), 'nonupdated', strjoin(nonUpdatedModule, ', ')));

            msgWarning = textFormatGUI.struct2PrettyPrintList(dataStruct);
        end
        
    catch ME
        msgWarning = ME.message;
    end

    htmlContent = msgWarning;
end