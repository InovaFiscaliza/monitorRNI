classdef (Abstract) Variable

    methods (Static)
        %-----------------------------------------------------------------%
        function fieldValue = GeneralSettings(reportInfo, fieldName)
            generalSettings = reportInfo.Settings;

            switch fieldName
                case 'MonitoringPlan'
                    fieldValue = jsonencode(generalSettings.(fieldName));
                case 'MonitoringPlanTHR'
                    fieldValue = sprintf('%.1f V/m', generalSettings.MonitoringPlan.FieldValue);
                case 'ExternalRequest'
                    fieldValue = jsonencode(generalSettings.(fieldName));
                case 'ExternalRequestTHR'
                    fieldValue = sprintf('%.1f V/m', generalSettings.ExternalRequest.FieldValue);
                case 'ReportTemplate'
                    fieldValue = '...';
                otherwise
                    error('UnexpectedFieldName')
            end
        end

        %-----------------------------------------------------------------%
        function fieldValue = ClassProperty(analyzedData, fieldName)
            measData  = analyzedData.InfoSet.measData;
            measTable = analyzedData.InfoSet.measTable;

            switch fieldName
                case 'Filename'
                    fieldValue = strjoin(unique(strcat('"', {measData.(fieldName)}, '"')), ', ');
                case 'NumFiles'
                    fieldValue = numel(analyzedData.InfoSet.measData);
                case {'Sensor', 'Location', 'Location_I'}
                    fieldValue = strjoin(unique({measData.(fieldName)}), ', ');
                case 'Content'
                    contentArray = arrayfun(@(x) strjoin(splitlines(x.Content(1:min(500, numel(x.Content)))), '<br>'), measData, 'UniformOutput', false);
                    fieldValue = ['<font style="text-align: justify; word-break: break-all;">', strjoin(strcat(contentArray, '<br><font style="color: red;">[Texto truncado — Fonte:&thinsp;', ' ', {measData.Filename}, ']</font>'), '<br><br>') '</font>'];
                case 'MetaData'
                    fieldValue = strjoin(unique(arrayfun(@(x) jsonencode(x.MetaData), measData, 'UniformOutput', false)), '<br>');
                case 'Measures'
                    fieldValue = sum([measData.(fieldName)]);
                case 'MeasuresRisk'
                    numMeasuresRisk = sum(measTable.FieldValue > fieldThreshold);
                    if numMeasuresRisk == 0
                        fieldValue = 'nenhuma';
                    else
                        fieldValue = num2str(numMeasuresRisk);
                    end
                case 'FieldValueLimits'
                    [minFieldValue, maxFieldValue] = bounds(measTable.FieldValue);
                    fieldValue = sprintf('%.1f - %.1f V/m', minFieldValue, maxFieldValue);
                case 'ObservationTime'
                    [beginTime, endTime] = bounds(measTable.Timestamp);
                    fieldValue = sprintf('%s a %s', string(beginTime), string(endTime));
                case 'CoveredDistance'
                    fieldValue = sprintf('%.1f km', sum([measData.(fieldName)]));
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
        function fieldValue = ProjectProperty(reportInfo, analyzedData, fieldName)
            generalSettings = reportInfo.Settings;
            projectData  = reportInfo.Project;
            stationTable = reportInfo.Function.tbl_StationTable;

            if endsWith(fieldName, 'Global')
                measData = reportInfo.Object;
            else
                measData = analyzedData.InfoSet.measData;
            end

            switch fieldName
                case 'LocationListGlobal'
                    locationList = {measData.Location};
                    locations    = unique(locationList);
                    
                    locationSubList = {};
                    for ii = 1:numel(locations)
                        idIndexes   = find(strcmp(locationList, locations{ii}));
                        [~, idSort] = sort(arrayfun(@(x) x.Data.Timestamp(1), measData(idIndexes)));
                        idIndexes   = idIndexes(idSort);
                        
                        locationSubList = union(locationSubList, getFullListOfLocation(projectData, measData(idIndexes), stationTable, max(generalSettings.MonitoringPlan.Distance_km, generalSettings.ExternalRequest.Distance_km)));
                    end

                    fieldValue = strjoin(unique(locationSubList), ', ');

                case 'LocationSummaryGlobal'
                    hash = strjoin(unique({measData.UUID}));
                    hashIndex = find(strcmp({projectData.listOfLocations.Hash}, hash), 1);
                    fieldValue = jsonencode(projectData.listOfLocations(hashIndex)); 

                case 'MeasuresGlobal'
                    fieldValue = projectData.numMeasurements;

                case 'MonitoringPlanMeasuresRiskGlobal'
                    if projectData.numAboveMonitoringPlanTHR == 0
                        fieldValue = 'NENHUMA';
                    else
                        fieldValue = num2str(projectData.numAboveMonitoringPlanTHR);
                    end

                case 'ExternalRequestsMeasuresRiskGlobal'
                    if projectData.numAboveExternalRequestTHR == 0
                        fieldValue = 'NENHUMA';
                    else
                        fieldValue = num2str(projectData.numAboveExternalRequestTHR);
                    end

                case 'LocationList'
                    fieldValue = strjoin(getFullListOfLocation(projectData, measData, stationTable, max(generalSettings.MonitoringPlan.Distance_km, generalSettings.ExternalRequest.Distance_km)), ', ');
                    
                case 'LocationSummary'
                    hash = strjoin(unique({measData.UUID}));
                    hashIndex = find(strcmp({projectData.listOfLocations.Hash}, hash), 1);
                    fieldValue = jsonencode(projectData.listOfLocations(hashIndex));

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
    end
end