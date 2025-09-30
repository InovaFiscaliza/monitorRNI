classdef projectLib < handle

    % ToDo:
    % - Revisar métodos, tirando publicidade daqueles métodos apenas chamados
    %   apenas dentro da própria classe.
    % - Evitar que propriedade dessa classe seja atualizada fora da classe.
    %   Criar um método geral "Update" p/ controlar toda e qualquer edição.
    % - ...

    properties
        %-----------------------------------------------------------------%
        name (1,:) char = ''
        file (1,:) char = ''

        report  = struct( ...
            'templates', [], ...
            'settings',  [] ...
        )

        modules = struct( ...
            'MonitoringPlan',  struct('stationTable',    [], ...
                                      'stationTable_I',  [], ...
                                      'annotationTable', [], ...
                                      'referenceData',   struct('years',      [],   ...
                                                                'locations', {{}},  ...
                                                                'states',    {{}}), ...
                                      'generatedFiles',  struct('rawFiles', {{}}, 'lastHTMLDocFullPath', '', 'lastTableFullPath', '', 'lastZIPFullPath', ''), ...
                                      'numMeasurements', [], ...
                                      'threshold',       [], ...
                                      'numAboveTHR',     [], ...
                                      'distance_km',     [], ...
                                      'ui',              struct('system',       '',   ...
                                                                'unit',         '',   ...
                                                                'issue',        -1,   ...
                                                                'templates',    {{}}, ...
                                                                'selectedGroup', '',  ...
                                                                'groupMapping', struct('hash',   {}, ...
                                                                                       'auto',   {}, ...
                                                                                       'manual', {}))), ...
            'ExternalRequest', struct('pointsTable',     [], ...
                                      'pointsTable_I',   [], ...
                                      'annotationTable', [], ...
                                      'generatedFiles',  struct('rawFiles', {{}}, 'lastHTMLDocFullPath', '', 'lastTableFullPath', '', 'lastZIPFullPath', ''), ...
                                      'numMeasurements', [], ...
                                      'threshold',       [], ...
                                      'numAboveTHR',     [], ...
                                      'distance_km',     [], ...
                                      'ui',              struct('system',       '',   ...
                                                                'unit',         '',   ...
                                                                'issue',        -1,   ...
                                                                'templates',    {{}}, ...
                                                                'selectedGroup', '')) ...
        )
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        mainApp
        rootFolder
    end


    methods
        %-----------------------------------------------------------------%
        function obj = projectLib(mainApp, rootFolder, generalSettings)            
            obj.mainApp    = mainApp;
            obj.rootFolder = rootFolder;

            % "ReportTemplates.json"
            ReadReportTemplates(obj, rootFolder)

            % "PM-RNI - Lista de estações.xlsx"
            % (stationTable)
            ReadStationTable(obj, generalSettings)

            % Tabelas vazias
            % (pointsTable e annotationTable)
            CreatePointsTable(obj, generalSettings)
            CreateAnnotationTable(obj)
        end

        %-----------------------------------------------------------------%
        function Restart(obj)
            obj.modules.MonitoringPlan.stationTable      = obj.modules.MonitoringPlan.stationTable_I;
            obj.modules.MonitoringPlan.generatedFiles    = struct('rawFiles', {{}}, 'lastHTMLDocFullPath', '', 'lastTableFullPath', '', 'lastZIPFullPath', '');
            obj.modules.MonitoringPlan.numMeasurements   = [];
            obj.modules.MonitoringPlan.threshold         = [];
            obj.modules.MonitoringPlan.numAboveTHR       = [];
            obj.modules.MonitoringPlan.distance_km       = [];
            obj.modules.MonitoringPlan.ui.selectedGroup  = '';

            obj.modules.ExternalRequest.pointsTable      = obj.modules.ExternalRequest.pointsTable_I;
            obj.modules.ExternalRequest.generatedFiles   = struct('rawFiles', {{}}, 'lastHTMLDocFullPath', '', 'lastTableFullPath', '', 'lastZIPFullPath', '');
            obj.modules.ExternalRequest.numMeasurements  = [];
            obj.modules.ExternalRequest.threshold        = [];
            obj.modules.ExternalRequest.numAboveTHR      = [];
            obj.modules.ExternalRequest.distance_km      = [];
            obj.modules.ExternalRequest.ui.selectedGroup = '';
        end

        %-----------------------------------------------------------------%
        function ReadReportTemplates(obj, rootFolder)
            [projectFolder, ...
             programDataFolder] = appUtil.Path(class.Constants.appName, rootFolder);
            projectFilePath  = fullfile(projectFolder,     'ReportTemplates.json');
            externalFilePath = fullfile(programDataFolder, 'ReportTemplates.json');

            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                obj.report.templates = jsondecode(fileread(externalFilePath));
            catch
                obj.report.templates = jsondecode(fileread(projectFilePath));
            end

            % Identifica lista de templates por módulo...
            moduleNameList   = fieldnames(obj.modules);
            templateNameList = {obj.report.templates.Name};

            for ii = 1:numel(moduleNameList)
                templateIndexes = ismember({obj.report.templates.Module}, moduleNameList(ii));
                obj.modules.(moduleNameList{ii}).ui.templates = [{''}, templateNameList(templateIndexes)];
            end
        end

        %-----------------------------------------------------------------%
        function ReadStationTable(obj, generalSettings)
            [stationTable, referenceData] = fileReader.MonitoringPlan(class.Constants.appName, obj.rootFolder, generalSettings);

            obj.modules.MonitoringPlan.stationTable_I = stationTable;
            obj.modules.MonitoringPlan.stationTable   = stationTable;

            obj.modules.MonitoringPlan.referenceData  = referenceData;
        end

        %-----------------------------------------------------------------%
        function updateGeneratedFiles(obj, context, htmlFile, tableFile)
            arguments
                obj
                context   (1,:) char {mustBeMember(context, {'MonitoringPlan', 'ExternalRequest'})}
                htmlFile  char = ''
                tableFile char = ''
            end

            obj.modules.(context).generatedFiles.lastHTMLDocFullPath = htmlFile;
            obj.modules.(context).generatedFiles.lastTableFullPath   = tableFile;

        end

        %-----------------------------------------------------------------%
        function updateUiInfo(obj, context, fieldName, fieldValue)
            arguments
                obj
                context    (1,:) char {mustBeMember(context, {'MonitoringPlan', 'ExternalRequest'})}
                fieldName  (1,:) char
                fieldValue
            end

            obj.modules.(context).ui.(fieldName) = fieldValue;
        end

        %-----------------------------------------------------------------%
        function updateAnnotationTable(obj, context, tableName, operationType)
            arguments
                obj
                context       char {mustBeMember(context,       {'MonitoringPlan', 'ExternalRequest'})}
                tableName     char {mustBeMember(tableName,     {'stationTable', 'pointsTable'})}
                operationType char {mustBeMember(operationType, {'save', 'load'})}
            end

            cachedColumns = {'Latitude', 'Longitude', 'Justificativa', 'Observações'};

            switch operationType
                case 'save'
                    cachedColumns = [{'Base64Hash'}, cachedColumns];

                    refTable   = model.projectLib.generateHash(obj.modules.(context).(tableName)(:, cachedColumns),        'annotationTable');
                    refTable_I = model.projectLib.generateHash(obj.modules.(context).([tableName '_I'])(:, cachedColumns), 'annotationTable');

                    refIndex   = ~strcmp(refTable.("EditionHash"), refTable_I.("EditionHash"));
                    obj.modules.(context).annotationTable = refTable(refIndex, cachedColumns);

                case 'load'
                    refTable   = obj.modules.(context).(tableName);
                    cacheTable = obj.modules.(context).annotationTable;

                    if ~isempty(cacheTable)
                        [refIndex, cacheIndex] = ismember(refTable.("Base64Hash"), cacheTable.("Base64Hash"));

                        if any(refIndex)
                            refTable(refIndex, cachedColumns) = cacheTable(cacheIndex(refIndex), cachedColumns);
                            obj.modules.(context).(tableName) = refTable;
                        end
                    end
            end
        end

        %-----------------------------------------------------------------%
        function updateAnalysis(obj, measData, generalSettings, updateType)
            arguments
                obj
                measData
                generalSettings
                updateType char {mustBeMember(updateType, {'FileListChanged:Add',                      ... % winMonitorRNI
                                                           'FileListChanged:Del',                      ... % winMonitorRNI
                                                           'MonitoringPlan:AnalysisParameterChanged',  ... % auxApp.winConfig
                                                           'MonitoringPlan:ManualLocationListChanged', ... % auxApp.winMonitoringPlan >> auxApp.dockListOfLocation
                                                           'MonitoringPlan:StationCoordinatesEdited',  ... % auxApp.winMonitoringPlan >> auxApp.dockStationInfo
                                                           'ExternalRequest:AnalysisParameterChanged', ... % auxApp.winConfig
                                                           'ExternalRequest:PointsTableChanged'})}         % auxApp.winExternalRequest
            end

            updateAnnotationTable(obj, 'MonitoringPlan',  'stationTable', 'save')
            updateAnnotationTable(obj, 'ExternalRequest', 'pointsTable',  'save')

            if ~isempty(measData)
                measTable = createMeasTable(measData);

                switch updateType
                    case {'FileListChanged:Add', ...
                          'FileListChanged:Del'}
                        updateStationTableAnalysis(obj, measData, measTable, generalSettings)
                        updatePointsTableAnalysis(obj, measTable, generalSettings)
    
                    case {'MonitoringPlan:AnalysisParameterChanged',  ...
                          'MonitoringPlan:ManualLocationListChanged', ...
                          'MonitoringPlan:StationCoordinatesEdited'}
                        updateStationTableAnalysis(obj, measData, measTable, generalSettings)
    
                    case {'ExternalRequest:AnalysisParameterChanged', ...
                          'ExternalRequest:PointsTableChanged'}
                        updatePointsTableAnalysis(obj, measTable, generalSettings)
                end

            else
                Restart(obj)
            end
        end

        %-----------------------------------------------------------------%
        function filename = getGeneratedDocumentFileName(obj, fileExt, context)
            arguments
                obj
                fileExt (1,:) char {mustBeMember(fileExt, {'rawFiles', '.html', '.json', '.xlsx', '.csv'})}
                context (1,:) char {mustBeMember(context, {'MonitoringPlan', 'ExternalRequest'})}
            end

            switch fileExt
                case 'rawFiles'
                    filename = obj.modules.(context).generatedFiles.rawFiles;
                case '.html'
                    filename = obj.modules.(context).generatedFiles.lastHTMLDocFullPath;
                otherwise
                    filename = obj.modules.(context).generatedFiles.lastTableFullPath;
            end
        end

        %-----------------------------------------------------------------%
        function updateSelectedListOfLocations(obj, location, context)
            arguments
                obj
                location (1,:) char
                context  (1,:) char {mustBeMember(context, {'MonitoringPlan', 'ExternalRequest'})} = 'MonitoringPlan'
            end

            obj.modules.(context).ui.selectedGroup = location;
        end


        %-----------------------------------------------------------------%
        % AUXAPP.WINMONITORINGPLAN
        %-----------------------------------------------------------------%
        function hashIndex = addAutomaticLocations(obj, measData, stationTable, dist)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.modules.MonitoringPlan.ui.groupMapping.hash}, hash), 1);

            if isempty(hashIndex)
                automaticLocations = {};
                for ii = 1:numel(measData)
                    % Limites de latitude e longitude relacionados à rota, acrescentando 
                    % a distância máxima à estação p/ fins de cômputo de medidas válidas 
                    % no entorno de uma estação.
                    [maxLatitude, maxLongitude] = reckon(measData(ii).LatitudeLimits(2), measData(ii).LongitudeLimits(2), km2deg(dist), 45);
                    [minLatitude, minLongitude] = reckon(measData(ii).LatitudeLimits(1), measData(ii).LongitudeLimits(1), km2deg(dist), 225);
        
                    idxLogicalStation = stationTable.Latitude  >= minLatitude  & ...
                                        stationTable.Latitude  <= maxLatitude  & ...
                                        stationTable.Longitude >= minLongitude & ...
                                        stationTable.Longitude <= maxLongitude;
        
                    if any(idxLogicalStation)
                        automaticLocations = [automaticLocations; unique(stationTable.Location(idxLogicalStation))];
                    end
                end

                % Caso se trate de uma visualização de mais de uma localidade, 
                % inicia-se a lista de municípios incluídos manualmente com
                % aquilo que foi inserido para os municípios isoladamente, 
                % caso aplicável.
                manualLocations = {};
                if numel(unique({measData.Location_I})) > 1
                    rawHashIndexes  = ismember({obj.modules.MonitoringPlan.ui.groupMapping.hash}, {measData.UUID});
                    if any(rawHashIndexes)
                        manualLocations = vertcat(obj.modules.MonitoringPlan.ui.groupMapping(rawHashIndexes).manual);
                    end
                end

                hashIndex = numel(obj.modules.MonitoringPlan.ui.groupMapping) + 1;
                obj.modules.MonitoringPlan.ui.groupMapping(hashIndex) = struct('hash', hash, 'auto', {unique(automaticLocations)}, 'manual', {unique(manualLocations)});
            end
        end

        %-----------------------------------------------------------------%
        function delLocationCache(obj, measData, indexes)
            currentLocation = unique({measData(indexes).Location});
            currentLocationIndexes = ismember({measData.Location}, currentLocation);

            hash = strjoin(unique({measData(currentLocationIndexes).UUID}));
            hashIndex = find(strcmp({obj.modules.MonitoringPlan.ui.groupMapping.hash}, hash), 1);

            if ~isempty(hashIndex)
                obj.modules.MonitoringPlan.ui.groupMapping(hashIndex) = [];
            end
        end

        %-----------------------------------------------------------------%
        function hashIndex = addManualLocations(obj, measData, locations)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.modules.MonitoringPlan.ui.groupMapping.hash}, hash), 1);
            
            if ~isempty(hashIndex)
                obj.modules.MonitoringPlan.ui.groupMapping(hashIndex).manual = locations;
            end
        end

        %-----------------------------------------------------------------%
        function locations = getFullListOfLocation(obj, measData, dist)
            locationList = {measData.Location};
            groupLocationList = unique(locationList);
            
            locations = {};
            for ii = 1:numel(groupLocationList)
                groupLocation   = groupLocationList{ii};
                locationIndexes = strcmp(locationList, groupLocation);

                hash = strjoin(unique({measData(locationIndexes).UUID}));
                hashIndex = find(strcmp({obj.modules.MonitoringPlan.ui.groupMapping.hash}, hash), 1);
    
                if isempty(hashIndex)
                    hashIndex = addAutomaticLocations(obj, measData(locationIndexes), obj.modules.MonitoringPlan.stationTable, dist);
                end

                locations = union(locations, union(obj.modules.MonitoringPlan.ui.groupMapping(hashIndex).auto, obj.modules.MonitoringPlan.ui.groupMapping(hashIndex).manual));
            end

            locations = unique(locations);
        end

        %-----------------------------------------------------------------%
        function manualLocations = getCurrentManualLocations(obj, measData)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.modules.MonitoringPlan.ui.groupMapping.hash}, hash), 1);

            if ~isempty(hashIndex)
                manualLocations = obj.modules.MonitoringPlan.ui.groupMapping(hashIndex).manual;
            else
                manualLocations = {};
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function CreatePointsTable(obj, generalSettings)
            pointsTable = table('Size',          [0, 19],                                                                                       ...
                                'VariableTypes', {'cell', 'cell', 'int32', 'double', 'double', 'cell', 'cell', 'double', 'double', 'double',    ...
                                                  'double', 'double', 'double', 'double', 'double', 'cell', 'categorical', 'cell', 'logical'},  ...
                                'VariableNames', {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'Base64Hash',                ...
                                                  'numberOfMeasures', 'numberOfRiskMeasures', 'minDistanceForMeasure', 'minFieldValue',         ...
                                                  'meanFieldValue', 'maxFieldValue', 'maxFieldLatitude', 'maxFieldLongitude', 'Fonte de dados', ...
                                                  'Justificativa', 'Observações', 'AnalysisFlag'});
        
            pointsTable.Justificativa = categorical(pointsTable.Justificativa, generalSettings.ExternalRequest.NoMeasureReasons);

            obj.modules.ExternalRequest.pointsTable_I = pointsTable;
            obj.modules.ExternalRequest.pointsTable   = pointsTable;
        end

        %-----------------------------------------------------------------%
        function CreateAnnotationTable(obj)
            cacheTable  = table('Size',          [0, 5],                                       ...
                                'VariableTypes', {'cell', 'double', 'double', 'cell', 'cell'}, ...
                                'VariableNames', {'Base64Hash', 'Latitude', 'Longitude', 'Justificativa', 'Observações'});

            obj.modules.MonitoringPlan.annotationTable  = cacheTable;
            obj.modules.ExternalRequest.annotationTable = cacheTable;
        end

        %-----------------------------------------------------------------%
        function updateStationTableAnalysis(obj, measData, measTable, generalSettings)
            obj.modules.MonitoringPlan.stationTable     = obj.modules.MonitoringPlan.stationTable_I;
            updateAnnotationTable(obj, 'MonitoringPlan',  'stationTable', 'load')

            stationTable = obj.modules.MonitoringPlan.stationTable;
            idxStations  = find(ismember(stationTable.Location, getFullListOfLocation(obj, measData, generalSettings.MonitoringPlan.Distance_km)))';
            stationTable = model.projectLib.identifyMeasuresForEachPoint(stationTable, idxStations, measTable, generalSettings.MonitoringPlan.FieldValue, generalSettings.MonitoringPlan.Distance_km);
            
            obj.modules.MonitoringPlan.stationTable     = stationTable;
            obj.modules.MonitoringPlan.numMeasurements  = height(measTable);
            obj.modules.MonitoringPlan.threshold        = generalSettings.MonitoringPlan.FieldValue;
            obj.modules.MonitoringPlan.numAboveTHR      = sum(measTable.FieldValue > generalSettings.MonitoringPlan.FieldValue);
            obj.modules.MonitoringPlan.distance_km      = generalSettings.MonitoringPlan.Distance_km;
        end

        %-----------------------------------------------------------------%
        function updatePointsTableAnalysis(obj, measTable, generalSettings)
            obj.modules.ExternalRequest.pointsTable     = obj.modules.ExternalRequest.pointsTable_I;
            updateAnnotationTable(obj, 'ExternalRequest', 'pointsTable',  'load')

            pointsTable  = obj.modules.ExternalRequest.pointsTable;
            idxPoints    = 1:height(pointsTable);
            pointsTable  = model.projectLib.identifyMeasuresForEachPoint(pointsTable, idxPoints, measTable, generalSettings.ExternalRequest.FieldValue, generalSettings.ExternalRequest.Distance_km);
            
            obj.modules.ExternalRequest.pointsTable     = pointsTable;
            obj.modules.ExternalRequest.numMeasurements = obj.modules.MonitoringPlan.numMeasurements;
            obj.modules.ExternalRequest.threshold       = generalSettings.ExternalRequest.FieldValue;
            obj.modules.ExternalRequest.numAboveTHR     = sum(measTable.FieldValue > generalSettings.ExternalRequest.FieldValue);
            obj.modules.ExternalRequest.distance_km     = generalSettings.ExternalRequest.Distance_km;
        end
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function referenceTable = prepareStationTableForExport(referenceTable, operationType, charReplace)
            arguments
                referenceTable table
                operationType  char {mustBeMember(operationType, {'stationTable', 'pointsTable'})}
                charReplace    char = ''
            end

            if strcmp(operationType, 'stationTable')
                % Insere coordenadas geográficas da estação no campo "Observações", 
                % caso editadas.
                idxEditedCoordinates = find((referenceTable.("Lat") ~= referenceTable.("Latitude")) | (referenceTable.("Long") ~= referenceTable.("Longitude")))';
                for ii = idxEditedCoordinates
                    Coordinates = struct('lat', struct('original', referenceTable.("Lat")(ii),  'edited', referenceTable.("Latitude")(ii)), ...
                                         'lng', struct('original', referenceTable.("Long")(ii), 'edited', referenceTable.("Longitude")(ii)));
            
                    if ~isempty(referenceTable.("Observações"){ii})
                        Coordinates.NotaAdicional = referenceTable.("Observações"){ii};
                    end
            
                    referenceTable.("Observações"){ii} = jsonencode(Coordinates);
                end
            end

            % Troca valores inválidos ("-1", por exemplo) por valores nulos.
            referenceTable.("Justificativa") = replace(cellstr(referenceTable.("Justificativa")), '-1', charReplace);
            if ~isempty(charReplace)
                referenceTable.("Observações")(strcmp(referenceTable.("Observações"), '')) = {charReplace};
            end
        end

        %-----------------------------------------------------------------%
        function referenceTable = generateHash(referenceTable, operationType)
            arguments
                referenceTable table
                operationType  char {mustBeMember(operationType, {'stationTable', 'pointsTable', 'annotationTable'})}
            end

            switch operationType
                case 'stationTable'
                    referenceTable.("Base64Hash") = cellfun(@(x) Base64Hash.encode(x), cellstr(...
                        string(referenceTable.Fistel) + "; " + ...
                        string(referenceTable.("Estação")) + "; " + ...
                        string(referenceTable.Lat) + "; " + ...
                        string(referenceTable.Long)), 'UniformOutput', false);

                case 'pointsTable'
                    referenceTable.("Base64Hash") = cellfun(@(x) Base64Hash.encode(x), strcat(...
                        referenceTable.("Type"), '; ', ...
                        cellstr(string(referenceTable.("Station"))   + "; " + ...
                                string(referenceTable.("Latitude"))  + "; " + ...
                                string(referenceTable.("Longitude")))), 'UniformOutput', false);

                case 'annotationTable'
                    referenceTable.("EditionHash") = cellfun(@(x) Base64Hash.encode(x), strcat(...
                        cellstr(string(referenceTable.("Latitude"))  + "; " + ...
                                string(referenceTable.("Longitude"))), '; ',  ...
                        cellstr(referenceTable.("Justificativa")), '; ',      ...
                        referenceTable.("Observações")), 'UniformOutput', false);
            end
        end

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
                    [maxFieldValue, idxMaxFieldValue] = max(pointMeasures.FieldValue);

                    refTable.numberOfMeasures(ii)     = height(pointMeasures);
                    refTable.numberOfRiskMeasures(ii) = sum(pointMeasures.FieldValue > threshold);
                    refTable.minFieldValue(ii)        = min(pointMeasures.FieldValue);
                    refTable.meanFieldValue(ii)       = mean(pointMeasures.FieldValue);
                    refTable.maxFieldValue(ii)        = maxFieldValue;
                    refTable.maxFieldLatitude(ii)     = pointMeasures.Latitude(idxMaxFieldValue);
                    refTable.maxFieldLongitude(ii)    = pointMeasures.Longitude(idxMaxFieldValue);
                    refTable.("Fonte de dados"){ii}   = jsonencode(unique(pointMeasures.FileSource));

                else
                    refTable.numberOfMeasures(ii)     = 0;
                    refTable.numberOfRiskMeasures(ii) = 0;
                    refTable.minFieldValue(ii)        = 0;
                    refTable.meanFieldValue(ii)       = 0;
                    refTable.maxFieldValue(ii)        = 0;
                    refTable.maxFieldLatitude(ii)     = 0;
                    refTable.maxFieldLongitude(ii)    = 0;
                    refTable.("Fonte de dados"){ii}   = jsonencode({''});   % '[""]'
                end

                refTable.minDistanceForMeasure(ii)    = min(pointDistance); % km
            end
        end
    end

end