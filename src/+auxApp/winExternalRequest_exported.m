classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        DockModule                 matlab.ui.container.GridLayout
        DockCloseButton            matlab.ui.control.Image
        DockUndockButton           matlab.ui.control.Image
        Document                   matlab.ui.container.GridLayout
        UITable                    matlab.ui.control.Table
        AxesToolbar                matlab.ui.container.GridLayout
        AxesBasemap                matlab.ui.control.DropDown
        AxesExportGraphicsButton   matlab.ui.control.Image
        AxesRegionZoomButton       matlab.ui.control.Image
        AxesRestoreViewButton      matlab.ui.control.Image
        AxesContainer              matlab.ui.container.Panel
        LeftPanel                  matlab.ui.container.Panel
        LeftPanelGrid              matlab.ui.container.GridLayout
        AddNewPointPanel           matlab.ui.container.Panel
        AddNewPointGrid            matlab.ui.container.GridLayout
        NewPointDescriptionLabel   matlab.ui.control.Label
        NewPointDescription        matlab.ui.control.EditField
        NewPointLongitudeLabel     matlab.ui.control.Label
        NewPointLongitude          matlab.ui.control.NumericEditField
        NewPointLatitude           matlab.ui.control.NumericEditField
        NewPointLatitudeLabel      matlab.ui.control.Label
        NewPointStation            matlab.ui.control.NumericEditField
        NewPointStationLabel       matlab.ui.control.Label
        NewPointType               matlab.ui.control.DropDown
        NewPointTypeLabel          matlab.ui.control.Label
        AddNewPointCancel          matlab.ui.control.Image
        AddNewPointConfirm         matlab.ui.control.Image
        AddNewPointMode            matlab.ui.control.Image
        PointList                  matlab.ui.container.Tree
        PointListLabel             matlab.ui.control.Label
        TreeFileLocations          matlab.ui.container.Tree
        TreeFileLocationsLabel     matlab.ui.control.Label
        ModuleIntro                matlab.ui.control.Label
        ModuleIcon                 matlab.ui.control.Image
        Toolbar                    matlab.ui.container.GridLayout
        UploadFinalFile            matlab.ui.control.Image
        GenerateReport             matlab.ui.control.Image
        OpenPopupProject           matlab.ui.control.Image
        PeakLabelButton            matlab.ui.control.Label
        PeakIconButton             matlab.ui.control.Image
        ToolbarSeparator2          matlab.ui.control.Image
        ExportFilesButton          matlab.ui.control.Image
        ToolbarSeparator1          matlab.ui.control.Image
        PlotTableLayoutButton      matlab.ui.control.Image
        LeftPanelVisibilityButton  matlab.ui.control.Image
        ContextMenu                matlab.ui.container.ContextMenu
        DeletePoint                matlab.ui.container.Menu
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'secondaryApp'
        Context = 'EXTERNALREQUEST'
    end


    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = false
        mainApp
        jsBackDoor
        progressDialog
        popupContainer

        projectData
        measData
        measTable

        % Localidades de agrupamento marcadas em auxApp.dockReportLib, as quais 
        % compõem o relatório. Inicia vazia (nenhuma localidade marcada).
        reportLocations = {}

        UIAxes1
        restoreView = struct( ...
            'ID', {}, ...
            'xLim', {}, ...
            'yLim', {}, ...
            'cLim', {} ...
        )
    end


    methods (Access = public)
        %-----------------------------------------------------------------%
        function ipcSecondaryJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    case 'renderer'
                        appEngine.activate(app, app.Role)

                    otherwise
                        ipcMainJSEventsHandler(app.mainApp, event)
                end

            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end
        end

        %-----------------------------------------------------------------%
        function ipcSecondaryMatlabCallsHandler(app, callingApp, eventName, varargin)
            try
                switch class(callingApp)
                    case {'winMonitorRNI', 'winMonitorRNI_exported'}
                        switch eventName
                            % winMonitorRNI >> auxApp.winExternalRequest
                            case {'onFileListAdded', 'onFileListRemoved', 'onFileListUnmerged', 'onFileListMerged', 'onProjectRestart', 'onProjectLoad'}
                                app.measData = getFullEMFieldData(app.projectData, app.mainApp.measData);
                                buildFileLocationTree(app)

                                if ~isempty(app.measData)
                                    refreshAnalysis(app)
                                end

                            % auxApp.winConfig >> winMonitorRNI >> auxApp.winExternalRequest
                            case 'onAnalysisParameterChanged'
                                app.UITable.ColumnName{4} = sprintf('Qtd.|>%.0fV/m', app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold);
                                updateAnalysis(app.projectData, app.measData, app.mainApp.General, eventName, app.Context);
                                refreshAnalysis(app)

                            case 'onAxesParameterChanged'
                                if ~isequal(app.UIAxes1.Basemap, app.mainApp.General.plot.geographicAxes.basemap)
                                    app.UIAxes1.Basemap = app.mainApp.General.plot.geographicAxes.basemap;

                                    switch app.mainApp.General.plot.geographicAxes.basemap
                                        case {'darkwater', 'none'}
                                            app.UIAxes1.Grid = 'on';
                                        otherwise
                                            app.UIAxes1.Grid = 'off';
                                    end
                                end

                                plot.axes.Colormap(app.UIAxes1, app.mainApp.General.plot.geographicAxes.colormap)
                                plot.axes.Colorbar(app.UIAxes1, app.mainApp.General.plot.geographicAxes.colorbar)

                            case 'onPlotParameterChanged'
                                refreshAnalysis(app)

                            % winMonitorRNI >> auxApp.winExternalRequest
                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winExternalRequest
                            case {'onReportGenerate', 'onFinalReportFileChanged'}
                                updateToolbar(app)

                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winExternalRequest
                            case 'onReportLocationsChanged'
                                updateLocationTreeMarks(app)

                            case 'onFetchIssueDetails'
                                system   = varargin{1};
                                issue    = varargin{2};
                                details  = varargin{3};
                                msgError = varargin{4};

                                if ~isempty(msgError)
                                    error(msgError)
                                end

                                msg = util.HtmlTextGenerator.issueDetails(system, issue, details);
                                ui.Dialog(app.UIFigure, 'info', msg);

                            % auxApp.winExternalRequest >> winMonitorRNI >> auxApp.winExternalRequest
                            case 'auxApp.winExternalRequest.TreePoints'
                                onDeleteSelectedPoint(app, struct('ContextObject', app.PointList))

                            otherwise
                                error('model:winExternalRequest:UnexpectedCall', 'Unexpected call "%s"', eventName)
                        end
    
                    otherwise
                        error('model:winExternalRequest:UnexpectedCaller', 'Unexpected caller "%s"', class(callingApp))
                end

            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end
        end

        %-----------------------------------------------------------------%
        function applyJSCustomizations(app)
            appName = class(app);
            elToModify = {
                app.AxesToolbar;
                app.AxesRestoreViewButton;
                app.AxesRegionZoomButton;
                app.AxesExportGraphicsButton;
                app.AddNewPointMode;
                app.AddNewPointConfirm;
                app.AddNewPointCancel;
                app.PointList;
                app.LeftPanelVisibilityButton;
                app.PlotTableLayoutButton;
                app.ExportFilesButton;
                app.PeakIconButton;
                app.OpenPopupProject;
                app.GenerateReport;
                app.UploadFinalFile;
                app.DockUndockButton;
                app.DockCloseButton
            };
            ui.CustomizationBase.getElementsDataTag(elToModify);

            try
                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                    struct('appName', appName, 'dataTag', app.AxesToolbar.UserData.id, 'styleImportant', struct('borderTopLeftRadius', '0', 'borderTopRightRadius', '0')), ...
                    struct('appName', appName, 'dataTag', app.AddNewPointMode.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Alterna visibilidade do painel de inclusão de ponto')), ...
                    struct('appName', appName, 'dataTag', app.AddNewPointConfirm.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Confirma edição')), ...
                    struct('appName', appName, 'dataTag', app.AddNewPointCancel.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Cancela edição')), ...
                    struct('appName', appName, 'dataTag', app.LeftPanelVisibilityButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Alterna visibilidade do painel')), ...
                    struct('appName', appName, 'dataTag', app.PlotTableLayoutButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Alterna entre três layouts do conjunto plot+tabela<br>(apenas plot, apenas tabela ou plot+tabela)')), ...
                    struct('appName', appName, 'dataTag', app.ExportFilesButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Exporta análise (.xlsx, .kml)')), ...
                    struct('appName', appName, 'dataTag', app.PeakIconButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Aplica zoom em torno do local de valor máximo')), ...
                    struct('appName', appName, 'dataTag', app.OpenPopupProject.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Edita informações do projeto<br>(fiscalizada, arquivo de backup etc)')), ...
                    struct('appName', appName, 'dataTag', app.GenerateReport.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Gera relatório')), ...
                    struct('appName', appName, 'dataTag', app.UploadFinalFile.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Upload relatório')), ...
                    ...
                    struct('appName', appName, 'dataTag', app.AxesRestoreViewButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Restaura limites iniciais dos eixos')), ...
                    struct('appName', appName, 'dataTag', app.AxesRegionZoomButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Habilita zoom de região')), ...
                    struct('appName', appName, 'dataTag', app.AxesExportGraphicsButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Exporta plot')), ...
                    ...
                    struct('appName', appName, 'dataTag', app.DockUndockButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Reabre módulo em outra janela')), ...
                    struct('appName', appName, 'dataTag', app.DockCloseButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Fecha módulo')), ...
                    ...
                    struct('appName', appName, 'dataTag', app.PointList.UserData.id, 'listener', struct('componentName', 'auxApp.winExternalRequest.TreePoints', 'keyEvents', {{'Delete', 'Backspace'}})) ...
                });
            catch
            end
        end

        %-----------------------------------------------------------------%
        function initializeAppProperties(app)
            app.LeftPanelVisibilityButton.UserData.status = true;
            app.PlotTableLayoutButton.UserData.layout = 1;
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.DockUndockButton.Enable = 1;
            end

            addStyle(app.PointList, uistyle('Interpreter', 'html'))

            if app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold ~= 14
                app.UITable.ColumnName{4} = sprintf('Qtd.|>%.0fV/m', app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold);
            end
            app.UITable.RowName = 'numbered';

            defaultBasemap = app.mainApp.General.plot.geographicAxes.basemap;
            if ~ismember(defaultBasemap, app.AxesBasemap.Items)
                app.AxesBasemap.Items{end+1} = defaultBasemap;
            end
            app.AxesBasemap.Value = defaultBasemap;

            [app.UIAxes1, app.restoreView] = plot.axesCreationController(app.AxesContainer, app.mainApp.General);

            buildFileLocationTree(app)
            if ~isempty(app.measData)
                refreshAnalysis(app)
            end

            % Especificidades do auxApp.winExternalRequest em relação ao
            % auxApp.winMonitoringPlan:
            buildPointsTree(app)
            app.NewPointType.Items = [{''}; app.mainApp.General.context.EXTERNALREQUEST.locationType];
            setAddPointPanelEnabled(app, 'off')
        end

        %-----------------------------------------------------------------%
        function applyInitialLayout(app)
            % ...
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function refreshAnalysis(app)
            app.progressDialog.Visible = 'visible';

            % Identifica arquivos selecionados pelo usuário, atualizando a
            % tabela de referência para o plot (app.measTable) e a relação
            % de localidades selecionadas na GUI (em app.projectData).
            [fileIdxs, selectedFileLocations] = getFileIndexes(app);
            app.measTable = buildMeasurementTable(app.measData(fileIdxs));

            updateSelectedListOfLocations(app.projectData, selectedFileLocations, app.Context)

            initialSelection = updateTable(app);
            applyTableStyle(app)

            % Atualiza outros elementos da GUI, inclusive painel com quantitativo 
            % de estações.
            updateToolbar(app)            

            % Atualiza plot.
            plotMeasuresAndPoints(app)

            if ~isempty(initialSelection)
                [~, rowIdx] = ismember(initialSelection, app.UITable.Data.ID);
                if rowIdx
                    app.UITable.Selection = rowIdx;
                    onUITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', rowIdx))
                end
            end

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function initialSelection = updateTable(app)
            initialSelection = [];
            if ~isempty(app.UITable.Selection)
                initialSelection = app.UITable.Data.ID{app.UITable.Selection};
            end

            table2Render = app.projectData.modules.EXTERNALREQUEST.pointsTable(:, {'ID',                    ...
                                                                                   'Description',           ...                                                                                    
                                                                                   'numberOfMeasures',      ...
                                                                                   'numberOfRiskMeasures',  ...
                                                                                   'minDistanceForMeasure', ...
                                                                                   'minFieldValue',         ...
                                                                                   'meanFieldValue',        ...
                                                                                   'maxFieldValue',         ...
                                                                                   'Justificativa'});
            set(app.UITable, 'Data', table2Render, 'Selection', [])
        end

        %-----------------------------------------------------------------%
        function applyTableStyle(app)
            removeStyle(app.UITable)

            tableDataNonEmpty = ~isempty(app.UITable.Data);
            if tableDataNonEmpty
                % Identifica pontos que NÃO tiveram medições no seu entorno. 
                % Ou pontos que apresentaram medições com níveis acima de 14 V/m.
                [invalidRowIdxs, ~, ~, ~, riskMeasurementsIdxs] = validateAuditorClassification(app.projectData, app.Context, app.mainApp.General);

                if ~isempty(invalidRowIdxs)
                    columnIndex1 = find(ismember(app.UITable.Data.Properties.VariableNames, 'Justificativa'));
                    s1 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');                
                    addStyle(app.UITable, s1, "cell", [invalidRowIdxs, repmat(columnIndex1, numel(invalidRowIdxs), 1)])
                end

                if ~isempty(riskMeasurementsIdxs)
                    columnIndex2 = find(ismember(app.UITable.Data.Properties.VariableNames, 'numberOfRiskMeasures'));

                    s2 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');
                    addStyle(app.UITable, s2, "cell", [riskMeasurementsIdxs, repmat(columnIndex2, numel(riskMeasurementsIdxs), 1)])
                end
            end
        end

        %-----------------------------------------------------------------%
        function updateToolbar(app)
            measDataNonEmpty                = ~isempty(app.measData);
            measTableNonEmpty               = ~isempty(app.measTable);
            pointsTableNonEmpty             = ~isempty(app.projectData.modules.(app.Context).pointsTable);
            reportFinalVersionGenerated     = ~isempty(app.projectData.modules.(app.Context).generatedFiles.lastHTMLDocFullPath);
            
            app.ExportFilesButton.Enable     = measDataNonEmpty && pointsTableNonEmpty;
            app.GenerateReport.Enable  = measDataNonEmpty && pointsTableNonEmpty;
            app.UploadFinalFile.Enable = reportFinalVersionGenerated;

            app.PeakLabelButton.Visible      = measTableNonEmpty;
            app.PeakIconButton.Enable        = measTableNonEmpty;

            if measTableNonEmpty
                [~, maxIndex] = max(app.measTable.FieldValue);

                app.PeakLabelButton.Text     = sprintf('%.2f V/m\n(%.6f, %.6f)', app.measTable.FieldValue(maxIndex), ...
                                                                                app.measTable.Latitude(maxIndex),   ...
                                                                                app.measTable.Longitude(maxIndex));
                app.PeakIconButton.UserData  = struct('idxMax',    maxIndex,                         ...
                                                     'Latitude',  app.measTable.Latitude(maxIndex), ...
                                                     'Longitude', app.measTable.Longitude(maxIndex));
            end
        end

        %-----------------------------------------------------------------%
        function updateLocationTreeMarks(app)
            % Localidades que compõem o relatório (marcadas em auxApp.dockReportLib) 
            % são identificadas com um símbolo verde. O nome da localidade é 
            % preservado em "NodeData".
            for treeNode = app.TreeFileLocations.Children'
                treeNode.Text = treeNode.NodeData;
                if ismember(treeNode.NodeData, app.reportLocations)
                    treeNode.Text = [treeNode.NodeData ' 🟢'];
                end
            end
        end

        %-----------------------------------------------------------------%
        function buildFileLocationTree(app)
            if ~isempty(app.TreeFileLocations.Children)
                delete(app.TreeFileLocations.Children)
            end

            locationGroups = unique({app.measData.Location});
            app.reportLocations = app.reportLocations(ismember(app.reportLocations, locationGroups));
            selectedNodes = [];
            for ii = 1:numel(locationGroups)
                treeNode = uitreenode(app.TreeFileLocations, 'Text', locationGroups{ii}, 'NodeData', locationGroups{ii});

                if strcmp(locationGroups{ii}, app.projectData.modules.EXTERNALREQUEST.ui.selectedGroup)
                    selectedNodes = [selectedNodes; treeNode];
                end
            end

            updateLocationTreeMarks(app)

            measDataNonEmpty = ~isempty(app.measData);
            if measDataNonEmpty
                if isempty(selectedNodes)
                    selectedNodes = app.TreeFileLocations.Children(1);
                elseif ~isscalar(selectedNodes)
                    selectedNodes = selectedNodes(1);
                end
                app.TreeFileLocations.SelectedNodes = selectedNodes;

            else
                app.measTable = [];

                plotRefreshAxes(app)
                updateTable(app);
            end

            updateToolbar(app)
        end

        %-----------------------------------------------------------------%
        function buildPointsTree(app)
            if ~isempty(app.PointList.Children)
                delete(app.PointList.Children)
            end

            for ii = 1:height(app.projectData.modules.EXTERNALREQUEST.pointsTable)
                pointId = strsplit(app.projectData.modules.EXTERNALREQUEST.pointsTable.ID{ii} , ' @ ');
                description = app.projectData.modules.EXTERNALREQUEST.pointsTable.Description{ii};
                nodeText = sprintf('<br><b>%s</b><br><font style="color: gray; font-size: 10px;">%s<br>"%s"</font><br><br>', pointId{1}, pointId{2}, description);

                uitreenode(app.PointList, 'Text', nodeText, 'NodeData', ii, 'Icon', 'location.svg', 'ContextMenu', app.ContextMenu);
            end
        end

        %-----------------------------------------------------------------%
        function setAddPointPanelEnabled(app, status)
            arguments
                app 
                status char {mustBeMember(status, {'on', 'off'})}
            end            

            switch status
                case 'on'
                    app.AddNewPointMode.ImageSource = 'addFiles_32Filled.png';
                    app.AddNewPointMode.UserData.status = true;
                    
                    app.LeftPanelGrid.RowHeight(10:11) = {170, 5};
                    app.LeftPanelGrid.ColumnWidth(end-1:end) = {18, 18};
                    set([app.AddNewPointConfirm, app.AddNewPointCancel], 'Enable', 'on')
                    app.AddNewPointPanel.Visible = 'on';

                case 'off'
                    app.AddNewPointMode.ImageSource = 'addFiles_32.png';
                    app.AddNewPointMode.UserData.status = false;

                    app.LeftPanelGrid.RowHeight(10:11) = {0, 0};
                    app.LeftPanelGrid.ColumnWidth(end-1:end) = {0,0};
                    set([app.AddNewPointConfirm, app.AddNewPointCancel], 'Enable', 'off')
                    app.AddNewPointPanel.Visible = 'off';
            end
        end

        
        %-----------------------------------------------------------------%
        % ## PLOT ##
        %-----------------------------------------------------------------%
        function plotRefreshAxes(app)
            cla(app.UIAxes1)
            geolimits(app.UIAxes1, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes1.LatitudeLimits, 'yLim', app.UIAxes1.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function plotMeasuresAndPoints(app)
            % prePlot
            plotRefreshAxes(app)

            % Measures
            if ~isempty(app.measTable)
                plot.draw.Measures(app.UIAxes1, app.measTable, app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold, app.mainApp.General);

                % Abaixo estabelece como limites do eixo os limites atuais,
                % configurados automaticamente pelo MATLAB. Ao fazer isso,
                % contudo, esses limites serão orientados às medidas e não às
                % estações.
                plotAxesDefaultLimits(app, 'measures')
            end

            % Stations/Points
            if ~isempty(app.UITable.Data)
                refPointsTable = app.projectData.modules.EXTERNALREQUEST.pointsTable;
                plot.draw.Points(app.UIAxes1, refPointsTable, 'Pontos críticos', app.mainApp.General)
            end
            plotAxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plotSelectedPoint(app)
            delete(findobj(app.UIAxes1.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.Selection;
                selectedPointTable = app.projectData.modules.EXTERNALREQUEST.pointsTable(idxSelectedPoint, :);

                plot.draw.SelectedPoint(app.UIAxes1, selectedPointTable, app.mainApp.General, class(app))
            end
        end

        %-----------------------------------------------------------------%
        function plotAxesDefaultLimits(app, zoomOrientation)
            arguments
                app
                zoomOrientation {mustBeMember(zoomOrientation, {'stations/points', 'measures'})}
            end

            if strcmp(app.mainApp.General.plot.geographicAxes.zoomOrientation, zoomOrientation) || (isempty(app.measTable) && strcmp(app.mainApp.General.plot.geographicAxes.zoomOrientation, 'measures'))
                geolimits(app.UIAxes1, app.UIAxes1.LatitudeLimits, app.UIAxes1.LongitudeLimits)
                app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes1.LatitudeLimits, 'yLim', app.UIAxes1.LongitudeLimits, 'cLim', 'auto');
            end
        end


        %-----------------------------------------------------------------%
        % ## GET ##
        %-----------------------------------------------------------------%
        function [idxFile, selectedFileLocations] = getFileIndexes(app)
            if ~isempty(app.TreeFileLocations.SelectedNodes)
                selectedFileLocations = {app.TreeFileLocations.SelectedNodes.NodeData};
                idxFile = find(ismember({app.measData.Location}, selectedFileLocations));
            else
                selectedFileLocations = {};
                idxFile = [];
            end
        end

        %-----------------------------------------------------------------%
        function idxFile = getReportFileIndexes(app)
            idxFile = find(ismember({app.measData.Location}, app.reportLocations));
        end


        %-----------------------------------------------------------------%
        % ## RELATÓRIO ##
        %-----------------------------------------------------------------%
        function reportDispatchOperation(app, eventName, varargin)
            if isempty(app.mainApp.eFiscalizaObj) || ~isvalid(app.mainApp.eFiscalizaObj)
                eventData = ws.eFiscaliza.getCredentials('auto', app.mainApp.executionMode, app.jsBackDoor, eventName, app.Context, varargin{:});
                if ~isempty(eventData)
                    eventData.uuid = eventName;
                    eventData.context = app.Context;

                    if ~isempty(varargin)
                        eventData.varargin = varargin;
                    end

                    ipcMainJSEventsHandler(app.mainApp, struct('HTMLEventName', 'customForm', 'HTMLEventData', eventData))
                end
            else
                ipcMainMatlabCallsHandler(app.mainApp, app, eventName, app.Context, varargin{:})
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            
            try
                app.projectData = mainApp.projectData;
                app.measData    = getFullEMFieldData(app.projectData, mainApp.measData);

                appEngine.boot(app, app.Role, mainApp)
            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end

        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            ipcMainMatlabCallsHandler(app.mainApp, app, 'closeFcn', app.Context)
            delete(app)
            
        end

        % Image clicked function: DockCloseButton, DockUndockButton
        function onDockModuleGroupButtonClicked(app, event)
            
            [idx, auxAppTag, relatedButton] = getAppInfoFromHandle(app.mainApp.tabGroupController, app);

            switch event.Source
                case app.DockUndockButton
                    appGeneral = app.mainApp.General;
                    appGeneral.operationMode.Dock = false;
                    
                    app.mainApp.tabGroupController.Components.appHandle{idx} = [];

                    inputArguments = ipcMainMatlabCallsHandler(app.mainApp, app, 'dockButtonPushed', auxAppTag);
                    openModule(app.mainApp.tabGroupController, relatedButton, false, appGeneral, inputArguments{:})
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General, 'undock')
                    
                    delete(app)

                case app.DockCloseButton
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General)
            end

        end

        % Image clicked function: AxesRegionZoomButton,
        % ...and 1 other component
        function onAxesToolbarZoomControlButtonClicked(app, event)

            switch event.Source
                case app.AxesRestoreViewButton
                    geolimits(app.UIAxes1, app.restoreView(1).xLim, app.restoreView(1).yLim)

                case app.AxesRegionZoomButton
                    plot.axes.Interactivity.GeographicRegionZoomInteraction(app.UIAxes1, app.AxesRegionZoomButton)
            end

        end

        % Image clicked function: AxesExportGraphicsButton
        function onAxesToolbarExportGraphicsClicked(app, event)
            
            fileFormats = {'*.jpeg', '(*.jpeg)'};
            fileFullPath = ui.Dialog(app.UIFigure, 'uiputfile', '', fileFormats, app.mainApp.General.fileFolder.userPath);
            if isempty(fileFullPath)
                return
            end

            app.progressDialog.Visible = 'visible';

            try
                exportgraphics(app.AxesContainer, fileFullPath, 'ContentType', 'image', 'Resolution', app.mainApp.General.reportLib.image.resolutionDpi, 'BackgroundColor', [0,0,0])
            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end

            app.progressDialog.Visible = 'hidden';

        end

        % Value changed function: AxesBasemap
        function onAxesToolbarBasemapValueChanged(app, event)

            app.UIAxes1.Basemap = app.AxesBasemap.Value;

            switch app.AxesBasemap.Value
                case {'darkwater', 'none'}
                    app.UIAxes1.Grid = 'on';
                otherwise
                    app.UIAxes1.Grid = 'off';
            end

        end

        % Image clicked function: LeftPanelVisibilityButton,
        % ...and 2 other components
        function onToolbarInteractionButtonClicked(app, event)

            switch event.Source
                case app.LeftPanelVisibilityButton
                    app.LeftPanelVisibilityButton.UserData.status = ~app.LeftPanelVisibilityButton.UserData.status;

                    if app.LeftPanelVisibilityButton.UserData.status
                        app.LeftPanel.Visible = 'on';
                        app.Document.ColumnWidth(1:2) = {232, 10};
                        app.LeftPanelVisibilityButton.ImageSource = 'layout-sidebar-left.svg';
                    else
                        app.LeftPanel.Visible = 'off';
                        app.Document.ColumnWidth(1:2) = {0, 0};
                        app.LeftPanelVisibilityButton.ImageSource = 'layout-sidebar-left-off.svg';
                    end

                case app.PlotTableLayoutButton
                    app.PlotTableLayoutButton.UserData.layout = mod(app.PlotTableLayoutButton.UserData.layout + 1, 3);

                    switch app.PlotTableLayoutButton.UserData.layout
                        case 0
                            app.UITable.Visible = 'off';
                            app.Document.RowHeight = {24, '1x', 0, 0};
                        case 1
                            app.UITable.Visible = 'on';
                            app.Document.RowHeight = {24, '1x', 10, '0.4x'};
                        case 2
                            app.UITable.Visible = 'on';
                            app.Document.RowHeight = {0, 0, 0, '1x'};
                    end

                case app.PeakIconButton
                    if ~isempty(app.PeakIconButton.UserData)
                        ReferenceDistance_km = 1;
                        plot.zoom(app.UIAxes1, app.PeakIconButton.UserData.Latitude, app.PeakIconButton.UserData.Longitude, ReferenceDistance_km)
                        plot.datatip.Create(app.UIAxes1, 'Measures', app.PeakIconButton.UserData.idxMax)
                    end
            end

        end

        % Image clicked function: ExportFilesButton
        function onToolbarTableResultsExportButtonClicked(app, event)
            
            context = app.Context;
            fileIdxs = getFileIndexes(app);

            if ~isempty(fileIdxs)
                % <VALIDAÇÕES>
                if numel(fileIdxs) < numel(app.measData)
                    initialQuestion  = 'Deseja exportar arquivos de análise preliminar (.xlsx / .kml) que contemplem informações de TODAS as localidades de agrupamento, ou apenas da SELECIONADA?';
                    initialSelection = ui.Dialog(app.UIFigure, 'uiconfirm', initialQuestion, {'Todas', 'Selecionada', 'Cancelar'}, 1, 3);

                    switch initialSelection
                        case 'Cancelar'
                            return
                        case 'Todas'
                            fileIdxs = 1:numel(app.measData);
                    end
                end

                invalidRowIndexes = validateAuditorClassification(app.projectData, context, app.mainApp.General);
                
                if ~isempty(invalidRowIndexes)
                    msgWarning = [ ...
                        'Há registro de pontos críticos localizados na(s) localidade(s) sob análise para os quais ' ...
                        'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher '     ...
                        'o campo "Justificativa" e anotar os registros, caso aplicável.<br><br>Deseja ignorar '     ...
                        'esse alerta, exportando PRÉVIA da análise?' ...
                    ];
                    userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgWarning, {'Sim', 'Não'}, 2, 2);
                    if userSelection == "Não"
                        return
                    end
                end
                % </VALIDAÇÕES>
    
                % <PROCESSO>
                % (a) Solicita ao usuário nome do arquivo de saída...
                appName       = class.Constants.appName;
                nameFormatMap = {'*.zip', [appName, ' (*.zip)']};                
                defaultName   = appEngine.util.DefaultFileName(app.mainApp.General.fileFolder.userPath, [appName '_Preview']);
                fileZIP       = ui.Dialog(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
                if isempty(fileZIP)
                    return
                end
    
                d = ui.Dialog(app.UIFigure, 'progressdlg', 'Em andamento a criação do arquivo de medidas no formato ".xlsx".');
    
                savedFiles = {};
                errorFiles = {};
    
                % (b) Gera a tabela global de medidas (englobando todas as localidades 
                %     de agrupamento).
                measTableGlobal = buildMeasurementTable(app.measData(fileIdxs));
                pointsTable = app.projectData.modules.(context).pointsTable;

                % (c) Arquivo no formato .XLSX
                fileName_XLSX = fullfile(app.mainApp.General.fileFolder.tempPath, 'Demanda externa (Preview).xlsx');
                [status, msgError] = model.ProjectBase.exportAnalysisPreview(app.Context, pointsTable, app.mainApp.General, timetable2table(measTableGlobal), fileName_XLSX, app.mainApp.General.context.EXTERNALREQUEST.exportOptions.xlsx);
                if status
                    savedFiles{end+1} = fileName_XLSX;
                else
                    errorFiles{end+1} = msgError;
                end
        
                % (d) Arquivos no formato .KML: "Measures" e "Route" 
                if app.mainApp.General.context.EXTERNALREQUEST.exportOptions.kml
                    d.Message = textFormatGUI.HTMLParagraph('Em andamento a criação dos arquivos de medidas e rotas no formato ".kml".');

                    groupLocations = unique({app.measData(fileIdxs).Location});

                    for ii = 1:numel(groupLocations)
                        groupLocation = groupLocations{ii};
                        [~, groupLocationIndex] = ismember(groupLocation, {app.TreeFileLocations.Children.NodeData});

                        if ~isequal(app.TreeFileLocations.SelectedNodes, app.TreeFileLocations.Children(groupLocationIndex))
                            app.TreeFileLocations.SelectedNodes = app.TreeFileLocations.Children(groupLocationIndex);
                            onFileLocationsSelectionChanged(app, struct('SelectedNodes', app.TreeFileLocations.Children(groupLocationIndex)))
                        end

                        groupLocationText      = replace(app.TreeFileLocations.SelectedNodes.NodeData, '/', '-');
                        groupLocationIndexes   = getFileIndexes(app);
                        groupLocationMeasTable = timetable2table(buildMeasurementTable(app.measData(groupLocationIndexes)));

                        % MEDIDAS
                        hMeasPlot = findobj(app.UIAxes1.Children, 'Tag', 'Measures');
                        KML1File  = fullfile(app.mainApp.General.fileFolder.tempPath, sprintf('%s (Measures).kml', groupLocationText));
                        [status1, msgError1] = RF.KML.generateKML(KML1File, 'measures', groupLocationMeasTable, 'FieldValue', hMeasPlot);
                        if status1
                            savedFiles{end+1} = KML1File;
                        else
                            errorFiles{end+1} = msgError1;
                        end

                        % ROTA
                        KML2File = fullfile(app.mainApp.General.fileFolder.tempPath, sprintf('%s (Route).kml', groupLocationText));
                        [status2, msgError2] = RF.KML.generateKML(KML2File, 'route', groupLocationMeasTable);
                        if status2
                            savedFiles{end+1} = KML2File;
                        else
                            errorFiles{end+1} = msgError2;
                        end
                    end
                end

                % (e) Arquivo no formato .ZIP
                if ~isempty(savedFiles)
                    zip(fileZIP, savedFiles)
    
                    [~, fileName, fileExt] = fileparts(savedFiles);
                    savedFiles = strcat('•&thinsp;', fileName, fileExt);
                    ui.Dialog(app.UIFigure, 'none', sprintf('Lista de arquivos criados:\n%s', strjoin(savedFiles, '\n')));
                end
    
                if ~isempty(errorFiles)
                    ui.Dialog(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
                end

                delete(d)
            end

        end

        % Image clicked function: OpenPopupProject
        function onToolbarProjectModuleButtonClicked(app, event)
            
            ipcMainMatlabOpenPopupApp(app.mainApp, app, 'ReportLib', app.Context, app.measData)

        end

        % Image clicked function: GenerateReport
        function onToolbarGenerateReportButtonClicked(app, event)
            
            context = app.Context;
            fileIdxs = getReportFileIndexes(app);
            
            issue = app.projectData.modules.(context).ui.issue;
            reportVersion = app.projectData.modules.(context).ui.reportVersion;

            if ~validateReportRequirements(app.projectData, context, 'reportModel')
                ui.Dialog(app.UIFigure, 'warning', 'Pendente escolha do modelo de relatório.');
                return
            end

            % <VALIDAÇÕES>
            if isempty(fileIdxs)
                ui.Dialog(app.UIFigure, 'warning', 'Nenhuma localidade de agrupamento está marcada para inclusão no relatório. Marque ao menos uma em "Gerenciamento do projeto".');
                return
            end

            msgWarning = {};
            if ~validateReportRequirements(app.projectData, context, 'issue')
                msgWarning{end+1} = sprintf('• O número da inspeção "%.0f" é inválido.', issue);
            end

            if ~validateReportRequirements(app.projectData, context, 'unit')
                msgWarning{end+1} = '• Unidade geradora do documento precisa ser selecionada.';
            end

            invalidRowIndexes = validateAuditorClassification(app.projectData, app.Context, app.mainApp.General);
            if ~isempty(invalidRowIndexes)
                msgWarning{end+1} = [
                    '• Há registro de estações instaladas na(s) localidade(s) sob análise para as quais '     ...
                    'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                    'o campo "Justificativa" e anotar os registros, caso aplicável.'                        ...
                ];
            end

            if isempty(msgWarning)
                switch reportVersion
                    case 'Definitiva'
                        msgQuestion = sprintf('Confirma que se trata de monitoração relacionada à Atividade de Inspeção nº %.0f?', issue);
                        userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 1, 2);
                        if userSelection == "Não"
                            return
                        end
                        
                    case 'Preliminar'
                        % ...
                end

            else
                msgInfo = model.ProjectBase.WARNING_VALIDATIONSRULES.EXTERNALREQUEST;

                switch reportVersion
                    case 'Definitiva'
                        msgInfo = sprintf([ ...
                                'Foi(ram) identificada(s) pendência(s) :<br>%s' ...
                                '<br><br>' ...
                                '<b>Essa(s) pendência(s) precisa(m) ser resolvida(s) ' ...
                                'antes de ser gerada a versão "Definitiva" do relatório</b>. ' ...
                                '<br><br>' ...
                                '<font style="color: gray; font-size: 11px;">%s</font></p>' ...
                            ], strjoin(msgWarning, '<br>'), msgInfo ...
                        );
                        ui.Dialog(app.UIFigure, 'warning', msgInfo);
                        return

                    case 'Preliminar'
                        msgQuestion = sprintf([ ...
                                'Foi(ram) identificado(s) a(s) pendência(s):<br>%s' ...
                                '<br><br>' ...
                                '<b>Continuar mesmo assim?</b>' ...
                                '<br><br>' ...
                                '<font style="color: gray; font-size: 11px;">%s</font></p>' ...
                            ], strjoin(msgWarning, '<br>'), msgInfo ...
                        );
                        selection = ui.Dialog(app.UIFigure, "uiconfirm", msgQuestion, {'Sim', 'Não'}, 1, 2);
                        if strcmp(selection, 'Não')
                            return
                        end
                end
            end
            % </VALIDAÇÕES>

            % <PROCESSO>
            reportDispatchOperation(app, 'onReportGenerate', fileIdxs)
            % </PROCESSO>

        end

        % Image clicked function: UploadFinalFile
        function onToolbarUploadFinalFileButtonClicked(app, event)
            
            % <VALIDAÇÕES>
            context = app.Context;
            system = app.projectData.modules.(context).ui.system;
            issue = app.projectData.modules.(context).ui.issue;
            generatedHtmlFilePath = getGeneratedDocumentFileName(app.projectData, '.html', context);
            
            msg = '';
            if isempty(generatedHtmlFilePath)
                msg = 'A versão definitiva do relatório ainda não foi gerada.';
            elseif ~isfile(generatedHtmlFilePath)
                msg = sprintf('O arquivo "%s" não foi encontrado.', generatedHtmlFilePath);
            elseif ~isfolder(app.mainApp.General.fileFolder.DataHub_POST)
                msg = 'Pendente mapear pasta do Sharepoint';
            elseif ~validateReportRequirements(app.projectData, context, 'issue')
                msg = sprintf('O número da inspeção "%.0f" é inválido.', issue);
            elseif ~validateReportRequirements(app.projectData, context, 'unit')
                msg = 'Unidade geradora do documento precisa ser selecionada.';
            elseif isempty(system)
                msg = 'Ambiente do eFiscaliza precisa ser selecionado.';
            end

            if ~isempty(msg)
                ui.Dialog(app.UIFigure, 'warning', msg);
                return
            end

            selectedMeasData  = app.measData(getReportFileIndexes(app));
            storedReportHash  = app.projectData.modules.(context).generatedFiles.id;
            currentReportHash = model.ProjectBase.computeReportAnalysisResultsHash(app.projectData.modules, context, selectedMeasData);

            if ~isequal(storedReportHash, currentReportHash)
                [~, generatedHtmlFileName, generatedHtmlFileExt] = fileparts(generatedHtmlFilePath);
                msgQuestion = sprintf([ ...
                    'O relatório indicado a seguir foi gerado com base em ' ...
                    'um conjunto específico de arquivos e anotações.<br>%s<br><br>' ...
                    '<i>Hash</i> no momento da geração:<br>' ...
                    '%s<br><br>' ...
                    '<i>Hash</i> atual (após alterações):<br>' ...
                    '%s<br><br>' ...
                    'Isso indica que um arquivo diferente foi selecionado ' ...
                    'ou que alguma anotação foi modificada desde a geração ' ...
                    'do relatório.<br><br>' ...
                    '<b>Deseja continuar com o <i>upload</i> mesmo assim?</b>' ...
                ], [generatedHtmlFileName, generatedHtmlFileExt], textFormatGUI.cellstr2Bullets(strsplit(storedReportHash, ' - ')), textFormatGUI.cellstr2Bullets(strsplit(currentReportHash, ' - ')));
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);

                if strcmp(userSelection, 'Não')
                    return
                end
            end

            uploadedFiles = getUploadedFiles(app.projectData, context, system, issue);
            if ~isempty(uploadedFiles)
                uploadedStatus = extractAfter({uploadedFiles.status}, 'Documento cadastrado no SEI sob o nº ');

                if isscalar(uploadedStatus)
                    uploadedStatus = uploadedStatus{1};
                else                    
                    uploadedStatus = strjoin([{strjoin(uploadedStatus(1:end-1), ', ')}, uploadedStatus(end)], ' e ');
                end

                msgQuestion = sprintf([ ...
                    'Já foi realizado <i>upload</i> para o SEI de relatório que engloba ' ...
                    'a presente lista de produtos sob análise - SEI nº %s.<br><br>' ...
                    'Deseja realizar um novo <i>upload</i> para o SEI?' ...
                ], uploadedStatus);
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);

                if strcmp(userSelection, 'Não')
                    return
                end
            end
            % </VALIDAÇÕES>

            % <PROCESSO>
            reportDispatchOperation(app, 'onUploadArtifacts')
            % </PROCESSO>

        end

        % Selection changed function: TreeFileLocations
        function onFileLocationsSelectionChanged(app, event)
            
            if isempty(event.SelectedNodes)
                app.TreeFileLocations.SelectedNodes = event.PreviousSelectedNodes;
                return
            end

            refreshAnalysis(app)

        end

        % Image clicked function: AddNewPointCancel, AddNewPointConfirm, 
        % ...and 1 other component
        function onNewPointEditionModeButtonClicked(app, event)
            
            switch event.Source
                case app.AddNewPointMode
                    app.AddNewPointMode.UserData.status = ~app.AddNewPointMode.UserData.status;
                    
                    if app.AddNewPointMode.UserData.status
                        setAddPointPanelEnabled(app, 'on')
                    else
                        setAddPointPanelEnabled(app, 'off')
                    end

                case app.AddNewPointConfirm
                    % VALIDAÇÃO
                    msgWarning = '';
                    if isempty(app.NewPointType.Value) || isempty(app.NewPointLatitude.Value) || isempty(app.NewPointLongitude.Value)
                        msgWarning = 'Um novo ponto crítico somente poderá ser incluído se definido o seu tipo e coordenadas geográficas.';

                    elseif app.NewPointLatitude.Value  < app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lat.min || ...
                           app.NewPointLatitude.Value  > app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lat.max || ...
                           app.NewPointLongitude.Value < app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lng.min || ...
                           app.NewPointLongitude.Value > app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lng.max
                        
                        msgWarning = sprintf([ ...
                            'Um novo ponto crítico somente poderá ser incluído ' ...
                            'se definido dentro dos limites:<br>' ...
                            '• Latitude: %.2fº a %.2fº<br>' ...
                            '• Longitude: %.2fº a %.2fº' ...
                        ], app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lat.min, app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lat.max, app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lng.min, app.mainApp.General.context.EXTERNALREQUEST.locationLimits.lng.max);

                    end

                    if ~isempty(msgWarning)
                        ui.Dialog(app.UIFigure, 'warning', msgWarning);
                        return
                    end
        
                    % CRIA ID DO NOVO PONTO
                    switch app.NewPointType.Value
                        case 'Estação'
                            pointId = num2str(app.NewPointStation.Value);
                        otherwise
                            pointId = app.NewPointType.Value;
                    end
                    pointId = sprintf('%s @ (%.6f, %.6f)', pointId, app.NewPointLatitude.Value, app.NewPointLongitude.Value);
        
                    % VERIFICA SE ESSE ID JÁ TINHA SIDO INCLUÍDO
                    if any(strcmp(app.projectData.modules.EXTERNALREQUEST.pointsTable_I.ID, pointId))
                        ui.Dialog(app.UIFigure, 'warning', 'Registro já consta na lista de pontos sob análise.');
                        return
                    end

                    valuesToFill = {
                        pointId,                       ...
                        app.NewPointType.Value,        ...
                        app.NewPointStation.Value,     ...
                        app.NewPointLatitude.Value,    ...
                        app.NewPointLongitude.Value,   ...
                        app.NewPointDescription.Value, ...
                        categorical("-"),              ...
                        '',                            ...
                        false
                    };
                    updatePointsTable(app.projectData, app.measData, app.mainApp.General, 'onPointAdded', valuesToFill)
        
                    % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                    buildPointsTree(app)
        
                    % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                    refreshAnalysis(app)

                    % DESABILITA MODO DE INCLUSÃO DE PONTO
                    setAddPointPanelEnabled(app, 'off')

                case app.AddNewPointCancel
                    setAddPointPanelEnabled(app, 'off')
            end

        end

        % Value changed function: NewPointType
        function onNewPointTypeValueChanged(app, event)

            switch app.NewPointType.Value
                case 'Estação'
                    set([app.NewPointStationLabel, app.NewPointStation], 'Visible', 'on')
                    set([app.NewPointLatitude, app.NewPointLongitude],  'Value', [], 'Enable', 'off')
                    app.NewPointType.Layout.Column = 1;

                    focus(app.NewPointStation)

                otherwise
                    app.NewPointStationLabel.Visible = 'off';
                    set(app.NewPointStation, 'Value', -1, 'Visible', 'off')
                    set([app.NewPointLatitude, app.NewPointLongitude], 'Enable', 'on')
                    app.NewPointType.Layout.Column = [1 2];
            end

        end

        % Value changed function: NewPointStation
        function onNewPointStationValueChanged(app, event)

            rfDataHubIdx = find(app.mainApp.rfDataHub.Station == app.NewPointStation.Value, 1);

            if ~isempty(rfDataHubIdx)
                lat = round(app.mainApp.rfDataHub.Latitude(rfDataHubIdx),  6);
                lng = round(app.mainApp.rfDataHub.Longitude(rfDataHubIdx), 6);

                set(app.NewPointLatitude,  'Value', lat, 'Enable', 'on')
                set(app.NewPointLongitude, 'Value', lng, 'Enable', 'on')

            else
                set(app.NewPointLatitude,  'Value', [], 'Enable', 'off')
                set(app.NewPointLongitude, 'Value', [], 'Enable', 'off')
            end

        end

        % Value changed function: NewPointLatitude
        function onNewPointLatitudeValueChanged(app, event)

            focus(app.NewPointLongitude)

        end

        % Selection changed function: PointList
        function onPointListSelectionChanged(app, event)

            pointIdx = [];
            if ~isempty(app.PointList.SelectedNodes)
                pointIdx = app.PointList.SelectedNodes.NodeData;
            end

            % Nessa operação, o foco sai de app.PointList e vai pra app.UITable.
            previousSelection = app.UITable.Selection;
            app.UITable.Selection = pointIdx;
            drawnow

            onUITableSelectionChanged(app, struct('PreviousSelection', previousSelection, 'Selection', pointIdx))
            focus(app.PointList)

        end

        % Selection changed function: UITable
        function onUITableSelectionChanged(app, event)

            if exist('event', 'var') && ~isempty(event.PreviousSelection) && isequal(event.Selection, event.PreviousSelection)
                return
            end

            if isempty(event.Selection)
                app.UITable.ContextMenu = [];
                app.PointList.SelectedNodes = [];
            else
                if isempty(app.UITable.ContextMenu)
                    app.UITable.ContextMenu = app.ContextMenu;
                end
                app.PointList.SelectedNodes = app.PointList.Children(event.Selection);
            end

            plotSelectedPoint(app)

        end

        % Cell edit callback: UITable
        function onUITableCellEdit(app, event)

            if isequal(event.PreviousData, event.NewData)
                return
            end

            pointIdx = event.Indices(1);
            updatePointsTable(app.projectData, [], [], 'onPointInfoChanged', pointIdx, event.NewData)

            applyTableStyle(app)

        end

        % Menu selected function: DeletePoint
        function onDeleteSelectedPoint(app, event)
            
            pointIdx = [];

            if ismember(app.PointList, [event.ContextObject, event.ContextObject.Parent])
                if ~isempty(app.PointList.SelectedNodes)
                    pointIdx = app.PointList.SelectedNodes.NodeData;
                end
            elseif event.ContextObject == app.UITable
                pointIdx = app.UITable.Selection;
            end

            if ~isempty(pointIdx)
                updatePointsTable(app.projectData, app.measData, app.mainApp.General, 'onPointRemoved', pointIdx)

                % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                buildPointsTree(app)
    
                % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                refreshAnalysis(app)
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, Container)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            if isempty(Container)
                app.UIFigure = uifigure('Visible', 'off');
                app.UIFigure.AutoResizeChildren = 'off';
                app.UIFigure.Position = [100 100 1244 660];
                app.UIFigure.Name = 'monitorRNI';
                app.UIFigure.Icon = 'icon_48.png';
                app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

                app.Container = app.UIFigure;

            else
                children = Container.Children;
                if isa(Container, 'matlab.ui.Figure') && isprop(Container, 'RunningAppInstance') && isprop(Container.RunningAppInstance, 'jsBackDoor')
                    children(children == Container.RunningAppInstance.jsBackDoor) = [];
                end
                delete(children)

                app.UIFigure  = ancestor(Container, 'figure');
                app.Container = Container;
                if ~isprop(Container, 'RunningAppInstance')
                    addprop(app.Container, 'RunningAppInstance');
                end
                app.Container.RunningAppInstance = app;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {20, '1x', 38, 10, 8, 2};
            app.GridLayout.RowHeight = {2, 8, 10, 14, '1x', 20, 34};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create Toolbar
            app.Toolbar = uigridlayout(app.GridLayout);
            app.Toolbar.ColumnWidth = {22, 22, 5, 22, 5, 22, '1x', 22, 22, 22};
            app.Toolbar.RowHeight = {4, 17, '1x'};
            app.Toolbar.ColumnSpacing = 5;
            app.Toolbar.RowSpacing = 0;
            app.Toolbar.Padding = [10 5 10 5];
            app.Toolbar.Layout.Row = 7;
            app.Toolbar.Layout.Column = [1 6];
            app.Toolbar.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create LeftPanelVisibilityButton
            app.LeftPanelVisibilityButton = uiimage(app.Toolbar);
            app.LeftPanelVisibilityButton.ScaleMethod = 'none';
            app.LeftPanelVisibilityButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarInteractionButtonClicked, true);
            app.LeftPanelVisibilityButton.Layout.Row = [1 3];
            app.LeftPanelVisibilityButton.Layout.Column = 1;
            app.LeftPanelVisibilityButton.ImageSource = 'layout-sidebar-left.svg';

            % Create PlotTableLayoutButton
            app.PlotTableLayoutButton = uiimage(app.Toolbar);
            app.PlotTableLayoutButton.ScaleMethod = 'none';
            app.PlotTableLayoutButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarInteractionButtonClicked, true);
            app.PlotTableLayoutButton.Layout.Row = [1 3];
            app.PlotTableLayoutButton.Layout.Column = 2;
            app.PlotTableLayoutButton.ImageSource = 'View_16.png';

            % Create ToolbarSeparator1
            app.ToolbarSeparator1 = uiimage(app.Toolbar);
            app.ToolbarSeparator1.ScaleMethod = 'none';
            app.ToolbarSeparator1.Enable = 'off';
            app.ToolbarSeparator1.Layout.Row = [1 3];
            app.ToolbarSeparator1.Layout.Column = 3;
            app.ToolbarSeparator1.ImageSource = 'LineV.svg';

            % Create ExportFilesButton
            app.ExportFilesButton = uiimage(app.Toolbar);
            app.ExportFilesButton.ScaleMethod = 'none';
            app.ExportFilesButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarTableResultsExportButtonClicked, true);
            app.ExportFilesButton.Enable = 'off';
            app.ExportFilesButton.Layout.Row = [1 3];
            app.ExportFilesButton.Layout.Column = 4;
            app.ExportFilesButton.ImageSource = 'Export_16.png';

            % Create ToolbarSeparator2
            app.ToolbarSeparator2 = uiimage(app.Toolbar);
            app.ToolbarSeparator2.ScaleMethod = 'none';
            app.ToolbarSeparator2.Enable = 'off';
            app.ToolbarSeparator2.Layout.Row = [1 3];
            app.ToolbarSeparator2.Layout.Column = 5;
            app.ToolbarSeparator2.ImageSource = 'LineV.svg';

            % Create PeakIconButton
            app.PeakIconButton = uiimage(app.Toolbar);
            app.PeakIconButton.ScaleMethod = 'none';
            app.PeakIconButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarInteractionButtonClicked, true);
            app.PeakIconButton.Enable = 'off';
            app.PeakIconButton.Layout.Row = [1 3];
            app.PeakIconButton.Layout.Column = 6;
            app.PeakIconButton.ImageSource = 'Detection_18.png';

            % Create PeakLabelButton
            app.PeakLabelButton = uilabel(app.Toolbar);
            app.PeakLabelButton.FontSize = 10;
            app.PeakLabelButton.Visible = 'off';
            app.PeakLabelButton.Layout.Row = [1 3];
            app.PeakLabelButton.Layout.Column = 7;
            app.PeakLabelButton.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create OpenPopupProject
            app.OpenPopupProject = uiimage(app.Toolbar);
            app.OpenPopupProject.ScaleMethod = 'none';
            app.OpenPopupProject.ImageClickedFcn = createCallbackFcn(app, @onToolbarProjectModuleButtonClicked, true);
            app.OpenPopupProject.Layout.Row = [1 3];
            app.OpenPopupProject.Layout.Column = 8;
            app.OpenPopupProject.ImageSource = 'organization-20px-black.svg';

            % Create GenerateReport
            app.GenerateReport = uiimage(app.Toolbar);
            app.GenerateReport.ScaleMethod = 'none';
            app.GenerateReport.ImageClickedFcn = createCallbackFcn(app, @onToolbarGenerateReportButtonClicked, true);
            app.GenerateReport.Layout.Row = [1 3];
            app.GenerateReport.Layout.Column = 9;
            app.GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create UploadFinalFile
            app.UploadFinalFile = uiimage(app.Toolbar);
            app.UploadFinalFile.ScaleMethod = 'none';
            app.UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @onToolbarUploadFinalFileButtonClicked, true);
            app.UploadFinalFile.Enable = 'off';
            app.UploadFinalFile.Layout.Row = [1 3];
            app.UploadFinalFile.Layout.Column = 10;
            app.UploadFinalFile.ImageSource = 'up-20px.png';

            % Create Document
            app.Document = uigridlayout(app.GridLayout);
            app.Document.ColumnWidth = {232, 10, 5, 215, '1x'};
            app.Document.RowHeight = {24, '1x', 10, '0.4x'};
            app.Document.ColumnSpacing = 0;
            app.Document.RowSpacing = 0;
            app.Document.Padding = [0 0 0 0];
            app.Document.Layout.Row = [4 5];
            app.Document.Layout.Column = [2 3];
            app.Document.BackgroundColor = [1 1 1];

            % Create LeftPanel
            app.LeftPanel = uipanel(app.Document);
            app.LeftPanel.Layout.Row = [1 4];
            app.LeftPanel.Layout.Column = 1;

            % Create LeftPanelGrid
            app.LeftPanelGrid = uigridlayout(app.LeftPanel);
            app.LeftPanelGrid.ColumnWidth = {22, '1x', '1x', 18, 0, 0};
            app.LeftPanelGrid.RowHeight = {92, 5, 12, 18, 5, 134, 20, 18, 5, 170, 0, '1x'};
            app.LeftPanelGrid.ColumnSpacing = 5;
            app.LeftPanelGrid.RowSpacing = 0;
            app.LeftPanelGrid.BackgroundColor = [1 1 1];

            % Create ModuleIcon
            app.ModuleIcon = uiimage(app.LeftPanelGrid);
            app.ModuleIcon.Layout.Row = 1;
            app.ModuleIcon.Layout.Column = 1;
            app.ModuleIcon.VerticalAlignment = 'top';
            app.ModuleIcon.ImageSource = 'report-24px.svg';

            % Create ModuleIntro
            app.ModuleIntro = uilabel(app.LeftPanelGrid);
            app.ModuleIntro.VerticalAlignment = 'top';
            app.ModuleIntro.WordWrap = 'on';
            app.ModuleIntro.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.ModuleIntro.Layout.Row = 1;
            app.ModuleIntro.Layout.Column = [2 6];
            app.ModuleIntro.Interpreter = 'html';
            app.ModuleIntro.Text = {'<b>Demanda externa</b>'; '<p style="padding: 2px; text-align: justify; font-size: 10px; color: gray; line-height: 13px">Análise de medições de campo elétrico realizadas no entorno de pontos de interesse pedidos pelo demandante, como escola, hospital etc.</p>'};

            % Create TreeFileLocationsLabel
            app.TreeFileLocationsLabel = uilabel(app.LeftPanelGrid);
            app.TreeFileLocationsLabel.VerticalAlignment = 'bottom';
            app.TreeFileLocationsLabel.WordWrap = 'on';
            app.TreeFileLocationsLabel.FontSize = 11;
            app.TreeFileLocationsLabel.Layout.Row = [3 4];
            app.TreeFileLocationsLabel.Layout.Column = [1 6];
            app.TreeFileLocationsLabel.Interpreter = 'html';
            app.TreeFileLocationsLabel.Text = {'Localidades de agrupamento:'; '<font style="color: gray; font-size: 10px;">Identificadas nos arquivos de medição</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.LeftPanelGrid);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @onFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 6;
            app.TreeFileLocations.Layout.Column = [1 6];

            % Create PointListLabel
            app.PointListLabel = uilabel(app.LeftPanelGrid);
            app.PointListLabel.VerticalAlignment = 'bottom';
            app.PointListLabel.FontSize = 11;
            app.PointListLabel.Layout.Row = [7 8];
            app.PointListLabel.Layout.Column = [1 3];
            app.PointListLabel.Interpreter = 'html';
            app.PointListLabel.Text = {'Pontos sob análise:'; '<font style="color: gray; font-size: 10px;">Pedido pelo demandante</font>'};

            % Create PointList
            app.PointList = uitree(app.LeftPanelGrid);
            app.PointList.SelectionChangedFcn = createCallbackFcn(app, @onPointListSelectionChanged, true);
            app.PointList.FontSize = 11;
            app.PointList.Layout.Row = 12;
            app.PointList.Layout.Column = [1 6];

            % Create AddNewPointMode
            app.AddNewPointMode = uiimage(app.LeftPanelGrid);
            app.AddNewPointMode.ImageClickedFcn = createCallbackFcn(app, @onNewPointEditionModeButtonClicked, true);
            app.AddNewPointMode.Layout.Row = 8;
            app.AddNewPointMode.Layout.Column = 4;
            app.AddNewPointMode.ImageSource = 'addFiles_32.png';

            % Create AddNewPointConfirm
            app.AddNewPointConfirm = uiimage(app.LeftPanelGrid);
            app.AddNewPointConfirm.ImageClickedFcn = createCallbackFcn(app, @onNewPointEditionModeButtonClicked, true);
            app.AddNewPointConfirm.Layout.Row = 8;
            app.AddNewPointConfirm.Layout.Column = 5;
            app.AddNewPointConfirm.ImageSource = 'Ok_32Green.png';

            % Create AddNewPointCancel
            app.AddNewPointCancel = uiimage(app.LeftPanelGrid);
            app.AddNewPointCancel.ImageClickedFcn = createCallbackFcn(app, @onNewPointEditionModeButtonClicked, true);
            app.AddNewPointCancel.Layout.Row = 8;
            app.AddNewPointCancel.Layout.Column = 6;
            app.AddNewPointCancel.ImageSource = 'Delete_32Red.png';

            % Create AddNewPointPanel
            app.AddNewPointPanel = uipanel(app.LeftPanelGrid);
            app.AddNewPointPanel.AutoResizeChildren = 'off';
            app.AddNewPointPanel.Layout.Row = 10;
            app.AddNewPointPanel.Layout.Column = [1 6];

            % Create AddNewPointGrid
            app.AddNewPointGrid = uigridlayout(app.AddNewPointPanel);
            app.AddNewPointGrid.RowHeight = {17, 22, 22, 22, 22, 22};
            app.AddNewPointGrid.RowSpacing = 5;
            app.AddNewPointGrid.Padding = [10 10 10 5];
            app.AddNewPointGrid.BackgroundColor = [1 1 1];

            % Create NewPointTypeLabel
            app.NewPointTypeLabel = uilabel(app.AddNewPointGrid);
            app.NewPointTypeLabel.VerticalAlignment = 'bottom';
            app.NewPointTypeLabel.FontSize = 10;
            app.NewPointTypeLabel.Layout.Row = 1;
            app.NewPointTypeLabel.Layout.Column = 1;
            app.NewPointTypeLabel.Text = 'Tipo:';

            % Create NewPointType
            app.NewPointType = uidropdown(app.AddNewPointGrid);
            app.NewPointType.Items = {};
            app.NewPointType.ValueChangedFcn = createCallbackFcn(app, @onNewPointTypeValueChanged, true);
            app.NewPointType.FontSize = 11;
            app.NewPointType.BackgroundColor = [1 1 1];
            app.NewPointType.Layout.Row = 2;
            app.NewPointType.Layout.Column = [1 2];
            app.NewPointType.Value = {};

            % Create NewPointStationLabel
            app.NewPointStationLabel = uilabel(app.AddNewPointGrid);
            app.NewPointStationLabel.VerticalAlignment = 'bottom';
            app.NewPointStationLabel.FontSize = 10;
            app.NewPointStationLabel.Visible = 'off';
            app.NewPointStationLabel.Layout.Row = 1;
            app.NewPointStationLabel.Layout.Column = 2;
            app.NewPointStationLabel.Text = 'Estação:';

            % Create NewPointStation
            app.NewPointStation = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointStation.Limits = [-1 Inf];
            app.NewPointStation.RoundFractionalValues = 'on';
            app.NewPointStation.ValueDisplayFormat = '%d';
            app.NewPointStation.ValueChangedFcn = createCallbackFcn(app, @onNewPointStationValueChanged, true);
            app.NewPointStation.HorizontalAlignment = 'left';
            app.NewPointStation.FontSize = 11;
            app.NewPointStation.Visible = 'off';
            app.NewPointStation.Layout.Row = 2;
            app.NewPointStation.Layout.Column = 2;
            app.NewPointStation.Value = -1;

            % Create NewPointLatitudeLabel
            app.NewPointLatitudeLabel = uilabel(app.AddNewPointGrid);
            app.NewPointLatitudeLabel.VerticalAlignment = 'bottom';
            app.NewPointLatitudeLabel.FontSize = 10;
            app.NewPointLatitudeLabel.Layout.Row = 3;
            app.NewPointLatitudeLabel.Layout.Column = 1;
            app.NewPointLatitudeLabel.Text = 'Latitude:';

            % Create NewPointLatitude
            app.NewPointLatitude = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointLatitude.Limits = [-90 90];
            app.NewPointLatitude.ValueDisplayFormat = '%.6f';
            app.NewPointLatitude.AllowEmpty = 'on';
            app.NewPointLatitude.ValueChangedFcn = createCallbackFcn(app, @onNewPointLatitudeValueChanged, true);
            app.NewPointLatitude.HorizontalAlignment = 'left';
            app.NewPointLatitude.FontSize = 11;
            app.NewPointLatitude.Layout.Row = 4;
            app.NewPointLatitude.Layout.Column = 1;
            app.NewPointLatitude.Value = [];

            % Create NewPointLongitude
            app.NewPointLongitude = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointLongitude.Limits = [-180 180];
            app.NewPointLongitude.ValueDisplayFormat = '%.6f';
            app.NewPointLongitude.AllowEmpty = 'on';
            app.NewPointLongitude.HorizontalAlignment = 'left';
            app.NewPointLongitude.FontSize = 11;
            app.NewPointLongitude.Layout.Row = 4;
            app.NewPointLongitude.Layout.Column = 2;
            app.NewPointLongitude.Value = [];

            % Create NewPointLongitudeLabel
            app.NewPointLongitudeLabel = uilabel(app.AddNewPointGrid);
            app.NewPointLongitudeLabel.VerticalAlignment = 'bottom';
            app.NewPointLongitudeLabel.FontSize = 10;
            app.NewPointLongitudeLabel.Layout.Row = 3;
            app.NewPointLongitudeLabel.Layout.Column = 2;
            app.NewPointLongitudeLabel.Text = 'Longitude:';

            % Create NewPointDescription
            app.NewPointDescription = uieditfield(app.AddNewPointGrid, 'text');
            app.NewPointDescription.FontSize = 11;
            app.NewPointDescription.Layout.Row = 6;
            app.NewPointDescription.Layout.Column = [1 2];

            % Create NewPointDescriptionLabel
            app.NewPointDescriptionLabel = uilabel(app.AddNewPointGrid);
            app.NewPointDescriptionLabel.VerticalAlignment = 'bottom';
            app.NewPointDescriptionLabel.FontSize = 10;
            app.NewPointDescriptionLabel.Layout.Row = 5;
            app.NewPointDescriptionLabel.Layout.Column = [1 2];
            app.NewPointDescriptionLabel.Text = 'Descrição:';

            % Create AxesContainer
            app.AxesContainer = uipanel(app.Document);
            app.AxesContainer.AutoResizeChildren = 'off';
            app.AxesContainer.BorderType = 'none';
            app.AxesContainer.BackgroundColor = [0 0 0];
            app.AxesContainer.Layout.Row = [1 2];
            app.AxesContainer.Layout.Column = [3 5];

            % Create AxesToolbar
            app.AxesToolbar = uigridlayout(app.Document);
            app.AxesToolbar.ColumnWidth = {10, 25, 25, 25, 5, 110, 10};
            app.AxesToolbar.RowHeight = {22};
            app.AxesToolbar.ColumnSpacing = 0;
            app.AxesToolbar.Padding = [0 2 0 1];
            app.AxesToolbar.Layout.Row = 1;
            app.AxesToolbar.Layout.Column = 4;
            app.AxesToolbar.BackgroundColor = [1 1 1];

            % Create AxesRestoreViewButton
            app.AxesRestoreViewButton = uiimage(app.AxesToolbar);
            app.AxesRestoreViewButton.ScaleMethod = 'none';
            app.AxesRestoreViewButton.ImageClickedFcn = createCallbackFcn(app, @onAxesToolbarZoomControlButtonClicked, true);
            app.AxesRestoreViewButton.Layout.Row = 1;
            app.AxesRestoreViewButton.Layout.Column = 2;
            app.AxesRestoreViewButton.ImageSource = 'Home_18.png';

            % Create AxesRegionZoomButton
            app.AxesRegionZoomButton = uiimage(app.AxesToolbar);
            app.AxesRegionZoomButton.ScaleMethod = 'none';
            app.AxesRegionZoomButton.ImageClickedFcn = createCallbackFcn(app, @onAxesToolbarZoomControlButtonClicked, true);
            app.AxesRegionZoomButton.Layout.Row = 1;
            app.AxesRegionZoomButton.Layout.Column = 3;
            app.AxesRegionZoomButton.ImageSource = 'ZoomRegion_20.png';

            % Create AxesExportGraphicsButton
            app.AxesExportGraphicsButton = uiimage(app.AxesToolbar);
            app.AxesExportGraphicsButton.ScaleMethod = 'none';
            app.AxesExportGraphicsButton.ImageClickedFcn = createCallbackFcn(app, @onAxesToolbarExportGraphicsClicked, true);
            app.AxesExportGraphicsButton.Layout.Row = 1;
            app.AxesExportGraphicsButton.Layout.Column = 4;
            app.AxesExportGraphicsButton.ImageSource = 'screen-cut.svg';

            % Create AxesBasemap
            app.AxesBasemap = uidropdown(app.AxesToolbar);
            app.AxesBasemap.Items = {'none', 'darkwater', 'streets-light', 'streets-dark', 'satellite', 'topographic', 'grayterrain'};
            app.AxesBasemap.ValueChangedFcn = createCallbackFcn(app, @onAxesToolbarBasemapValueChanged, true);
            app.AxesBasemap.FontSize = 11;
            app.AxesBasemap.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.AxesBasemap.BackgroundColor = [1 1 1];
            app.AxesBasemap.Layout.Row = 1;
            app.AxesBasemap.Layout.Column = 6;
            app.AxesBasemap.Value = 'none';

            % Create UITable
            app.UITable = uitable(app.Document);
            app.UITable.ColumnName = {'ID'; 'DESCRIÇÃO'; 'QTD.|MEDIDAS'; 'QTD.|>14V/m'; 'Dₘᵢₙ|(km)'; 'Eₘᵢₙ|(V/m)'; 'Eₘₑₐₙ|(V/m)'; 'Eₘₐₓ|(V/m)'; 'JUSTIFICATIVA'};
            app.UITable.ColumnWidth = {240, 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @onUITableCellEdit, true);
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @onUITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 4;
            app.UITable.Layout.Column = [3 5];
            app.UITable.FontSize = 11;

            % Create DockModule
            app.DockModule = uigridlayout(app.GridLayout);
            app.DockModule.RowHeight = {'1x'};
            app.DockModule.ColumnSpacing = 2;
            app.DockModule.Padding = [5 2 5 2];
            app.DockModule.Visible = 'off';
            app.DockModule.Layout.Row = [2 4];
            app.DockModule.Layout.Column = [3 5];
            app.DockModule.BackgroundColor = [0.1294 0.2 0.2392];

            % Create DockUndockButton
            app.DockUndockButton = uiimage(app.DockModule);
            app.DockUndockButton.ScaleMethod = 'none';
            app.DockUndockButton.ImageClickedFcn = createCallbackFcn(app, @onDockModuleGroupButtonClicked, true);
            app.DockUndockButton.Enable = 'off';
            app.DockUndockButton.Layout.Row = 1;
            app.DockUndockButton.Layout.Column = 1;
            app.DockUndockButton.ImageSource = 'Undock_18White.png';

            % Create DockCloseButton
            app.DockCloseButton = uiimage(app.DockModule);
            app.DockCloseButton.ScaleMethod = 'none';
            app.DockCloseButton.ImageClickedFcn = createCallbackFcn(app, @onDockModuleGroupButtonClicked, true);
            app.DockCloseButton.Layout.Row = 1;
            app.DockCloseButton.Layout.Column = 2;
            app.DockCloseButton.ImageSource = 'Delete_12SVG_white.svg';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'auxApp.winExternalRequest';

            % Create DeletePoint
            app.DeletePoint = uimenu(app.ContextMenu);
            app.DeletePoint.MenuSelectedFcn = createCallbackFcn(app, @onDeleteSelectedPoint, true);
            app.DeletePoint.Text = '❌ Excluir';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winExternalRequest_exported(Container, varargin)

            % Create UIFigure and components
            createComponents(app, Container)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            if app.isDocked
                children = app.Container.Children;
                if isa(app.Container, 'matlab.ui.Figure') && isprop(app.Container, 'RunningAppInstance') && isprop(app.Container.RunningAppInstance, 'jsBackDoor')
                    children(children == app.Container.RunningAppInstance.jsBackDoor) = [];
                end
                delete(children)
            else
                delete(app.UIFigure)
            end
        end
    end
end
