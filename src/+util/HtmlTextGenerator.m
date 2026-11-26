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
        function htmlContent = getAppInfo(generalSettings, rootFolder, executionMode, renderCount, projectData, eFiscalizaObj, outputFormat)
            arguments
                generalSettings 
                rootFolder 
                executionMode 
                renderCount
                projectData
                eFiscalizaObj
                outputFormat char {mustBeMember(outputFormat, {'popup', 'textview'})} = 'textview'
            end

            global RFDataHub
            global RFDataHub_info
        
            appName = class.Constants.appName;
            appVersion = generalSettings.AppVersion;
            appURL = util.publicLink(appName, rootFolder, appName);
        
            switch executionMode
                case {'MATLABEnvironment', 'desktopStandaloneApp'}
                    appMode = 'desktopApp';        
                case 'webApp'
                    computerName = appEngine.util.OperationSystem('computerName');
                    if strcmpi(computerName, generalSettings.computerName.webServer)
                        appMode = 'webServer';
                    else
                        appMode = 'deployServer';                    
                    end
            end

            displayEntry = struct('group', 'COMPUTADOR', 'value', struct('Machine', rmfield(appVersion.machine, 'name'), 'Mode', sprintf('%s - %s', executionMode, appMode)));
            displayEntry(2) = struct('group', 'MATLAB', 'value', rmfield(appVersion.matlab, 'name'));
            if ~isempty(appVersion.browser)
                displayEntry(3) = struct('group', 'NAVEGADOR', 'value', rmfield(appVersion.browser, 'name'));
            end
            displayEntry(end+1) = struct('group', 'RENDERIZAÇÕES','value', renderCount);
            displayEntry(end+1) = struct('group', 'APLICATIVO', 'value', appVersion.application);
            displayEntry(end+1) = struct('group', 'RFDataHub', 'value', struct('releasedDate', RFDataHub_info.ReleaseDate, 'numberOfRows', height(RFDataHub), 'numberOfUniqueStations', numel(unique(RFDataHub.("Station")))));

            displayEntry(end+1) = struct('group', 'PM-RNI DATABASE', 'value', struct( ...
                'selectedYears', "[ " + strjoin(string(projectData.modules.MONITORINGPLAN.referenceData.selectedYears), ', ') + " ]", ...
                'numberOfRows', height(projectData.modules.MONITORINGPLAN.stationTable) ...
            ));

            if ~isempty(eFiscalizaObj) && isvalid(eFiscalizaObj) && isprop(eFiscalizaObj, 'userAttributes') && ~isempty(eFiscalizaObj.userAttributes)
                displayEntry(end+1) = struct('group', 'USUÁRIO AUTENTICADO', 'value', eFiscalizaObj.userAttributes);
            end
        
            htmlIntro = sprintf('<font style="font-size: 12px;">O repositório das ferramentas desenvolvidas no Laboratório de inovação da SFI pode ser acessado <a href="%s" target="_blank">aqui</a>.</font>\n\n', appURL.Sharepoint);
            htmlContent = textFormatGUI.struct2PrettyPrintList(displayEntry, 'print -1', htmlIntro, outputFormat);
        end


        %-----------------------------------------------------------------%
        % WINMONITOR - MODO "FILE"
        %-----------------------------------------------------------------%
        function htmlContent = SelectedFile(measData)
            if isscalar(measData)
                dataStruct      = struct('group', 'ARQUIVO',  'value', sprintf('"%s"', measData.FileName));
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
                                                                              'CoveredDistance',  sprintf('%.1f km', measData.CoveredDistanceKm)));

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
                    dataStruct(1)   = struct('group', 'ARQUIVO', 'value', textFormatGUI.cellstr2Bullets(cellfun(@(x) sprintf('"%s"', x), {measData.FileName}, 'UniformOutput', false)));

                    [minField, maxField] = bounds([measData.FieldValueLimits], 'all');
                    freeInitialText = sprintf(['<p style="padding-left: 10px; padding-top: 10px; font-size: 16px;"><b>%s </b>' ...
                                                   '<font style="color: gray; font-size: 11px;">%s</font>' ...
                                               '</p>'], measData(1).Location, sprintf('[%.1f - %.1f] V/m', minField, maxField));

                else
                    dataStruct(1)   = struct('group', 'ARQUIVO', 'value', textFormatGUI.cellstr2Bullets(cellfun(@(x) sprintf('"%s"', x), {measData.FileName}, 'UniformOutput', false)));
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
                
                fileInfo{end+1} = sprintf('•&thinsp;"%s": %s', measData(ii).FileName, locationInfo);
            end

            switch messageType
                case 'MergedStatusOn'
                    specificContent = 'Deseja desfazer edições?';
                case 'ScalarLocation'
                    specificContent = 'Ou seja, os arquivos já estão relacionados a uma mesma LOCALIDADE.';
                case 'MoreThanThreeLocations'
                    specificContent = 'Os arquivos estão relacionados a mais de três LOCALIDADES. Caso essa mesclagem seja intencional, ela deve ser conduzida de forma iterativa, com no máximo três LOCALIDADES por iteração.';
                case 'FinalConfirmationBeforeEdition'
                    specificContent = 'Qual das LOCALIDADES deve ser escolhida como "localidade de agrupamento"?';
            end

            htmlContent = sprintf(['No monitorRNI, a informação constante nos arquivos é agrupada por LOCALIDADE.<br><br>' ...
                                   'A seguir informações acerca dos arquivos selecionados:<br>%s<br><br>%s'], strjoin(fileInfo, '<br>'), specificContent);
        end


        %-----------------------------------------------------------------%
        % AUXAPP.WINCONFIG
        %-----------------------------------------------------------------%
        function [htmlContent, stableVersion, updatedModule] = checkAvailableUpdate(generalSettings, rootFolder)
            stableVersion = [];
            updatedModule = {};
            
            try
                % Versão instalada no computador:
                appName          = class.Constants.appName;
                presentVersion   = struct(appName,     generalSettings.AppVersion.application.version, ...
                                          'rfDataHub', rmfield(generalSettings.AppVersion.database, 'name'));
                
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
        function htmlContent = StationInfo(stationTable, stationIdx, rfDataHub)
            % PM-RNI
            % (planilha de referência)
            stationTable = stationTable(stationIdx, :);
            stationId = stationTable.("Estação");
        
            stationEntity = '';
            if ~isempty(stationTable.("Entidade"){1})
                stationEntity = [stationTable.("Entidade"){1} ' '];
            end
        
            stationAddress = '';
            if ~isempty(stationTable.("Endereço"){1})
                stationAddress = sprintf(', Endereço="%s"', stationTable.("Endereço"){1});
            end
        
            stationCritical = '';
            if ~isempty(stationTable.("Áreas Críticas"){1})
                stationCritical = sprintf('\nÁreas críticas: %s', stationTable.("Áreas Críticas"){1});
            end    
        
            stationMonitoringPlan = sprintf([ ...
                '%s, %s(Fistel=%.0f, Estação=%.0f), %s/%s @ (Latitude=%.6fº, ' ...
                'Longitude=%.6fº%s)%s' ...
            ], upper(stationTable.("Serviço"){1}), stationEntity, stationTable.("Fistel")(1), stationTable.("Estação")(1), stationTable.("Município"){1}, stationTable.UF{1}, stationTable.("Lat")(1), stationTable.("Long")(1), stationAddress, stationCritical);
        
            % RFDATAHUB
            rdDataHubIdx = [];            
            if stationId > 0
                rdDataHubIdx = find(rfDataHub.Station == stationId);
            end
        
            if ~isempty(rdDataHubIdx)
                % Frequência central e descrição:
                stationRFDataHub   = {};
                for ii = rdDataHubIdx'
                    stationTag = sprintf('%.3f MHz', rfDataHub.Frequency(ii));
                    if rfDataHub.BW(ii) > 0
                        stationTag = [stationTag sprintf(' ⌂ %.1f kHz', rfDataHub.BW(ii))];
                    end
                    stationRFDataHub{end+1} = [stationTag newline model.RFDataHub.Description(rfDataHub, ii)];
                end
                stationRFDataHub = strjoin(unique(stationRFDataHub, 'stable'), '\n\n');
        
            else
                stationRFDataHub = '(registro não encontrado na base do RF.DataHub)';
            end
        
            dataStruct = [
                struct('group', 'PM-RNI',    'value', stationMonitoringPlan);
                struct('group', 'RFDATAHUB', 'value', stationRFDataHub)
            ];
        
            htmlIntro = sprintf('<font style="font-size: 14px;"><b>Estação nº %.0f</b><br></font>', stationId);
            htmlContent = textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete', htmlIntro, 'textview', 'normal+gray');
        end

        
        %-----------------------------------------------------------------%
        % AUXAPP.DOCKREPORTLIB
        %-----------------------------------------------------------------%
        function htmlContent = issueDetails(system, issue, details)
            dataStruct = [ ...
                struct('group', 'ATIVIDADE DE INSPEÇÃO',   'value', details.issueContext.atividade), ...
                struct('group', 'AÇÃO DE INSPEÇÃO',        'value', details.issueContext.acao), ...
                struct('group', 'SOLICITAÇÃO DE INSPEÇÃO', 'value', details.issueContext.solicitacao), ...
                struct('group', 'USUÁRIO',                 'value', details.usuario) ...
            ];

            freeInitialText = sprintf('<font style="font-size: 16px;"><b>Atividade de Inspeção #%d</b></font> %s<br><br>', issue, system);
            htmlContent     = textFormatGUI.struct2PrettyPrintList(dataStruct, 'print -1', freeInitialText, 'popup');
        end
    
        %-----------------------------------------------------------------%
        function htmlContent = entityDetails(id, details)
            dataStruct      = struct('group', 'CADASTRO', 'value', details);
            freeInitialText = sprintf('<font style="font-size: 16px;"><b>%s</b></font><br><br>', id);
            htmlContent     = textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete', freeInitialText, 'popup');
        end
    end


    methods (Static = true, Access = private)
        %-----------------------------------------------------------------%
        function entry = makeDisplayEntry(group, value, link)
            arguments
                group
                value
                link = ''
            end

            entry = struct('group', group, 'value', value, 'link', link);
        end


        %-----------------------------------------------------------------%
        function html = receiverBadge(label)
            html = sprintf('<font style="color: white; background-color: #b7312c; display: inline-block; vertical-align: middle; padding: 5px; border-radius: 5px;">%s</font>', label);
        end
    end
end