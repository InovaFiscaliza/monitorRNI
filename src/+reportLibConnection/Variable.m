classdef (Abstract) Variable

    methods (Static)
        %-----------------------------------------------------------------%
        function fieldValue = ClassProperty(analyzedData, fieldName)
            EMFieldObj = analyzedData.InfoSet.measData;
            measTable  = analyzedData.InfoSet.measTable;

            switch fieldName
                case 'Filename'
                    fieldValue = strjoin(unique(strcat('"', {EMFieldObj.(fieldName)}, '"')), ', ');
                case 'NumFiles'
                    fieldValue = numel(analyzedData.InfoSet.measData);
                case {'Sensor', 'Location', 'Location_I'}
                    fieldValue = strjoin(unique({EMFieldObj.(fieldName)}), ', ');
                case 'Content'
                    contentArray = arrayfun(@(x) strjoin(splitlines(x.Content(1:min(500, numel(x.Content)))), '<br>'), EMFieldObj, 'UniformOutput', false);
                    fieldValue = ['<font style="text-align: justify; word-break: break-all;">', strjoin(strcat(contentArray, '<br><font style="color: red;">[Texto truncado — Fonte:&thinsp;', ' ', {EMFieldObj.FileName}, ']</font>'), '<br><br>') '</font>'];
                case 'MetaData'
                    fieldValue = strjoin(unique(arrayfun(@(x) jsonencode(x.MetaData), EMFieldObj, 'UniformOutput', false)), '<br>');
                case 'Measures'
                    fieldValue = sum([EMFieldObj.(fieldName)]);
                case 'FieldValueLimits'
                    [minFieldValue, maxFieldValue] = bounds(measTable.FieldValue);
                    fieldValue = sprintf('%.1f - %.1f V/m', minFieldValue, maxFieldValue);
                case 'ObservationTime'
                    [beginTime, endTime] = bounds(measTable.Timestamp);
                    fieldValue = sprintf('%s a %s', string(beginTime), string(endTime));
                case 'CoveredDistance'
                    fieldValue = sprintf('%.1f km', sum([EMFieldObj.(fieldName)]));
                case 'LatitudeLimits'
                    [minLat, maxLat] = bounds(measTable.Latitude);
                    fieldValue = sprintf('[%.6fº, %.6fº]', minLat, maxLat);
                case 'LongitudeLimits'
                    [minLng, maxLng] = bounds(measTable.Longitude);
                    fieldValue = sprintf('[%.6fº, %.6fº]', minLng, maxLng);
                case {'Latitude', 'Longitude'}
                    fieldValue = sprintf('%.6fº', mean(measTable.(fieldName)));
                otherwise
                    error('UnexpectedFieldName')
            end
        end

        %-----------------------------------------------------------------%
        function fieldValue = ProjectPropertyGlobal(dataOverview, fieldName)
            switch fieldName
                case 'MeasurementsGlobal'
                    fieldValue = sum(arrayfun(@(x) x.InfoSet.numMeasurements, dataOverview));
                
                case 'NumAboveTHRGlobal'
                    numAboveTHRGlobal = arrayfun(@(x) x.InfoSet.numAboveTHR, dataOverview, 'UniformOutput', false);
                    numAboveTHRGlobal = sum(horzcat(numAboveTHRGlobal{:}));
                    
                    if numAboveTHRGlobal == 0
                        fieldValue = 'NENHUMA';
                    else
                        fieldValue = num2str(numAboveTHRGlobal);
                    end
            end
        end

        %-----------------------------------------------------------------%
        function fieldValue = ProjectProperty(reportInfo, analyzedData, fieldName)
            generalSettings = reportInfo.Settings;
            projectData  = reportInfo.Project;
            context = analyzedData.InfoSet.context;

            if endsWith(fieldName, 'Global')
                measData = reportInfo.Object;
            else
                measData = analyzedData.InfoSet.measData;
            end

            switch fieldName
                case 'LocationListGlobal' 
                    groupLocationList = {measData.Location};
                    groupLocations    = unique(groupLocationList);
                    
                    locations = {};
                    for ii = 1:numel(groupLocations)
                        idIndexes = strcmp(groupLocationList, groupLocations{ii});                        
                        locations = union(locations, getFullListOfLocation(projectData, measData(idIndexes), generalSettings.context.MONITORINGPLAN.maxMeasurementDistanceKm));
                    end
                    
                    fieldValue = strjoin(unique(locations), ', ');

                case 'LocationList'
                    fieldValue = strjoin(getFullListOfLocation(projectData, measData, generalSettings.context.MONITORINGPLAN.maxMeasurementDistanceKm), ', ');

                case {'LocationSummaryGlobal', 'LocationSummary'}
                    hash = strjoin(unique({measData.UUID}));
                    hashIndex = find(strcmp({projectData.modules.(context).referenceData.locations.Hash}, hash), 1);
                    fieldValue = jsonencode(projectData.modules.(context).referenceData.locations(hashIndex)); 

                otherwise
                    error('UnexpectedFieldName')
            end
        end

        %-----------------------------------------------------------------%
        function tableValue = TableProperty(reportInfo, analyzedData, fieldName)
            switch fieldName
                case 'PointsTableHeight'
                    tableValue = reportLibConnection.Table.PointsByLocation(reportInfo, analyzedData, 'all', 'tableHeight');
                case 'StationTableHeight'
                    tableValue = reportLibConnection.Table.StationsByLocation(reportInfo, analyzedData, 'all', 'tableHeight');
                otherwise
                    error('UnexpectedFieldName')
            end
        end

        %-----------------------------------------------------------------%
        function fieldValue = GeneralSettings(reportInfo, fieldName, varargin)
            projectData     = reportInfo.Project;
            context         = reportInfo.Context;
            generalSettings = reportInfo.Settings;

            switch fieldName
                case 'ReportTemplate'
                     fieldValue = jsonencode(struct('Name', reportInfo.Model.Name, 'DocumentType', reportInfo.Model.DocumentType, 'Version', reportInfo.Model.Version));

                case {'Solicitação de Inspeção'; 
                      'Ação de Inspeção'; 
                      'Atividade de Inspeção';
                      'Unidade Demandante'
                      'Unidade Executante';
                      'Sede da Unidade Executante';
                      'Descrição da Atividade de Inspeção';
                      'Período Previsto da Fiscalização';
                      'Lista de Fiscais';
                      'Processo SEI'}

                    issueDetails = getOrFetchIssueDetails(projectData, projectData.modules.(context).ui.system, projectData.modules.(context).ui.issue, reportInfo.App.eFiscalizaObj);

                    if ~isempty(issueDetails)
                        switch fieldName
                            case 'Solicitação de Inspeção'
                                fieldValue = issueDetails.issueTree.solicitacao;
                            case 'Ação de Inspeção'
                                fieldValue = issueDetails.issueTree.acao;
                            case 'Atividade de Inspeção'
                                fieldValue = issueDetails.issueTree.atividade;
                            case 'Unidade Demandante'
                                issueCode  = issueDetails.issueTree.solicitacao; % 'SOL_GIDS_2024_0002'
                                fieldValue = char(regexp(issueCode, '^SOL_([^_]+)_', 'tokens', 'once'));
                            case 'Unidade Executante'
                                fieldValue = issueDetails.unit;
                            case 'Sede da Unidade Executante'
                                unit = issueDetails.unit;
                                unitIndex = find(strcmp({generalSettings.eFiscaliza.defaultValues.unitCityMapping.unit}, unit), 1);
                                if ~isempty(unitIndex)
                                    fieldValue = generalSettings.eFiscaliza.defaultValues.unitCityMapping(unitIndex).city;
                                else
                                    fieldValue = '';
                                end
                            case 'Descrição da Atividade de Inspeção'
                                fieldValue = issueDetails.description;
                            case 'Período Previsto da Fiscalização'
                                fieldValue = issueDetails.period;
                            case 'Lista de Fiscais'
                                fiscais = issueDetails.fiscais;
                                if isscalar(fiscais)
                                    fieldValue = char(fiscais);
                                else
                                    fieldValue = strjoin(strjoin(fiscais(1:end-1), ', '), fiscais(end), ' e ');
                                end
                            case 'Processo SEI'
                                fieldValue = issueDetails.sei;
                        end
                    end

                otherwise
                    error('UnexpectedFieldName')
            end
        end
    end
end