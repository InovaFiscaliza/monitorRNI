classdef projectLib < handle

    properties
        %-----------------------------------------------------------------%
        name  (1,:) char
        file  (1,:) char
        issue (1,1) double
        unit  (1,:) char

        documentType {mustBeMember(documentType, {'Relatório de Atividades', 'Relatório de Fiscalização', 'Informe'})} = 'Relatório de Atividades'
        documentModel
        documentScript
        generatedFiles

        rawListOfYears
        referenceListOfLocations
        referenceListOfStates

        selectedFileLocations
        listOfLocations    = struct('Hash', {}, 'Automatic', {}, 'Manual', {})
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        mainApp
        rootFolder
        defaultFilePreffix = 'monitorRNI'
    end


    methods
        %-----------------------------------------------------------------%
        function obj = projectLib(mainApp)            
            obj.mainApp    = mainApp;
            obj.rootFolder = mainApp.rootFolder;

            Restart(obj)
            ReadReportTemplates(obj)

            % A planilha de referência do PM-RNI possui uma relação de estações 
            % de telecomunicações que deve ser avaliada. Dessa planilha, extrai-se:
            % • rawListOfYears: a lista com todos os anos da planilha 
            %   bruta - Coluna "Ano".
            
            % • referenceListOfLocation: a lista com todas as localidades 
            %   relacionadas às estações da planilha filtrada (pelo ano sob 
            %   análise).
            
            % • referenceListOfStates: a lista com todas as UFs relacionadas 
            %   às estações da planilha filtrada.

            % O monitorRNI identifica a localidade relacionada às coordenadas 
            % centrais de cada arquivo. Essa lista é apresentada nos modos 
            % auxiliares auxApp.winRNI e auxApp.ExternalRequest.
            % • selectedFileLocations: a lista com as localidades selecionadas 
            %   pelo usuário em um dos modos auxiliares.

            % • listOfLocations: a lista de localidades sob análise no módulo 
            %   auxApp.winMonitoringPlan p/ fins de geração da planilha que será 
            %   submetida ao Centralizador do PM-RNI.
        end

        %-----------------------------------------------------------------%
        function Restart(obj)
            obj.name           = '';
            obj.file           = '';
            obj.issue          = -1;
            obj.unit           = '';

            obj.documentType   = 'Relatório de Atividades';
            obj.documentScript = [];
            obj.generatedFiles = [];

            obj.selectedFileLocations = {};
        end

        %-----------------------------------------------------------------%
        function ReadReportTemplates(obj)
            [projectFolder, ...
             externalFolder] = appUtil.Path(class.Constants.appName, obj.rootFolder);
            projectFilePath  = fullfile(projectFolder,  'ReportTemplates.json');
            externalFilePath = fullfile(externalFolder, 'ReportTemplates.json');

            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                obj.documentModel = jsondecode(fileread(externalFilePath));
            catch
                obj.documentModel = jsondecode(fileread(projectFilePath));
            end
        end

        %-----------------------------------------------------------------%
        function stationTable = ReadStationTable(obj, generalSettings)
            [stationTable,                ...
            obj.rawListOfYears,           ...
            obj.referenceListOfLocations, ...
            obj.referenceListOfStates] = fileReader.MonitoringPlan(class.Constants.appName, obj.rootFolder, generalSettings);
        end
    end


    methods
        %-----------------------------------------------------------------%
        % AUXAPP.WINMONITORINGPLAN
        % AUXAPP.WINEXTERNALREQUEST
        %-----------------------------------------------------------------%
        function [measTable, stationTable, pointsTable] = updateAnalysis(obj, measData, stationTable, pointsTable, generalSettings, updateType)
            arguments
                obj
                measData
                stationTable
                pointsTable
                generalSettings
                updateType char {mustBeMember(updateType, {'station+points', 'station', 'points'})} = 'station+points'
            end

            % auxApp.winMonitoringPlan.measTable
            % auxApp.winExternalRequest.measTable
            if ~isempty(measData)
                measTable = createMeasTable(measData);

                % winMonitorRNI.stationTable
                if contains(updateType, 'station')
                    idxStations  = find(ismember(stationTable.Location, getFullListOfLocation(obj, measData, stationTable, max(generalSettings.MonitoringPlan.Distance_km, generalSettings.ExternalRequest.Distance_km))))';
                    stationTable = identifyMeasuresForEachPoint(obj, stationTable, idxStations, measTable, generalSettings.MonitoringPlan.FieldValue, generalSettings.MonitoringPlan.Distance_km);
                end
    
                % winMonitorRNI.pointsTable
                if contains(updateType, 'points')
                    idxPoints    = 1:height(pointsTable);
                    pointsTable  = identifyMeasuresForEachPoint(obj, pointsTable, idxPoints, measTable, generalSettings.ExternalRequest.FieldValue, generalSettings.ExternalRequest.Distance_km);
                end

            else
                measTable = [];
            end
        end

        %-----------------------------------------------------------------%
        function referenceTable = identifyMeasuresForEachPoint(obj, referenceTable, referenceTableIndexes, measTable, threshold, dist)
            for ii = referenceTableIndexes
                if referenceTable.AnalysisFlag(ii)
                    continue
                end

                referenceTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância da estação/ponto a cada uma 
                % das medidas, identificando aquelas no entorno.
                pointDistance      = deg2km(distance(referenceTable.Latitude(ii), referenceTable.Longitude(ii), measTable.Latitude, measTable.Longitude));                
                idxLogicalMeasures = pointDistance <= dist;

                if any(idxLogicalMeasures)
                    pointMeasures = measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(pointMeasures.FieldValue);

                    referenceTable.numberOfMeasures(ii)     = height(pointMeasures);
                    referenceTable.numberOfRiskMeasures(ii) = sum(pointMeasures.FieldValue > threshold);
                    referenceTable.minFieldValue(ii)        = min(pointMeasures.FieldValue);
                    referenceTable.meanFieldValue(ii)       = mean(pointMeasures.FieldValue);
                    referenceTable.maxFieldValue(ii)        = maxFieldValue;
                    referenceTable.maxFieldLatitude(ii)     = pointMeasures.Latitude(idxMaxFieldValue);
                    referenceTable.maxFieldLongitude(ii)    = pointMeasures.Longitude(idxMaxFieldValue);
                    referenceTable.("Fonte de dados"){ii}   = jsonencode(unique(pointMeasures.FileSource));

                else
                    referenceTable.numberOfMeasures(ii)     = 0;
                    referenceTable.numberOfRiskMeasures(ii) = 0;
                    referenceTable.minFieldValue(ii)        = 0;
                    referenceTable.meanFieldValue(ii)       = 0;
                    referenceTable.maxFieldValue(ii)        = 0;
                    referenceTable.maxFieldLatitude(ii)     = 0;
                    referenceTable.maxFieldLongitude(ii)    = 0;
                    referenceTable.("Fonte de dados"){ii}   = jsonencode({''});   % '[""]'
                end

                referenceTable.minDistanceForMeasure(ii)    = min(pointDistance); % km
            end
        end

        %-----------------------------------------------------------------%
        function updateSelectedListOfLocations(obj, locations)
            obj.selectedFileLocations = locations;
        end

        %-----------------------------------------------------------------%
        function hashIndex = addAutomaticLocations(obj, measData, stationTable, dist)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

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
                    rawHashIndexes  = ismember({obj.listOfLocations.Hash}, {measData.UUID});
                    if any(rawHashIndexes)
                        manualLocations = vertcat(obj.listOfLocations(rawHashIndexes).Manual);
                    end
                end

                hashIndex = numel(obj.listOfLocations) + 1;
                obj.listOfLocations(hashIndex) = struct('Hash', hash, 'Automatic', {unique(automaticLocations)}, 'Manual', {unique(manualLocations)});
            end
        end

        %-----------------------------------------------------------------%
        function delLocationCache(obj, measData, indexes)
            currentLocation = unique({measData(indexes).Location});
            currentLocationIndexes = ismember({measData.Location}, currentLocation);

            hash = strjoin(unique({measData(currentLocationIndexes).UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

            if ~isempty(hashIndex)
                obj.listOfLocations(hashIndex) = [];
            end
        end

        %-----------------------------------------------------------------%
        function hashIndex = addManualLocations(obj, measData, locations)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);
            
            if ~isempty(hashIndex)
                obj.listOfLocations(hashIndex).Manual = locations;
            end
        end

        %-----------------------------------------------------------------%
        function fullListOfLocation = getFullListOfLocation(obj, measData, stationTable, dist)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

            if isempty(hashIndex)
                hashIndex = addAutomaticLocations(obj, measData, stationTable, dist);
            end
            
            fullListOfLocation = sort(union(...
                obj.listOfLocations(hashIndex).Automatic, ...
                obj.listOfLocations(hashIndex).Manual ...
            ));
        end

        %-----------------------------------------------------------------%
        function manualLocations = getCurrentManualLocations(obj, measData)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

            if ~isempty(hashIndex)
                manualLocations = obj.listOfLocations(hashIndex).Manual;
            else
                manualLocations = {};
            end
        end
    end
end