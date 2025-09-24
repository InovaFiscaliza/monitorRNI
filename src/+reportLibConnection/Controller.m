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
        function Run(callingApp, projectData, measData, stationTable, pointsTable, generalSettings)
            arguments
                callingApp
                projectData
                measData
                stationTable
                pointsTable
                generalSettings
            end

            switch class(callingApp)
                case 'winMonitorRNI'
                    app = callingApp;
                case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported', ...
                      'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported'}
                    app = callingApp.mainApp;
                otherwise
                    error('UnexpectedCaller')
            end

            [projectFolder, ...
             programDataFolder] = appUtil.Path(class.Constants.appName, app.rootFolder);

            issueId    = num2str(generalSettings.Report.issue);
            docName    = generalSettings.Report.model;
            docIndex   = find(strcmp({projectData.documentModel.Name}, docName), 1);
            if isempty(docIndex)
                error('Pendente escolha do modelo de relatório')
            end

            docType    = projectData.documentModel(docIndex).DocumentType;
            docVersion = reportLibConnection.Controller.docVersion(generalSettings.Report.reportVersion);

            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                docScript = jsondecode(fileread(fullfile(programDataFolder, 'ReportTemplates', projectData.documentModel(docIndex).File)));
            catch
                docScript = jsondecode(fileread(fullfile(projectFolder,     'ReportTemplates', projectData.documentModel(docIndex).File)));
            end
        
            % reportInfo
            % Importante observar que o campo "Function" armazena informações
            % gerais, a compor itens "Introdução", "Metodologia" e "Conclusão",
            % e informações específicas, a compor itens com recorrências, como 
            % "Resultados".
            reportInfo = struct('App',      app, ...
                                'Version',  app.General.AppVersion,                                              ...
                                'Path',     struct('rootFolder',            app.rootFolder,                      ...
                                                   'userFolder',            generalSettings.fileFolder.userPath, ...
                                                   'tempFolder',            generalSettings.fileFolder.tempPath, ...
                                                   'appConnection',         projectFolder,                       ...
                                                   'appDataFolder',         programDataFolder),                  ...
                                'Model',    struct('Name',                  docName,                             ...
                                                   'DocumentType',          docType,                             ...
                                                   'Script',                docScript,                           ...
                                                   'Version',               docVersion.version),                 ...
                                'Function', struct(... 
                                                   ... % APLICÁVEIS ÀS SEÇÕES GERAIS DO RELATÓRIO
                                                   'cfg_MonitoringPlan',    'reportLibConnection.Variable.GeneralSettings(reportInfo, "MonitoringPlan")', ...
                                                   'cfg_ExternalRequest',   'reportLibConnection.Variable.GeneralSettings(reportInfo, "ExternalRequest")', ...      
                                                   'var_Issue',             issueId, ...
                                                   'var_Unit',              generalSettings.Report.unit, ...
                                                   'var_LocationFullList',  'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationFullList")', ...
                                                   'var_LocationFullSummary','reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationFullSummary")', ...
                                                   'tbl_StationTable',      stationTable,                        ...
                                                   'tbl_PointsTable',       pointsTable,                         ...
                                                   'tbl_FileByLocation',    'reportLibConnection.Table.FileByLocation(reportInfo)', ...
                                                   'tbl_SummaryByLocation', 'reportLibConnection.Table.SummaryByLocation(analyzedData)', ...
                                                   ...
                                                   ... % APLICÁVEIS À SEÇÃO COM RECORRÊNCIA DO RELATÓRIO
                                                   ... % 'var_Index'
                                                   'var_Id',                'analyzedData.ID', ...
                                                   'var_NumFiles',          'reportLibConnection.Variable.ClassProperty(analyzedData, "NumFiles")', ...
                                                   'var_FileName',          'reportLibConnection.Variable.ClassProperty(analyzedData, "Filename")', ...
                                                   'var_Sensor',            'reportLibConnection.Variable.ClassProperty(analyzedData, "Sensor")', ...
                                                   'var_Location',          'reportLibConnection.Variable.ClassProperty(analyzedData, "Location")', ...
                                                   'var_Location_I',        'reportLibConnection.Variable.ClassProperty(analyzedData, "Location_I")', ...
                                                   'var_LocationList',      'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationList")', ...
                                                   'var_LocationSummary',   'reportLibConnection.Variable.ProjectProperty(reportInfo, analyzedData, "LocationSummary")', ...
                                                   'var_Content',           'reportLibConnection.Variable.ClassProperty(analyzedData, "Content")', ...
                                                   'var_MetaData',          'reportLibConnection.Variable.ClassProperty(analyzedData, "MetaData")', ...
                                                   'var_Measures',          'reportLibConnection.Variable.ClassProperty(analyzedData, "Measures")', ...
                                                   'var_CoveredDistance',   'reportLibConnection.Variable.ClassProperty(analyzedData, "CoveredDistance")', ...
                                                   'var_FieldValueLimits',  'reportLibConnection.Variable.ClassProperty(analyzedData, "FieldValueLimits")', ...
                                                   'var_ObservationTime',   'reportLibConnection.Variable.ClassProperty(analyzedData, "ObservationTime")', ...
                                                   'var_LatitudeLimits',    'reportLibConnection.Variable.ClassProperty(analyzedData, "LatitudeLimits")', ...
                                                   'var_LongitudeLimits',   'reportLibConnection.Variable.ClassProperty(analyzedData, "LongitudeLimits")', ...
                                                   'var_Latitude',          'reportLibConnection.Variable.ClassProperty(analyzedData, "Latitude")', ...
                                                   'var_Longitude',         'reportLibConnection.Variable.ClassProperty(analyzedData, "Longitude")', ...
                                                   'var_NumPoints',         'reportLibConnection.Variable.TableProperty(reportInfo, analyzedData, "PointsTableHeight")', ...
                                                   'var_NumStations',       'reportLibConnection.Variable.TableProperty(reportInfo, analyzedData, "StationTableHeight")', ...
                                                   'tbl_PointsByLocation',  'reportLibConnection.Table.PointsByLocation(reportInfo, analyzedData, tableOptArgs{:})', ...
                                                   'tbl_StationsByLocation','reportLibConnection.Table.StationsByLocation(reportInfo, analyzedData, tableOptArgs{:})', ...
                                                   'img_Plot',              'reportLibConnection.Plot.Controller(reportInfo, analyzedData, imgSettings)'), ...
                                'Project',  projectData, ...
                                'Object',   measData, ...
                                'Settings', generalSettings);
            
            fieldsUnnecessary = {'rootFolder', 'entryPointFolder', 'tempSessionFolder', 'ctfRoot'};
            fieldsUnnecessary(cellfun(@(x) ~isfield(reportInfo.Version.application, x), fieldsUnnecessary)) = [];
            if ~isempty(fieldsUnnecessary)
                reportInfo.Version.application = rmfield(reportInfo.Version.application, fieldsUnnecessary);
            end

            % dataOverview
            % Caso dataOverview não seja escalar e exista um item no relatório
            % com recorrência, a própria lib cria a variável "var_Index", acessível 
            % em "reportInfo.Function.var_Index".
            dataOverview = struct('ID', {}, 'InfoSet', {}, 'HTML', {});

            locationList = {measData.Location};
            locations    = unique(locationList);

            for ii = 1:numel(locations)
                idIndexes   = find(strcmp(locationList, locations{ii}));
                [~, idSort] = sort(arrayfun(@(x) x.Data.Timestamp(1), measData(idIndexes)));
                idIndexes   = idIndexes(idSort);
                
                fileList    = unique({measData(idIndexes).Filename});
                pointsTableIndexes = [];
                for jj = 1:height(pointsTable)
                    sourceFiles = jsondecode(pointsTable.("Fonte de dados"){jj});
                    if ~iscellstr(sourceFiles)
                        sourceFiles = cellstr(sourceFiles);
                    end

                    if any(ismember(sourceFiles, fileList))
                        pointsTableIndexes = [pointsTableIndexes, jj];
                    end
                end                   
                
                locationSubList = getFullListOfLocation(projectData, measData(idIndexes), stationTable, max(generalSettings.MonitoringPlan.Distance_km, generalSettings.ExternalRequest.Distance_km));
                stationTableIndexes = ismember(stationTable.Location, locationSubList);

                dataOverview(end+1) = struct('ID',      measData(idIndexes(1)).Location,                              ...
                                             'InfoSet', struct('indexes',      idIndexes,                             ...
                                                               'measData',     measData(idIndexes),                   ...
                                                               'measTable',    createMeasTable(measData(idIndexes)),  ...
                                                               'pointsTable',  pointsTable(pointsTableIndexes, :),    ...
                                                               'stationTable', stationTable(stationTableIndexes, :)), ...
                                             'HTML',    struct('Component', {}, 'Source', {}, 'Value', {}));
                    
                % if ~isempty(measData(idIndexes(1)).UserData) && isfield(measData(idIndexes(1)).UserData, 'externalFiles')
                %     dataOverview(end).HTML = vertcat([measData(idIndexes).UserData].externalFiles);
                % end
            end
            
            % Cria relatório:
            HTMLDocContent = reportLib.Controller(reportInfo, dataOverview);

            % Exclui container criado para os plots, caso aplicável.
            hFigure    = app.UIFigure;
            hContainer = findobj(hFigure, 'Tag', 'reportGeneratorContainer');
            if ~isempty(hContainer)
                delete(hContainer)
            end
            
            % Em sendo a versão "Preliminar", apenas apresenta o html no
            % navegador. Por outro lado, em sendo a versão "Definitiva",
            % salva-se o arquivo ZIP em pasta local.
            [baseFullFileName, baseFileName] = appUtil.DefaultFileName(generalSettings.fileFolder.tempPath, 'Report', issueId);
            HTMLFile = [baseFullFileName '.html'];
            
            writematrix(HTMLDocContent, HTMLFile, 'QuoteStrings', 'none', 'FileType', 'text', 'Encoding', docVersion.encoding)
            web(HTMLFile, '-new')

            switch docVersion.version
                case 'preview'
                    % ...

                case 'final'
                    % ...
            end
        end
    end
end