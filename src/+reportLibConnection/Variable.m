classdef (Abstract) Variable

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
        function fieldValue = GeneralSettings(reportInfo, fieldName)
            appGeneral = reportInfo.Settings;

            switch fieldName
                case 'MonitoringPlan'
                    fieldValue = jsonencode(appGeneral.(fieldName));
                case 'ExternalRequest'
                    fieldValue = jsonencode(appGeneral.(fieldName));
            end
        end

        %-----------------------------------------------------------------%
        function fieldValue = ClassProperty(analyzedData, fieldName)
            measData  = analyzedData.InfoSet.measData;
            measTable = analyzedData.InfoSet.measTable;

            switch fieldName
                case {'Filename', 'Sensor', 'Location'}
                    fieldValue = strjoin(unique({measData.(fieldName)}), ', ');
                case 'Content'
                    fieldValue = strjoin(strcat({measData.Content}, '<br><font style="color: red;">[Texto truncado — Fonte:&thinsp;', ' ', {measData.Filename}, ']</font>'), '<br><br>');
                case 'MetaData'
                    fieldValue = strjoin(unique(arrayfun(@(x) jsonencode(x.MetaData), measData, 'UniformOutput', false)), '<br>');
                case 'Measures'
                    fieldValue = num2str(sum([measData.(fieldName)]));
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
            end
        end

        %-----------------------------------------------------------------%
        function tableValue = TableProperty(reportInfo, analyzedData, fieldName)
            switch fieldName
                case 'PointsTableHeight'
                    tableValue = reportLibConnection.PointsByLocation(reportInfo, analyzedData, 'all', 'tableHeight');
                case 'StationsTableHeight'
                    tableValue = reportLibConnection.StationsByLocation(reportInfo, analyzedData, 'all', 'tableHeight');
            end
        end
    end
end