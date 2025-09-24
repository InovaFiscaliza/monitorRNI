classdef (Abstract) Table

    methods (Static)
        %-----------------------------------------------------------------%
        function Table = FileByLocation(reportInfo)
            generalSettings = reportInfo.Settings;
            projectData  = reportInfo.Project;
            stationTable = reportInfo.Function.tbl_StationTable;
            measData = reportInfo.Object;

            Table    = table('Size',          [0, 7],                                                       ...
                             'VariableTypes', {'double', 'cell', 'cell', 'cell', 'cell', 'double', 'cell'}, ...
                             'VariableNames', {'#', 'Localidade de agrupamento', 'Localidades sob análise', 'Arquivo', 'Período de observação', 'Número de medidas', 'Limites'});

            locationList = {measData.Location};
            locations    = unique(locationList);

            for ii = 1:numel(locations)
                idIndexes   = find(strcmp(locationList, locations{ii}));
                [~, idSort] = sort(arrayfun(@(x) x.Data.Timestamp(1), measData(idIndexes)));
                idIndexes   = idIndexes(idSort);

                locationSubList = strjoin(getFullListOfLocation(projectData, measData(idIndexes), stationTable, max(generalSettings.MonitoringPlan.Distance_km, generalSettings.ExternalRequest.Distance_km)), '<br>');
                fileList    = strjoin({measData(idIndexes).Filename}, '<br>');
                numMeasures = sum(arrayfun(@(x) height(x.Data), measData(idIndexes)));
                [beginTime, endTime] = bounds([arrayfun(@(x) x.Data.Timestamp(1), measData(idIndexes)), arrayfun(@(x) x.Data.Timestamp(end), measData(idIndexes))]);
                durationTime = sum(arrayfun(@(x) x.Data.Timestamp(end) - x.Data.Timestamp(1), measData(idIndexes)));
                [minField, maxField] = bounds([measData(idIndexes).FieldValueLimits]);

                Table(end+1,:) = {...
                    ii, ...
                    locations{ii}, ...
                    locationSubList, ...
                    fileList, ...
                    sprintf('%s - %s<br>⌛%s', beginTime, endTime, durationTime), ...
                    numMeasures, ...
                    sprintf('[%.1f - %.1f] V/m', minField, maxField) ...
                };
            end
        end

        %-----------------------------------------------------------------%
        function Table = SummaryByLocation(analyzedData)
            measData = analyzedData.InfoSet.measData;
            Table    = table('Size',          [0, 7],                                                     ...
                             'VariableTypes', {'cell', 'cell', 'cell', 'cell', 'cell', 'double', 'cell'}, ...
                             'VariableNames', {'Arquivo', 'Sensor', 'Metadados', 'Região', 'Período de observação', 'Número de medidas', 'Limites'});
        
            for ii = 1:numel(measData)
                durationTime = measData(ii).Data.Timestamp(end) - measData(ii).Data.Timestamp(1);

                Table(end+1,:) = { ...
                    measData(ii).Filename, ...
                    measData(ii).Sensor, ...
                    jsonencode(measData(ii).MetaData), ...
                    jsonencode(struct('latLimits', measData(ii).LatitudeLimits, 'lngLimits', measData(ii).LongitudeLimits)), ...
                    sprintf('%s - %s<br>⌛%s', string(measData(ii).Data.Timestamp(1)), string(measData(ii).Data.Timestamp(end)), durationTime), ...
                    height(measData(ii).Data), ...
                    sprintf('[%.1f - %.1f] V/m', measData(ii).FieldValueLimits(:)) ...
                };
            end
        end

        %-----------------------------------------------------------------%
        function varargout = PointsByLocation(reportInfo, analyzedData, measuredFlag, outputType)
            arguments
                reportInfo
                analyzedData
                measuredFlag char {mustBeMember(measuredFlag, {'all', 'on', 'off'})} = 'all'
                outputType   char {mustBeMember(outputType, {'table', 'tableHeight'})} = 'table'
            end

            Table = analyzedData.InfoSet.pointsTable;

            switch measuredFlag
                case 'on'
                    Table = Table(Table.numberOfMeasures > 0, :);
                case 'off'
                    Table = Table(Table.numberOfMeasures == 0, :);
            end

            switch outputType
                case 'table'
                    varargout = {Table};
                case 'tableHeight'
                    varargout = {height(Table)};
            end
        end

        %-----------------------------------------------------------------%
        function varargout = StationsByLocation(reportInfo, analyzedData, measuredFlag, outputType)
            arguments
                reportInfo
                analyzedData
                measuredFlag char {mustBeMember(measuredFlag, {'all', 'on', 'off'})} = 'all'
                outputType   char {mustBeMember(outputType, {'table', 'tableHeight'})} = 'table'
            end

            stationTable = reportInfo.Function.tbl_StationTable;
            measData     = analyzedData.InfoSet.measData;            
            projectData  = reportInfo.Project;
            DIST_km      = reportInfo.Settings.MonitoringPlan.Distance_km;
            locations    = getFullListOfLocation(projectData, measData, stationTable, DIST_km);

            logicalIndexes = ismember(stationTable.Location, locations); 
            Table = stationTable(logicalIndexes, :);

            switch measuredFlag
                case 'on'
                    Table = Table(Table.numberOfMeasures > 0, :);
                case 'off'
                    Table = Table(Table.numberOfMeasures == 0, :);
            end

            switch outputType
                case 'table'
                    varargout = {Table};
                case 'tableHeight'
                    varargout = {height(Table)};
            end
        end
    end
end