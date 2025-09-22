classdef (Abstract) Table

    % Relação de variáveis que podem ser manipuladas quando da execução de
    % um dos métodos desta classe estática. Importante, contudo, editar os
    % argumentos previstos por método em "reportLibConnection.Controller".

    % • reportInfo....: estrutura com os campos "App", "Version", "Path", 
    %   "Model", "Function" e "Project" (este último, opcional).

    % • dataOverview..: lista de estruturas com os campos "ID", "InfoSet" e
    %   "HTML". Em "InfoSet", armazena-se um handle para instância da classe 
    %   model.measData. As instância desse classe são organizadas, em dataOverview, 
    %   ordenadas à Localidade (ordenação primária) e Início de observação
    %   (secundária).

    % • analyzedData..: instância da classe model.measData.
    
    % • tableSettings.: campo extraído do script .JSON que norteia a criação
    %   do relatório, o qual é uma estrutura com os campos "Origin", "Source", 
    %   "Columns", "Caption", "Settings", "Intro", "Error" e "LineBreak".

    methods (Static)
        %-----------------------------------------------------------------%
        function Table = FileSummary(reportInfo)
            measData = reportInfo.Object;
            Table    = table('Size',          [0, 7],                                                     ...
                             'VariableTypes', {'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell'}, ...
                             'VariableNames', {'#', 'Arquivo', 'Sensor', 'Metadados', 'Região', 'Período de observação', 'Limites'});
        
            for ii = 1:numel(measData)
                Table(end+1,:) = {ii, ...
                    measData(ii).Filename, ...
                    measData(ii).Sensor, ...
                    jsonencode(measData(ii).MetaData), ...
                    jsonencode(struct('latLimits', measData(ii).LatitudeLimits, 'lngLimits', measData(ii).LongitudeLimits)), ...
                    sprintf('%s - %s', string(measData(ii).Data.Timestamp(1)), string(measData(ii).Data.Timestamp(end))), ...
                    sprintf('[%.1f - %.1f] V/m', measData(ii).FieldValueLimits(:))};
            end
        end

        %-----------------------------------------------------------------%
        function Table = FileByLocation(reportInfo)
            measData = reportInfo.Object;
            Table    = table('Size',          [0, 4],                           ...
                             'VariableTypes', {'cell', 'cell', 'cell', 'cell'}, ...
                             'VariableNames', {'Localidade', 'Arquivo', 'Período de observação', 'Limites'});

            locationList = {measData.Location};
            locations    = unique(locationList);

            for ii = 1:numel(locations)
                idIndexes   = find(strcmp(locationList, locations{ii}));
                [~, idSort] = sort(arrayfun(@(x) x.Data.Timestamp(1), measData(idIndexes)));
                idIndexes   = idIndexes(idSort);

                fileList    = strjoin({measData(idIndexes).Filename}, '<br>');
                periodList  = strjoin(arrayfun(@(x) sprintf('%s - %s', string(x.Data.Timestamp(1)), string(x.Data.Timestamp(end))), measData(idIndexes), 'UniformOutput', false), '<br>');
                limitsList  = strjoin(arrayfun(@(x) sprintf('[%.1f - %.1f] V/m', x.FieldValueLimits(:)), measData(idIndexes), 'UniformOutput', false), '<br>');

                Table(end+1,:) = {locations{ii}, fileList, periodList, limitsList};
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

            pointsTable = reportInfo.Function.table_Points;            
            measData    = analyzedData.InfoSet.measData;
            locations   = unique({measData.Location});

            logicalIndexes = cellfun(@(x) any(ismember(x, locations)), pointsTable.DataSourceLocation); 
            Table = pointsTable(logicalIndexes, :);

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

            stationTable = reportInfo.Function.table_Stations;
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