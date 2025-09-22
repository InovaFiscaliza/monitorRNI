classdef (Abstract) HtmlTextGenerator

    % Essa classe abstrata organiza a criação de "textos decorados",
    % valendo-se das funcionalidades do HTML+CSS. Um texto aqui produzido
    % será renderizado em um componente uihtml, uilabel ou outro que tenha 
    % html como interpretador.

    % Antes de cada função, consta a indicação do módulo que chama a
    % função.

    properties (Constant)
        %-----------------------------------------------------------------%
    end

    
    methods (Static = true)
        %-----------------------------------------------------------------%
        % WINMONITORRNI - INFO
        %-----------------------------------------------------------------%
        function htmlContent = AppInfo(appGeneral, rootFolder, executionMode, outputFormat)
            arguments
                appGeneral 
                rootFolder 
                executionMode 
                outputFormat char {mustBeMember(outputFormat, {'popup', 'textview'})} = 'textview'
            end
        
            appName    = class.Constants.appName;
            appVersion = appGeneral.AppVersion;
            appURL     = util.publicLink(appName, rootFolder, appName);
        
            switch executionMode
                case {'MATLABEnvironment', 'desktopStandaloneApp'}
                    appMode = 'desktopApp';        
                case 'webApp'
                    computerName = ccTools.fcn.OperationSystem('computerName');
                    if strcmpi(computerName, appGeneral.computerName.webServer)
                        appMode = 'webServer';
                    else
                        appMode = 'deployServer';                    
                    end
            end

            dataStruct    = struct('group', 'COMPUTADOR',     'value', struct('Machine', rmfield(appVersion.machine, 'name'), 'Mode', sprintf('%s - %s', executionMode, appMode)));
            dataStruct(2) = struct('group', 'MATLAB',         'value', rmfield(appVersion.matlab, 'name'));
            if ~isempty(appVersion.browser)
                dataStruct(3) = struct('group', 'NAVEGADOR',  'value', rmfield(appVersion.browser, 'name'));
            end
            dataStruct(end+1) = struct('group', 'APLICATIVO', 'value', appVersion.application);

            global RFDataHub
            global RFDataHub_info
            dataStruct(end+1) = struct('group', 'RFDataHub', 'value', struct('releasedDate', RFDataHub_info.ReleaseDate, 'numberOfRows', height(RFDataHub), 'numberOfUniqueStations', numel(unique(RFDataHub.("Station")))));
        
            freeInitialText = sprintf('<font style="font-size: 12px;">O repositório das ferramentas desenvolvidas no Laboratório de inovação da SFI pode ser acessado <a href="%s" target="_blank">aqui</a>.</font>\n\n', appURL.Sharepoint);
            htmlContent     = textFormatGUI.struct2PrettyPrintList(dataStruct, 'print -1', freeInitialText, outputFormat);
        end


        %-----------------------------------------------------------------%
        % WINMONITOR - MODO "FILE"
        %-----------------------------------------------------------------%
        function htmlContent = SelectedFile(measData)
            if isscalar(measData)
                dataStruct      = struct('group', 'ARQUIVO',  'value', sprintf('"%s"', measData.Filename));
                dataStruct(2)   = struct('group', 'SENSOR',   'value', measData.MetaData);

                locationInfo = measData.Location;
                if ~strcmp(measData.Location, measData.Location_I)
                    locationInfo = sprintf('<del>%s</del> → <font style="color: red;">%s</font>', measData.Location_I, measData.Location);
                end

                dataStruct(3)   = struct('group', 'ROTA',     'value', struct('LatitudeLimits',   sprintf('[%.6f, %.6f]', measData.LatitudeLimits(:)),  ...
                                                                              'LongitudeLimits',  sprintf('[%.6f, %.6f]', measData.LongitudeLimits(:)), ...
                                                                              'Latitude',         measData.Latitude,        ...
                                                                              'Longitude',        measData.Longitude,       ...
                                                                              'Location',         locationInfo,             ...
                                                                              'CoveredDistance',  sprintf('%.1f km', measData.CoveredDistance)));

                dataStruct(4)   = struct('group', 'MEDIDAS',  'value', struct('Measures',         measData.Measures,        ...
                                                                              'ObservationTime',  measData.ObservationTime, ...
                                                                              'FieldValueLimits', sprintf('[%.1f - %.1f] V/m', measData.FieldValueLimits(:))));
                dataStruct(5)   = struct('group', 'CONTEÚDO', 'value', [measData.Content '<br><font style="color: red;">... [texto truncado]</font>']);
            
                freeInitialText = sprintf(['<p style="padding-left: 10px; padding-top: 10px; font-size: 16px;"><b>%s </b>' ...
                                               '<font style="color: gray; font-size: 11px;">%s</font>' ...
                                           '</p>'], measData.Location, sprintf('[%.1f - %.1f] V/m', measData.FieldValueLimits(:)));
            
            else
                locationList = {measData.Location};
                locations = unique(locationList);

                if isscalar(locations)
                    dataStruct(1)   = struct('group', 'ARQUIVO', 'value', textFormatGUI.cellstr2Bullets(cellfun(@(x) sprintf('"%s"', x), {measData.Filename}, 'UniformOutput', false)));

                    [minField, maxField] = bounds([measData.FieldValueLimits], 'all');
                    freeInitialText = sprintf(['<p style="padding-left: 10px; padding-top: 10px; font-size: 16px;"><b>%s </b>' ...
                                                   '<font style="color: gray; font-size: 11px;">%s</font>' ...
                                               '</p>'], measData(1).Location, sprintf('[%.1f - %.1f] V/m', minField, maxField));

                else
                    dataStruct(1)   = struct('group', 'ARQUIVO', 'value', textFormatGUI.cellstr2Bullets(cellfun(@(x) sprintf('"%s"', x), {measData.Filename}, 'UniformOutput', false)));
                    freeInitialText = '<p style="padding-left: 10px; padding-top: 10px; font-size: 16px;"><b>*.*</b></p>';
                end
            end
            htmlContent     = [freeInitialText, textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete')];
        end

        %-----------------------------------------------------------------%
        function htmlContent = MergedFiles(measData, messageType)
            arguments 
                measData
                messageType char {mustBeMember(messageType, {'MergedStatusOn', 'ScalarLocation', 'MoreThanThreeLocations', 'FinalConfirmationBeforeEdition'})}
            end

            fileInfo = {};            
            for ii = 1:numel(measData)
                locationInfo = measData(ii).Location;
                if ~strcmp(measData(ii).Location, measData(ii).Location_I)
                    locationInfo = sprintf('<del>%s</del> → <font style="color: red;">%s</font>', measData(ii).Location_I, measData(ii).Location);
                end
                
                fileInfo{end+1} = sprintf('•&thinsp;"%s": %s', measData(ii).Filename, locationInfo);
            end

            switch messageType
                case 'MergedStatusOn'
                    specificContent = 'Deseja desfazer edições?';
                case 'ScalarLocation'
                    specificContent = 'Ou seja, os arquivos já estão relacionados a uma mesma LOCALIDADE.';
                case 'MoreThanThreeLocations'
                    specificContent = 'Os arquivos estão relacionados a mais de três LOCALIDADES. Caso essa mesclagem seja intencional, ela deve ser conduzida de forma iterativa, com no máximo três LOCALIDADES por iteração.';
                case 'FinalConfirmationBeforeEdition'
                    specificContent = 'Deseja confirmar essa edição, escolhendo qual das LOCALIDADES como "localidade de agrupamento"?';
            end

            htmlContent = sprintf(['No monitorRNI, a informação constante nos arquivos é agrupada por LOCALIDADE.<br><br>' ...
                                   'A seguir informações acerca dos arquivos selecionados:<br>%s<br><br>%s'], strjoin(fileInfo, '<br>'), specificContent);
        end


        %-----------------------------------------------------------------%
        % AUXAPP.RFDATAHUB
        %-----------------------------------------------------------------%
        function htmlContent = Station(rfDataHub, idxRFDataHub, rfDataHubLOG, appGeneral)
            % stationTag
            stationInfo    = table2struct(rfDataHub(idxRFDataHub,:));
            if stationInfo.BW <= 0
                stationTag = sprintf('%.3f MHz',            stationInfo.Frequency);
            else
                stationTag = sprintf('%.3f MHz ⌂ %.1f kHz', stationInfo.Frequency, stationInfo.BW);
            end
        
            % stationService
            global id2nameTable
            if isempty(id2nameTable)
                serviceOptions = appGeneral.eFiscaliza.defaultValues.servicos_da_inspecao.options;
                serviceIDs     = int16(str2double(extractBefore(serviceOptions, '-')));
                id2nameTable   = table(serviceIDs, serviceOptions, 'VariableNames', {'ID', 'Serviço'});
            end
            stationService = fiscalizaGUI.serviceMapping(stationInfo.Service);
        
            [~, idxService] = ismember(stationInfo.Service, id2nameTable.ID);
            if idxService
                stationService = id2nameTable.("Serviço"){idxService};
            else
                stationService = num2str(stationService);
            end
        
            if strcmp(stationService, '-1')
                stationService = '<font style="color: red;">-1</font>';
            end
            
            % stationNumber
            mergeCount = str2double(string(stationInfo.MergeCount));
            if stationInfo.Station == -1
                stationNumber = sprintf('<font style="color: red;">%d</font>', stationInfo.Station);
            else
                stationNumber = num2str(stationInfo.Station);
                if mergeCount > 1
                    stationNumber = sprintf('%s*', stationNumber);
                end
            end
        
            % stationLocation, stationHeight
            stationLocation = sprintf('(%.6fº, %.6fº)', stationInfo.Latitude, stationInfo.Longitude);
            stationHeight   = str2double(char(stationInfo.AntennaHeight));
            if stationHeight <= 0
                stationHeight = '<font style="color: red;">-1</font>';
            else
                stationHeight = sprintf('%.1fm', stationHeight);
            end    
        
            % stationLOG
            stationLOG = model.RFDataHub.queryLog(rfDataHubLOG, stationInfo.Log);
            if isempty(stationLOG)
                stationLOG = 'Registro não editado';
            end
        
            % dataStruct2HTMLContent
            dataStruct(1) = struct('group', 'Service',                  'value', stationService);
            dataStruct(2) = struct('group', 'Station',                  'value', stationNumber);
            dataStruct(3) = struct('group', 'Localização',              'value', stationLocation);
            dataStruct(4) = struct('group', 'Altura',                   'value', stationHeight);

            columns2Del   = {'AntennaPattern', 'BW', 'Description', 'Distance', 'Fistel', 'Frequency',     ...
                             'ID', 'Latitude', 'LocationID', 'Location', 'Log', 'Longitude', 'MergeCount', ...
                             'Name', 'Station', 'StationClass', 'Status', 'Service', 'Source', 'State', 'URL'};
            dataStruct(5) = struct('group', 'OUTROS ASPECTOS TÉCNICOS', 'value', rmfield(stationInfo, columns2Del));        
            if mergeCount > 1
                dataStruct(end+1) = struct('group', 'NÚMERO ESTAÇÕES AGRUPADAS', 'value', string(mergeCount));
            end
        
            try
                if isstruct(stationLOG) || ischar(stationLOG)
                    dataStruct(end+1) = struct('group', 'LOG', 'value', stationLOG);
                elseif iscell(stationLOG)
                    for ii = 1:numel(stationLOG)
                        dataStruct(end+1) = struct('group', sprintf('LOG #%d', ii), 'value', stationLOG{ii});
                    end
                end
            catch
            end
        
            freeInitialText = [sprintf('<font style="font-size: 10px; color: white; background-color: red; display: inline-block; vertical-align: middle; padding: 5px; border-radius: 5px;">%s</font><span style="font-size: 10px; display: inline-block; vertical-align: sub; margin-left: 5px;">  ID %s</span><br><br>', stationInfo.Source, stationInfo.ID) ...
                               sprintf('<font style="font-size: 16px;"><b>%s</b></font><br>', stationTag)                                                                                                                                                                                                                                                     ...
                               sprintf('<font style="font-size: 11px;">%s</font><br><br>', stationInfo.Description)];
            htmlContent     = textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete', freeInitialText);
        end


        %-----------------------------------------------------------------%
        % AUXAPP.WINCONFIG
        %-----------------------------------------------------------------%
        function [htmlContent, stableVersion, updatedModule] = checkAvailableUpdate(appGeneral, rootFolder)
            stableVersion = [];
            updatedModule = {};
            
            try
                % Versão instalada no computador:
                appName          = class.Constants.appName;
                presentVersion   = struct(appName,     appGeneral.AppVersion.application.version, ...
                                          'rfDataHub', rmfield(appGeneral.AppVersion.database, 'name'));
                
                % Versão estável, indicada nos arquivos de referência (na nuvem):
                [versionFileURL, rfDataHubURL] = util.publicLink(appName, rootFolder, 'VersionFile+RFDataHub');
        
        
                generalVersions  = webread(versionFileURL,       weboptions("ContentType", "json"));
                rfdatahubVersion = webread(rfDataHubURL.Release, weboptions("ContentType", "json"));
        
                stableVersion    = struct(appName,     generalVersions.(appName).Version, ...
                                          'rfDataHub', rfdatahubVersion.rfdatahub);
                
                % Validação:
                if isequal(presentVersion, stableVersion)
                    msgWarning    = 'O monitorRNI está atualizado.';
                    updatedModule = {'monitorRNI', 'RFDataHub'};
                else
                    nonUpdatedModule = {};
                    if strcmp(presentVersion.(appName), stableVersion.(appName))
                        updatedModule(end+1)    = {'monitorRNI'};
                    else
                        nonUpdatedModule(end+1) = {'monitorRNI'};
                    end
        
                    if isequal(presentVersion.rfDataHub, stableVersion.rfDataHub)
                        updatedModule(end+1)    = {'RFDataHub'};
                    else
                        nonUpdatedModule(end+1) = {'RFDataHub'};
                    end
        
                    dataStruct    = struct('group', 'VERSÃO INSTALADA', 'value', presentVersion);
                    dataStruct(2) = struct('group', 'VERSÃO ESTÁVEL',   'value', stableVersion);
                    dataStruct(3) = struct('group', 'SITUAÇÃO',         'value', struct('updated', strjoin(updatedModule, ', '), 'nonupdated', strjoin(nonUpdatedModule, ', ')));
        
                    msgWarning    = textFormatGUI.struct2PrettyPrintList(dataStruct, "print -1", '', 'popup');
                end
                
            catch ME
                msgWarning = ME.message;
            end
        
            htmlContent = msgWarning;
        end


        %-----------------------------------------------------------------%
        % AUXAPP.DOCKSTATIONINFO
        %-----------------------------------------------------------------%
        function htmlContent = StationInfo(stationTable, idxStation, rfDataHub)
            % PM-RNI
            % (planilha de referência)
            stationTable = stationTable(idxStation, :);
            stationID    = stationTable.("Estação");
        
            stationEntity   = '';
            if ~isempty(stationTable.("Entidade"){1})
                stationEntity = [stationTable.("Entidade"){1} ' '];
            end
        
            stationAddress  = '';
            if ~isempty(stationTable.("Endereço"){1})
                stationAddress = sprintf(', Endereço="%s"', stationTable.("Endereço"){1});
            end
        
            stationCritical = '';
            if ~isempty(stationTable.("Áreas Críticas"){1})
                stationCritical = sprintf('\nÁreas críticas: %s', stationTable.("Áreas Críticas"){1});
            end    
        
            stationMonitoringPlan  = sprintf('%s, %s(Fistel=%.0f, Estação=%.0f), %s/%s @ (Latitude=%.6fº, Longitude=%.6fº%s)%s', ...
                upper(stationTable.("Serviço"){1}), stationEntity, stationTable.("Fistel")(1), stationTable.("Estação")(1), stationTable.("Município"){1}, stationTable.UF{1}, ...
                stationTable.("Lat")(1), stationTable.("Long")(1), stationAddress, stationCritical);
        
            % RFDATAHUB
            idxRFDataHub = [];            
            if stationID > 0
                idxRFDataHub = find(rfDataHub.Station == stationID);
            end
        
            if ~isempty(idxRFDataHub)
                % Frequência central e descrição:
                stationRFDataHub   = {};
                for ii = idxRFDataHub'
                    stationTag     = sprintf('%.3f MHz', rfDataHub.Frequency(ii));
                    if rfDataHub.BW(ii) > 0
                        stationTag = [stationTag sprintf(' ⌂ %.1f kHz', rfDataHub.BW(ii))];
                    end
                    stationRFDataHub{end+1} = [stationTag newline model.RFDataHub.Description(rfDataHub, ii)];
                end
                stationRFDataHub   = strjoin(unique(stationRFDataHub), '\n\n');
        
            else
                stationRFDataHub   = '(registro não encontrado na base do RFDataHub)';
            end
        
            dataStruct(1)  = struct('group', 'PM-RNI', 'value', stationMonitoringPlan);
            dataStruct(2)  = struct('group', 'RFDATAHUB',   'value', stationRFDataHub);
        
            htmlContent{1} = sprintf('<p style="padding-left: 10px; padding-top: 10px; font-size: 16px;"><b>Estação nº %.0f</b></p>', stationID);
            htmlContent{2} = textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete');
            htmlContent    = strjoin(htmlContent);
        end
    end
end