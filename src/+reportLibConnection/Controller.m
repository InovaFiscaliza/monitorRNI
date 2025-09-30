classdef (Abstract) Controller

    % Trata-se de classe abstrata, cujo método Run cria as variáveis requeridas
    % pelo biblioteca reportLib, de SupportPackages. São elas:
    % • reportInfo....: estrutura com os campos obrigatórios "App", "Version", 
    %   "Path", "Model" e "Function". Campos opcionais podem ser criados.

    % • dataOverview..: lista de estruturas com os campos obrigatórios "ID", 
    %   "InfoSet" e "HTML". Em "InfoSet", armazena-se um handle para instância 
    %   da classe model.ECD. As instância desse classe são agrupadas por 
    %   LOCALIDADE e ordenadas pelo início da monitoração.

    % • analyzedData..: instância de dataOverview (imaginando que dataOverview 
    %   é a variável que possibilita a recorrência).

    % Quando o objeto criado é uma IMAGEM, tem-se:
    % • imgSettings.: campo extraído do script .JSON que norteia a criação
    %   do relatório, o qual é uma estrutura com os campos "Origin", "Source", 
    %   "Caption", "Settings", "Intro", "Error" e "LineBreak".
    
    % Quando o objeto criado uma TABELA, tem-se:
    % • tableSettings.: campo extraído do script .JSON que norteia a criação
    %   do relatório, o qual é uma estrutura com os campos "Origin", "Source", 
    %   "Columns", "Caption", "Settings", "Intro", "Error" e "LineBreak".

    properties (Constant)
        %-----------------------------------------------------------------%
        docVersion = dictionary(["Preliminar", "Definitiva"], ...
            [struct('version', 'preview', 'encoding', 'UTF-8'), struct('version', 'final', 'encoding', 'ISO-8859-1')])
    end

    methods (Static)
        %-----------------------------------------------------------------%
        function Run(callingApp, projectData, measData, reportSettings, generalSettings)
            arguments
                callingApp
                projectData
                measData
                reportSettings
                generalSettings
            end

            switch class(callingApp)
                case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported'}
                    app = callingApp.mainApp;
                    context = 'MonitoringPlan';
                case {'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported'}
                    app = callingApp.mainApp;
                    context = 'ExternalRequest';
                otherwise
                    error('UnexpectedCaller')
            end

            [projectFolder, ...
             programDataFolder] = appUtil.Path(class.Constants.appName, app.rootFolder);

            issueId    = num2str(reportSettings.issue);
            docName    = reportSettings.model;
            docIndex   = find(strcmp({projectData.report.templates.Name}, docName), 1);
            if isempty(docIndex)
                error('Pendente escolha do modelo de relatório')
            end

            docType    = projectData.report.templates(docIndex).DocumentType;
            docVersion = reportLibConnection.Controller.docVersion(reportSettings.reportVersion);

            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                docScript = jsondecode(fileread(fullfile(programDataFolder, 'ReportTemplates', projectData.report.templates(docIndex).File)));
            catch
                docScript = jsondecode(fileread(fullfile(projectFolder,     'ReportTemplates', projectData.report.templates(docIndex).File)));
            end

            stationTableGlobal = projectData.modules.MonitoringPlan.stationTable;
            pointsTableGlobal  = projectData.modules.ExternalRequest.pointsTable;
            pointsTableGlobal  = model.projectLib.prepareStationTableForExport(pointsTableGlobal, 'pointsTable', '-');
        
            
            %-------------------------------------------------------------%
            % reportInfo
            %
            % Importante observar que o campo "Function" armazena informações
            % gerais, a compor itens "Introdução", "Metodologia" e "Conclusão",
            % e informações específicas, a compor itens com recorrências, como 
            % "Resultados".
            %-------------------------------------------------------------%
            reportInfo = struct('App',      app, ...
                                'Version',  app.General.AppVersion,                                                   ...
                                'Path',     struct('rootFolder',                 app.rootFolder,                      ...
                                                   'userFolder',                 generalSettings.fileFolder.userPath, ...
                                                   'tempFolder',                 generalSettings.fileFolder.tempPath, ...
                                                   'appConnection',              projectFolder,                       ...
                                                   'appDataFolder',              programDataFolder),                  ...
                                'Model',    struct('Name',                       docName,                             ...
                                                   'DocumentType',               docType,                             ...
                                                   'Script',                     docScript,                           ...
                                                   'Version',                    docVersion.version),                 ...
                                'Function', struct(... 
                                                   ... % APLICÁVEIS ÀS SEÇÕES GERAIS DO RELATÓRIO
                                                   'cfg_Context',                jsonencode(generalSettings.(context)), ...
                                                   'cfg_DataBinning',            jsonencode(generalSettings.Report.DataBinning), ...
                                                   'cfg_ReportTemplate',         jsonencode(struct('Name', docName, 'DocumentType', docType, 'Version', docVersion.version)), ...
                                                   'var_Issue',                  issueId, ...
                                                   'var_Unit',                   reportSettings.unit, ...
                                                   'var_LocationListGlobal',    'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationListGlobal")', ...
                                                   'var_LocationSummaryGlobal', 'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationSummaryGlobal")', ...
                                                   'var_MeasurementsGlobal',     projectData.modules.(context).numMeasurements, ...
                                                   'var_ThresholdGlobal',        projectData.modules.(context).threshold, ...
                                                   'var_NumAboveTHRGlobal',     'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "NumAboveTHRGlobal")', ...
                                                   'var_DistanceKmGlobal',       projectData.modules.(context).distance_km, ...
                                                   'tbl_StationTable',           stationTableGlobal, ...
                                                   'tbl_PointsTable',            pointsTableGlobal, ...
                                                   'tbl_FileByLocation',        'reportLibConnection.Table.FileByLocation(dataOverview)', ...
                                                   'tbl_SummaryByLocation',     'reportLibConnection.Table.SummaryByLocation(analyzedData)', ...
                                                   ...
                                                   ... % APLICÁVEIS À SEÇÃO COM RECORRÊNCIA DO RELATÓRIO
                                                   ... % 'var_Index'
                                                   'var_Id',                    'analyzedData.ID', ...
                                                   'var_NumFiles',              'reportLibConnection.Variable.ClassProperty(analyzedData, "NumFiles")', ...
                                                   'var_FileName',              'reportLibConnection.Variable.ClassProperty(analyzedData, "Filename")', ...
                                                   'var_Sensor',                'reportLibConnection.Variable.ClassProperty(analyzedData, "Sensor")', ...
                                                   'var_Location',              'reportLibConnection.Variable.ClassProperty(analyzedData, "Location")', ...
                                                   'var_Location_I',            'reportLibConnection.Variable.ClassProperty(analyzedData, "Location_I")', ...
                                                   'var_LocationList',          'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationList")', ...
                                                   'var_LocationSummary',       'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationSummary")', ...
                                                   'var_Content',               'reportLibConnection.Variable.ClassProperty(analyzedData, "Content")', ...
                                                   'var_MetaData',              'reportLibConnection.Variable.ClassProperty(analyzedData, "MetaData")', ...
                                                   'var_Measures',              'reportLibConnection.Variable.ClassProperty(analyzedData, "Measures")', ...
                                                   'var_MeasuresRisk',          'reportLibConnection.Variable.ClassProperty(analyzedData, "MeasuresRisk")', ...
                                                   'var_CoveredDistance',       'reportLibConnection.Variable.ClassProperty(analyzedData, "CoveredDistance")', ...
                                                   'var_FieldValueLimits',      'reportLibConnection.Variable.ClassProperty(analyzedData, "FieldValueLimits")', ...
                                                   'var_ObservationTime',       'reportLibConnection.Variable.ClassProperty(analyzedData, "ObservationTime")', ...
                                                   'var_LatitudeLimits',        'reportLibConnection.Variable.ClassProperty(analyzedData, "LatitudeLimits")', ...
                                                   'var_LongitudeLimits',       'reportLibConnection.Variable.ClassProperty(analyzedData, "LongitudeLimits")', ...
                                                   'var_Latitude',              'reportLibConnection.Variable.ClassProperty(analyzedData, "Latitude")', ...
                                                   'var_Longitude',             'reportLibConnection.Variable.ClassProperty(analyzedData, "Longitude")', ...
                                                   'var_NumPoints',             'reportLibConnection.Variable.TableProperty(reportInfo, analyzedData, "PointsTableHeight")', ...
                                                   'var_NumStations',           'reportLibConnection.Variable.TableProperty(reportInfo, analyzedData, "StationTableHeight")', ...
                                                   'tbl_PointsByLocation',      'reportLibConnection.Table.PointsByLocation(analyzedData, tableOptArgs{:})', ...
                                                   'tbl_StationsByLocation',    'reportLibConnection.Table.StationsByLocation(analyzedData, tableOptArgs{:})', ...
                                                   'tbl_AboveTHR',              'analyzedData.InfoSet.aboveTHRTable', ...
                                                   'img_Plot',                  'reportLibConnection.Plot.Controller(reportInfo, analyzedData, imgSettings)'), ...
                                'Project',  projectData, ...
                                'Object',   measData, ...
                                'Settings', generalSettings);
            
            fieldsUnnecessary = {'rootFolder', 'entryPointFolder', 'tempSessionFolder', 'ctfRoot'};
            fieldsUnnecessary(cellfun(@(x) ~isfield(reportInfo.Version.application, x), fieldsUnnecessary)) = [];
            if ~isempty(fieldsUnnecessary)
                reportInfo.Version.application = rmfield(reportInfo.Version.application, fieldsUnnecessary);
            end


            %-------------------------------------------------------------%
            % dataOverview
            %
            % Caso dataOverview não seja escalar e exista um item no relatório
            % com recorrência, a própria lib cria a variável "var_Index", acessível 
            % em "reportInfo.Function.var_Index".
            %-------------------------------------------------------------%
            dataOverview = struct('ID', {}, 'InfoSet', {}, 'HTML', {});

            locationList = {measData.Location};
            groupLocationList = unique(locationList);

            for ii = 1:numel(groupLocationList)
                groupLocation   = groupLocationList{ii};

                locationIndexes = find(strcmp(locationList, groupLocation));
                [~, idSort]     = sort(arrayfun(@(x) x.Data.Timestamp(1), measData(locationIndexes)));
                locationIndexes = locationIndexes(idSort);

                fileList        = unique({measData(locationIndexes).Filename});

                switch context
                    case 'MonitoringPlan'
                        locations      = getFullListOfLocation(projectData, measData(locationIndexes), projectData.modules.MonitoringPlan.distance_km);                        
                        stationIndexes = ismember(stationTableGlobal.Location, locations);
                        
                        stationTable   = stationTableGlobal(stationIndexes, :);
                        pointsTable    = [];

                    case 'ExternalRequest'
                        locations      = unique({measData(locationIndexes).Location});
                        pointsIndexes  = [];
                        for jj = 1:height(pointsTableGlobal)
                            sourceFiles = jsondecode(pointsTableGlobal.("Fonte de dados"){jj});
                            if ~iscellstr(sourceFiles)
                                sourceFiles = cellstr(sourceFiles);
                            end
        
                            if any(ismember(sourceFiles, fileList))
                                pointsIndexes = [pointsIndexes, jj];
                            end
                        end

                        stationTable = [];
                        pointsTable  = pointsTableGlobal(pointsIndexes, :);
                end

                measTable = createMeasTable(measData(locationIndexes));
                [beginTime, endTime] = bounds(measTable.Timestamp);
                [minField, maxField] = bounds(measTable.FieldValue);
                durationTime = sum(arrayfun(@(x) x.Data.Timestamp(end) - x.Data.Timestamp(1), measData(locationIndexes)));

                aboveTHR = measTable.FieldValue > projectData.modules.(context).threshold;
                if any(aboveTHR)
                    rawTable  = timetable2table(measTable(aboveTHR, :));
                    rawTable  = rawTable(:, {'Timestamp', 'Latitude', 'Longitude', 'FieldValue'});
                    rawFilter = table({}, {}, struct('handle', {}, 'specification', {}), true(0, 1), 'VariableNames', {'type', 'subtype', 'roi', 'enable'});
                    [~, ~, aboveTHRTable] = RF.DataBinning.execute(rawTable, generalSettings.Report.DataBinning.length_m, generalSettings.Report.DataBinning.function, rawFilter, 'FieldValue');

                    numAboveTHR = [];
                    for file = fileList
                        idxFile = strcmp(measTable.FileSource, file);
                        numAboveTHR = [numAboveTHR, sum(measTable.FieldValue(idxFile) > projectData.modules.(context).threshold)];
                    end
                else
                    aboveTHRTable = table('Size', [0,4], 'VariableTypes', {'double', 'double', 'double', 'double'}, 'VariableNames', {'Latitude', 'Longitude', 'FieldValues', 'Measures'});
                    numAboveTHR   = zeros(1, numel(fileList));
                end

                dataOverview(end+1) = struct('ID',      measData(locationIndexes(1)).Location,               ...
                                             'InfoSet', struct('context',         context,                   ...
                                                               'indexes',         locationIndexes,           ...
                                                               'measData',        measData(locationIndexes), ...
                                                               'measTable',       measTable,                 ...
                                                               'locations',       {locations},                 ...
                                                               'durationTime',    durationTime,              ...
                                                               'period',          sprintf('%s - %s<br>⌛%s', beginTime, endTime, durationTime), ...
                                                               'limits',          sprintf('[%.1f - %.1f] V/m', minField, maxField), ...
                                                               'numMeasurements', height(measTable),         ...
                                                               'threshold',       projectData.modules.(context).threshold, ...
                                                               'numAboveTHR',     numAboveTHR, ...
                                                               'aboveTHRTable',   aboveTHRTable, ...
                                                               'distanceTHR',     projectData.modules.(context).distance_km, ...
                                                               'pointsTable',     pointsTable,  ...
                                                               'stationTable',    stationTable), ...
                                             'HTML',    struct('Component', {}, 'Source', {}, 'Value', {}));
                    
                % if ~isempty(measData(idIndexes(1)).UserData) && isfield(measData(idIndexes(1)).UserData, 'externalFiles')
                %     dataOverview(end).HTML = vertcat([measData(idIndexes).UserData].externalFiles);
                % end
            end


            %-------------------------------------------------------------%
            % Conexão com reportLib, parte do repositório "SupportPackages"
            %-------------------------------------------------------------%
            HTMLDocContent = reportLib.Controller(reportInfo, dataOverview);


            %-------------------------------------------------------------%
            % Exclui container criado para os plots, caso aplicável.
            %-------------------------------------------------------------%            
            hFigure    = app.UIFigure;
            hContainer = findobj(hFigure, 'Tag', 'reportGeneratorContainer');
            if ~isempty(hContainer)
                delete(hContainer)
            end


            %-------------------------------------------------------------%
            % Em sendo a versão "Preliminar", apenas apresenta o html no
            % navegador. Por outro lado, em sendo a versão "Definitiva",
            % salva-se o arquivo ZIP em pasta local.
            %-------------------------------------------------------------%
            [baseFullFileName, baseFileName] = appUtil.DefaultFileName(generalSettings.fileFolder.tempPath, 'monitorRNI_Report', issueId);
            HTMLFile = [baseFullFileName '.html'];
            
            writematrix(HTMLDocContent, HTMLFile, 'QuoteStrings', 'none', 'FileType', 'text', 'Encoding', docVersion.encoding)

            switch docVersion.version
                case 'preview'
                    web(HTMLFile, '-new')
                    updateGeneratedFiles(projectData, context)

                case 'final'
                    XLSXFile = [baseFullFileName '.xlsx'];
                    RAWFiles = fullfile({measData.Filepath}, {measData.Filename});

                    if numel(groupLocationList) > 1
                        measTableGlobal = createMeasTable(measData);
                    else
                        measTableGlobal = measTable;
                    end

                    switch context
                        case 'MonitoringPlan'
                            stationTableArray  = arrayfun(@(x) x.InfoSet.stationTable, dataOverview, "UniformOutput", false);
                            stationTableMerged = vertcat(stationTableArray{:});

                            [~, msgError] = fileWriter.MonitoringPlan(XLSXFile, stationTableMerged, measTableGlobal, projectData.modules.(context).threshold);
                        case 'ExternalRequest'
                            [~, msgError] = fileWriter.ExternalRequest(XLSXFile, pointsTableGlobal, measTableGlobal, projectData.modules.(context).threshold);
                    end

                    if ~isempty(msgError)
                        error(msgError)
                    end
                    
                    ZIPFile  = appUtil.modalWindow(app.UIFigure, 'uiputfile', '', {'*.zip', 'monitorRNI (*.zip)'}, fullfile(app.General.fileFolder.userPath, [baseFileName '.zip']));
                    if isempty(ZIPFile)
                        return
                    end                    

                    zip(ZIPFile, [{HTMLFile}, {XLSXFile}, RAWFiles])
                
                    app.projectData.modules.(context).generatedFiles.rawFiles            = HTMLFile;
                    app.projectData.modules.(context).generatedFiles.lastHTMLDocFullPath = HTMLFile;
                    app.projectData.modules.(context).generatedFiles.lastTableFullPath   = XLSXFile;
                    app.projectData.modules.(context).generatedFiles.lastZIPFullPath     = ZIPFile;
            end
        end
    end
end