classdef projectLib < dynamicprops

    properties
        %-----------------------------------------------------------------%
        name  (1,:) char   = ''
        file  (1,:) char   = ''
        issue (1,1) double = -1
        unit  (1,:) char   = ''

        documentType {mustBeMember(documentType, {'Relatório de Atividades', 'Relatório de Fiscalização', 'Informe'})} = 'Relatório de Atividades'
        documentModel      = ''
        documentScript     = []
        generatedFiles     = []
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        callingApp
        defaultFilePreffix = ''
        customProperties   = {}
    end


    methods
        %-----------------------------------------------------------------%
        function obj = projectLib(callingApp, varargin)            
            obj.callingApp = callingApp;

            obj.defaultFilePreffix = 'monitorRNI';
            obj.customProperties   = {'rawListOfYears', 'referenceListOfLocations', 'referenceListOfStates', 'selectedFileLocations', 'listOfLocations'};

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

            addprop(obj, 'rawListOfYears');
            addprop(obj, 'referenceListOfLocations');
            addprop(obj, 'referenceListOfStates');
            addprop(obj, 'selectedFileLocations');
            addprop(obj, 'listOfLocations');
            
            obj.selectedFileLocations = {};
            obj.listOfLocations = struct('Hash', {}, 'Automatic', {}, 'Manual', {});
        end

        %-----------------------------------------------------------------%
        function Restart(obj)
            obj.name           = '';
            obj.file           = '';
            obj.issue          = -1;
            obj.unit           = '';

            obj.documentType   = 'Relatório de Atividades';
            obj.documentModel  = '';
            obj.documentScript = [];
            obj.generatedFiles = [];

            customPropertiesList = obj.customProperties;
            for ii = 1:numel(customPropertiesList)
                propertyName = customPropertiesList{ii};

                switch class(obj.(propertyName))
                    case 'table'
                        obj.(propertyName)(:,:) = [];
                    case 'struct'
                        obj.(propertyName)(:)   = [];
                    case 'cell'
                        obj.(propertyName)      = {};
                    case 'char'
                        obj.(propertyName)      = '';
                    otherwise
                        obj.(propertyName)      = [];
                end
            end
        end
    end


    methods
        %-----------------------------------------------------------------%
        % AUXAPP.WINMONITORINGPLAN
        %-----------------------------------------------------------------%
        function updateSelectedListOfLocations(obj, locations)
            obj.selectedFileLocations = locations;
        end

        %-----------------------------------------------------------------%
        function hashIndex = addAutomaticLocations(obj, measData, stationTable, DIST_km)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

            if isempty(hashIndex)
                selectedLocations  = unique({measData.Location});                
                automaticLocations = {};
                manualLocations    = {};

                for ii = 1:numel(measData)
                    % Limites de latitude e longitude relacionados à rota, acrescentando 
                    % a distância máxima à estação p/ fins de cômputo de medidas válidas 
                    % no entorno de uma estação.
                    [maxLatitude, maxLongitude] = reckon(measData(ii).LatitudeLimits(2), measData(ii).LongitudeLimits(2), km2deg(DIST_km), 45);
                    [minLatitude, minLongitude] = reckon(measData(ii).LatitudeLimits(1), measData(ii).LongitudeLimits(1), km2deg(DIST_km), 225);
        
                    idxLogicalStation = stationTable.Latitude  >= minLatitude  & ...
                                        stationTable.Latitude  <= maxLatitude  & ...
                                        stationTable.Longitude >= minLongitude & ...
                                        stationTable.Longitude <= maxLongitude;
        
                    if any(idxLogicalStation)
                        automaticLocations = [automaticLocations; unique(stationTable.Location(idxLogicalStation))];
                    end

                    % Caso se trate de uma visualização de mais de uma localidade, 
                    % inicia-se a lista de municípios incluídos manualmente com
                    % aquilo que foi inserido para os municípios isoladamente, 
                    % caso aplicável.
                    if numel(selectedLocations) > 1
                        manualLocationsIndex = find(cellfun(@(x) isequal(x, {measData(ii).Location}), {obj.listOfLocations.Automatic}), 1);
                        if ~isempty(manualLocationsIndex)
                            manualLocations = [manualLocations, obj.listOfLocations(manualLocationsIndex).Manual];
                        end
                    end
                end

                obj.listOfLocations(end+1) = struct('Hash', hash, 'Automatic', {unique(automaticLocations)}, 'Manual', {unique(manualLocations)});
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
        function fullListOfLocation = getFullListOfLocation(obj, measData, stationTable, DIST_km)
            hash = strjoin(unique({measData.UUID}));
            hashIndex = find(strcmp({obj.listOfLocations.Hash}, hash), 1);

            if isempty(hashIndex)
                hashIndex = addAutomaticLocations(obj, measData, stationTable, DIST_km);
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