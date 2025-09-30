classdef (Abstract) Variable

    methods (Static)
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
                        locations = union(locations, getFullListOfLocation(projectData, measData(idIndexes), generalSettings.MonitoringPlan.Distance_km));
                    end
                    
                    fieldValue = strjoin(unique(locations), ', ');

                case 'LocationList'
                    fieldValue = strjoin(getFullListOfLocation(projectData, measData, generalSettings.MonitoringPlan.Distance_km), ', ');

                case {'LocationSummaryGlobal', 'LocationSummary'}
                    hash = strjoin(unique({measData.UUID}));
                    hashIndex = find(strcmp({projectData.modules.(context).referenceData.locations.Hash}, hash), 1);
                    fieldValue = jsonencode(projectData.modules.(context).referenceData.locations(hashIndex)); 

                case 'NumAboveTHRGlobal'
                    if projectData.modules.(context).numAboveTHR == 0
                        fieldValue = 'NENHUMA';
                    else
                        fieldValue = num2str(projectData.modules.(context).numAboveTHR);
                    end

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