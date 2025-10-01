classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        TabGroup                     matlab.ui.container.TabGroup
        PMRNITab                     matlab.ui.container.Tab
        Control                      matlab.ui.container.GridLayout
        TreePoints                   matlab.ui.container.Tree
        AddNewPointPanel             matlab.ui.container.Panel
        AddNewPointGrid              matlab.ui.container.GridLayout
        NewPointDescription          matlab.ui.control.EditField
        NewPointDescriptionLabel     matlab.ui.control.Label
        NewPointLongitude            matlab.ui.control.NumericEditField
        NewPointLongitudeLabel       matlab.ui.control.Label
        NewPointLatitude             matlab.ui.control.NumericEditField
        NewPointLatitudeLabel        matlab.ui.control.Label
        NewPointStation              matlab.ui.control.NumericEditField
        NewPointStationLabel         matlab.ui.control.Label
        NewPointType                 matlab.ui.control.DropDown
        NewPointTypeLabel            matlab.ui.control.Label
        AddNewPointCancel            matlab.ui.control.Image
        AddNewPointConfirm           matlab.ui.control.Image
        AddNewPointMode              matlab.ui.control.Image
        TreePointsLabel              matlab.ui.control.Label
        TreeFileLocations            matlab.ui.container.Tree
        config_geoAxesLabel          matlab.ui.control.Label
        PROJETOTab                   matlab.ui.container.Tab
        Tab4Grid                     matlab.ui.container.GridLayout
        reportPanel                  matlab.ui.container.Panel
        reportGrid                   matlab.ui.container.GridLayout
        reportVersion                matlab.ui.control.DropDown
        reportVersionLabel           matlab.ui.control.Label
        reportModelName              matlab.ui.control.DropDown
        reportModelNameLabel         matlab.ui.control.Label
        reportLabel                  matlab.ui.control.Label
        eFiscalizaPanel              matlab.ui.container.Panel
        eFiscalizaGrid               matlab.ui.container.GridLayout
        reportIssue                  matlab.ui.control.NumericEditField
        reportIssueLabel             matlab.ui.control.Label
        reportUnit                   matlab.ui.control.DropDown
        reportUnitLabel              matlab.ui.control.Label
        reportSystem                 matlab.ui.control.DropDown
        reportSystemLabel            matlab.ui.control.Label
        eFiscalizaLabel              matlab.ui.control.Label
        dockModuleGrid               matlab.ui.container.GridLayout
        dockModule_Undock            matlab.ui.control.Image
        dockModule_Close             matlab.ui.control.Image
        Document                     matlab.ui.container.GridLayout
        AxesToolbar                  matlab.ui.container.GridLayout
        axesTool_RegionZoom          matlab.ui.control.Image
        axesTool_RestoreView         matlab.ui.control.Image
        plotPanel                    matlab.ui.container.Panel
        UITable                      matlab.ui.control.Table
        toolGrid                     matlab.ui.container.GridLayout
        tool_UploadFinalFile         matlab.ui.control.Image
        tool_ExportFiles             matlab.ui.control.Image
        tool_GenerateReport          matlab.ui.control.Image
        tool_peakIcon                matlab.ui.control.Image
        tool_peakLabel               matlab.ui.control.Label
        tool_Separator               matlab.ui.control.Image
        tool_TableVisibility         matlab.ui.control.Image
        tool_ControlPanelVisibility  matlab.ui.control.Image
        ContextMenu                  matlab.ui.container.ContextMenu
        DeletePoint                  matlab.ui.container.Menu
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = false

        mainApp
        
        % A função do timer é executada uma única vez após a renderização
        % da figura, lendo arquivos de configuração, iniciando modo de operação
        % paralelo etc. A ideia é deixar o MATLAB focar apenas na criação dos 
        % componentes essenciais da GUI (especificados em "createComponents"), 
        % mostrando a GUI para o usuário o mais rápido possível.
        timerObj
        jsBackDoor

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog
        popupContainer
        
        %-----------------------------------------------------------------%
        % ESPECIFICIDADES AUXAPP.WINEXTERNALREQUEST
        %-----------------------------------------------------------------%
        projectData
        measData
        measTable

        % Handle do eixo e propriedade que armazena os limites automáticos
        UIAxes
        restoreView = struct('ID', {}, 'xLim', {}, 'yLim', {}, 'cLim', {})        
    end


    methods
        %-----------------------------------------------------------------%
        % IPC: COMUNICAÇÃO ENTRE PROCESSOS
        %-----------------------------------------------------------------%
        function ipcSecundaryJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    case 'renderer'
                        startup_Controller(app)

                    case 'customForm'
                        switch event.HTMLEventData.uuid
                            case 'eFiscalizaSignInPage'
                                report_uploadInfoController(app.mainApp, event.HTMLEventData, 'uploadDocument')

                            otherwise
                                error('UnexpectedEvent')
                        end

                    case 'auxApp.winExternalRequest.TreePoints'
                        DeleteSelectedPoint(app, struct('ContextObject', app.TreePoints))

                    otherwise
                        error('UnexpectedEvent')
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);
            end
        end

        %-----------------------------------------------------------------%
        function ipcSecundaryMatlabCallsHandler(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    case {'winMonitorRNI', 'winMonitorRNI_exported'}
                        switch operationType
                            case {'FileListChanged:Add', ...
                                  'FileListChanged:Del', ...
                                  'FileListChanged:Unmerge', ...
                                  'FileListChanged:Merge'}
                                app.measData = app.mainApp.measData;
                                TreeFileLocationBuilding(app)

                                if ~isempty(app.measData)
                                    Analysis(app)
                                end

                            case 'ExternalRequest:AnalysisParameterChanged'
                                app.UITable.ColumnName{4} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.ExternalRequest.FieldValue);
                                updateAnalysis(app.projectData, app.measData, app.mainApp.General, operationType);
                                Analysis(app)

                            case 'ExternalRequest:AxesParameterChanged'
                                if ~isequal(app.UIAxes.Basemap, app.mainApp.General.Plot.GeographicAxes.Basemap)
                                    app.UIAxes.Basemap = app.mainApp.General.Plot.GeographicAxes.Basemap;

                                    switch app.mainApp.General.Plot.GeographicAxes.Basemap
                                        case {'darkwater', 'none'}
                                            app.UIAxes.Grid = 'on';
                                        otherwise
                                            app.UIAxes.Grid = 'off';
                                    end
                                end

                                plot.axes.Colormap(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colormap)
                                plot.axes.Colorbar(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colorbar)

                            case 'ExternalRequest:PlotParameterChanged'
                                Analysis(app)

                            otherwise
                                error('UnexpectedCall')
                        end
    
                    otherwise
                        error('UnexpectedCall')
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            app.jsBackDoor = uihtml(app.UIFigure, "HTMLSource",           appUtil.jsBackDoorHTMLSource(),                 ...
                                                  "HTMLEventReceivedFcn", @(~, evt)ipcSecundaryJSEventsHandler(app, evt), ...
                                                  "Visible",              "off");
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app, tabIndex)
            persistent customizationStatus
            if isempty(customizationStatus)
                customizationStatus = [false, false];
            end

            switch tabIndex
                case 0 % STARTUP
                    if app.isDocked
                        app.progressDialog = app.mainApp.progressDialog;
                    else
                        sendEventToHTMLSource(app.jsBackDoor, 'startup', app.mainApp.executionMode);
                        app.progressDialog = ccTools.ProgressDialog(app.jsBackDoor);                        
                    end
                    customizationStatus = [false, false];

                otherwise
                    if customizationStatus(tabIndex)
                        return
                    end

                    customizationStatus(tabIndex) = true;
                    switch tabIndex
                        case 1
                            appName = class(app);

                            % Grid botões "dock":
                            if app.isDocked
                                elToModify = {app.dockModuleGrid};
                                elDataTag  = ui.CustomizationBase.getElementsDataTag(elToModify);
                                if ~isempty(elDataTag)                                    
                                    sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                                        struct('appName', appName, 'dataTag', elDataTag{1}, 'style', struct('transition', 'opacity 2s ease', 'opacity', '0.5')) ...
                                    });
                                end
                            end

                            % Outros elementos:
                            elToModify = {app.AxesToolbar, app.TreePoints};
                            elDataTag  = ui.CustomizationBase.getElementsDataTag(elToModify);
                            if ~isempty(elDataTag)
                                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                                    struct('appName', appName, 'dataTag', elDataTag{1}, 'styleImportant', struct('borderTopLeftRadius', '0', 'borderTopRightRadius', '0')), ...
                                    struct('appName', appName, 'dataTag', elDataTag{2}, 'listener', struct('componentName', 'auxApp.winExternalRequest.TreePoints', 'keyEvents', {{'Delete', 'Backspace'}})) ...
                                });
                            end

                        case 2
                            context = 'ExternalRequest';

                            if isempty(app.projectData.modules.(context).ui.system) && ~isequal(app.projectData.modules.(context).ui.system, app.mainApp.General.Report.system)
                                app.projectData.modules.(context).ui.system = app.mainApp.General.Report.system;
                            end
                            
                            if isempty(app.projectData.modules.(context).ui.unit)   && ~isequal(app.projectData.modules.(context).ui.unit,   app.mainApp.General.Report.unit)
                                app.projectData.modules.(context).ui.unit   = app.mainApp.General.Report.unit;
                            end

                            app.reportSystem.Value    = app.projectData.modules.(context).ui.system;
                            set(app.reportUnit, 'Items', app.mainApp.General.eFiscaliza.defaultValues.unit, ...
                                                'Value', app.projectData.modules.(context).ui.unit)                            
                            app.reportIssue.Value     = app.projectData.modules.(context).ui.issue;
                            app.reportModelName.Items = app.projectData.modules.(context).ui.templates;
                    end
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO
        %-----------------------------------------------------------------%
        function startup_timerCreation(app)
            app.timerObj = timer("ExecutionMode", "fixedSpacing", ...
                                 "StartDelay",    1.5,            ...
                                 "Period",        .1,             ...
                                 "TimerFcn",      @(~,~)app.startup_timerFcn);
            start(app.timerObj)
        end

        %-----------------------------------------------------------------%
        function startup_timerFcn(app)
            if ccTools.fcn.UIFigureRenderStatus(app.UIFigure)
                stop(app.timerObj)
                delete(app.timerObj)

                jsBackDoor_Initialization(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Controller(app)
            drawnow

            jsBackDoor_Customizations(app, 0)
            jsBackDoor_Customizations(app, 1)

            % Define tamanho mínimo do app (não aplicável à versão webapp).
            if ~strcmp(app.mainApp.executionMode, 'webApp') && ~app.isDocked
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            app.progressDialog.Visible = 'visible';

            startup_GUIComponents(app)

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            context = 'ExternalRequest';

            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.dockModule_Undock.Enable = 1;
            end

            if app.mainApp.General.(context).FieldValue ~= 14
                app.UITable.ColumnName{4} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.(context).FieldValue);
            end

            [app.UIAxes, app.restoreView] = plot.axesCreationController(app.plotPanel, app.mainApp.General);

            TreeFileLocationBuilding(app)
            if ~isempty(app.measData)
                Analysis(app)
            end
            
            app.tool_TableVisibility.UserData = 1;

            % Especificidades do auxApp.winExternalRequest em relação ao
            % auxApp.winMonitoringPlan:
            TreePointsBuilding(app)
            app.NewPointType.Items = [{''}; app.mainApp.General.(context).TypeOfLocation];
            layout_newPointPanel(app, 'off')
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function Analysis(app)
            app.progressDialog.Visible = 'visible';

            % Identifica arquivos selecionados pelo usuário, atualizando a
            % tabela de referência para o plot (app.measTable) e a relação
            % de localidades selecionadas na GUI (em app.projectData).
            [idxFile, selectedFileLocations] = FileIndex(app);
            app.measTable = createMeasTable(app.measData(idxFile));

            updateSelectedListOfLocations(...
                app.projectData, ...
                selectedFileLocations, ...
                'ExternalRequest' ...
            )

            initialSelection = updateTable(app);
            layout_TableStyle(app)

            % Atualiza outros elementos da GUI, inclusive painel com quantitativo 
            % de estações.
            updateToolbar(app)            

            % Atualiza plot.
            plot_MeasuresAndPoints(app)

            if ~isempty(initialSelection)
                [~, idxRow] = ismember(initialSelection, app.UITable.Data.ID);
                if idxRow
                    app.UITable.Selection = idxRow;
                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', idxRow))
                end
            end

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function [idxFile, selectedFileLocations] = FileIndex(app)
            if ~isempty(app.TreeFileLocations.SelectedNodes)
                selectedFileLocations = {app.TreeFileLocations.SelectedNodes.Text};
                idxFile = find(ismember({app.measData.Location}, selectedFileLocations));
            else
                selectedFileLocations = {};
                idxFile = [];
            end
        end

        %-----------------------------------------------------------------%
        function initialSelection = updateTable(app)
            initialSelection = [];
            if ~isempty(app.UITable.Selection)
                initialSelection = app.UITable.Data.ID{app.UITable.Selection};
            end

            table2Render = app.projectData.modules.ExternalRequest.pointsTable(:, {'ID',                    ...
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
        function updateToolbar(app)
            context = 'ExternalRequest';

            measDataNonEmpty                = ~isempty(app.measData);
            meastTableNonEmpty              = ~isempty(app.measTable);
            reportModelSelected             = ~isempty(app.reportModelName.Value);
            reportFinalVersionGenerated     = ~isempty(app.projectData.modules.(context).generatedFiles.lastHTMLDocFullPath);
            
            app.tool_ExportFiles.Enable     = measDataNonEmpty;
            app.tool_GenerateReport.Enable  = measDataNonEmpty & reportModelSelected;
            app.tool_UploadFinalFile.Enable = reportFinalVersionGenerated;

            app.tool_peakLabel.Visible      = meastTableNonEmpty;
            app.tool_peakIcon.Enable        = meastTableNonEmpty;

            if meastTableNonEmpty
                [~, maxIndex] = max(app.measTable.FieldValue);

                app.tool_peakLabel.Text    = sprintf('%.2f V/m\n(%.6f, %.6f)', app.measTable.FieldValue(maxIndex), ...
                                                                               app.measTable.Latitude(maxIndex),   ...
                                                                               app.measTable.Longitude(maxIndex));
                app.tool_peakIcon.UserData = struct('idxMax',    maxIndex,                         ...
                                                    'Latitude',  app.measTable.Latitude(maxIndex), ...
                                                    'Longitude', app.measTable.Longitude(maxIndex));
            end
        end

        %-----------------------------------------------------------------%
        function plot_RestartAxes(app)
            cla(app.UIAxes)
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function plot_MeasuresAndPoints(app)
            % prePlot
            plot_RestartAxes(app)

            % Measures
            if ~isempty(app.measTable)
                plot.draw.Measures(app.UIAxes, app.measTable, app.mainApp.General.ExternalRequest.FieldValue, app.mainApp.General);

                % Abaixo estabelece como limites do eixo os limites atuais,
                % configurados automaticamente pelo MATLAB. Ao fazer isso,
                % contudo, esses limites serão orientados às medidas e não às
                % estações.
                plot_AxesDefaultLimits(app, 'measures')
            end

            % Stations/Points
            if ~isempty(app.UITable.Data)
                refPointsTable = app.projectData.modules.ExternalRequest.pointsTable;

                plot.draw.Points(app.UIAxes, refPointsTable, 'Pontos críticos', app.mainApp.General)
            end
            plot_AxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plot_SelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.Selection;
                selectedPointTable = app.projectData.modules.ExternalRequest.pointsTable(idxSelectedPoint, :);

                plot.draw.SelectedPoint(app.UIAxes, selectedPointTable, app.mainApp.General, class(app))
            end
        end

        %-----------------------------------------------------------------%
        function plot_AxesDefaultLimits(app, zoomOrientation)
            arguments
                app
                zoomOrientation {mustBeMember(zoomOrientation, {'stations/points', 'measures'})}
            end

            if strcmp(app.mainApp.General.Plot.GeographicAxes.ZoomOrientation, zoomOrientation) || (isempty(app.measTable) && strcmp(app.mainApp.General.Plot.GeographicAxes.ZoomOrientation, 'measures'))
                geolimits(app.UIAxes, app.UIAxes.LatitudeLimits, app.UIAxes.LongitudeLimits)
                app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
            end
        end

        %-----------------------------------------------------------------%
        function [idxMissingInfo, idxRiskMeasures] = layout_searchUnexpectedTableValues(app)
            idxMissingInfo   = [];
            idxRiskMeasures  = [];

            if ~isempty(app.UITable.Data)
                idxMissingInfo  = find(((app.projectData.modules.ExternalRequest.pointsTable.numberOfMeasures == 0) & (app.projectData.modules.ExternalRequest.pointsTable.("Justificativa") == "-1")));
                idxRiskMeasures = find(app.projectData.modules.ExternalRequest.pointsTable.numberOfRiskMeasures > 0);
            end
        end

        %-----------------------------------------------------------------%
        function layout_TableStyle(app)
            removeStyle(app.UITable)

            tableDataNonEmpty = ~isempty(app.UITable.Data);
            if tableDataNonEmpty
                % Identifica pontos que NÃO tiveram medições no seu entorno. 
                % Ou pontos que apresentaram medições com níveis acima de 14 V/m.
                [idxMissingInfo, idxRiskMeasures] = layout_searchUnexpectedTableValues(app);

                if ~isempty(idxMissingInfo)
                    columnIndex1 = find(ismember(app.UITable.Data.Properties.VariableNames, 'Justificativa'));
                    s1 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');                
                    addStyle(app.UITable, s1, "cell", [idxMissingInfo, repmat(columnIndex1, numel(idxMissingInfo), 1)])
                end

                if ~isempty(idxRiskMeasures)
                    columnIndex2 = find(ismember(app.UITable.Data.Properties.VariableNames, 'numberOfRiskMeasures'));

                    s2 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');
                    addStyle(app.UITable, s2, "cell", [idxRiskMeasures, repmat(columnIndex2, numel(idxRiskMeasures), 1)])
                end
            end
        end

        %-----------------------------------------------------------------%
        function TreeFileLocationBuilding(app)
            if ~isempty(app.TreeFileLocations.Children)
                delete(app.TreeFileLocations.Children)
            end

            locationGroups = unique({app.measData.Location});
            selectedNodes = [];
            for ii = 1:numel(locationGroups)
                treeNode = uitreenode(app.TreeFileLocations, 'Text', locationGroups{ii});

                if strcmp(locationGroups{ii}, app.projectData.modules.ExternalRequest.ui.selectedGroup)
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

                plot_RestartAxes(app)
                updateTable(app);
            end

            updateToolbar(app)
        end

        %-----------------------------------------------------------------%
        function TreePointsBuilding(app)
            if ~isempty(app.TreePoints.Children)
                delete(app.TreePoints.Children)
            end

            for ii = 1:height(app.projectData.modules.ExternalRequest.pointsTable)
                uitreenode(app.TreePoints, 'Text', app.projectData.modules.ExternalRequest.pointsTable.ID{ii}, 'NodeData', ii, 'ContextMenu', app.ContextMenu);
            end
        end

        %-----------------------------------------------------------------%
        function layout_newPointPanel(app, editionStatus)
            arguments
                app 
                editionStatus char {mustBeMember(editionStatus, {'on', 'off'})}
            end            

            switch editionStatus
                case 'on'
                    set(app.AddNewPointMode, 'ImageSource', 'addFiles_32Filled.png', 'Tooltip', 'Desabilita painel de inclusão de ponto', 'UserData', true)
                    
                    app.Control.RowHeight{4} = 170;
                    app.Control.ColumnWidth(end-1:end) = {18, 18};
                    app.AddNewPointConfirm.Enable = 1;
                    app.AddNewPointCancel.Enable  = 1;

                case 'off'
                    set(app.AddNewPointMode, 'ImageSource', 'addFiles_32.png',       'Tooltip', 'Habilita painel de inclusão de ponto',   'UserData', false)

                    app.Control.RowHeight{4} = 0;
                    app.Control.ColumnWidth(end-1:end) = {0,0};
                    app.AddNewPointConfirm.Enable = 0;
                    app.AddNewPointCancel.Enable  = 0;
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            
            app.mainApp     = mainApp;
            app.projectData = mainApp.projectData;
            app.measData    = mainApp.measData;

            if app.isDocked
                app.GridLayout.Padding(4)  = 30;
                app.dockModuleGrid.Visible = 1;
                app.jsBackDoor = mainApp.jsBackDoor;
                startup_Controller(app)
            else
                appUtil.winPosition(app.UIFigure)
                startup_timerCreation(app)
            end

        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            ipcMainMatlabCallsHandler(app.mainApp, app, 'closeFcn')
            delete(app)
            
        end

        % Image clicked function: dockModule_Close, dockModule_Undock
        function DockModuleGroup_ButtonPushed(app, event)
            
            [idx, auxAppTag, relatedButton] = getAppInfoFromHandle(app.mainApp.tabGroupController, app);

            switch event.Source
                case app.dockModule_Undock
                    appGeneral = app.mainApp.General;
                    appGeneral.operationMode.Dock = false;
                    
                    inputArguments = ipcMainMatlabCallsHandler(app.mainApp, app, 'dockButtonPushed', auxAppTag);
                    app.mainApp.tabGroupController.Components.appHandle{idx} = [];
                    
                    openModule(app.mainApp.tabGroupController, relatedButton, false, appGeneral, inputArguments{:})
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General, 'undock')
                    
                    delete(app)

                case app.dockModule_Close
                    closeModule(app.mainApp.tabGroupController, auxAppTag, app.mainApp.General)
            end

        end

        % Image clicked function: tool_ControlPanelVisibility, 
        % ...and 2 other components
        function Toolbar_InteractionImageClicked(app, event)
            
            switch event.Source
                case app.tool_ControlPanelVisibility
                    if app.TabGroup.Visible
                        app.tool_ControlPanelVisibility.ImageSource = 'ArrowRight_32.png';
                        app.TabGroup.Visible = 0;
                        app.Document.Layout.Column = [2 5];
                    else
                        app.tool_ControlPanelVisibility.ImageSource = 'ArrowLeft_32.png';
                        app.TabGroup.Visible = 1;
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

                case app.tool_peakIcon
                    if ~isempty(app.tool_peakIcon.UserData)
                        ReferenceDistance_km = 1;
                        plot.zoom(app.UIAxes, app.tool_peakIcon.UserData.Latitude, app.tool_peakIcon.UserData.Longitude, ReferenceDistance_km)
                        plot.datatip.Create(app.UIAxes, 'Measures', app.tool_peakIcon.UserData.idxMax)
                    end
            end

        end

        % Image clicked function: tool_ExportFiles
        function Toolbar_ExportTableAsExcelSheet(app, event)
            
            context = 'ExternaRequest';
            indexes = FileIndex(app);

            pointsTable = app.projectData.modules.(context).pointsTable;
            if isempty(pointsTable)
                warningMessages = 'Funcionalidade aplicável apenas quando há ao menos um ponto crítico';
                appUtil.modalWindow(app.UIFigure, 'warning', warningMessages);
                return
            end

            if ~isempty(indexes)
                % <VALIDAÇÕES>
                if numel(indexes) < numel(app.measData)
                    initialQuestion  = 'Deseja exportar arquivos de análise preliminar (.xlsx / .kml) que contemplem informações de TODAS as localidades de agrupamento, ou apenas da SELECIONADA?';
                    initialSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', initialQuestion, {'Todas', 'Selecionada', 'Cancelar'}, 1, 3);

                    switch initialSelection
                        case 'Cancelar'
                            return
                        case 'Todas'
                            indexes = 1:numel(app.measData);
                    end
                end

                if ~isempty(layout_searchUnexpectedTableValues(app))
                    warningMessages = ['Há registro de pontos críticos localizados na(s) localidade(s) sob análise para os quais '     ...
                                       'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                                       'o campo "Justificativa" e anotar os registros, caso aplicável.<br><br>Deseja ignorar ' ...
                                       'esse alerta, exportando PRÉVIA da análise?'];
                    userSelection   = appUtil.modalWindow(app.UIFigure, 'uiconfirm', warningMessages, {'Sim', 'Não'}, 2, 2);
                    if userSelection == "Não"
                        return
                    end
                end
                % </VALIDAÇÕES>
    
                % <PROCESSO>
                % (a) Solicita ao usuário nome do arquivo de saída...
                appName       = class.Constants.appName;
                nameFormatMap = {'*.zip', [appName, ' (*.zip)']};                
                defaultName   = appUtil.DefaultFileName(app.mainApp.General.fileFolder.userPath, [appName '_Preview']);
                fileZIP       = appUtil.modalWindow(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
                if isempty(fileZIP)
                    return
                end
    
                d = appUtil.modalWindow(app.UIFigure, 'progressdlg', 'Em andamento a criação do arquivo de medidas no formato ".xlsx".');
    
                savedFiles   = {};
                errorFiles   = {};
    
                % (b) Gera a tabela global de medidas (englobando todas as localidades 
                %     de agrupamento).
                measTableGlobal    = createMeasTable(app.measData(indexes));

                % (c) Arquivo no formato .XLSX
                fileName_XLSX = fullfile(app.mainApp.General.fileFolder.tempPath, 'Demanda externa (Preview).xlsx');
                [status, msgError] = fileWriter.ExternalRequest(fileName_XLSX, pointsTable, timetable2table(measTableGlobal), app.mainApp.General.(context).FieldValue, app.mainApp.General.(context).Export.XLSX);
                if status
                    savedFiles{end+1} = fileName_XLSX;
                else
                    errorFiles{end+1} = msgError;
                end
        
                % (d) Arquivos no formato .KML: "Measures" e "Route" 
                if app.mainApp.General.(context).Export.KML
                    d.Message = 'Em andamento a criação dos arquivos de medidas e rotas no formato ".kml".';

                    groupLocations = unique({app.measData(indexes).Location});

                    for ii = 1:numel(groupLocations)
                        groupLocation = groupLocations{ii};
                        [~, groupLocationIndex] = ismember(groupLocation, {app.TreeFileLocations.Children.Text});

                        if ~isequal(app.TreeFileLocations.SelectedNodes, app.TreeFileLocations.Children(groupLocationIndex))
                            app.TreeFileLocations.SelectedNodes = app.TreeFileLocations.Children(groupLocationIndex);
                            TreeFileLocationsSelectionChanged(app, struct('SelectedNodes', app.TreeFileLocations.Children(groupLocationIndex)))
                        end

                        groupLocationText    = replace(app.TreeFileLocations.SelectedNodes.Text, '/', '-');
                        groupLocationIndexes = FileIndex(app);
                        groupLocationMeasTable = createMeasTable(app.measData(groupLocationIndexes));

                        % MEDIDAS
                        hMeasPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');                        
                        KML1File  = fullfile(app.mainApp.General.fileFolder.tempPath, sprintf('%s (Measures).kml', groupLocationText));
                        [status1, msgError1] = fileWriter.KML(KML1File, 'Measures', timetable2table(groupLocationMeasTable), hMeasPlot);
                        if status1
                            savedFiles{end+1} = KML1File;
                        else
                            errorFiles{end+1} = msgError1;
                        end

                        % ROTA
                        KML2File = fullfile(app.mainApp.General.fileFolder.tempPath, sprintf('%s (Route).kml', groupLocationText));
                        [status2, msgError2] = fileWriter.KML(KML2File, 'Route', timetable2table(groupLocationMeasTable));
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
                    appUtil.modalWindow(app.UIFigure, 'none', sprintf('Lista de arquivos criados:\n%s', strjoin(savedFiles, '\n')));
                end
    
                if ~isempty(errorFiles)
                    appUtil.modalWindow(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
                end

                delete(d)
            end

        end

        % Image clicked function: tool_GenerateReport
        function Toolbar_GenerateReportImageClicked(app, event)
            
            context = 'ExternalRequest';
            indexes = FileIndex(app);

            if ~isempty(indexes)
                % <VALIDAÇÕES>
                if numel(indexes) < numel(app.measData)
                    initialQuestion  = 'Deseja gerar relatório que contemple informações de TODAS as localidades de agrupamento, ou apenas da SELECIONADA?';
                    initialSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', initialQuestion, {'Todas', 'Selecionada', 'Cancelar'}, 1, 3);

                    switch initialSelection
                        case 'Cancelar'
                            return
                        case 'Todas'
                            indexes = 1:numel(app.measData);
                    end
                end

                warningMessages = {};
                if ~report_checkEFiscalizaIssueId(app.mainApp, app.projectData.modules.(context).ui.issue)
                    warningMessages{end+1} = sprintf('O número da inspeção "%.0f" é inválido.', app.projectData.modules.(context).ui.issue);
                end
                
                if ~isempty(layout_searchUnexpectedTableValues(app))
                    warningMessages{end+1} = ['Há registro de pontos críticos localizados na(s) localidade(s) sob análise para os quais '     ...
                                              'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                                              'o campo "Justificativa" e anotar os registros, caso aplicável.'];
                end

                if ~isempty(warningMessages)
                    warningMessages = strjoin(warningMessages, '<br><br>');

                    switch app.reportVersion.Value
                        case 'Definitiva'
                            warningMessages = [warningMessages, '<br><br>Isso impossibilita a geração da versão DEFINITIVA do relatório.'];
                            appUtil.modalWindow(app.UIFigure, "warning", warningMessages);
                            return

                        otherwise % 'Preliminar'
                            warningMessages = [warningMessages, '<br><br>Deseja ignorar esse alerta, gerando a versão PRÉVIA do relatório?'];
                            userSelection   = appUtil.modalWindow(app.UIFigure, 'uiconfirm', warningMessages, {'Sim', 'Não'}, 2, 2);
                            if userSelection == "Não"
                                return
                            end
                    end
                end
                % </VALIDAÇÕES>

                % <PROCESSO>
                app.progressDialog.Visible = 'visible';

                try
                    reportSettings = struct('system',        app.reportSystem.Value, ...
                                            'unit',          app.reportUnit.Value, ...
                                            'issue',         app.reportIssue.Value, ...
                                            'model',         app.reportModelName.Value, ...
                                            'reportVersion', app.reportVersion.Value);
                    reportLibConnection.Controller.Run(app, app.projectData, app.measData(indexes), reportSettings, app.mainApp.General)
                catch ME
                    appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));
                end

                updateToolbar(app)

                app.progressDialog.Visible = 'hidden';
                % </PROCESSO>
            end

        end

        % Image clicked function: tool_UploadFinalFile
        function Toolbar_UploadFinalFileImageClicked(app, event)
            
            % <VALIDAÇÕES>
            context = 'ExternalRequest';
            lastHTMLDocFullPath = getGeneratedDocumentFileName(app.projectData, '.html', context);

            msg = '';
            if isempty(lastHTMLDocFullPath)
                msg = 'A versão definitiva do relatório ainda não foi gerada.';
            elseif ~isfile(lastHTMLDocFullPath)
                msg = sprintf('O arquivo "%s" não foi encontrado.', lastHTMLDocFullPath);
            elseif ~isfolder(app.mainApp.General.fileFolder.DataHub_POST)
                msg = 'Pendente mapear pasta do Sharepoint';
            elseif ~report_checkEFiscalizaIssueId(app.mainApp, app.projectData.modules.(context).ui.issue)
                msg = sprintf('O número da inspeção "%.0f" é inválido.', app.projectData.modules.(context).ui.issue);
            elseif isempty(app.projectData.modules.(context).ui.system)
                msg = 'Ambiente do eFiscaliza precisa ser selecionado.';
            elseif isempty(app.projectData.modules.(context).ui.unit)
                msg = 'Unidade geradora do documento precisa ser selecionada.';
            end

            if ~isempty(msg)
                appUtil.modalWindow(app.UIFigure, 'warning', msg);
                return
            end
            % </VALIDAÇÕES>

            % <PROCESSO>
            if isempty(app.mainApp.eFiscalizaObj)
                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');
                sendEventToHTMLSource(app.jsBackDoor, 'customForm', struct('UUID', 'eFiscalizaSignInPage', 'Fields', dialogBox, 'Context', context))
            else
                report_uploadInfoController(app.mainApp, [], 'uploadDocument', context)
            end
            % </PROCESSO>

        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)

            [~, tabIndex] = ismember(app.TabGroup.SelectedTab, app.TabGroup.Children);
            jsBackDoor_Customizations(app, tabIndex)

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
            
            idxPoint = [];
            if ~isempty(app.TreePoints.SelectedNodes)
                idxPoint = app.TreePoints.SelectedNodes.NodeData;
            end

            % Nessa operação, o foco sai de app.TreePoints e vai pra app.UITable.
            previousSelection = app.UITable.Selection;
            app.UITable.Selection = idxPoint;
            drawnow            

            UITableSelectionChanged(app, struct('PreviousSelection', previousSelection, 'Selection', idxPoint))            
            focus(app.TreePoints)

        end

        % Selection changed function: TreeFileLocations
        function TreeFileLocationsSelectionChanged(app, event)
            
            if isempty(event.SelectedNodes)
                app.TreeFileLocations.SelectedNodes = event.PreviousSelectedNodes;
                return
            end

            Analysis(app)

        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            
            if ~ismember(event.EditData, app.mainApp.General.ExternalRequest.NoMeasureReasons)
                app.UITable.Data.("Justificativa") = app.projectData.modules.ExternalRequest.pointsTable.("Justificativa");
                return
            end

            idxPoint = event.Indices(1);
            app.projectData.modules.ExternalRequest.pointsTable.("Justificativa")(idxPoint) = event.NewData;
            
            layout_TableStyle(app)

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

            plot_SelectedPoint(app)

        end

        % Value changed function: NewPointType
        function NewPointTypeValueChanged(app, event)
            
            switch app.NewPointType.Value
                case 'Estação'
                    app.NewPointStation.Enable = 1;
                    set(app.NewPointLatitude,  'Value', -1, 'Enable', 0)
                    set(app.NewPointLongitude, 'Value', -1, 'Enable', 0)

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
                set(app.NewPointLatitude,  'Value', -1, 'Enable', 1)
                set(app.NewPointLongitude, 'Value', -1, 'Enable', 1)
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
                    app.AddNewPointMode.UserData = ~app.AddNewPointMode.UserData;
                    
                    if app.AddNewPointMode.UserData
                        layout_newPointPanel(app, 'on')
                    else
                        layout_newPointPanel(app, 'off')
                    end

                case app.AddNewPointConfirm
                    % VALIDAÇÃO
                    if isempty(app.NewPointType.Value) || ((app.NewPointLatitude.Value == -1) && (app.NewPointLongitude.Value == -1))
                        msgWarning = 'Um novo ponto crítico somente poderá ser incluído se definido o seu tipo e coordenadas geográficas diferentes de (-1, -1).';
                        appUtil.modalWindow(app.UIFigure, 'warning', msgWarning);
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
                    if any(strcmp(app.projectData.modules.ExternalRequest.pointsTable_I.ID, ID))
                        appUtil.modalWindow(app.UIFigure, 'warning', 'Registro já consta na lista de pontos sob análise.');
                        return
                    end

                    columsn2Fill = {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'Justificativa', 'AnalysisFlag'};        
                    app.projectData.modules.ExternalRequest.pointsTable_I(end+1, columsn2Fill) = {ID,                            ...
                                                                                                app.NewPointType.Value,        ...
                                                                                                app.NewPointStation.Value,     ...
                                                                                                app.NewPointLatitude.Value,    ...
                                                                                                app.NewPointLongitude.Value,   ...
                                                                                                app.NewPointDescription.Value, ...
                                                                                                categorical("-1"),             ...
                                                                                                false};
                    app.projectData.modules.ExternalRequest.pointsTable_I = model.projectLib.generateHash(app.projectData.modules.ExternalRequest.pointsTable_I, 'pointsTable');
                    app.projectData.modules.ExternalRequest.pointsTable(end+1, :) = app.projectData.modules.ExternalRequest.pointsTable_I(end, :);
                    updateAnalysis(app.projectData, app.measData, app.mainApp.General, 'ExternalRequest:PointsTableChanged');
        
                    % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                    TreePointsBuilding(app)
        
                    % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                    Analysis(app)

                    % DESABILITA MODO DE INCLUSÃO DE PONTO
                    layout_newPointPanel(app, 'off')

                case app.AddNewPointCancel
                    layout_newPointPanel(app, 'off')
            end

        end

        % Menu selected function: DeletePoint
        function DeleteSelectedPoint(app, event)
            
            idxPoint = [];

            if ismember(app.TreePoints, [event.ContextObject, event.ContextObject.Parent])
                if ~isempty(app.TreePoints.SelectedNodes)
                    idxPoint = app.TreePoints.SelectedNodes.NodeData;
                end
            elseif event.ContextObject == app.UITable
                idxPoint = app.UITable.Selection;
            end

            if ~isempty(idxPoint)
                app.projectData.modules.ExternalRequest.pointsTable_I(idxPoint, :) = [];
                app.projectData.modules.ExternalRequest.pointsTable(idxPoint, :)   = [];
                updateAnalysis(app.projectData, app.measData, app.mainApp.General, 'ExternalRequest:PointsTableChanged');

                % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                TreePointsBuilding(app)
    
                % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                Analysis(app)
            end

        end

        % Value changed function: reportModelName
        function reportModelNameValueChanged(app, event)
            
            updateToolbar(app)

        end

        % Value changed function: reportIssue, reportSystem, reportUnit
        function reportInfoValueChanged(app, event)
            
            context = 'ExternalRequest';

            switch event.Source
                case app.reportSystem
                    updateUiInfo(app.projectData, context, 'system', app.reportSystem.Value)
                case app.reportUnit
                    updateUiInfo(app.projectData, context, 'unit',   app.reportUnit.Value)
                case app.reportIssue
                    updateUiInfo(app.projectData, context, 'issue',  app.reportIssue.Value)
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

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, 22, 5, 22, '1x', 22, 22};
            app.toolGrid.RowHeight = {4, 17, '1x'};
            app.toolGrid.ColumnSpacing = 5;
            app.toolGrid.RowSpacing = 0;
            app.toolGrid.Padding = [10 5 10 5];
            app.toolGrid.Layout.Row = 6;
            app.toolGrid.Layout.Column = [1 7];
            app.toolGrid.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create tool_ControlPanelVisibility
            app.tool_ControlPanelVisibility = uiimage(app.toolGrid);
            app.tool_ControlPanelVisibility.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_ControlPanelVisibility.Layout.Row = 2;
            app.tool_ControlPanelVisibility.Layout.Column = 1;
            app.tool_ControlPanelVisibility.ImageSource = 'ArrowLeft_32.png';

            % Create tool_TableVisibility
            app.tool_TableVisibility = uiimage(app.toolGrid);
            app.tool_TableVisibility.ScaleMethod = 'none';
            app.tool_TableVisibility.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_TableVisibility.Tooltip = {'Visibilidade da tabela'};
            app.tool_TableVisibility.Layout.Row = 2;
            app.tool_TableVisibility.Layout.Column = 2;
            app.tool_TableVisibility.ImageSource = 'View_16.png';

            % Create tool_Separator
            app.tool_Separator = uiimage(app.toolGrid);
            app.tool_Separator.ScaleMethod = 'none';
            app.tool_Separator.Enable = 'off';
            app.tool_Separator.Layout.Row = [1 3];
            app.tool_Separator.Layout.Column = 4;
            app.tool_Separator.ImageSource = 'LineV.svg';

            % Create tool_peakLabel
            app.tool_peakLabel = uilabel(app.toolGrid);
            app.tool_peakLabel.FontSize = 10;
            app.tool_peakLabel.Visible = 'off';
            app.tool_peakLabel.Layout.Row = [1 3];
            app.tool_peakLabel.Layout.Column = 6;
            app.tool_peakLabel.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create tool_peakIcon
            app.tool_peakIcon = uiimage(app.toolGrid);
            app.tool_peakIcon.ScaleMethod = 'none';
            app.tool_peakIcon.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_peakIcon.Enable = 'off';
            app.tool_peakIcon.Tooltip = {'Zoom em torno do local de máximo'};
            app.tool_peakIcon.Layout.Row = [1 3];
            app.tool_peakIcon.Layout.Column = 5;
            app.tool_peakIcon.ImageSource = 'Detection_18.png';

            % Create tool_GenerateReport
            app.tool_GenerateReport = uiimage(app.toolGrid);
            app.tool_GenerateReport.ScaleMethod = 'none';
            app.tool_GenerateReport.ImageClickedFcn = createCallbackFcn(app, @Toolbar_GenerateReportImageClicked, true);
            app.tool_GenerateReport.Enable = 'off';
            app.tool_GenerateReport.Tooltip = {'Gera relatório (.html)'};
            app.tool_GenerateReport.Layout.Row = 2;
            app.tool_GenerateReport.Layout.Column = 7;
            app.tool_GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.toolGrid);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @Toolbar_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Tooltip = {'Exporta análise (.xlsx, .kml)'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 3;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create tool_UploadFinalFile
            app.tool_UploadFinalFile = uiimage(app.toolGrid);
            app.tool_UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @Toolbar_UploadFinalFileImageClicked, true);
            app.tool_UploadFinalFile.Enable = 'off';
            app.tool_UploadFinalFile.Tooltip = {'Upload relatório'};
            app.tool_UploadFinalFile.Layout.Row = 2;
            app.tool_UploadFinalFile.Layout.Column = 8;
            app.tool_UploadFinalFile.ImageSource = 'Up_24.png';

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
            app.axesTool_RestoreView.Tooltip = {'RestoreView'};
            app.axesTool_RestoreView.Layout.Row = 1;
            app.axesTool_RestoreView.Layout.Column = 1;
            app.axesTool_RestoreView.ImageSource = 'Home_18.png';

            % Create axesTool_RegionZoom
            app.axesTool_RegionZoom = uiimage(app.AxesToolbar);
            app.axesTool_RegionZoom.ScaleMethod = 'none';
            app.axesTool_RegionZoom.ImageClickedFcn = createCallbackFcn(app, @AxesToolbarImageClicked, true);
            app.axesTool_RegionZoom.Tooltip = {'RegionZoom'};
            app.axesTool_RegionZoom.Layout.Row = 1;
            app.axesTool_RegionZoom.Layout.Column = 2;
            app.axesTool_RegionZoom.ImageSource = 'ZoomRegion_20.png';

            % Create dockModuleGrid
            app.dockModuleGrid = uigridlayout(app.GridLayout);
            app.dockModuleGrid.RowHeight = {'1x'};
            app.dockModuleGrid.ColumnSpacing = 2;
            app.dockModuleGrid.Padding = [5 2 5 2];
            app.dockModuleGrid.Visible = 'off';
            app.dockModuleGrid.Layout.Row = [2 3];
            app.dockModuleGrid.Layout.Column = [5 6];
            app.dockModuleGrid.BackgroundColor = [0.2 0.2 0.2];

            % Create dockModule_Close
            app.dockModule_Close = uiimage(app.dockModuleGrid);
            app.dockModule_Close.ScaleMethod = 'none';
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @DockModuleGroup_ButtonPushed, true);
            app.dockModule_Close.Tag = 'DRIVETEST';
            app.dockModule_Close.Tooltip = {'Fecha módulo'};
            app.dockModule_Close.Layout.Row = 1;
            app.dockModule_Close.Layout.Column = 2;
            app.dockModule_Close.ImageSource = 'Delete_12SVG_white.svg';

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.dockModuleGrid);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @DockModuleGroup_ButtonPushed, true);
            app.dockModule_Undock.Tag = 'DRIVETEST';
            app.dockModule_Undock.Enable = 'off';
            app.dockModule_Undock.Tooltip = {'Reabre módulo em outra janela'};
            app.dockModule_Undock.Layout.Row = 1;
            app.dockModule_Undock.Layout.Column = 1;
            app.dockModule_Undock.ImageSource = 'Undock_18White.png';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Layout.Row = [3 4];
            app.TabGroup.Layout.Column = 2;

            % Create PMRNITab
            app.PMRNITab = uitab(app.TabGroup);
            app.PMRNITab.AutoResizeChildren = 'off';
            app.PMRNITab.Title = 'PM-RNI';

            % Create Control
            app.Control = uigridlayout(app.PMRNITab);
            app.Control.ColumnWidth = {'1x', 18, 0, 0};
            app.Control.RowHeight = {30, '1x', 37, 0, 174};
            app.Control.ColumnSpacing = 5;
            app.Control.RowSpacing = 5;
            app.Control.BackgroundColor = [1 1 1];

            % Create config_geoAxesLabel
            app.config_geoAxesLabel = uilabel(app.Control);
            app.config_geoAxesLabel.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel.WordWrap = 'on';
            app.config_geoAxesLabel.FontSize = 10;
            app.config_geoAxesLabel.Layout.Row = 1;
            app.config_geoAxesLabel.Layout.Column = 1;
            app.config_geoAxesLabel.Interpreter = 'html';
            app.config_geoAxesLabel.Text = {'LOCALIDADES DE AGRUPAMENTO:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.Control);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @TreeFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 2;
            app.TreeFileLocations.Layout.Column = [1 4];

            % Create TreePointsLabel
            app.TreePointsLabel = uilabel(app.Control);
            app.TreePointsLabel.VerticalAlignment = 'bottom';
            app.TreePointsLabel.FontSize = 10;
            app.TreePointsLabel.Layout.Row = 3;
            app.TreePointsLabel.Layout.Column = 1;
            app.TreePointsLabel.Interpreter = 'html';
            app.TreePointsLabel.Text = {'PONTOS CRÍTICOS SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionado àquilo que fora pedido pelo demandante)</font>'};

            % Create AddNewPointMode
            app.AddNewPointMode = uiimage(app.Control);
            app.AddNewPointMode.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointMode.Tooltip = {'Habilita painel de inclusão de ponto'};
            app.AddNewPointMode.Layout.Row = 3;
            app.AddNewPointMode.Layout.Column = 2;
            app.AddNewPointMode.VerticalAlignment = 'bottom';
            app.AddNewPointMode.ImageSource = 'addFiles_32.png';

            % Create AddNewPointConfirm
            app.AddNewPointConfirm = uiimage(app.Control);
            app.AddNewPointConfirm.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointConfirm.Enable = 'off';
            app.AddNewPointConfirm.Tooltip = {'Confirma edição'};
            app.AddNewPointConfirm.Layout.Row = 3;
            app.AddNewPointConfirm.Layout.Column = 3;
            app.AddNewPointConfirm.VerticalAlignment = 'bottom';
            app.AddNewPointConfirm.ImageSource = 'Ok_32Green.png';

            % Create AddNewPointCancel
            app.AddNewPointCancel = uiimage(app.Control);
            app.AddNewPointCancel.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointCancel.Enable = 'off';
            app.AddNewPointCancel.Tooltip = {'Cancela edição'};
            app.AddNewPointCancel.Layout.Row = 3;
            app.AddNewPointCancel.Layout.Column = 4;
            app.AddNewPointCancel.VerticalAlignment = 'bottom';
            app.AddNewPointCancel.ImageSource = 'Delete_32Red.png';

            % Create AddNewPointPanel
            app.AddNewPointPanel = uipanel(app.Control);
            app.AddNewPointPanel.AutoResizeChildren = 'off';
            app.AddNewPointPanel.Layout.Row = 4;
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
            app.NewPointLatitude.ValueChangedFcn = createCallbackFcn(app, @NewPointLatitudeValueChanged, true);
            app.NewPointLatitude.HorizontalAlignment = 'left';
            app.NewPointLatitude.FontSize = 11;
            app.NewPointLatitude.Layout.Row = 4;
            app.NewPointLatitude.Layout.Column = 2;
            app.NewPointLatitude.Value = -1;

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
            app.NewPointLongitude.HorizontalAlignment = 'left';
            app.NewPointLongitude.FontSize = 11;
            app.NewPointLongitude.Layout.Row = 4;
            app.NewPointLongitude.Layout.Column = 3;
            app.NewPointLongitude.Value = -1;

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
            app.TreePoints = uitree(app.Control);
            app.TreePoints.SelectionChangedFcn = createCallbackFcn(app, @TreePointsSelectionChanged, true);
            app.TreePoints.FontSize = 11;
            app.TreePoints.Layout.Row = 5;
            app.TreePoints.Layout.Column = [1 4];

            % Create PROJETOTab
            app.PROJETOTab = uitab(app.TabGroup);
            app.PROJETOTab.AutoResizeChildren = 'off';
            app.PROJETOTab.Title = 'PROJETO';

            % Create Tab4Grid
            app.Tab4Grid = uigridlayout(app.PROJETOTab);
            app.Tab4Grid.ColumnWidth = {'1x', 22};
            app.Tab4Grid.RowHeight = {17, 100, 22, '1x'};
            app.Tab4Grid.RowSpacing = 5;
            app.Tab4Grid.BackgroundColor = [1 1 1];

            % Create eFiscalizaLabel
            app.eFiscalizaLabel = uilabel(app.Tab4Grid);
            app.eFiscalizaLabel.VerticalAlignment = 'bottom';
            app.eFiscalizaLabel.FontSize = 10;
            app.eFiscalizaLabel.Layout.Row = 1;
            app.eFiscalizaLabel.Layout.Column = 1;
            app.eFiscalizaLabel.Text = 'eFISCALIZA';

            % Create eFiscalizaPanel
            app.eFiscalizaPanel = uipanel(app.Tab4Grid);
            app.eFiscalizaPanel.Layout.Row = 2;
            app.eFiscalizaPanel.Layout.Column = [1 2];

            % Create eFiscalizaGrid
            app.eFiscalizaGrid = uigridlayout(app.eFiscalizaPanel);
            app.eFiscalizaGrid.ColumnWidth = {'1x', 150};
            app.eFiscalizaGrid.RowHeight = {22, 22, 22, '1x'};
            app.eFiscalizaGrid.RowSpacing = 5;
            app.eFiscalizaGrid.BackgroundColor = [1 1 1];

            % Create reportSystemLabel
            app.reportSystemLabel = uilabel(app.eFiscalizaGrid);
            app.reportSystemLabel.FontSize = 11;
            app.reportSystemLabel.Layout.Row = 1;
            app.reportSystemLabel.Layout.Column = 1;
            app.reportSystemLabel.Text = 'Sistema:';

            % Create reportSystem
            app.reportSystem = uidropdown(app.eFiscalizaGrid);
            app.reportSystem.Items = {'eFiscaliza', 'eFiscaliza DS', 'eFiscaliza HM'};
            app.reportSystem.ValueChangedFcn = createCallbackFcn(app, @reportInfoValueChanged, true);
            app.reportSystem.FontSize = 11;
            app.reportSystem.BackgroundColor = [1 1 1];
            app.reportSystem.Layout.Row = 1;
            app.reportSystem.Layout.Column = 2;
            app.reportSystem.Value = 'eFiscaliza';

            % Create reportUnitLabel
            app.reportUnitLabel = uilabel(app.eFiscalizaGrid);
            app.reportUnitLabel.FontSize = 11;
            app.reportUnitLabel.Layout.Row = 2;
            app.reportUnitLabel.Layout.Column = 1;
            app.reportUnitLabel.Text = 'Unidade responsável:';

            % Create reportUnit
            app.reportUnit = uidropdown(app.eFiscalizaGrid);
            app.reportUnit.Items = {};
            app.reportUnit.ValueChangedFcn = createCallbackFcn(app, @reportInfoValueChanged, true);
            app.reportUnit.FontSize = 11;
            app.reportUnit.BackgroundColor = [1 1 1];
            app.reportUnit.Layout.Row = 2;
            app.reportUnit.Layout.Column = 2;
            app.reportUnit.Value = {};

            % Create reportIssueLabel
            app.reportIssueLabel = uilabel(app.eFiscalizaGrid);
            app.reportIssueLabel.FontSize = 11;
            app.reportIssueLabel.Layout.Row = [3 4];
            app.reportIssueLabel.Layout.Column = 1;
            app.reportIssueLabel.Text = {'Atividade de inspeção:'; '(# ID)'};

            % Create reportIssue
            app.reportIssue = uieditfield(app.eFiscalizaGrid, 'numeric');
            app.reportIssue.Limits = [-1 Inf];
            app.reportIssue.RoundFractionalValues = 'on';
            app.reportIssue.ValueDisplayFormat = '%d';
            app.reportIssue.ValueChangedFcn = createCallbackFcn(app, @reportInfoValueChanged, true);
            app.reportIssue.FontSize = 11;
            app.reportIssue.FontColor = [0.149 0.149 0.149];
            app.reportIssue.Layout.Row = 3;
            app.reportIssue.Layout.Column = 2;
            app.reportIssue.Value = -1;

            % Create reportLabel
            app.reportLabel = uilabel(app.Tab4Grid);
            app.reportLabel.VerticalAlignment = 'bottom';
            app.reportLabel.FontSize = 10;
            app.reportLabel.Layout.Row = 3;
            app.reportLabel.Layout.Column = 1;
            app.reportLabel.Text = 'RELATÓRIO';

            % Create reportPanel
            app.reportPanel = uipanel(app.Tab4Grid);
            app.reportPanel.BackgroundColor = [1 1 1];
            app.reportPanel.Layout.Row = 4;
            app.reportPanel.Layout.Column = [1 2];

            % Create reportGrid
            app.reportGrid = uigridlayout(app.reportPanel);
            app.reportGrid.ColumnWidth = {'1x', 150};
            app.reportGrid.RowHeight = {22, 22};
            app.reportGrid.RowSpacing = 5;
            app.reportGrid.BackgroundColor = [1 1 1];

            % Create reportModelNameLabel
            app.reportModelNameLabel = uilabel(app.reportGrid);
            app.reportModelNameLabel.FontSize = 11;
            app.reportModelNameLabel.Layout.Row = 1;
            app.reportModelNameLabel.Layout.Column = 1;
            app.reportModelNameLabel.Text = 'Modelo (.json):';

            % Create reportModelName
            app.reportModelName = uidropdown(app.reportGrid);
            app.reportModelName.Items = {''};
            app.reportModelName.ValueChangedFcn = createCallbackFcn(app, @reportModelNameValueChanged, true);
            app.reportModelName.FontSize = 11;
            app.reportModelName.BackgroundColor = [1 1 1];
            app.reportModelName.Layout.Row = 1;
            app.reportModelName.Layout.Column = 2;
            app.reportModelName.Value = '';

            % Create reportVersionLabel
            app.reportVersionLabel = uilabel(app.reportGrid);
            app.reportVersionLabel.WordWrap = 'on';
            app.reportVersionLabel.FontSize = 11;
            app.reportVersionLabel.Layout.Row = 2;
            app.reportVersionLabel.Layout.Column = 1;
            app.reportVersionLabel.Text = 'Versão do relatório:';

            % Create reportVersion
            app.reportVersion = uidropdown(app.reportGrid);
            app.reportVersion.Items = {'Preliminar', 'Definitiva'};
            app.reportVersion.FontSize = 11;
            app.reportVersion.BackgroundColor = [1 1 1];
            app.reportVersion.Layout.Row = 2;
            app.reportVersion.Layout.Column = 2;
            app.reportVersion.Value = 'Preliminar';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'auxApp.winExternalRequest';

            % Create DeletePoint
            app.DeletePoint = uimenu(app.ContextMenu);
            app.DeletePoint.MenuSelectedFcn = createCallbackFcn(app, @DeleteSelectedPoint, true);
            app.DeletePoint.ForegroundColor = [1 0 0];
            app.DeletePoint.Text = 'Excluir';

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
