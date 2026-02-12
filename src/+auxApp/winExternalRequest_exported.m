classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        SubTabGroup               matlab.ui.container.TabGroup
        SubTab1                   matlab.ui.container.Tab
        SubGrid1                  matlab.ui.container.GridLayout
        TreePoints                matlab.ui.container.Tree
        AddNewPointPanel          matlab.ui.container.Panel
        AddNewPointGrid           matlab.ui.container.GridLayout
        NewPointDescription       matlab.ui.control.EditField
        NewPointDescriptionLabel  matlab.ui.control.Label
        NewPointLongitude         matlab.ui.control.NumericEditField
        NewPointLongitudeLabel    matlab.ui.control.Label
        NewPointLatitude          matlab.ui.control.NumericEditField
        NewPointLatitudeLabel     matlab.ui.control.Label
        NewPointStation           matlab.ui.control.NumericEditField
        NewPointStationLabel      matlab.ui.control.Label
        NewPointType              matlab.ui.control.DropDown
        NewPointTypeLabel         matlab.ui.control.Label
        AddNewPointCancel         matlab.ui.control.Image
        AddNewPointConfirm        matlab.ui.control.Image
        AddNewPointMode           matlab.ui.control.Image
        TreePointsLabel           matlab.ui.control.Label
        TreeFileLocations         matlab.ui.container.Tree
        TreeFileLocationsLabel    matlab.ui.control.Label
        DockModule                matlab.ui.container.GridLayout
        dockModule_Close          matlab.ui.control.Image
        dockModule_Undock         matlab.ui.control.Image
        Document                  matlab.ui.container.GridLayout
        AxesToolbar               matlab.ui.container.GridLayout
        axesTool_RegionZoom       matlab.ui.control.Image
        axesTool_RestoreView      matlab.ui.control.Image
        plotPanel                 matlab.ui.container.Panel
        UITable                   matlab.ui.control.Table
        Toolbar                   matlab.ui.container.GridLayout
        tool_UploadFinalFile      matlab.ui.control.Image
        tool_GenerateReport       matlab.ui.control.Image
        tool_OpenPopupProject     matlab.ui.control.Image
        tool_PeakLabel            matlab.ui.control.Label
        tool_PeakIcon             matlab.ui.control.Image
        tool_Separator2           matlab.ui.control.Image
        tool_ExportFiles          matlab.ui.control.Image
        tool_TableVisibility      matlab.ui.control.Image
        tool_Separator1           matlab.ui.control.Image
        tool_PanelVisibility      matlab.ui.control.Image
        ContextMenu               matlab.ui.container.ContextMenu
        DeletePoint               matlab.ui.container.Menu
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

        UIAxes
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

                    case 'auxApp.winExternalRequest.TreePoints'
                        DeleteSelectedPoint(app, struct('ContextObject', app.TreePoints))

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
                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winExternalRequest
                            case 'closeFcnCallFromPopupApp'
                                app.popupContainer.Parent.Visible = 0;

                            % winMonitorRNI >> auxApp.winExternalRequest
                            case {'onFileListAdded', 'onFileListRemoved', 'onFileListUnmerged', 'onFileListMerged'}
                                app.measData = app.mainApp.measData;
                                buildFileLocationTree(app)

                                if ~isempty(app.measData)
                                    refreshAnalysis(app)
                                end

                            % auxApp.winConfig >> winMonitorRNI >> auxApp.winExternalRequest
                            case 'onAnalysisParameterChanged'
                                app.UITable.ColumnName{4} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold);
                                updateAnalysis(app.projectData, app.measData, app.mainApp.General, eventName, app.Context);
                                refreshAnalysis(app)

                            case 'onAxesParameterChanged'
                                if ~isequal(app.UIAxes.Basemap, app.mainApp.General.plot.geographicAxes.basemap)
                                    app.UIAxes.Basemap = app.mainApp.General.plot.geographicAxes.basemap;

                                    switch app.mainApp.General.plot.geographicAxes.basemap
                                        case {'darkwater', 'none'}
                                            app.UIAxes.Grid = 'on';
                                        otherwise
                                            app.UIAxes.Grid = 'off';
                                    end
                                end

                                plot.axes.Colormap(app.UIAxes, app.mainApp.General.plot.geographicAxes.colormap)
                                plot.axes.Colorbar(app.UIAxes, app.mainApp.General.plot.geographicAxes.colorbar)

                            case 'onPlotParameterChanged'
                                refreshAnalysis(app)

                            % winMonitorRNI >> auxApp.winExternalRequest
                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winExternalRequest
                            case {'onReportGenerate', 'onFinalReportFileChanged'}
                                updateToolbar(app)

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
        function applyJSCustomizations(app, tabIndex)
            if app.SubTabGroup.UserData.isTabInitialized(tabIndex)
                return
            end
            app.SubTabGroup.UserData.isTabInitialized(tabIndex) = true;

            switch tabIndex
                case 1
                    appName = class(app);
                    elToModify = {
                        app.AxesToolbar;
                        app.AddNewPointMode;
                        app.AddNewPointConfirm;
                        app.AddNewPointCancel;
                        app.TreePoints;
                        app.tool_PanelVisibility;
                        app.tool_TableVisibility;
                        app.tool_ExportFiles;
                        app.tool_PeakIcon;
                        app.tool_OpenPopupProject;
                        app.tool_GenerateReport;
                        app.tool_UploadFinalFile;
                        app.dockModule_Undock;
                        app.dockModule_Close
                    };
                    ui.CustomizationBase.getElementsDataTag(elToModify);

                    try
                        sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                            struct('appName', appName, 'dataTag', app.AxesToolbar.UserData.id,    'styleImportant', struct('borderTopLeftRadius', '0', 'borderTopRightRadius', '0')), ...
                            struct('appName', appName, 'dataTag', app.AddNewPointMode.UserData.id,       'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna visibilidade do painel de inclusão de ponto')), ...
                            struct('appName', appName, 'dataTag', app.AddNewPointConfirm.UserData.id,    'tooltip', struct('defaultPosition', 'top',    'textContent', 'Confirma edição')), ...
                            struct('appName', appName, 'dataTag', app.AddNewPointCancel.UserData.id,     'tooltip', struct('defaultPosition', 'top',    'textContent', 'Cancela edição')), ...
                            struct('appName', appName, 'dataTag', app.tool_PanelVisibility.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna visibilidade do painel')), ...
                            struct('appName', appName, 'dataTag', app.tool_TableVisibility.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna entre três layouts do conjunto plot+tabela<br>(apenas plot, apenas tabela ou plot+tabela)')), ...
                            struct('appName', appName, 'dataTag', app.tool_ExportFiles.UserData.id,      'tooltip', struct('defaultPosition', 'top',    'textContent', 'Exporta análise (.xlsx, .kml)')), ...
                            struct('appName', appName, 'dataTag', app.tool_PeakIcon.UserData.id,         'tooltip', struct('defaultPosition', 'top',    'textContent', 'Aplica zoom em torno do local de valor máximo')), ...
                            struct('appName', appName, 'dataTag', app.tool_OpenPopupProject.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita informações do projeto<br>(fiscalizada, arquivo de backup etc)')), ...
                            struct('appName', appName, 'dataTag', app.tool_GenerateReport.UserData.id,   'tooltip', struct('defaultPosition', 'top',    'textContent', 'Gera relatório')), ...
                            struct('appName', appName, 'dataTag', app.tool_UploadFinalFile.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Upload relatório')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Undock.UserData.id,     'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Reabre módulo em outra janela')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Close.UserData.id,      'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Fecha módulo')), ...
                            struct('appName', appName, 'dataTag', app.TreePoints.UserData.id, 'listener', struct('componentName', 'auxApp.winExternalRequest.TreePoints', 'keyEvents', {{'Delete', 'Backspace'}})) ...
                        });
                    catch
                    end

                otherwise
                    % ...
            end
        end

        %-----------------------------------------------------------------%
        function initializeAppProperties(app)
            % ...
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.dockModule_Undock.Enable = 1;
            end

            if app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold ~= 14
                app.UITable.ColumnName{4} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold);
            end
            app.UITable.RowName = 'numbered';

            [app.UIAxes, app.restoreView] = plot.axesCreationController(app.plotPanel, app.mainApp.General);

            buildFileLocationTree(app)
            if ~isempty(app.measData)
                refreshAnalysis(app)
            end
            
            app.tool_TableVisibility.UserData = 1;

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
                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', rowIdx))
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
            
            app.tool_ExportFiles.Enable     = measDataNonEmpty && pointsTableNonEmpty;
            app.tool_GenerateReport.Enable  = measDataNonEmpty && pointsTableNonEmpty;
            app.tool_UploadFinalFile.Enable = reportFinalVersionGenerated;

            app.tool_PeakLabel.Visible      = measTableNonEmpty;
            app.tool_PeakIcon.Enable        = measTableNonEmpty;

            if measTableNonEmpty
                [~, maxIndex] = max(app.measTable.FieldValue);

                app.tool_PeakLabel.Text     = sprintf('%.2f V/m\n(%.6f, %.6f)', app.measTable.FieldValue(maxIndex), ...
                                                                                app.measTable.Latitude(maxIndex),   ...
                                                                                app.measTable.Longitude(maxIndex));
                app.tool_PeakIcon.UserData  = struct('idxMax',    maxIndex,                         ...
                                                     'Latitude',  app.measTable.Latitude(maxIndex), ...
                                                     'Longitude', app.measTable.Longitude(maxIndex));
            end
        end

        %-----------------------------------------------------------------%
        function buildFileLocationTree(app)
            if ~isempty(app.TreeFileLocations.Children)
                delete(app.TreeFileLocations.Children)
            end

            locationGroups = unique({app.measData.Location});
            selectedNodes = [];
            for ii = 1:numel(locationGroups)
                treeNode = uitreenode(app.TreeFileLocations, 'Text', locationGroups{ii});

                if strcmp(locationGroups{ii}, app.projectData.modules.EXTERNALREQUEST.ui.selectedGroup)
                    selectedNodes = [selectedNodes; treeNode];
                end
            end

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
            if ~isempty(app.TreePoints.Children)
                delete(app.TreePoints.Children)
            end

            for ii = 1:height(app.projectData.modules.EXTERNALREQUEST.pointsTable)
                uitreenode(app.TreePoints, 'Text', app.projectData.modules.EXTERNALREQUEST.pointsTable.ID{ii}, 'NodeData', ii, 'ContextMenu', app.ContextMenu);
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
                    
                    app.SubGrid1.RowHeight{5} = 170;
                    app.SubGrid1.ColumnWidth(end-1:end) = {18, 18};
                    app.AddNewPointConfirm.Enable = 1;
                    app.AddNewPointCancel.Enable  = 1;

                case 'off'
                    app.AddNewPointMode.ImageSource = 'addFiles_32.png';
                    app.AddNewPointMode.UserData.status = false;

                    app.SubGrid1.RowHeight{5} = 0;
                    app.SubGrid1.ColumnWidth(end-1:end) = {0,0};
                    app.AddNewPointConfirm.Enable = 0;
                    app.AddNewPointCancel.Enable  = 0;
            end
        end

        %-----------------------------------------------------------------%
        % ## PLOT ##
        %-----------------------------------------------------------------%
        function plotRefreshAxes(app)
            cla(app.UIAxes)
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function plotMeasuresAndPoints(app)
            % prePlot
            plotRefreshAxes(app)

            % Measures
            if ~isempty(app.measTable)
                plot.draw.Measures(app.UIAxes, app.measTable, app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold, app.mainApp.General);

                % Abaixo estabelece como limites do eixo os limites atuais,
                % configurados automaticamente pelo MATLAB. Ao fazer isso,
                % contudo, esses limites serão orientados às medidas e não às
                % estações.
                plotAxesDefaultLimits(app, 'measures')
            end

            % Stations/Points
            if ~isempty(app.UITable.Data)
                refPointsTable = app.projectData.modules.EXTERNALREQUEST.pointsTable;
                plot.draw.Points(app.UIAxes, refPointsTable, 'Pontos críticos', app.mainApp.General)
            end
            plotAxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plotSelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.Selection;
                selectedPointTable = app.projectData.modules.EXTERNALREQUEST.pointsTable(idxSelectedPoint, :);

                plot.draw.SelectedPoint(app.UIAxes, selectedPointTable, app.mainApp.General, class(app))
            end
        end

        %-----------------------------------------------------------------%
        function plotAxesDefaultLimits(app, zoomOrientation)
            arguments
                app
                zoomOrientation {mustBeMember(zoomOrientation, {'stations/points', 'measures'})}
            end

            if strcmp(app.mainApp.General.plot.geographicAxes.zoomOrientation, zoomOrientation) || (isempty(app.measTable) && strcmp(app.mainApp.General.plot.geographicAxes.zoomOrientation, 'measures'))
                geolimits(app.UIAxes, app.UIAxes.LatitudeLimits, app.UIAxes.LongitudeLimits)
                app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
            end
        end

        %-----------------------------------------------------------------%
        % ## GET ##
        %-----------------------------------------------------------------%
        function [idxFile, selectedFileLocations] = getFileIndexes(app)
            if ~isempty(app.TreeFileLocations.SelectedNodes)
                selectedFileLocations = {app.TreeFileLocations.SelectedNodes.Text};
                idxFile = find(ismember({app.measData.Location}, selectedFileLocations));
            else
                selectedFileLocations = {};
                idxFile = [];
            end
        end

        %-----------------------------------------------------------------%
        % ## REPORTLIB ##
        %-----------------------------------------------------------------%
        function reportDispatchOperation(app, eventName, varargin)
            arguments
                app
                eventName {mustBeMember(eventName, {'onReportGenerate', 'onUploadArtifacts'})}
            end

            arguments (Repeating)
                varargin
            end

            if isempty(app.mainApp.eFiscalizaObj) || ~isvalid(app.mainApp.eFiscalizaObj)
                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');

                customFormData = struct('UUID', eventName, 'Fields', dialogBox, 'Context', app.Context);
                if ~isempty(varargin)
                    customFormData.Varargin = varargin;
                end

                sendEventToHTMLSource(app.jsBackDoor, 'customForm', customFormData)

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
                app.measData    = mainApp.measData;

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

        % Image clicked function: dockModule_Close, dockModule_Undock
        function DockModuleGroup_ButtonPushed(app, event)
            
            [idx, auxAppTag, relatedButton] = getAppInfoFromHandle(app.mainApp.tabGroupController, app);

            switch event.Source
                case app.dockModule_Undock
                    appGeneral = app.mainApp.General;
                    appGeneral.operationMode.Dock = false;
                    
                    app.mainApp.tabGroupController.Components.appHandle{idx} = [];

                    inputArguments = ipcMainMatlabCallsHandler(app.mainApp, app, 'dockButtonPushed', auxAppTag);
                    openModule(app.mainApp.tabGroupController, relatedButton, false, appGeneral, inputArguments{:})
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General, 'undock')
                    
                    delete(app)

                case app.dockModule_Close
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General)
            end

        end

        % Image clicked function: tool_PanelVisibility, tool_PeakIcon, 
        % ...and 1 other component
        function Toolbar_InteractionImageClicked(app, event)
            
            switch event.Source
                case app.tool_PanelVisibility
                    if app.SubTabGroup.Visible
                        app.tool_PanelVisibility.ImageSource = 'layout-sidebar-left-off.svg';
                        app.SubTabGroup.Visible = 0;
                        app.Document.Layout.Column = [2 5];
                    else
                        app.tool_PanelVisibility.ImageSource = 'layout-sidebar-left.svg';
                        app.SubTabGroup.Visible = 1;
                        app.Document.Layout.Column = [4 5];
                    end

                case app.tool_TableVisibility
                    app.tool_TableVisibility.UserData = mod(app.tool_TableVisibility.UserData+1, 3);

                    switch app.tool_TableVisibility.UserData
                        case 0
                            app.UITable.Visible = 0;
                            app.Document.RowHeight = {24,'1x', 0, 0};
                        case 1
                            app.UITable.Visible = 1;
                            app.Document.RowHeight = {24, '1x', 10, 186};
                        case 2
                            app.UITable.Visible = 1;
                            app.Document.RowHeight = {0, 0, 0, '1x'};
                    end

                case app.tool_PeakIcon
                    if ~isempty(app.tool_PeakIcon.UserData)
                        ReferenceDistance_km = 1;
                        plot.zoom(app.UIAxes, app.tool_PeakIcon.UserData.Latitude, app.tool_PeakIcon.UserData.Longitude, ReferenceDistance_km)
                        plot.datatip.Create(app.UIAxes, 'Measures', app.tool_PeakIcon.UserData.idxMax)
                    end
            end

        end

        % Image clicked function: tool_ExportFiles
        function Toolbar_ExportTableAsExcelSheet(app, event)
            
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
                        [~, groupLocationIndex] = ismember(groupLocation, {app.TreeFileLocations.Children.Text});

                        if ~isequal(app.TreeFileLocations.SelectedNodes, app.TreeFileLocations.Children(groupLocationIndex))
                            app.TreeFileLocations.SelectedNodes = app.TreeFileLocations.Children(groupLocationIndex);
                            TreeFileLocationsSelectionChanged(app, struct('SelectedNodes', app.TreeFileLocations.Children(groupLocationIndex)))
                        end

                        groupLocationText      = replace(app.TreeFileLocations.SelectedNodes.Text, '/', '-');
                        groupLocationIndexes   = getFileIndexes(app);
                        groupLocationMeasTable = timetable2table(buildMeasurementTable(app.measData(groupLocationIndexes)));

                        % MEDIDAS
                        hMeasPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');
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

        % Image clicked function: tool_OpenPopupProject
        function Toolbar_OpenPopupProjectImageClicked(app, event)
            
            ipcMainMatlabOpenPopupApp(app.mainApp, app, 'ReportLib', app.Context)

        end

        % Image clicked function: tool_GenerateReport
        function Toolbar_GenerateReportImageClicked(app, event)
            
            context = app.Context;
            fileIdxs = getFileIndexes(app);
            
            issue = app.projectData.modules.(context).ui.issue;
            reportVersion = app.projectData.modules.(context).ui.reportVersion;

            if ~validateReportRequirements(app.projectData, context, 'reportModel')
                ui.Dialog(app.UIFigure, 'warning', 'Pendente escolha do modelo de relatório.');
                return
            end

            % <VALIDAÇÕES>
            if numel(fileIdxs) < numel(app.measData)
                initialQuestion  = 'Deseja gerar relatório que contemple informações de TODAS as localidades de agrupamento, ou apenas da SELECIONADA?';
                initialSelection = ui.Dialog(app.UIFigure, 'uiconfirm', initialQuestion, {'Todas', 'Selecionada', 'Cancelar'}, 1, 3);

                switch initialSelection
                    case 'Cancelar'
                        return
                    case 'Todas'
                        fileIdxs = 1:numel(app.measData);
                end
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

        % Image clicked function: tool_UploadFinalFile
        function Toolbar_UploadFinalFileImageClicked(app, event)
            
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

            selectedMeasData  = app.measData(getFileIndexes(app));
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

        % Image clicked function: axesTool_RegionZoom, axesTool_RestoreView
        function AxesToolbarImageClicked(app, event)
            
            switch event.Source
                case app.axesTool_RestoreView
                    geolimits(app.UIAxes, app.restoreView(1).xLim, app.restoreView(1).yLim)

                case app.axesTool_RegionZoom
                    plot.axes.Interactivity.GeographicRegionZoomInteraction(app.UIAxes, app.axesTool_RegionZoom)
            end

        end

        % Selection changed function: TreePoints
        function TreePointsSelectionChanged(app, event)
            
            pointIdx = [];
            if ~isempty(app.TreePoints.SelectedNodes)
                pointIdx = app.TreePoints.SelectedNodes.NodeData;
            end

            % Nessa operação, o foco sai de app.TreePoints e vai pra app.UITable.
            previousSelection = app.UITable.Selection;
            app.UITable.Selection = pointIdx;
            drawnow            

            UITableSelectionChanged(app, struct('PreviousSelection', previousSelection, 'Selection', pointIdx))            
            focus(app.TreePoints)

        end

        % Selection changed function: TreeFileLocations
        function TreeFileLocationsSelectionChanged(app, event)
            
            if isempty(event.SelectedNodes)
                app.TreeFileLocations.SelectedNodes = event.PreviousSelectedNodes;
                return
            end

            refreshAnalysis(app)

        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            
            if isequal(event.PreviousData, event.NewData)
                return
            end

            pointIdx = event.Indices(1);
            updatePointsTable(app.projectData, [], [], 'onPointInfoChanged', pointIdx, event.NewData)
            
            applyTableStyle(app)

        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            
            if exist('event', 'var') && ~isempty(event.PreviousSelection) && isequal(event.Selection, event.PreviousSelection)
                return
            end

            if isempty(event.Selection)
                app.UITable.ContextMenu = [];
                app.TreePoints.SelectedNodes = [];
            else
                if isempty(app.UITable.ContextMenu)
                    app.UITable.ContextMenu = app.ContextMenu;
                end
                app.TreePoints.SelectedNodes = app.TreePoints.Children(event.Selection);
            end

            plotSelectedPoint(app)

        end

        % Value changed function: NewPointType
        function NewPointTypeValueChanged(app, event)
            
            switch app.NewPointType.Value
                case 'Estação'
                    app.NewPointStation.Enable = 1;
                    set(app.NewPointLatitude,  'Value', [], 'Enable', 0)
                    set(app.NewPointLongitude, 'Value', [], 'Enable', 0)

                otherwise
                    set(app.NewPointStation, 'Value', -1, 'Enable', 0)
                    app.NewPointLatitude.Enable  = 1;
                    app.NewPointLongitude.Enable = 1;
            end

        end

        % Value changed function: NewPointStation
        function NewPointStationValueChanged(app, event)
            
            idxRFDataHub = find(app.mainApp.rfDataHub.Station == app.NewPointStation.Value, 1);

            if ~isempty(idxRFDataHub)
                latStation  = round(app.mainApp.rfDataHub.Latitude(idxRFDataHub), 6);
                longStation = round(app.mainApp.rfDataHub.Longitude(idxRFDataHub), 6);

                set(app.NewPointLatitude,  'Value', latStation,  'Enable', 1)
                set(app.NewPointLongitude, 'Value', longStation, 'Enable', 1)

            else
                set(app.NewPointLatitude,  'Value', [], 'Enable', 1)
                set(app.NewPointLongitude, 'Value', [], 'Enable', 1)
            end

            focus(app.NewPointLatitude);

        end

        % Value changed function: NewPointLatitude
        function NewPointLatitudeValueChanged(app, event)
            
            focus(app.NewPointLongitude)
            
        end

        % Image clicked function: AddNewPointCancel, AddNewPointConfirm, 
        % ...and 1 other component
        function AddNewPointEditionModeCallbacks(app, event)
            
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
                            ID = num2str(app.NewPointStation.Value);
                        otherwise
                            ID = app.NewPointType.Value;
                    end
                    ID = sprintf('%s @ (%.6f, %.6f)', ID, app.NewPointLatitude.Value, app.NewPointLongitude.Value);
        
                    % VERIFICA SE ESSE ID JÁ TINHA SIDO INCLUÍDO
                    if any(strcmp(app.projectData.modules.EXTERNALREQUEST.pointsTable_I.ID, ID))
                        ui.Dialog(app.UIFigure, 'warning', 'Registro já consta na lista de pontos sob análise.');
                        return
                    end

                    valuesToFill = {
                        ID,                            ...
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

        % Menu selected function: DeletePoint
        function DeleteSelectedPoint(app, event)
            
            pointIdx = [];

            if ismember(app.TreePoints, [event.ContextObject, event.ContextObject.Parent])
                if ~isempty(app.TreePoints.SelectedNodes)
                    pointIdx = app.TreePoints.SelectedNodes.NodeData;
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
                if ~isempty(Container.Children)
                    delete(Container.Children)
                end

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
            app.GridLayout.ColumnWidth = {10, 320, 10, '1x', 48, 8, 2};
            app.GridLayout.RowHeight = {2, 8, 24, '1x', 10, 34};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create Toolbar
            app.Toolbar = uigridlayout(app.GridLayout);
            app.Toolbar.ColumnWidth = {22, 5, 22, 22, 5, 22, '1x', 22, 22, 22};
            app.Toolbar.RowHeight = {4, 17, '1x'};
            app.Toolbar.ColumnSpacing = 5;
            app.Toolbar.RowSpacing = 0;
            app.Toolbar.Padding = [10 5 10 5];
            app.Toolbar.Layout.Row = 6;
            app.Toolbar.Layout.Column = [1 7];
            app.Toolbar.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create tool_PanelVisibility
            app.tool_PanelVisibility = uiimage(app.Toolbar);
            app.tool_PanelVisibility.ScaleMethod = 'none';
            app.tool_PanelVisibility.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_PanelVisibility.Layout.Row = [1 3];
            app.tool_PanelVisibility.Layout.Column = 1;
            app.tool_PanelVisibility.ImageSource = 'layout-sidebar-left.svg';

            % Create tool_Separator1
            app.tool_Separator1 = uiimage(app.Toolbar);
            app.tool_Separator1.ScaleMethod = 'none';
            app.tool_Separator1.Enable = 'off';
            app.tool_Separator1.Layout.Row = [1 3];
            app.tool_Separator1.Layout.Column = 2;
            app.tool_Separator1.ImageSource = 'LineV.svg';

            % Create tool_TableVisibility
            app.tool_TableVisibility = uiimage(app.Toolbar);
            app.tool_TableVisibility.ScaleMethod = 'none';
            app.tool_TableVisibility.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_TableVisibility.Layout.Row = [1 3];
            app.tool_TableVisibility.Layout.Column = 3;
            app.tool_TableVisibility.ImageSource = 'View_16.png';

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.Toolbar);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @Toolbar_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Layout.Row = [1 3];
            app.tool_ExportFiles.Layout.Column = 4;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create tool_Separator2
            app.tool_Separator2 = uiimage(app.Toolbar);
            app.tool_Separator2.ScaleMethod = 'none';
            app.tool_Separator2.Enable = 'off';
            app.tool_Separator2.Layout.Row = [1 3];
            app.tool_Separator2.Layout.Column = 5;
            app.tool_Separator2.ImageSource = 'LineV.svg';

            % Create tool_PeakIcon
            app.tool_PeakIcon = uiimage(app.Toolbar);
            app.tool_PeakIcon.ScaleMethod = 'none';
            app.tool_PeakIcon.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_PeakIcon.Enable = 'off';
            app.tool_PeakIcon.Layout.Row = [1 3];
            app.tool_PeakIcon.Layout.Column = 6;
            app.tool_PeakIcon.ImageSource = 'Detection_18.png';

            % Create tool_PeakLabel
            app.tool_PeakLabel = uilabel(app.Toolbar);
            app.tool_PeakLabel.FontSize = 10;
            app.tool_PeakLabel.Visible = 'off';
            app.tool_PeakLabel.Layout.Row = [1 3];
            app.tool_PeakLabel.Layout.Column = 7;
            app.tool_PeakLabel.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create tool_OpenPopupProject
            app.tool_OpenPopupProject = uiimage(app.Toolbar);
            app.tool_OpenPopupProject.ScaleMethod = 'none';
            app.tool_OpenPopupProject.ImageClickedFcn = createCallbackFcn(app, @Toolbar_OpenPopupProjectImageClicked, true);
            app.tool_OpenPopupProject.Layout.Row = [1 3];
            app.tool_OpenPopupProject.Layout.Column = 8;
            app.tool_OpenPopupProject.ImageSource = 'organization-20px-black.svg';

            % Create tool_GenerateReport
            app.tool_GenerateReport = uiimage(app.Toolbar);
            app.tool_GenerateReport.ScaleMethod = 'none';
            app.tool_GenerateReport.ImageClickedFcn = createCallbackFcn(app, @Toolbar_GenerateReportImageClicked, true);
            app.tool_GenerateReport.Layout.Row = [1 3];
            app.tool_GenerateReport.Layout.Column = 9;
            app.tool_GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create tool_UploadFinalFile
            app.tool_UploadFinalFile = uiimage(app.Toolbar);
            app.tool_UploadFinalFile.ScaleMethod = 'none';
            app.tool_UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @Toolbar_UploadFinalFileImageClicked, true);
            app.tool_UploadFinalFile.Enable = 'off';
            app.tool_UploadFinalFile.Layout.Row = [1 3];
            app.tool_UploadFinalFile.Layout.Column = 10;
            app.tool_UploadFinalFile.ImageSource = 'up-20px.png';

            % Create Document
            app.Document = uigridlayout(app.GridLayout);
            app.Document.ColumnWidth = {5, 50, '1x'};
            app.Document.RowHeight = {24, '1x', 10, 186};
            app.Document.ColumnSpacing = 0;
            app.Document.RowSpacing = 0;
            app.Document.Padding = [0 0 0 0];
            app.Document.Layout.Row = [3 4];
            app.Document.Layout.Column = [4 5];
            app.Document.BackgroundColor = [1 1 1];

            % Create UITable
            app.UITable = uitable(app.Document);
            app.UITable.ColumnName = {'ID'; 'DESCRIÇÃO'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Dmin|(km)'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'JUSTIFICATIVA'};
            app.UITable.ColumnWidth = {240, 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 4;
            app.UITable.Layout.Column = [1 3];
            app.UITable.FontSize = 11;

            % Create plotPanel
            app.plotPanel = uipanel(app.Document);
            app.plotPanel.AutoResizeChildren = 'off';
            app.plotPanel.BorderType = 'none';
            app.plotPanel.BackgroundColor = [1 1 1];
            app.plotPanel.Layout.Row = [1 2];
            app.plotPanel.Layout.Column = [1 3];

            % Create AxesToolbar
            app.AxesToolbar = uigridlayout(app.Document);
            app.AxesToolbar.ColumnWidth = {22, 22};
            app.AxesToolbar.RowHeight = {22};
            app.AxesToolbar.ColumnSpacing = 0;
            app.AxesToolbar.Padding = [2 2 2 0];
            app.AxesToolbar.Layout.Row = 1;
            app.AxesToolbar.Layout.Column = 2;
            app.AxesToolbar.BackgroundColor = [1 1 1];

            % Create axesTool_RestoreView
            app.axesTool_RestoreView = uiimage(app.AxesToolbar);
            app.axesTool_RestoreView.ScaleMethod = 'none';
            app.axesTool_RestoreView.ImageClickedFcn = createCallbackFcn(app, @AxesToolbarImageClicked, true);
            app.axesTool_RestoreView.Layout.Row = 1;
            app.axesTool_RestoreView.Layout.Column = 1;
            app.axesTool_RestoreView.ImageSource = 'Home_18.png';

            % Create axesTool_RegionZoom
            app.axesTool_RegionZoom = uiimage(app.AxesToolbar);
            app.axesTool_RegionZoom.ScaleMethod = 'none';
            app.axesTool_RegionZoom.ImageClickedFcn = createCallbackFcn(app, @AxesToolbarImageClicked, true);
            app.axesTool_RegionZoom.Layout.Row = 1;
            app.axesTool_RegionZoom.Layout.Column = 2;
            app.axesTool_RegionZoom.ImageSource = 'ZoomRegion_20.png';

            % Create DockModule
            app.DockModule = uigridlayout(app.GridLayout);
            app.DockModule.RowHeight = {'1x'};
            app.DockModule.ColumnSpacing = 2;
            app.DockModule.Padding = [5 2 5 2];
            app.DockModule.Visible = 'off';
            app.DockModule.Layout.Row = [2 3];
            app.DockModule.Layout.Column = [5 6];
            app.DockModule.BackgroundColor = [0.2 0.2 0.2];

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.DockModule);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @DockModuleGroup_ButtonPushed, true);
            app.dockModule_Undock.Enable = 'off';
            app.dockModule_Undock.Layout.Row = 1;
            app.dockModule_Undock.Layout.Column = 1;
            app.dockModule_Undock.ImageSource = 'Undock_18White.png';

            % Create dockModule_Close
            app.dockModule_Close = uiimage(app.DockModule);
            app.dockModule_Close.ScaleMethod = 'none';
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @DockModuleGroup_ButtonPushed, true);
            app.dockModule_Close.Layout.Row = 1;
            app.dockModule_Close.Layout.Column = 2;
            app.dockModule_Close.ImageSource = 'Delete_12SVG_white.svg';

            % Create SubTabGroup
            app.SubTabGroup = uitabgroup(app.GridLayout);
            app.SubTabGroup.AutoResizeChildren = 'off';
            app.SubTabGroup.Layout.Row = [3 4];
            app.SubTabGroup.Layout.Column = 2;

            % Create SubTab1
            app.SubTab1 = uitab(app.SubTabGroup);
            app.SubTab1.AutoResizeChildren = 'off';
            app.SubTab1.Title = 'DEMANDA EXTERNA';

            % Create SubGrid1
            app.SubGrid1 = uigridlayout(app.SubTab1);
            app.SubGrid1.ColumnWidth = {'1x', 18, 0, 0};
            app.SubGrid1.RowHeight = {30, '1x', 9, 18, 0, 174};
            app.SubGrid1.ColumnSpacing = 5;
            app.SubGrid1.RowSpacing = 5;
            app.SubGrid1.BackgroundColor = [1 1 1];

            % Create TreeFileLocationsLabel
            app.TreeFileLocationsLabel = uilabel(app.SubGrid1);
            app.TreeFileLocationsLabel.VerticalAlignment = 'bottom';
            app.TreeFileLocationsLabel.WordWrap = 'on';
            app.TreeFileLocationsLabel.FontSize = 10;
            app.TreeFileLocationsLabel.Layout.Row = 1;
            app.TreeFileLocationsLabel.Layout.Column = 1;
            app.TreeFileLocationsLabel.Interpreter = 'html';
            app.TreeFileLocationsLabel.Text = {'LOCALIDADES DE AGRUPAMENTO:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.SubGrid1);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @TreeFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 2;
            app.TreeFileLocations.Layout.Column = [1 4];

            % Create TreePointsLabel
            app.TreePointsLabel = uilabel(app.SubGrid1);
            app.TreePointsLabel.VerticalAlignment = 'bottom';
            app.TreePointsLabel.FontSize = 10;
            app.TreePointsLabel.Layout.Row = [3 4];
            app.TreePointsLabel.Layout.Column = 1;
            app.TreePointsLabel.Interpreter = 'html';
            app.TreePointsLabel.Text = {'PONTOS CRÍTICOS SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionado àquilo que fora pedido pelo demandante)</font>'};

            % Create AddNewPointMode
            app.AddNewPointMode = uiimage(app.SubGrid1);
            app.AddNewPointMode.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointMode.Layout.Row = 4;
            app.AddNewPointMode.Layout.Column = 2;
            app.AddNewPointMode.ImageSource = 'addFiles_32.png';

            % Create AddNewPointConfirm
            app.AddNewPointConfirm = uiimage(app.SubGrid1);
            app.AddNewPointConfirm.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointConfirm.Layout.Row = 4;
            app.AddNewPointConfirm.Layout.Column = 3;
            app.AddNewPointConfirm.ImageSource = 'Ok_32Green.png';

            % Create AddNewPointCancel
            app.AddNewPointCancel = uiimage(app.SubGrid1);
            app.AddNewPointCancel.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointCancel.Layout.Row = 4;
            app.AddNewPointCancel.Layout.Column = 4;
            app.AddNewPointCancel.ImageSource = 'Delete_32Red.png';

            % Create AddNewPointPanel
            app.AddNewPointPanel = uipanel(app.SubGrid1);
            app.AddNewPointPanel.AutoResizeChildren = 'off';
            app.AddNewPointPanel.Layout.Row = 5;
            app.AddNewPointPanel.Layout.Column = [1 4];

            % Create AddNewPointGrid
            app.AddNewPointGrid = uigridlayout(app.AddNewPointPanel);
            app.AddNewPointGrid.ColumnWidth = {'1x', '1x', '1x'};
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
            app.NewPointType.Items = {''};
            app.NewPointType.ValueChangedFcn = createCallbackFcn(app, @NewPointTypeValueChanged, true);
            app.NewPointType.FontSize = 11;
            app.NewPointType.BackgroundColor = [1 1 1];
            app.NewPointType.Layout.Row = 2;
            app.NewPointType.Layout.Column = [1 3];
            app.NewPointType.Value = '';

            % Create NewPointStationLabel
            app.NewPointStationLabel = uilabel(app.AddNewPointGrid);
            app.NewPointStationLabel.VerticalAlignment = 'bottom';
            app.NewPointStationLabel.FontSize = 10;
            app.NewPointStationLabel.Layout.Row = 3;
            app.NewPointStationLabel.Layout.Column = 1;
            app.NewPointStationLabel.Text = 'Estação:';

            % Create NewPointStation
            app.NewPointStation = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointStation.Limits = [-1 Inf];
            app.NewPointStation.RoundFractionalValues = 'on';
            app.NewPointStation.ValueDisplayFormat = '%d';
            app.NewPointStation.ValueChangedFcn = createCallbackFcn(app, @NewPointStationValueChanged, true);
            app.NewPointStation.HorizontalAlignment = 'left';
            app.NewPointStation.FontSize = 11;
            app.NewPointStation.Enable = 'off';
            app.NewPointStation.Layout.Row = 4;
            app.NewPointStation.Layout.Column = 1;
            app.NewPointStation.Value = -1;

            % Create NewPointLatitudeLabel
            app.NewPointLatitudeLabel = uilabel(app.AddNewPointGrid);
            app.NewPointLatitudeLabel.VerticalAlignment = 'bottom';
            app.NewPointLatitudeLabel.FontSize = 10;
            app.NewPointLatitudeLabel.Layout.Row = 3;
            app.NewPointLatitudeLabel.Layout.Column = 2;
            app.NewPointLatitudeLabel.Text = 'Latitude:';

            % Create NewPointLatitude
            app.NewPointLatitude = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointLatitude.Limits = [-90 90];
            app.NewPointLatitude.ValueDisplayFormat = '%.6f';
            app.NewPointLatitude.AllowEmpty = 'on';
            app.NewPointLatitude.ValueChangedFcn = createCallbackFcn(app, @NewPointLatitudeValueChanged, true);
            app.NewPointLatitude.HorizontalAlignment = 'left';
            app.NewPointLatitude.FontSize = 11;
            app.NewPointLatitude.Layout.Row = 4;
            app.NewPointLatitude.Layout.Column = 2;
            app.NewPointLatitude.Value = [];

            % Create NewPointLongitudeLabel
            app.NewPointLongitudeLabel = uilabel(app.AddNewPointGrid);
            app.NewPointLongitudeLabel.VerticalAlignment = 'bottom';
            app.NewPointLongitudeLabel.FontSize = 10;
            app.NewPointLongitudeLabel.Layout.Row = 3;
            app.NewPointLongitudeLabel.Layout.Column = 3;
            app.NewPointLongitudeLabel.Text = 'Longitude:';

            % Create NewPointLongitude
            app.NewPointLongitude = uieditfield(app.AddNewPointGrid, 'numeric');
            app.NewPointLongitude.Limits = [-180 180];
            app.NewPointLongitude.ValueDisplayFormat = '%.6f';
            app.NewPointLongitude.AllowEmpty = 'on';
            app.NewPointLongitude.HorizontalAlignment = 'left';
            app.NewPointLongitude.FontSize = 11;
            app.NewPointLongitude.Layout.Row = 4;
            app.NewPointLongitude.Layout.Column = 3;
            app.NewPointLongitude.Value = [];

            % Create NewPointDescriptionLabel
            app.NewPointDescriptionLabel = uilabel(app.AddNewPointGrid);
            app.NewPointDescriptionLabel.VerticalAlignment = 'bottom';
            app.NewPointDescriptionLabel.FontSize = 10;
            app.NewPointDescriptionLabel.Layout.Row = 5;
            app.NewPointDescriptionLabel.Layout.Column = 1;
            app.NewPointDescriptionLabel.Text = 'Descrição:';

            % Create NewPointDescription
            app.NewPointDescription = uieditfield(app.AddNewPointGrid, 'text');
            app.NewPointDescription.FontSize = 11;
            app.NewPointDescription.Layout.Row = 6;
            app.NewPointDescription.Layout.Column = [1 3];

            % Create TreePoints
            app.TreePoints = uitree(app.SubGrid1);
            app.TreePoints.SelectionChangedFcn = createCallbackFcn(app, @TreePointsSelectionChanged, true);
            app.TreePoints.FontSize = 11;
            app.TreePoints.Layout.Row = 6;
            app.TreePoints.Layout.Column = [1 4];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'auxApp.winExternalRequest';

            % Create DeletePoint
            app.DeletePoint = uimenu(app.ContextMenu);
            app.DeletePoint.MenuSelectedFcn = createCallbackFcn(app, @DeleteSelectedPoint, true);
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
                delete(app.Container.Children)
            else
                delete(app.UIFigure)
            end
        end
    end
end
