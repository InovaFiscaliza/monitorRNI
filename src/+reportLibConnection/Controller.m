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
        docVersion = dictionary( ...
            ["Preliminar", "Definitiva"], ...
            ["preview", "final"] ...
        )
    end

    methods (Static)
        %-----------------------------------------------------------------%
        function Run(mainApp, callingApp, context, EMFieldObj)
            arguments
                mainApp
                callingApp
                context {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                EMFieldObj
            end

            appName = class.Constants.appName;
            projectData = mainApp.projectData;
            generalSettings = mainApp.General;
            rootFolder = mainApp.rootFolder;

            [projectFolder, ...
             programDataFolder] = appEngine.util.Path(appName, rootFolder);

            issueId = num2str(projectData.modules.(context).ui.issue);
            docName = projectData.modules.(context).ui.reportModel;
            docIndex = find(strcmp({projectData.report.templates.Name}, docName), 1);
            if isempty(docIndex)
                error('Pendente escolha do modelo de relatório.')
            end

            docType = projectData.report.templates(docIndex).DocumentType;
            docVersion = reportLibConnection.Controller.docVersion(projectData.modules.(context).ui.reportVersion);

            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                docScript = jsondecode(fileread(fullfile(programDataFolder, 'ReportTemplates', projectData.report.templates(docIndex).File)));
            catch
                docScript = jsondecode(fileread(fullfile(projectFolder,     'ReportTemplates', projectData.report.templates(docIndex).File)));
            end

            stationTableGlobal = projectData.modules.MONITORINGPLAN.stationTable;
            pointsTableGlobal  = projectData.modules.EXTERNALREQUEST.pointsTable;
            pointsTableGlobal  = model.ProjectBase.prepareTableForExport(pointsTableGlobal, 'POINTS', '-');

            %-------------------------------------------------------------%
            % reportInfo
            %
            % Importante observar que o campo "Function" armazena informações
            % gerais, a compor itens "Introdução", "Metodologia" e "Conclusão",
            % e informações específicas, a compor itens com recorrências, como 
            % "Resultados".
            %-------------------------------------------------------------%
            reportInfo = struct('App',      mainApp,                                                                  ...
                                'Version',  generalSettings.AppVersion,                                               ...
                                'Path',     struct('rootFolder',                 rootFolder,                          ...
                                                   'userFolder',                 generalSettings.fileFolder.userPath, ...
                                                   'tempFolder',                 generalSettings.fileFolder.tempPath, ...
                                                   'appConnection',              projectFolder,                       ...
                                                   'appDataFolder',              programDataFolder),                  ...
                                'Model',    struct('Name',                       docName,                             ...
                                                   'DocumentType',               docType,                             ...
                                                   'Script',                     docScript,                           ...
                                                   'Version',                    docVersion),                         ...
                                'Function', struct(...
                                                   ... % APLICÁVEIS ÀS SEÇÕES GERAIS DO RELATÓRIO
                                                   'cfg_Context',                jsonencode(generalSettings.context.(context)), ...
                                                   'cfg_DataBinning',            jsonencode(generalSettings.reportLib.dataBinning), ...
                                                   'cfg_ReportTemplate',         'reportLibConnection.Variable.GeneralSettings(reportInfo, "ReportTemplate")', ...
                                                   ...
                                                   'var_Issue',                  issueId, ...
                                                   'var_Unit',                   projectData.modules.(context).ui.unit, ...
                                                   'var_EntityGroupType',        projectData.modules.(context).ui.entity.type, ...
                                                   'var_EntityGroupName',        projectData.modules.(context).ui.entity.name, ...
                                                   'var_EntityGroupId',          projectData.modules.(context).ui.entity.id, ...
                                                   ...
                                                   'eFiscaliza_solicitacaoCode', 'reportLibConnection.Variable.GeneralSettings(reportInfo, "Solicitação de Inspeção")', ...
                                                   'eFiscaliza_acaoCode',       'reportLibConnection.Variable.GeneralSettings(reportInfo, "Ação de Inspeção")', ...
                                                   'eFiscaliza_atividadeCode',  'reportLibConnection.Variable.GeneralSettings(reportInfo, "Atividade de Inspeção")', ...
                                                   'eFiscaliza_requester',      'reportLibConnection.Variable.GeneralSettings(reportInfo, "Unidade Demandante")', ...
                                                   'eFiscaliza_unit',           'reportLibConnection.Variable.GeneralSettings(reportInfo, "Unidade Executante")', ...
                                                   'eFiscaliza_unitCity',       'reportLibConnection.Variable.GeneralSettings(reportInfo, "Sede da Unidade Executante")', ...
                                                   'eFiscaliza_description',    'reportLibConnection.Variable.GeneralSettings(reportInfo, "Descrição da Atividade de Inspeção")', ...
                                                   'eFiscaliza_period',         'reportLibConnection.Variable.GeneralSettings(reportInfo, "Período Previsto da Fiscalização")', ...
                                                   'eFiscaliza_fiscais',        'reportLibConnection.Variable.GeneralSettings(reportInfo, "Lista de Fiscais")', ...
                                                   'eFiscaliza_sei',            'reportLibConnection.Variable.GeneralSettings(reportInfo, "Processo SEI")', ...
                                                   ...
                                                   'var_LocationListGlobal',    'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationListGlobal")', ...
                                                   'var_LocationSummaryGlobal', 'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationSummaryGlobal")', ...
                                                   'var_MeasurementsGlobal',    'reportLibConnection.Variable.ProjectPropertyGlobal(dataOverview, "MeasurementsGlobal")', ...
                                                   'var_ThresholdGlobal',        projectData.modules.(context).analysis.threshold, ...
                                                   'var_NumAboveTHRGlobal',     'reportLibConnection.Variable.ProjectPropertyGlobal(dataOverview, "NumAboveTHRGlobal")', ...
                                                   'var_DistanceKmGlobal',       projectData.modules.(context).analysis.maxMeasurementDistanceKm, ...
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
                                'Context',  context,     ...
                                'Object',   EMFieldObj,  ...
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

            locationList = {EMFieldObj.Location};
            groupLocationList = unique(locationList);

            for ii = 1:numel(groupLocationList)
                groupLocation   = groupLocationList{ii};

                locationIndexes = find(strcmp(locationList, groupLocation));
                [~, idSort]     = sort(arrayfun(@(x) x.Data.Timestamp(1), EMFieldObj(locationIndexes)));
                locationIndexes = locationIndexes(idSort);

                fileList        = unique({EMFieldObj(locationIndexes).FileName});

                switch context
                    case 'MONITORINGPLAN'
                        locations      = getFullListOfLocation(projectData, EMFieldObj(locationIndexes), projectData.modules.MONITORINGPLAN.analysis.maxMeasurementDistanceKm);                        
                        stationIndexes = ismember(stationTableGlobal.Location, locations);
                        
                        stationTable   = stationTableGlobal(stationIndexes, :);
                        pointsTable    = [];

                    case 'EXTERNALREQUEST'
                        locations      = unique({EMFieldObj(locationIndexes).Location});
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

                measTable = buildMeasurementTable(EMFieldObj(locationIndexes));
                [beginTime, endTime] = bounds(measTable.Timestamp);
                [minField, maxField] = bounds(measTable.FieldValue);
                durationTime = sum(arrayfun(@(x) x.Data.Timestamp(end) - x.Data.Timestamp(1), EMFieldObj(locationIndexes)));

                aboveTHR = measTable.FieldValue > projectData.modules.(context).analysis.threshold;
                if any(aboveTHR)
                    rawTable  = timetable2table(measTable(aboveTHR, :));
                    rawTable  = rawTable(:, {'Timestamp', 'Latitude', 'Longitude', 'FieldValue'});
                    rawFilter = table({}, {}, struct('handle', {}, 'specification', {}), true(0, 1), 'VariableNames', {'type', 'subtype', 'roi', 'enable'});
                    [~, ~, aboveTHRTable] = RF.DataBinning.execute(rawTable, generalSettings.reportLib.dataBinning.binLengthMeters, generalSettings.reportLib.dataBinning.aggregationFunction, rawFilter, 'FieldValue');

                    numAboveTHR = [];
                    for file = fileList
                        idxFile = strcmp(measTable.FileSource, file);
                        numAboveTHR = [numAboveTHR, sum(measTable.FieldValue(idxFile) > projectData.modules.(context).analysis.threshold)];
                    end
                else
                    aboveTHRTable = table('Size', [0,4], 'VariableTypes', {'double', 'double', 'double', 'double'}, 'VariableNames', {'Latitude', 'Longitude', 'FieldValues', 'Measures'});
                    numAboveTHR   = zeros(1, numel(fileList));
                end

                dataOverview(end+1) = struct('ID',      EMFieldObj(locationIndexes(1)).Location,               ...
                                             'InfoSet', struct('context',         context,                   ...
                                                               'indexes',         locationIndexes,           ...
                                                               'measData',        EMFieldObj(locationIndexes), ...
                                                               'measTable',       measTable,                 ...
                                                               'locations',       {locations},                 ...
                                                               'durationTime',    durationTime,              ...
                                                               'period',          sprintf('%s - %s<br>⌛%s', beginTime, endTime, durationTime), ...
                                                               'limits',          sprintf('[%.1f - %.1f] V/m', minField, maxField), ...
                                                               'numMeasurements', height(measTable),         ...
                                                               'threshold',       projectData.modules.(context).analysis.threshold, ...
                                                               'numAboveTHR',     numAboveTHR, ...
                                                               'aboveTHRTable',   aboveTHRTable, ...
                                                               'distanceTHR',     projectData.modules.(context).analysis.maxMeasurementDistanceKm, ...
                                                               'pointsTable',     pointsTable,  ...
                                                               'stationTable',    stationTable), ...
                                             'HTML',    struct('Component', {}, 'Source', {}, 'Value', {}));
            end

            %-------------------------------------------------------------%
            % Conexão com reportLib, parte do repositório "SupportPackages"
            %-------------------------------------------------------------%
            HTMLDocContent = reportLib.Controller(reportInfo, dataOverview);

            %-------------------------------------------------------------%
            % Exclui container criado para os plots, caso aplicável.
            %-------------------------------------------------------------%
            hFigure    = mainApp.UIFigure;
            hContainer = findobj(hFigure, 'Tag', 'reportGeneratorContainer');
            if ~isempty(hContainer)
                delete(hContainer)
            end

            %-------------------------------------------------------------%
            % Em sendo a versão "Preliminar", apenas apresenta o html no
            % navegador. Por outro lado, em sendo a versão "Definitiva",
            % salva-se o arquivo ZIP em pasta local.
            %-------------------------------------------------------------%
            [baseFullFileName, baseFileName] = appEngine.util.DefaultFileName(generalSettings.fileFolder.tempPath, [appName '_FinalReport'], issueId);
            HTMLFile = [baseFullFileName '.html'];
            
            writematrix(HTMLDocContent, HTMLFile, 'QuoteStrings', 'none', 'FileType', 'text', 'Encoding', 'UTF-8')

            switch docVersion
                case 'preview'
                    web(HTMLFile, '-new')
                    updateGeneratedFiles(projectData, context)

                case 'final'
                    JSONFile = '';
                    XLSXFile = [baseFullFileName '.xlsx'];
                    RAWFiles = {EMFieldObj.FileFullName};
                    ZIPFile  = ui.Dialog(callingApp.UIFigure, 'uiputfile', '', {'*.zip', [appName ' (*.zip)']}, fullfile(generalSettings.fileFolder.userPath, [baseFileName '.zip']));
                    if isempty(ZIPFile)
                        return
                    end

                    if numel(groupLocationList) > 1
                        measTableGlobal = buildMeasurementTable(EMFieldObj);
                    else
                        measTableGlobal = measTable;
                    end

                    switch context
                        case 'MONITORINGPLAN'
                            stationTableArray  = arrayfun(@(x) x.InfoSet.stationTable, dataOverview, "UniformOutput", false);
                            stationTableMerged = vertcat(stationTableArray{:});
                            [~, msgError]      = fileWriter.MonitoringPlan(XLSXFile, stationTableMerged, measTableGlobal, projectData.modules.(context).analysis.threshold);

                        case 'EXTERNALREQUEST'
                            [~, msgError]      = fileWriter.ExternalRequest(XLSXFile, pointsTableGlobal, measTableGlobal, projectData.modules.(context).analysis.threshold);
                    end

                    if ~isempty(msgError)
                        error(msgError)
                    end

                    zip(ZIPFile, [{HTMLFile}, {XLSXFile}, RAWFiles])

                    generatedFileId = model.ProjectBase.computeReportAnalysisResultsHash(projectData.modules, context, EMFieldObj);
                    updateGeneratedFiles(projectData, context, generatedFileId, RAWFiles, HTMLFile, JSONFile, XLSXFile, ZIPFile)
            end
        end
    end
end