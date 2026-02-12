classdef (Abstract) ProjectBase

    % ## model.ProjectBase ##      
    % - *.*
    %   ├── computeProjectHash (Static)
    %   └── ...
    %       └── ...

    properties (Constant)
    %---------------------------------------------------------------------%
        WARNING_VALIDATIONSRULES = struct( ...
            'MONITORINGPLAN', [ ...
                'As regras de validação do registro não foram atendidas.<br>' ...
                '•&thinsp;A <b>Justificativa</b> deve ser informada quando o número de medições for igual a zero.<br>' ...
                '•&thinsp;O campo <b>Observações</b> é obrigatório quando a <b>Justificativa</b> corresponder a um dos motivos que exigem comentário.<br>' ...
                '•&thinsp;A <b>Latitude</b> ou <b>Longitude</b> deve ser ajustada quando a <b>Justificativa</b> corresponder a um dos motivos que exigem atualização de localização.'
            ], ...
            'EXTERNALREQUEST', [ ...
                'As regras de validação do registro não foram atendidas.<br>' ...
                '•&thinsp;A <b>Justificativa</b> deve ser informada quando o número de medições for igual a zero.<br>' ...
            ] ...
        )
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        % Hash do projeto, utilizado para identificar alterações em
        % informações sensíveis durante a sessão corrente do app.
        %-----------------------------------------------------------------%
        function hash = computeProjectHash(prjName, prjFile, prjModules, prjIssueDetails, prjEntityDetails, EMFieldObj)
            hashList = sort({EMFieldObj.Hash});

            contextList = fieldnames(prjModules);
            annotationTable = [];

            for ii = 1:numel(contextList)
                context = contextList{ii};
                annotationTable = [annotationTable; prjModules.(context).annotationTable];
            end

            if ~isempty(annotationTable)
                annotationTable = sortrows(annotationTable, 'Hash');
            end

            hash = Hash.sha1(sprintf('%s - %s - %s - %s - %s - %s', prjName, prjFile, strjoin(hashList, ' - '), jsonencode(annotationTable), jsonencode(prjIssueDetails), jsonencode(prjEntityDetails)));
        end

        %-----------------------------------------------------------------%
        % Hash da versão definitiva do relatório, utilizado para assegurar 
        % conteúdo atualizado em relação ao que é apresentado no app.
        %-----------------------------------------------------------------%
        function hash = computeReportAnalysisResultsHash(prjModules, context, EMFieldObj)
            prjModule = struct(context, prjModules.(context));
            hash = model.ProjectBase.computeProjectHash('', '', prjModule, [], [], EMFieldObj);
        end

        %-----------------------------------------------------------------%
        % Hash do upload do relatório, utilizado para sinalizar ao usuário
        % os relatórios já enviados ao SEI durante a sessão corrente do app.
        %-----------------------------------------------------------------%
        function hash = computeUploadedFileHash(system, issue, status)
            hash = Hash.sha1(strjoin({system, num2str(issue), status}, ' - '));
        end

        %-----------------------------------------------------------------%
        % Hash da instância da classe model.EMFieldData.
        %-----------------------------------------------------------------%
        function hash = computeEMFieldDataHash(EMFieldDataObj)
            hash = Hash.sha1(sprintf('%s - %d - %s - %s - %s - %s', ...
                EMFieldDataObj.Sensor, ...
                EMFieldDataObj.Measures, ...
                EMFieldDataObj.ObservationTime, ...
                strjoin(string(EMFieldDataObj.FieldValueLimits), ' - '), ...
                strjoin(string(EMFieldDataObj.LatitudeLimits), ' - '), ...
                strjoin(string(EMFieldDataObj.LongitudeLimits), ' - ') ...
            ));
        end

        %-----------------------------------------------------------------%
        function hash = computeFileRuleHash(filterType, filterOperation, filterValue)
            hash = Hash.sha1(sprintf('%s - %s - %s', filterType, filterOperation, strjoin(string(filterValue), ' - ')));
        end

        %-----------------------------------------------------------------%
        function varargout = initializeCustomTable(tableId, varargin)
            arguments
                tableId {mustBeMember(tableId, {'STATIONS', 'POINTS', 'ANNOTATION'})}
            end

            arguments (Repeating)
                varargin
            end

            % As colunas "Latitude", "Longitude", "Justificativa" e "Observações"
            % contam em todas as tabelas - "STATIONS", "POINTS" e "ANNOTATION".

            switch tableId
                case 'STATIONS'
                    appName = varargin{1};
                    rootFolder = varargin{2};
                    generalSettings = varargin{3};

                    % Em 29/01/2026, a planilha base do PM-RNI, em formato .xlsx, possui 13 
                    % colunas. Antes de exportar essa planilha como .mat, acrescentam-se 
                    % outras cinco colunas - "Ano", "Hash", "Location", "Latitude" e 
                    % "Longitude".
                
                    % • Colunas 01-07: ["ID", "UD", "UF", "Município", "Tipo", "Serviço", "Entidade"] - cellstr
                    % • Coluna     08: ["Fistel"]                                                     - int64
                    % • Coluna     09: ["Estação"]                                                    - int32
                    % • Coluna     10: ["Endereço"]                                                   - cellstr
                    % • Colunas 11-12: ["Lat" e "Long"]                                               - double
                    % • Coluna     13: ["Áreas Críticas"]                                             - cellstr
                    % • Coluna     14: ["Ano"]                                                        - double
                    % • Colunas 15-16: ["Hash", "Location"]                                           - cellstr
                    % • Colunas 17-18: ["Latitude", "Longitude"]                                      - double
                
                    % No processo de leitura, são eliminados registros que não correspondem 
                    % aos anos de interesse. Além disso, são incluídas colunas que auxiliam 
                    % no registro da análise realizada por meio do app.
                    
                    [projectFolder, ...
                     programDataFolder] = appEngine.util.Path(appName, rootFolder);
                
                    projectFilePath     = fullfile(projectFolder,     'DataBase', [generalSettings.context.MONITORINGPLAN.referenceFile '.mat']);
                    programDataFilePath = fullfile(programDataFolder, 'DataBase', [generalSettings.context.MONITORINGPLAN.referenceFile '.mat']);
                
                    try
                        load(programDataFilePath, 'stationTable');
                    catch
                        load(projectFilePath,     'stationTable')
                    end
                
                    idxInvalid = isnan(stationTable.Lat) | isnan(stationTable.Long);
                    if any(idxInvalid)
                        stationTable(idxInvalid, :) = [];
                    end
                
                    yearList = unique(stationTable.Ano);
                    idxFilter = ~ismember(stationTable.Ano, generalSettings.context.MONITORINGPLAN.periodYears);
                    if any(idxFilter)
                        stationTable(idxFilter, :) = [];
                    end
                    
                    stationTable.numberOfMeasures(:)      = 0;
                    stationTable.numberOfRiskMeasures(:)  = 0;
                    stationTable.minDistanceForMeasure(:) = 0;
                    stationTable.minFieldValue(:)         = 0;
                    stationTable.meanFieldValue(:)        = 0;
                    stationTable.maxFieldValue(:)         = 0;
                
                    stationTable.maxFieldTimestamp(:)     = NaT;
                    stationTable.maxFieldTimestamp.Format = 'dd/MM/yyyy HH:mm:ss';
                    stationTable.maxFieldLatitude(:)      = 0;
                    stationTable.maxFieldLongitude(:)     = 0;
                
                    stationTable.("Fonte de dados")(:)    = {''};
                    stationTable.("Justificativa")(:)     = categorical("-", generalSettings.context.MONITORINGPLAN.noMeasurementReasons, 'Protected', true);
                    stationTable.("Observações")(:)       = {''};
                
                    stationTable.AnalysisFlag(:)          = false;    
                
                    % Por fim, ordena-se a tabela, de forma que "Águas Claras", por exemplo, 
                    % não seja apresentada depois dos municípios que se iniciam com a letra "z".
                    locationList = unique(stationTable.Location);
                    locationNormalizedList = textAnalysis.normalizeWords(lower(locationList));
                    [~, idxSort] = sort(locationNormalizedList);
                    
                    referenceData = struct( ...
                        'years', yearList, ...
                        'selectedYears', generalSettings.context.MONITORINGPLAN.periodYears, ...
                        'locations', {locationList(idxSort)}, ...
                        'states', {unique(stationTable.UF)} ...
                    );
                    
                    varargout = {stationTable, referenceData};

                case 'POINTS'
                    generalSettings = varargin{1};
                    pointsTable = table( ...
                        'Size', [0, 19], ...
                        'VariableTypes', {'cell', 'cell', 'int32', 'double', 'double', 'cell', 'cell', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'cell', 'categorical', 'cell', 'logical'}, ...
                        'VariableNames', {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'Hash', 'numberOfMeasures', 'numberOfRiskMeasures', 'minDistanceForMeasure', 'minFieldValue', 'meanFieldValue', 'maxFieldValue', 'maxFieldLatitude', 'maxFieldLongitude', 'Fonte de dados', 'Justificativa', 'Observações', 'AnalysisFlag'} ...
                    );                
                    pointsTable.Justificativa = categorical(pointsTable.Justificativa, generalSettings.context.EXTERNALREQUEST.noMeasurementReasons, 'Protected', true);
                    varargout = {pointsTable};

                case 'ANNOTATION'
                    annotationTable = table( ...
                        'Size', [0, 5], ...
                        'VariableTypes', {'cell', 'double', 'double', 'categorical', 'cell'}, ...
                        'VariableNames', {'Hash', 'Latitude', 'Longitude', 'Justificativa', 'Observações'} ...
                    );
                    varargout = {annotationTable};
            end
        end

        %-----------------------------------------------------------------%
        % Identifica medidas no entorno de cada ponto de interesse, inserindo 
        % informações na tabela de referência:
        % - "STATIONS" (auxApp.winMonitoringPlan); ou 
        % - "POINTS"   (auxApp.winExternalRequest).
        %-----------------------------------------------------------------%
        function refTable = identifyMeasuresForEachPoint(refTable, refTableIndexes, measTable, threshold, dist)
            for ii = refTableIndexes
                if refTable.AnalysisFlag(ii)
                    continue
                end

                refTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância da estação/ponto a cada uma 
                % das medidas, identificando aquelas no entorno.
                pointDistance      = deg2km(distance(refTable.Latitude(ii), refTable.Longitude(ii), measTable.Latitude, measTable.Longitude));                
                idxLogicalMeasures = pointDistance <= dist;

                if any(idxLogicalMeasures)
                    pointMeasures = measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue]  = max(pointMeasures.FieldValue);

                    refTable.numberOfMeasures(ii)      = height(pointMeasures);
                    refTable.numberOfRiskMeasures(ii)  = sum(pointMeasures.FieldValue > threshold);
                    refTable.minFieldValue(ii)         = round(min(pointMeasures.FieldValue),             6);
                    refTable.meanFieldValue(ii)        = round(mean(pointMeasures.FieldValue),            6);
                    refTable.maxFieldValue(ii)         = round(maxFieldValue,                             6);
                    refTable.maxFieldLatitude(ii)      = round(pointMeasures.Latitude(idxMaxFieldValue),  6);
                    refTable.maxFieldLongitude(ii)     = round(pointMeasures.Longitude(idxMaxFieldValue), 6);
                    refTable.("Fonte de dados"){ii}    = jsonencode(unique(pointMeasures.FileSource));

                    if ismember('maxFieldTimestamp', refTable.Properties.VariableNames)
                        refTable.maxFieldTimestamp(ii) = pointMeasures.Timestamp(idxMaxFieldValue);
                    end

                else
                    refTable.numberOfMeasures(ii)      = 0;
                    refTable.numberOfRiskMeasures(ii)  = 0;
                    refTable.minFieldValue(ii)         = 0;
                    refTable.meanFieldValue(ii)        = 0;
                    refTable.maxFieldValue(ii)         = 0;
                    refTable.maxFieldLatitude(ii)      = 0;
                    refTable.maxFieldLongitude(ii)     = 0;
                    refTable.("Fonte de dados"){ii}    = jsonencode({''});   % '[""]'
                end

                refTable.minDistanceForMeasure(ii)     = round(min(pointDistance), 3); % km
            end
        end

        %-----------------------------------------------------------------%
        function referenceTable = computeHashColumn(referenceTable, tableId)
            arguments
                referenceTable table
                tableId  char {mustBeMember(tableId, {'STATIONS', 'POINTS'})}
            end

            switch tableId
                case 'STATIONS'
                    referenceTable.("Hash") = cellfun(@(x) Hash.sha1(x), cellstr(...
                        string(referenceTable.Fistel)      + " - " + ...
                        string(referenceTable.("Estação")) + " - " + ...
                        string(referenceTable.Lat)         + " - " + ...
                        string(referenceTable.Long)                  ...
                    ), 'UniformOutput', false);

                case 'POINTS'
                    referenceTable.("Hash") = cellfun(@(x) Hash.sha1(x), cellstr( ...
                        string(referenceTable.("Station"))   + " - " + ...
                        string(referenceTable.("Latitude"))  + " - " + ...
                        string(referenceTable.("Longitude"))           ...
                    ), 'UniformOutput', false);
            end
        end

        %-----------------------------------------------------------------%
        function [status, msgError] = exportAnalysisPreview(context, referenceTable, generalSettings, measTable, fileName, exportRawMeasuresFlag)
            arguments
                context {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                referenceTable                
                generalSettings
                measTable
                fileName
                exportRawMeasuresFlag
            end
        
            status = true;
            msgError = '';

            referenceTable = model.ProjectBase.prepareReferenceTableToExport(context, referenceTable, generalSettings);

            switch context
                case 'MONITORINGPLAN'
                    referenceTable = renamevars(referenceTable, ...
                        {'id', 'unit', 'state', 'city', 'stationType', 'stationService', 'stationCompanyName', 'stationFistel', 'stationId', 'stationAddress', 'stationLat', 'stationLng', 'criticalAreas', 'measurementCount', 'measurementsAboveLimit', 'nearestMeasurementDistanceKm', 'electricFieldLimit', 'electricFieldMin', 'electricFieldMean', 'electricFieldMax', 'maxElectricFieldInstant', 'maxElectricFieldLat', 'maxElectricFieldLng', 'dataSources', 'auditorReason', 'auditorComment'}, ...
                        {'ID', 'UD', 'UF', 'Município', 'Tipo', 'Serviço', 'Entidade', 'Fistel', 'Estação', 'Endereço', 'Lat', 'Long', 'Áreas Críticas', 'Qtd. Medidas', 'Qtd. Medidas Acima do Limite', 'Distância Mínima (km)', 'Limite (V/m)', 'Emin (V/m)', 'Emean (V/m)', 'Emax (V/m)', 'Emax - Data da Medição', 'Emax - Latitude', 'Emax - Longitude', 'Fonte de dados', 'Justificativa', 'Observações'} ...
                    );
                    referenceTableTag = 'STATIONS';

                case 'EXTERNALREQUEST'
                    referenceTable = renamevars(referenceTable, ...
                        {'id', 'stationType', 'stationId', 'stationLat', 'stationLng', 'stationDescription', 'measurementCount', 'measurementsAboveLimit', 'nearestMeasurementDistanceKm', 'electricFieldMin', 'electricFieldMean', 'electricFieldMax', 'maxElectricFieldLat', 'maxElectricFieldLng', 'dataSources', 'auditorReason', 'auditorComment'}, ...
                        {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'numberOfMeasures', 'numberOfRiskMeasures', 'minDistanceForMeasure', 'minFieldValue', 'meanFieldValue', 'maxFieldValue', 'maxFieldLatitude', 'maxFieldLongitude', 'Fonte de dados', 'Justificativa', 'Observações'} ...
                    );
                    referenceTableTag = 'POINTS';
            end

            try
                writetable(referenceTable, fileName, 'FileType', 'spreadsheet', 'WriteMode', 'replacefile',    'Sheet', referenceTableTag)
                if exportRawMeasuresFlag
                    writetable(measTable,  fileName, 'FileType', 'spreadsheet', 'WriteMode', 'overwritesheet', 'Sheet', 'MEASURES')
                end

            catch ME
                status = false;
                msgError = ME.message;
            end
        end

        %-----------------------------------------------------------------%
        function varargout = prepareReferenceTableToExport(context, referenceTable, generalSettings)
            arguments
                context {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                referenceTable
                generalSettings
            end
        
            electricFieldStrengthThreshold = generalSettings.context.(context).electricFieldStrengthThreshold;
        
            switch context
                case 'MONITORINGPLAN'
                    stationTable = referenceTable;
        
                    % (a) Elimina linhas idênticas, caso existentes.
                    [~, uniqueIdxs] = unique(stationTable.("Hash"), "stable");
                    stationTable = stationTable(uniqueIdxs, :);
            
                    % (b) Insere coordenadas geográficas da estação no campo "Observações", 
                    %     caso editadas, e troca valores inválidos ("-1", por exemplo) por 
                    %     valores nulos.
                    stationTable = model.ProjectBase.normalizeStationTableAnnotations(stationTable);
                
                    % (c) Seleciona colunas que irão compor o arquivo .XLSX, criando coluna 
                    %     com informação do "Limite".
                    stationTable = removevars(stationTable, {'Ano', 'Hash', 'Location', 'Latitude', 'Longitude', 'AnalysisFlag'});
                    stationTable.("electricFieldLimit")(:) = electricFieldStrengthThreshold;

                    stationTable.("Lat")  = round(stationTable.("Lat"),  6);
                    stationTable.("Long") = round(stationTable.("Long"), 6);
                    
                    stationTable.("maxFieldTimestamp").Format = 'yyyyMMdd HH:mm:ss';
                    stationTable.("maxFieldTimestamp") = string(stationTable.("maxFieldTimestamp"));
                    stationTable.("maxFieldTimestamp")(ismissing(stationTable.("maxFieldTimestamp"))) = "";
                
                    % (d) Edita nomes de algumas das colunas da tabela.
                    stationTable = renamevars(stationTable, ...
                        {'ID', 'UD', 'UF', 'Município', 'Tipo', 'Serviço', 'Entidade', 'Fistel', 'Estação', 'Endereço', 'Lat', 'Long', 'Áreas Críticas', 'numberOfMeasures', 'numberOfRiskMeasures', 'minDistanceForMeasure', 'minFieldValue', 'meanFieldValue', 'maxFieldValue', 'maxFieldTimestamp', 'maxFieldLatitude', 'maxFieldLongitude', 'Fonte de dados', 'Justificativa', 'Observações'}, ...
                        {'id', 'unit', 'state', 'city', 'stationType', 'stationService', 'stationCompanyName', 'stationFistel', 'stationId', 'stationAddress', 'stationLat', 'stationLng', 'criticalAreas', 'measurementCount', 'measurementsAboveLimit', 'nearestMeasurementDistanceKm', 'electricFieldMin', 'electricFieldMean', 'electricFieldMax', 'maxElectricFieldInstant', 'maxElectricFieldLat', 'maxElectricFieldLng', 'dataSources', 'auditorReason', 'auditorComment'} ...
                    );
                    stationTable = movevars(stationTable, 'electricFieldLimit', 'After', 'nearestMeasurementDistanceKm');
                    
                    varargout = {stationTable};
        
                case 'EXTERNALREQUEST'
                    pointsTable = referenceTable;
        
                    % (a) Seleciona colunas que irão compor o arquivo .XLSX, criando coluna 
                    %     com informação do "Limite".
                    pointsTable = removevars(pointsTable, {'Hash', 'AnalysisFlag'});
                    pointsTable.("electricFieldLimit")(:) = electricFieldStrengthThreshold;
                
                    % (b) Troca valores inválidos ("-1", por exemplo) por valores nulos.
                    pointsTable = model.ProjectBase.normalizePointsTableAnnotation(pointsTable);
                
                    % (c) Edita nomes de algumas das colunas da tabela.
                    pointsTable = renamevars(pointsTable, ...
                        {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'numberOfMeasures', 'numberOfRiskMeasures', 'minDistanceForMeasure', 'minFieldValue', 'meanFieldValue', 'maxFieldValue', 'maxFieldLatitude', 'maxFieldLongitude', 'Fonte de dados', 'Justificativa', 'Observações'}, ...
                        {'id', 'stationType', 'stationId', 'stationLat', 'stationLng', 'stationDescription', 'measurementCount', 'measurementsAboveLimit', 'nearestMeasurementDistanceKm', 'electricFieldMin', 'electricFieldMean', 'electricFieldMax', 'maxElectricFieldLat', 'maxElectricFieldLng', 'dataSources', 'auditorReason', 'auditorComment'} ...
                    );
                    pointsTable = movevars(pointsTable, 'electricFieldLimit', 'After', 'nearestMeasurementDistanceKm');
        
                    varargout = {pointsTable};
            end
        end

        %-----------------------------------------------------------------%
        function stationTable = normalizeStationTableAnnotations(stationTable, charReplace)
            arguments
                stationTable
                charReplace = ''
            end

            editedLocationIdxs = find((stationTable.("Lat") ~= stationTable.("Latitude")) | (stationTable.("Long") ~= stationTable.("Longitude")))';
            for ii = editedLocationIdxs
                locationInfo = struct( ...
                    'lat', struct('original', stationTable.("Lat")(ii),  'edited', stationTable.("Latitude")(ii)), ...
                    'lng', struct('original', stationTable.("Long")(ii), 'edited', stationTable.("Longitude")(ii)) ...
                );
        
                if ~isempty(stationTable.("Observações"){ii})
                    locationInfo.additionalNote = stationTable.("Observações"){ii};
                end
        
                stationTable.("Observações"){ii} = jsonencode(locationInfo);
            end

            stationTable.("Justificativa") = replace(cellstr(stationTable.("Justificativa")), '-1', charReplace);
            if ~isempty(charReplace)
                stationTable.("Observações")(strcmp(stationTable.("Observações"), '')) = {charReplace};
            end
        end

        %-----------------------------------------------------------------%
        function pointsTable = normalizePointsTableAnnotation(pointsTable, charReplace)
            arguments
                pointsTable
                charReplace = ''
            end

            pointsTable.("Justificativa") = replace(cellstr(pointsTable.("Justificativa")), '-1', charReplace);
            if ~isempty(charReplace)
                stationTable.("Observações")(strcmp(stationTable.("Observações"), '')) = {charReplace};
            end
        end

        %-----------------------------------------------------------------%
        % ## PM-RNI ##
        % Executar essa função toda vez que o Centralizador do PM-RNI (UO0.1)
        % disponibilizar uma nova planilha de referência.
        %-----------------------------------------------------------------%
        function stationTable = updateStationTableFromRawData(fileFullName, exportFlag)
            stationTable = readtable(fileFullName, 'VariableNamingRule', 'preserve');

            expectedVariableNames = {'ID','UD','UF','Município','Tipo','Serviço','Entidade', 'Fistel','Estação','Endereço','Lat','Long','Áreas Críticas','Ano'};            
            foundVariableNames = stationTable.Properties.VariableNames;            
            if any(~ismember(foundVariableNames, expectedVariableNames))
                error('model:ProjectBase:InvalidTableSchema', 'Invalid table schema.\nExpected columns: %s\nFound columns: %s', strjoin(expectedVariableNames, ', '), strjoin(foundVariableNames, ', '))
            end
            
            stationTable.Fistel = int64(stationTable.Fistel);
            stationTable.("Estação") = int32(stationTable.("Estação"));    
            
            stationTable =  model.ProjectBase.computeHashColumn(stationTable, 'STATIONS');
            [~, idxUnique] = unique(stationTable.Hash, 'stable');
            stationTable = stationTable(idxUnique, :);    
            
            stationTable.Location = strcat(stationTable.("Município"), '/', stationTable.UF);
            stationTable.Latitude = stationTable.Lat;
            stationTable.Longitude = stationTable.Long;

            if exportFlag
                [fileFolder, fileName] = fileparts(fileFullName);
                save(fullfile(fileFolder, [fileName '.mat']), 'stationTable', '-mat', '-v7')
            end
        end
    end
    
end