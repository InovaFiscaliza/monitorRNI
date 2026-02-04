classdef (Abstract) Table

    methods (Static)
        %-----------------------------------------------------------------%
        function Table = FileByLocation(dataOverview)
            Table = table('Size',          [0, 8],                                                                 ...
                          'VariableTypes', {'double', 'cell', 'cell', 'cell', 'cell', 'double', 'double', 'cell'}, ...
                          'VariableNames', {'#', 'Localidade de agrupamento', 'Localidades sob análise', 'Arquivo', 'Período de observação', 'Qtd. medidas', 'Qtd. medidas superior limar', 'Limites'});

            groupLocationList = {dataOverview.ID};

            for ii = 1:numel(groupLocationList)
                groupLocation = groupLocationList{ii};
                groupIndex    = find(strcmp(groupLocationList, groupLocation), 1);

                Table(end+1,:) = {...
                    ii, ...
                    groupLocation, ...
                    strjoin(dataOverview(groupIndex).InfoSet.locations,           '<br>'), ...
                    strjoin({dataOverview(groupIndex).InfoSet.measData.FileName}, '<br>'), ...
                    dataOverview(groupIndex).InfoSet.period, ...
                    dataOverview(groupIndex).InfoSet.numMeasurements, ...
                    sum(dataOverview(groupIndex).InfoSet.numAboveTHR), ...
                    dataOverview(groupIndex).InfoSet.limits ...
                };
            end
        end

        %-----------------------------------------------------------------%
        function Table = SummaryByLocation(analyzedData)
            measData = analyzedData.InfoSet.measData;
            measIdx  = analyzedData.Index;
            Table    = table('Size',          [0, 9],                                                                       ...
                             'VariableTypes', {'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'double', 'double', 'cell'}, ...
                             'VariableNames', {'#', 'Arquivo', 'Sensor', 'Metadados', 'Região', 'Período de observação', 'Qtd. medidas', 'Qtd. medidas superior limar', 'Limites'});
        
            for ii = 1:numel(measData)
                durationTime = measData(ii).Data.Timestamp(end) - measData(ii).Data.Timestamp(1);

                Table(end+1,:) = { ...
                    sprintf('%d.%d', measIdx, ii), ...
                    measData(ii).FileName, ...
                    measData(ii).Sensor, ...
                    jsonencode(measData(ii).MetaData), ...
                    jsonencode(struct('latLimits', measData(ii).LatitudeLimits, 'lngLimits', measData(ii).LongitudeLimits)), ...
                    sprintf('%s<br>⌛%s', measData(ii).ObservationTime, durationTime), ...
                    measData(ii).Measures, ...
                    analyzedData.InfoSet.numAboveTHR(ii), ...
                    sprintf('[%.1f - %.1f] V/m', measData(ii).FieldValueLimits(:)) ...
                };
            end
        end

        %-----------------------------------------------------------------%
        function varargout = PointsByLocation(analyzedData, measuredFlag, outputType)
            arguments
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
        function varargout = StationsByLocation(analyzedData, measuredFlag, outputType)
            arguments
                analyzedData
                measuredFlag char {mustBeMember(measuredFlag, {'all', 'on', 'off'})} = 'all'
                outputType   char {mustBeMember(outputType, {'table', 'tableHeight'})} = 'table'
            end

            stationTable = analyzedData.InfoSet.stationTable;

            % Insere coordenadas geográficas da estação no campo "Observações", 
            % caso editadas, e troca valores inválidos ("-1", por exemplo) por 
            % valores nulos.
            Table = model.ProjectBase.prepareTableForExport(stationTable, 'STATIONS', '-');

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