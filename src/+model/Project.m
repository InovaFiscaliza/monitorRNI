classdef Project < model.ProjectCommon

    % ## model.Project (monitorRNI) ##      
    % PUBLIC
    %   ├── Project
    %   |   |── restart
    %   |   └── model.ProjectBase.initializeCustomTable
    %   ├── restart
    %   │   └── contextInitialization
    %   ├── checkIfUpdateNeeded
    %   │   └── model.ProjectBase.computeProjectHash
    %   ├── save
    %   │   └── model.ProjectBase.computeProjectHash
    %   ├── load
    %   │   └── restart
    %   ├── validateAuditorClassification
    %   ├── updateStationTable
    %   |   |── syncAnnotationTable
    %   |   └── updateAnalysis
    %   ├── updatePointsTable
    %   |   |── syncAnnotationTable
    %   |   └── updateAnalysis
    %   ├── syncAnnotationTable
    %   ├── updateAnalysis
    %   |   |── updateStationTableAnalysis
    %   |   |── updatePointsTableAnalysis
    %   |   └── restart
    %   ├── updateSelectedListOfLocations
    %   ├── addAutomaticLocations
    %   ├── delLocationCache
    %   ├── addManualLocations
    %   ├── getFullListOfLocation
    %   |   └── addAutomaticLocations
    %   └── getCurrentManualLocations
    % PRIVATE
    %   ├── contextInitialization
    %   │   └── initialization (SuperClass)
    %   ├── updateStationTableAnalysis
    %   |   └── getFullListOfLocation
    %   └── updatePointsTableAnalysis


    methods
        %-----------------------------------------------------------------%
        function obj = Project(mainApp, rootFolder, generalSettings)
            obj@model.ProjectCommon(mainApp, rootFolder);
            
            restart(obj, {'MONITORINGPLAN', 'EXTERNALREQUEST'}, 'AppStarted', generalSettings)

            % Inicialização de tabelas de suporte:
            [stationTable, ...
             referenceData] = model.ProjectBase.initializeCustomTable('STATIONS', class.Constants.appName, rootFolder, generalSettings);
            pointsTable     = model.ProjectBase.initializeCustomTable('POINTS', generalSettings);
            annotationTable = model.ProjectBase.initializeCustomTable('ANNOTATION');
            
            % Relacionados ao contexto "MONITORINGPLAN":
            obj.modules.MONITORINGPLAN.stationTable_I   = stationTable;
            obj.modules.MONITORINGPLAN.stationTable     = stationTable;
            obj.modules.MONITORINGPLAN.referenceData    = referenceData;
            obj.modules.MONITORINGPLAN.annotationTable  = annotationTable;

            % Relacionados ao contexto "EXTERNALREQUEST":
            obj.modules.EXTERNALREQUEST.pointsTable_I   = pointsTable;
            obj.modules.EXTERNALREQUEST.pointsTable     = pointsTable;
            obj.modules.EXTERNALREQUEST.annotationTable = annotationTable;
        end

        %-----------------------------------------------------------------%
        % ## LIFECYCLE MANAGEMENT ##
        %-----------------------------------------------------------------%
        function restart(obj, contextList, operationType, generalSettings)
            contextInitialization(obj, contextList, operationType, generalSettings)
        end

        %-----------------------------------------------------------------%
        function updateNeeded = checkIfUpdateNeeded(obj, EMFieldObj)
            updateNeeded = false;
            
            if ~isempty(obj.name)
                currentPrjHash = model.ProjectBase.computeProjectHash(obj.name, obj.file, EMFieldObj, obj.issueDetails, obj.entityDetails);
                updateNeeded   = ~isequal(obj.hash, currentPrjHash);
            end
        end

        %-----------------------------------------------------------------%
        function save(obj, context, prjName, prjFile, outputFileCompressionMode, EMFieldObj)
            arguments
                obj
                context (1,:) char {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                prjName
                prjFile
                outputFileCompressionMode
                EMFieldObj
            end

            source    = class.Constants.appName;
            type      = 'ProjectData';
            version   = 1;
            userData  = [];

            prjHash   = model.ProjectBase.computeProjectHash(prjName, prjFile, obj.modules, obj.issueDetails, obj.entityDetails, EMFieldObj);
            variables = struct( ...
                'name',    prjName, ...
                'hash',    prjHash, ...
                'modules', obj.modules, ...
                'issueDetails', obj.issueDetails, ...
                'entityDetails', obj.entityDetails, ...
                'EMFieldObj', EMFieldObj ...
            );

            compressionMode = {};
            if strcmp(outputFileCompressionMode, 'Não')
                compressionMode = {'-nocompression'};
            end

            save(prjFile, 'source', 'type', 'version', 'variables', 'userData', '-mat', '-v7', compressionMode{:})

            obj.name = prjName;
            obj.file = prjFile;
            obj.hash = prjHash;
        end

        %-----------------------------------------------------------------%
        function [EMFieldObj, msg] = load(obj, context, fileName, generalSettings, EMFieldObj)
            arguments
                obj
                context (1,:) char {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                fileName
                generalSettings
                EMFieldObj
            end

            try
                required = {'source', 'version', 'variables'};
                varsInFile = who('-file', fileName);
                if any(~ismember(required, varsInFile))
                    missing = setdiff(required, varsInFile);
                    error('Missing required variables: %s', strjoin(missing, ', '))
                end
                
                prjData = load(fileName, '-mat', required{:});
                
                if ~strcmp(class.Constants.appName, prjData.source)
                    error('File generated by a different application. Expected: %s. Found: %s.', class.Constants.appName, prjData.source)
                end
    
                switch prjData.version
                    case 1
                        restart(obj)

                        obj.name = prjData.variables.name;
                        obj.file = fileName;
                        obj.hash = prjData.variables.hash;

                        contextList = {'MONITORINGPLAN', 'EXTERNALREQUEST'};
                        for ii = 1:numel(contextList)
                            context = contextList{ii};

                            if isfile(prjData.variables.modules.(context).generatedFiles.lastZIPFullPath)
                                try
                                    unzipFiles = unzip(prjData.variables.modules.(context).generatedFiles.lastZIPFullPath, generalSettings.fileFolder.tempPath);
                                    for jj = 1:numel(unzipFiles)
                                        [~, ~, unzipFileExt] = fileparts(unzipFiles{jj});
    
                                        switch lower(unzipFileExt)
                                            case '.html'
                                                obj.modules.(context).generatedFiles.lastHTMLDocFullPath = unzipFiles{jj};
                                            case '.json'
                                                obj.modules.(context).generatedFiles.lastJSONFullPath    = unzipFiles{jj};
                                            case '.xlsx'
                                                obj.modules.(context).generatedFiles.lastTableFullPath   = unzipFiles{jj};
                                            case '.teams'
                                                obj.modules.(context).generatedFiles.lastTEAMSFullPath   = unzipFiles{jj};
                                        end
                                    end
                                    
                                    obj.modules.(context).generatedFiles.id              = prjData.variables.modules.(context).generatedFiles.id;
                                    obj.modules.(context).generatedFiles.lastZIPFullPath = prjData.variables.modules.(context).generatedFiles.lastZIPFullPath;
                                catch 
                                end
                            end
    
                            obj.modules.(context).ui.system = prjData.variables.modules.(context).ui.system;
                            obj.modules.(context).ui.unit   = prjData.variables.modules.(context).ui.unit;
                            obj.modules.(context).ui.issue  = prjData.variables.modules.(context).ui.issue;
                            obj.modules.(context).ui.entity = prjData.variables.modules.(context).ui.entity;
        
                            reportModel = prjData.variables.modules.(context).ui.reportModel;
                            if ismember(reportModel, obj.modules.(context).ui.templates)
                                obj.modules.(context).ui.reportModel = reportModel;
                            end
    
                            obj.modules.(context).uploadedFiles = [prjData.variables.modules.(context).uploadedFiles, obj.modules.(context).uploadedFiles];
                            [~, uniqueUploadedFilesIndexes] = unique({obj.modules.(context).uploadedFiles.hash});
                            obj.modules.(context).uploadedFiles = obj.modules.(context).uploadedFiles(uniqueUploadedFilesIndexes);
                        end

                        obj.issueDetails = [prjData.variables.issueDetails, obj.issueDetails];                        
                        
                        obj.entityDetails = [prjData.variables.entityDetails, obj.entityDetails];                        
                        [~, uniqueDetailsIndexes] = unique({obj.entityDetails.id});
                        obj.entityDetails = obj.entityDetails(uniqueDetailsIndexes);

                        % Pode ocorrer uma coincidência de fluxos que compõem
                        % o projeto e fluxos já lidos. Se evidenciado, serão
                        % mantidos os fluxos do projeto.
                        idx = ismember({EMFieldObj.Hash}, {prjData.variables.EMFieldObj.Hash});
                        if any(idx)
                            delete(EMFieldObj(idx))
                            EMFieldObj(idx) = [];
                        end
    
                        EMFieldObj = [EMFieldObj, prjData.variables.EMFieldObj];
    
                    otherwise
                        error('UnexpectedVersion')
                end
                msg = '';

            catch ME
                msg = ME.message;
            end
        end

        %-----------------------------------------------------------------%
        % ## VALIDATION ##
        %-----------------------------------------------------------------%
        function [invalidRowIndexes, ruleViolationMatrix, ruleColumns, manualEditionRowIndexes, riskMeasurementsIndexes] = validateAuditorClassification(obj, context, generalSettings, varargin)
            % Função que valida a consistência e o preenchimento de dados da
            % tabela "stationTable" e "pointsTable".

            switch context
                case 'MONITORINGPLAN'
                    REASONS_REQUIRING_COMMENT         = generalSettings.context.MONITORINGPLAN.reasonsRequiringComment;
                    REASONS_REQUIRING_LOCATION_UPDATE = generalSettings.context.MONITORINGPLAN.reasonsRequiringLocationUpdate;

                    % #01 "Justificativa" deve estar preenchido (≠ "-") se "numberOfMeasures" igual a zero.
                    % #02 "Observações" deve estar preenchido caso "Justificativa" seja um dos itens listados em generalSettings.context.MONITORINGPLAN.reasonsRequiringComment.
                    % #03 "Latitude" ou "Longitude" deve ser editado caso "Justificativa" seja um dos itens listados em generalSettings.context.MONITORINGPLAN.reasonsRequiringLocationUpdate.        
                    ruleColumns = {                                ...
                        {'Justificativa', 'numberOfMeasures'},     ... #01
                        {'Justificativa', 'Observações'},          ... #02
                        {'Justificativa', 'Latitude', 'Longitude'} ... #03
                    };
                    
                    stationIdxs = varargin{1};       
                    currentPointsTable = obj.modules.MONITORINGPLAN.stationTable(stationIdxs, :);
        
                    % "Registros anotados" por meio da inclusão de uma observação 
                    % ou da edição das coordenadas geográficas da estação.
                    addedObservationLogical   = cellfun(@(x) ~isempty(x), currentPointsTable.("Observações"));
                    editedLocationLogical     = (currentPointsTable.("Lat") ~= currentPointsTable.("Latitude")) | (currentPointsTable.("Long") ~= currentPointsTable.("Longitude"));
        
                    % Registros ainda pendentes de edição por infringir alguma
                    % das regras de validação.
                    ruleViolationMatrix       = zeros(height(currentPointsTable), numel(ruleColumns), 'logical');
                    ruleViolationMatrix(:, 1) = (currentPointsTable.numberOfMeasures == 0) & (currentPointsTable.("Justificativa") == "-");
                    ruleViolationMatrix(:, 2) = ismember(currentPointsTable.("Justificativa"), REASONS_REQUIRING_COMMENT) & ~addedObservationLogical;
                    ruleViolationMatrix(:, 3) = ismember(currentPointsTable.("Justificativa"), REASONS_REQUIRING_LOCATION_UPDATE) & ~editedLocationLogical;

                    invalidRowIndexes         = find(any(ruleViolationMatrix, 2));
                    manualEditionRowIndexes   = find(addedObservationLogical | editedLocationLogical);
                    riskMeasurementsIndexes   = find(currentPointsTable.numberOfRiskMeasures > 0);

                case 'EXTERNALREQUEST'
                    % #01 "Justificativa" deve estar preenchido (≠ "-") se "numberOfMeasures" igual a zero.
                    ruleColumns = { ...
                        {'Justificativa', 'numberOfMeasures'} ... #01
                    };
                    
                    initialPointsTable        = obj.modules.EXTERNALREQUEST.pointsTable_I;
                    currentPointsTable        = obj.modules.EXTERNALREQUEST.pointsTable;
        
                    % "Registros anotados" por meio da inclusão de uma observação 
                    % ou da edição das coordenadas geográficas da estação.
                    addedObservationLogical   = cellfun(@(x) ~isempty(x), currentPointsTable.("Observações"));
                    editedLocationLogical     = (initialPointsTable.("Latitude") ~= currentPointsTable.("Latitude")) | (initialPointsTable.("Longitude") ~= currentPointsTable.("Longitude"));
        
                    % Registros ainda pendentes de edição por infringir alguma
                    % das regras de validação.
                    ruleViolationMatrix       = zeros(height(currentPointsTable), numel(ruleColumns), 'logical');
                    ruleViolationMatrix(:, 1) = (currentPointsTable.numberOfMeasures == 0) & (currentPointsTable.("Justificativa") == "-");

                    invalidRowIndexes         = find(any(ruleViolationMatrix, 2));
                    manualEditionRowIndexes   = find(addedObservationLogical | editedLocationLogical);
                    riskMeasurementsIndexes   = find(currentPointsTable.numberOfRiskMeasures > 0);
            end
        end

        %-----------------------------------------------------------------%
        % ## UPDATE ##
        %-----------------------------------------------------------------%
        function updateStationTable(obj, eventName, varargin)
            switch eventName
                case 'onStationInfoChanged'
                    index = varargin{1};
                    reason = varargin{2};
                    observation = varargin{3};

                    obj.modules.MONITORINGPLAN.stationTable.("Justificativa")(index)   = reason;
                    if ~iscell(observation)
                        obj.modules.MONITORINGPLAN.stationTable.("Observações"){index} = observation;
                    end
                    syncAnnotationTable(obj, 'MONITORINGPLAN', index)

                case 'onStationCoordinatesEdited'
                    index = varargin{1};
                    latitude = varargin{2};
                    longitude = varargin{3};
                    
                    obj.modules.MONITORINGPLAN.stationTable.("Latitude")(index)     = latitude;
                    obj.modules.MONITORINGPLAN.stationTable.("Longitude")(index)    = longitude;
                    obj.modules.MONITORINGPLAN.stationTable.("AnalysisFlag")(index) = false;
                    syncAnnotationTable(obj, 'MONITORINGPLAN', index)

                    EMFieldObj = varargin{4};
                    generalSettings = varargin{5};
                    updateAnalysis(obj, EMFieldObj, generalSettings, eventName, 'MONITORINGPLAN')
            end
        end

        %-----------------------------------------------------------------%
        function updatePointsTable(obj, EMFieldObj, generalSettings, eventName, varargin)
            forceUpdate = true;

            switch eventName
                case 'onPointInfoChanged'
                    forceUpdate = false;

                    index = varargin{1};
                    value = varargin{2};
                    obj.modules.EXTERNALREQUEST.pointsTable_I.("Justificativa")(index) = value;
                    obj.modules.EXTERNALREQUEST.pointsTable.("Justificativa")(index)   = value;
                    
                    syncAnnotationTable(obj, 'EXTERNALREQUEST', index)

                case 'onPointAdded'
                    valuesToFill = varargin{1};
                    columsnToFill = {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'Justificativa', 'Observações', 'AnalysisFlag'};
                    
                    index = height(obj.modules.EXTERNALREQUEST.pointsTable_I)+1;
                    obj.modules.EXTERNALREQUEST.pointsTable_I(index, columsnToFill) = valuesToFill;
                    obj.modules.EXTERNALREQUEST.pointsTable_I = model.ProjectBase.computeHashColumn(obj.modules.EXTERNALREQUEST.pointsTable_I, 'POINTS');

                    obj.modules.EXTERNALREQUEST.pointsTable(index, :) = obj.modules.EXTERNALREQUEST.pointsTable_I(index, :);

                case 'onPointRemoved'
                    index = varargin{1};
                    obj.modules.EXTERNALREQUEST.pointsTable_I(index, :) = [];
                    obj.modules.EXTERNALREQUEST.pointsTable(index, :)   = [];
            end
            
            if forceUpdate
                updateAnalysis(obj, EMFieldObj, generalSettings, eventName, 'EXTERNALREQUEST');
            end
        end

        %-----------------------------------------------------------------%
        function syncAnnotationTable(obj, context, index)
            switch context
                case 'MONITORINGPLAN'
                    referenceTable = obj.modules.MONITORINGPLAN.stationTable(index, {'Hash', 'Latitude', 'Longitude', 'Justificativa', 'Observações'});
                case 'EXTERNALREQUEST'
                    referenceTable = obj.modules.EXTERNALREQUEST.pointsTable(index, {'Hash', 'Latitude', 'Longitude', 'Justificativa', 'Observações'});
            end

            annotationTable = obj.modules.(context).annotationTable;
            
            [~, hashIndex] = ismember(referenceTable.Hash, annotationTable.Hash);
            if ~hashIndex
                hashIndex = height(annotationTable)+1;
            end

            obj.modules.(context).annotationTable(hashIndex, :) = referenceTable;
        end

        %-----------------------------------------------------------------%
        function updateAnalysis(obj, EMFieldObj, generalSettings, eventName, varargin)
            arguments
                obj
                EMFieldObj
                generalSettings
                eventName char {mustBeMember(eventName, {'onFileListAdded',            ... % winMonitorRNI >> model.Project
                                                         'onFileListRemoved',          ... % winMonitorRNI >> model.Project
                                                         'onAnalysisParameterChanged', ... % auxApp.winConfig >> winMonitorRNI >> auxApp.winMonitoringPlan | auxApp.winExternalRequest >> model.Project
                                                         'onLocationListModeChanged',  ... % auxApp.dockListOfLocation >> winMonitorRNI >> auxApp.winMonitoringPlan >> model.Project
                                                         'onStationCoordinatesEdited', ... % auxApp.dockStationInfo    >> winMonitorRNI >> auxApp.winMonitoringPlan >> model.Project
                                                         'onPointAdded',               ... % auxApp.winExternalRequest >> model.Project
                                                         'onPointRemoved'})}               % auxApp.winExternalRequest >> model.Project
            end

            arguments (Repeating)
                varargin
            end

            if ~isempty(EMFieldObj)
                measTable = buildMeasurementTable(EMFieldObj);

                switch eventName
                    case {'onFileListAdded', 'onFileListRemoved'}
                        updateStationTableAnalysis(obj, EMFieldObj, measTable, generalSettings)
                        updatePointsTableAnalysis(obj, measTable, generalSettings)
    
                    case {'onAnalysisParameterChanged', ...
                          'onLocationListModeChanged',  ...
                          'onStationCoordinatesEdited', ...
                          'onPointAdded', 'onPointRemoved'}
                        context = varargin{1};
                        
                        switch context
                            case 'MONITORINGPLAN'
                                updateStationTableAnalysis(obj, EMFieldObj, measTable, generalSettings)
                            case 'EXTERNALREQUEST'
                                updatePointsTableAnalysis(obj, measTable, generalSettings)
                        end
                end

            else
                restart(obj, {'MONITORINGPLAN', 'EXTERNALREQUEST'}, 'EMFieldDataEmpty', generalSettings)
            end
        end

        %-----------------------------------------------------------------%
        function updateSelectedListOfLocations(obj, location, context)
            arguments
                obj
                location (1,:) char
                context  (1,:) char {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})} = 'MONITORINGPLAN'
            end

            obj.modules.(context).ui.selectedGroup = location;
        end


        %-----------------------------------------------------------------%
        % AUXAPP.WINMONITORINGPLAN
        %-----------------------------------------------------------------%
        function uuidIndex = addAutomaticLocations(obj, EMFieldObj, stationTable, dist)
            uuidList  = strjoin(unique({EMFieldObj.UUID}));
            uuidIndex = find(strcmp({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, uuidList), 1);

            if isempty(uuidIndex)
                automaticLocations = {};
                for ii = 1:numel(EMFieldObj)
                    % Limites de latitude e longitude relacionados à rota, acrescentando 
                    % a distância máxima à estação p/ fins de cômputo de medidas válidas 
                    % no entorno de uma estação.
                    [maxLatitude, maxLongitude] = reckon(EMFieldObj(ii).LatitudeLimits(2), EMFieldObj(ii).LongitudeLimits(2), km2deg(dist), 45);
                    [minLatitude, minLongitude] = reckon(EMFieldObj(ii).LatitudeLimits(1), EMFieldObj(ii).LongitudeLimits(1), km2deg(dist), 225);
        
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
                if numel(unique({EMFieldObj.Location_I})) > 1
                    rawHashIndexes  = ismember({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, {EMFieldObj.UUID});
                    if any(rawHashIndexes)
                        manualLocations = vertcat(obj.modules.MONITORINGPLAN.ui.groupMapping(rawHashIndexes).manual);
                    end
                end

                uuidIndex = numel(obj.modules.MONITORINGPLAN.ui.groupMapping) + 1;
                obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex) = struct('hash', uuidList, 'auto', {unique(automaticLocations)}, 'manual', {unique(manualLocations)});
            end
        end

        %-----------------------------------------------------------------%
        function delLocationCache(obj, EMFieldObj, indexes)
            currentLocation = unique({EMFieldObj(indexes).Location});
            currentLocationIndexes = ismember({EMFieldObj.Location}, currentLocation);

            uuidList  = strjoin(unique({EMFieldObj(currentLocationIndexes).UUID}));
            uuidIndex = find(strcmp({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, uuidList), 1);

            if ~isempty(uuidIndex)
                obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex) = [];
            end
        end

        %-----------------------------------------------------------------%
        function uuidIndex = addManualLocations(obj, EMFieldObj, locations)
            uuidList  = strjoin(unique({EMFieldObj.UUID}));
            uuidIndex = find(strcmp({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, uuidList), 1);
            
            if ~isempty(uuidIndex)
                obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex).manual = locations;
            end
        end

        %-----------------------------------------------------------------%
        function locations = getFullListOfLocation(obj, EMFieldObj, dist)
            locationList = {EMFieldObj.Location};
            groupLocationList = unique(locationList);
            
            locations = {};
            for ii = 1:numel(groupLocationList)
                groupLocation   = groupLocationList{ii};
                locationIndexes = strcmp(locationList, groupLocation);

                uuidList  = strjoin(unique({EMFieldObj(locationIndexes).UUID}));
                uuidIndex = find(strcmp({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, uuidList), 1);
    
                if isempty(uuidIndex)
                    uuidIndex = addAutomaticLocations(obj, EMFieldObj(locationIndexes), obj.modules.MONITORINGPLAN.stationTable, dist);
                end

                locations = union(locations, union(obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex).auto, obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex).manual));
            end

            locations = unique(locations);
        end

        %-----------------------------------------------------------------%
        function manualLocations = getCurrentManualLocations(obj, EMFieldObj)
            uuidList  = strjoin(unique({EMFieldObj.UUID}));
            uuidIndex = find(strcmp({obj.modules.MONITORINGPLAN.ui.groupMapping.hash}, uuidList), 1);

            if ~isempty(uuidIndex)
                manualLocations = obj.modules.MONITORINGPLAN.ui.groupMapping(uuidIndex).manual;
            else
                manualLocations = {};
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function contextInitialization(obj, contextList, operationType, generalSettings)
            arguments
                obj
                contextList
                operationType {mustBeMember(operationType, {'AppStarted', 'onProjectRestart', 'EMFieldDataEmpty'})}
                generalSettings
            end

            switch operationType
                case 'AppStarted'
                    initialization(obj, contextList, generalSettings)
        
                    for ii = 1:numel(contextList)
                        context = contextList{ii};
                        obj.modules.(context).ui.selectedGroup = '';
                        
                        obj.modules.(context).analysis = struct( ...
                            'maxMeasurementDistanceKm', [], ...
                            'numMeasurements', [], ...
                            'threshold', [], ...
                            'numMeasurementsAboveThreshold', [] ...
                        );
        
                        switch context
                            case 'MONITORINGPLAN'
                                obj.modules.MONITORINGPLAN.stationTable    = [];
                                obj.modules.MONITORINGPLAN.stationTable_I  = [];
                                obj.modules.MONITORINGPLAN.referenceData   = struct('years', [], 'locations', {{}}, 'states', {{}});
                                obj.modules.MONITORINGPLAN.ui.groupMapping = struct('hash', {}, 'auto', {}, 'manual', {});
                            case 'EXTERNALREQUEST'
                                obj.modules.EXTERNALREQUEST.pointsTable    = [];
                                obj.modules.EXTERNALREQUEST.pointsTable_I  = [];
                        end
                    end

                case 'onProjectRestart'
                    for ii = 1:numel(contextList)
                        context = contextList{ii};

                        uploadedFiles = obj.modules.(context).uploadedFiles;
                        
                        switch context
                            case 'MONITORINGPLAN'
                                stationTable_I = obj.modules.MONITORINGPLAN.stationTable_I;
                                referenceData  = obj.modules.MONITORINGPLAN.referenceData;
                            case 'EXTERNALREQUEST'
                                pointsTable_I  = obj.modules.EXTERNALREQUEST.pointsTable_I;
                        end

                        contextInitialization(obj, {context}, 'AppStarted', generalSettings)
                        
                        obj.modules.(context).uploadedFiles = uploadedFiles;

                        switch context
                            case 'MONITORINGPLAN'
                                obj.modules.MONITORINGPLAN.stationTable    = stationTable_I;
                                obj.modules.MONITORINGPLAN.stationTable_I  = stationTable_I;
                                obj.modules.MONITORINGPLAN.referenceData   = referenceData;
                            case 'EXTERNALREQUEST'
                                obj.modules.EXTERNALREQUEST.pointsTable    = pointsTable_I;
                                obj.modules.EXTERNALREQUEST.pointsTable_I  = pointsTable_I;
                        end
                    end

                case 'EMFieldDataEmpty'
                    prjName = obj.name;
                    prjFile = obj.file;
                    prjHash = obj.hash;

                    for ii = 1:numel(contextList)
                        context = contextList{ii};

                        annotationTable = obj.modules.(context).annotationTable;
                        uploadedFiles = obj.modules.(context).uploadedFiles;
                        ui = obj.modules.(context).ui;
                        ui.SelectedGroup = '';

                        switch context
                            case 'MONITORINGPLAN'
                                stationTable_I = obj.modules.MONITORINGPLAN.stationTable_I;
                                referenceData  = obj.modules.MONITORINGPLAN.referenceData;
                            case 'EXTERNALREQUEST'
                                pointsTable_I  = obj.modules.EXTERNALREQUEST.pointsTable_I;
                        end

                        contextInitialization(obj, {context}, 'AppStarted', generalSettings)
                        
                        obj.modules.(context).annotationTable = annotationTable;
                        obj.modules.(context).uploadedFiles = uploadedFiles;
                        obj.modules.(context).ui = ui;

                        switch context
                            case 'MONITORINGPLAN'
                                obj.modules.MONITORINGPLAN.stationTable    = stationTable_I;
                                obj.modules.MONITORINGPLAN.stationTable_I  = stationTable_I;
                                obj.modules.MONITORINGPLAN.referenceData   = referenceData;
                            case 'EXTERNALREQUEST'
                                obj.modules.EXTERNALREQUEST.pointsTable    = pointsTable_I;
                                obj.modules.EXTERNALREQUEST.pointsTable_I  = pointsTable_I;
                        end
                    end

                    obj.name = prjName;
                    obj.file = prjFile;
                    obj.hash = prjHash;
            end
        end

        %-----------------------------------------------------------------%
        function updateStationTableAnalysis(obj, EMFieldObj, measTable, generalSettings)
            MAX_MEAS_DISTANCE_KM = generalSettings.context.MONITORINGPLAN.maxMeasurementDistanceKm;
            EFIELD_THRESHOLD = generalSettings.context.MONITORINGPLAN.electricFieldStrengthThreshold;

            stationTable    = obj.modules.MONITORINGPLAN.stationTable_I;
            annotationTable = obj.modules.MONITORINGPLAN.annotationTable;

            if ~isempty(annotationTable)
                [~, stationIdxs] = ismember(annotationTable.Hash, stationTable.Hash);
                variableNames = setdiff(annotationTable.Properties.VariableNames, 'Hash', 'stable');

                stationTable(stationIdxs, variableNames) = annotationTable(:, variableNames);
            end

            stationIndexes = find(ismember(stationTable.Location, getFullListOfLocation(obj, EMFieldObj, MAX_MEAS_DISTANCE_KM)))';
            stationTable = model.ProjectBase.identifyMeasuresForEachPoint(stationTable, stationIndexes, measTable, EFIELD_THRESHOLD, MAX_MEAS_DISTANCE_KM);

            obj.modules.MONITORINGPLAN.stationTable = stationTable;
            obj.modules.MONITORINGPLAN.analysis.maxMeasurementDistanceKm = MAX_MEAS_DISTANCE_KM;
            obj.modules.MONITORINGPLAN.analysis.numMeasurements = height(measTable);
            obj.modules.MONITORINGPLAN.analysis.threshold = EFIELD_THRESHOLD;
            obj.modules.MONITORINGPLAN.analysis.numMeasurementsAboveThreshold = sum(measTable.FieldValue > EFIELD_THRESHOLD);            
        end

        %-----------------------------------------------------------------%
        function updatePointsTableAnalysis(obj, measTable, generalSettings)
            MAX_MEAS_DISTANCE_KM = generalSettings.context.EXTERNALREQUEST.maxMeasurementDistanceKm;
            EFIELD_THRESHOLD = generalSettings.context.EXTERNALREQUEST.electricFieldStrengthThreshold;

            pointsTable     = obj.modules.EXTERNALREQUEST.pointsTable_I;
            annotationTable = obj.modules.EXTERNALREQUEST.annotationTable;

            if ~isempty(annotationTable)
                pointIdxs     = (1:height(pointsTable))';
                [~, mapIdxs]  = ismember(pointsTable.Hash, annotationTable.Hash);
                validMapIdxs  = mapIdxs ~= 0;
                variableNames = setdiff(annotationTable.Properties.VariableNames, 'Hash', 'stable');

                pointsTable(pointIdxs(validMapIdxs), variableNames) = annotationTable(mapIdxs(validMapIdxs), variableNames);
            end

            pointIndexes = 1:height(pointsTable);
            pointsTable  = model.ProjectBase.identifyMeasuresForEachPoint(pointsTable, pointIndexes, measTable, EFIELD_THRESHOLD, MAX_MEAS_DISTANCE_KM);
            
            obj.modules.EXTERNALREQUEST.pointsTable = pointsTable;
            obj.modules.EXTERNALREQUEST.analysis.maxMeasurementDistanceKm = MAX_MEAS_DISTANCE_KM;
            obj.modules.EXTERNALREQUEST.analysis.numMeasurements = height(measTable);
            obj.modules.EXTERNALREQUEST.analysis.threshold = EFIELD_THRESHOLD;
            obj.modules.EXTERNALREQUEST.analysis.numMeasurementsAboveThreshold = sum(measTable.FieldValue > EFIELD_THRESHOLD);            
        end
    end
end