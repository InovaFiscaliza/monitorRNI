classdef winMonitoringPlan_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        SubTabGroup                 matlab.ui.container.TabGroup
        SubTab1                     matlab.ui.container.Tab
        SubGrid1                    matlab.ui.container.GridLayout
        Card4_stationsOutRoute      matlab.ui.control.Label
        Card3_stationsOnRoute       matlab.ui.control.Label
        Card2_numberOfRiskStations  matlab.ui.control.Label
        Card1_numberOfStations      matlab.ui.control.Label
        LocationList                matlab.ui.control.TextArea
        LocationListEdit            matlab.ui.control.Image
        LocationListLabel           matlab.ui.control.Label
        TreeFileLocations           matlab.ui.container.Tree
        config_geoAxesLabel_2       matlab.ui.control.Label
        DockModule                  matlab.ui.container.GridLayout
        dockModule_Close            matlab.ui.control.Image
        dockModule_Undock           matlab.ui.control.Image
        Document                    matlab.ui.container.GridLayout
        AxesToolbar                 matlab.ui.container.GridLayout
        axesTool_RegionZoom         matlab.ui.control.Image
        axesTool_RestoreView        matlab.ui.control.Image
        plotPanel                   matlab.ui.container.Panel
        UITable                     matlab.ui.control.Table
        Toolbar                     matlab.ui.container.GridLayout
        tool_UploadFinalFile        matlab.ui.control.Image
        tool_GenerateReport         matlab.ui.control.Image
        tool_OpenPopupProject       matlab.ui.control.Image
        tool_PeakLabel              matlab.ui.control.Label
        tool_PeakIcon               matlab.ui.control.Image
        tool_Separator2             matlab.ui.control.Image
        tool_ExportFiles            matlab.ui.control.Image
        tool_TableEdition           matlab.ui.control.Image
        tool_TableVisibility        matlab.ui.control.Image
        tool_Separator1             matlab.ui.control.Image
        tool_PanelVisibility        matlab.ui.control.Image
        ContextMenu                 matlab.ui.container.ContextMenu
        EditSelectedUITableRow      matlab.ui.container.Menu
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'secondaryApp'
        Context = 'MONITORINGPLAN'
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


    properties (Access = protected, Constant)
        %-----------------------------------------------------------------%
        LOCATION_SELECTION_EVENT_MAPPING = dictionary( ...
            ["Selecionada", "Todas"], ...
            ["onInspectSelection", "onInspectAll"] ...
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
                            % auxApp.dockListOfLocation >> winMonitorRNI >> auxApp.winMonitoringPlan
                            % auxApp.dockStationInfo    >> winMonitorRNI >> auxApp.winMonitoringPlan
                            % auxApp.dockReportLib      >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case 'closeFcnCallFromPopupApp'
                                app.popupContainer.Parent.Visible = 0;
                                
                            % winMonitorRNI >> auxApp.winMonitoringPlan
                            case {'onFileListAdded', 'onFileListRemoved', 'onFileListUnmerged', 'onFileListMerged'}
                                app.measData = app.mainApp.measData;
                                buildFileLocationTree(app)

                                if ~isempty(app.measData)
                                    refreshAnalysis(app)
                                end

                            % auxApp.winConfig >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case 'onAnalysisParameterChanged'
                                app.UITable.ColumnName{6} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
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

                            % winMonitorRNI >> auxApp.winMonitoringPlan
                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winMonitoringPlan
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

                            % auxApp.dockStationInfo >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case 'onStationInfoChanged'
                                [stationIdx, stationTableRow] = getSelectedStationIndex(app);
                                newReason = varargin{1};
                                newObservation = varargin{2};
                                updateStationTable(app.projectData, eventName, stationIdx, newReason, newObservation)

                                app.UITable.Data.("Justificativa")(stationTableRow) = newReason;
                                applyTableStyle(app)

                            case 'onStationCoordinatesEdited'
                                stationIdx = getSelectedStationIndex(app);
                                newLatitude  = varargin{1};
                                newLongitude = varargin{2};
                                updateStationTable(app.projectData, eventName, stationIdx, newLatitude, newLongitude, app.measData, app.mainApp.General)

                                refreshAnalysis(app)

                            case 'onStationSelectionChanged'
                                newRowSelection = varargin{1};
                                app.UITable.Selection = newRowSelection;
                                scroll(app.UITable, 'row', newRowSelection)

                                UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', newRowSelection))

                            % auxApp.dockListOfLocation >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case 'onLocationListModeChanged'
                                updateAnalysis(app.projectData, app.measData, app.mainApp.General, eventName, app.Context)
                                refreshAnalysis(app)

                            otherwise
                                error('model:winMonitoringPlan:UnexpectedCall', 'Unexpected call "%s"', eventName)
                        end
    
                    otherwise
                        error('model:winMonitoringPlan:UnexpectedCaller', 'Unexpected caller "%s"', class(callingApp))
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
                        app.LocationListEdit;
                        app.tool_PanelVisibility;
                        app.tool_TableVisibility;
                        app.tool_TableEdition;
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
                            struct('appName', appName, 'dataTag', app.LocationListEdit.UserData.id,      'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita lista de localidades sob análise')), ...
                            struct('appName', appName, 'dataTag', app.tool_PanelVisibility.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna visibilidade do painel')), ...
                            struct('appName', appName, 'dataTag', app.tool_TableVisibility.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna entre três layouts do conjunto plot+tabela<br>(apenas plot, apenas tabela ou plot+tabela)')), ...
                            struct('appName', appName, 'dataTag', app.tool_TableEdition.UserData.id,     'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita, em formulário, as informações do registro selecionado na tabela')), ...
                            struct('appName', appName, 'dataTag', app.tool_ExportFiles.UserData.id,      'tooltip', struct('defaultPosition', 'top',    'textContent', 'Exporta análise (.xlsx, .kml)')), ...
                            struct('appName', appName, 'dataTag', app.tool_PeakIcon.UserData.id,         'tooltip', struct('defaultPosition', 'top',    'textContent', 'Aplica zoom em torno do local de valor máximo')), ...
                            struct('appName', appName, 'dataTag', app.tool_OpenPopupProject.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita informações do projeto<br>(fiscalizada, arquivo de backup etc)')), ...
                            struct('appName', appName, 'dataTag', app.tool_GenerateReport.UserData.id,   'tooltip', struct('defaultPosition', 'top',    'textContent', 'Gera relatório')), ...
                            struct('appName', appName, 'dataTag', app.tool_UploadFinalFile.UserData.id,  'tooltip', struct('defaultPosition', 'top',    'textContent', 'Upload relatório')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Undock.UserData.id,     'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Reabre módulo em outra janela')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Close.UserData.id,      'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Fecha módulo')) ...
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

            if app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold ~= 14
                app.UITable.ColumnName{6} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
            end
            app.UITable.RowName = 'numbered';

            [app.UIAxes, app.restoreView] = plot.axesCreationController(app.plotPanel, app.mainApp.General);
            
            buildFileLocationTree(app)
            if ~isempty(app.measData)
                refreshAnalysis(app)
            end
                        
            app.tool_TableVisibility.UserData = 1;
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
            
            [stationIdxs, fullListOfLocation] = getAnalyzedStationIndexes(app, 'onSelectionChanging');            
            initialSelection = updateTable(app, stationIdxs);
            applyTableStyle(app)

            % Atualiza outros elementos da GUI, inclusive painel com quantitativo 
            % de estações.
            updatePanel(app, fullListOfLocation, stationIdxs)
            updateToolbar(app)

            % Atualiza plot.
            plotMeasuresAndPoints(app)

            if ~isempty(initialSelection)
                [~, rowIdx] = ismember(initialSelection, app.UITable.UserData);
                if rowIdx
                    app.UITable.Selection = rowIdx;
                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', rowIdx))
                end
            end

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function initialSelection = updateTable(app, stationIdxs)
            initialSelection = [];
            if ~isempty(app.UITable.Selection)
                initialSelection = app.UITable.UserData(app.UITable.Selection);
            end

            table2Render = app.projectData.modules.MONITORINGPLAN.stationTable(stationIdxs, {'Fistel',                ...
                                                                                             'Estação',               ...
                                                                                             'Location',              ...
                                                                                             'Serviço',               ...                                                                                      
                                                                                             'numberOfMeasures',      ...
                                                                                             'numberOfRiskMeasures',  ...
                                                                                             'minDistanceForMeasure', ...
                                                                                             'minFieldValue',         ...
                                                                                             'meanFieldValue',        ...
                                                                                             'maxFieldValue',         ...
                                                                                             'Justificativa'});
            set(app.UITable, 'Data', table2Render, 'UserData', stationIdxs, 'Selection', [])
        end

        %-----------------------------------------------------------------%
        function applyTableStyle(app)
            removeStyle(app.UITable)

            if ~isempty(app.UITable.Data)
                % Identifica estações que NÃO tiveram medições no seu entorno, 
                % apesar da rota englobar o município em que está instalada a
                % estação. Ou estações que apresentaram medições com níveis
                % acima de 14 V/m.
                stationIdxs = getAnalyzedStationIndexes(app, 'onInspectSelection');
                [invalidRowIdxs, ~, ~, manualEditionRowIdxs, riskMeasurementsIdxs] = validateAuditorClassification(app.projectData, app.Context, app.mainApp.General, stationIdxs);

                if ~isempty(invalidRowIdxs)
                    columnIndex1 = find(ismember(app.UITable.Data.Properties.VariableNames, 'Justificativa'));
                    s1 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');                
                    addStyle(app.UITable, s1, "cell", [invalidRowIdxs, repmat(columnIndex1, numel(invalidRowIdxs), 1)])
                end

                if ~isempty(manualEditionRowIdxs)
                    s2 = uistyle('Icon', 'edit.svg', 'IconAlignment', 'leftmargin');
                    addStyle(app.UITable, s2, "cell", [manualEditionRowIdxs, ones(numel(manualEditionRowIdxs), 1)])
                end

                if ~isempty(riskMeasurementsIdxs)
                    columnIndex2 = find(ismember(app.UITable.Data.Properties.VariableNames, 'numberOfRiskMeasures'));

                    s3 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');
                    addStyle(app.UITable, s3, "cell", [riskMeasurementsIdxs, repmat(columnIndex2, numel(riskMeasurementsIdxs), 1)])
                end
            end
        end

        %-----------------------------------------------------------------%
        function updatePanel(app, fullListOfLocation, idxStations)
            % Atualiza outros elementos da GUI, inclusive painel com quantitativo 
            % de estações.
            if ~isempty(fullListOfLocation)
                app.LocationList.Value = fullListOfLocation;
            else
                app.LocationList.Value = '';
            end
            
            nStations         = numel(idxStations);
            nRiskStations     = sum(app.UITable.Data.numberOfRiskMeasures > 0);
            nStationsOnRoute  = sum(app.UITable.Data.numberOfMeasures > 0);
            nStationsOutRoute = nStations - nStationsOnRoute;

            app.Card1_numberOfStations.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NAS LOCALIDADES SOB ANÁLISE</p>',                  nStations);
            app.Card2_numberOfRiskStations.Text = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE %.0f V/m</p></p>', nRiskStations, app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
            app.Card3_stationsOnRoute .Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>',                           nStationsOnRoute);
            app.Card4_stationsOutRoute.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS FORA DA ROTA</p>',                                 nStationsOutRoute);
        end

        %-----------------------------------------------------------------%
        function updateToolbar(app)
            measDataNonEmpty                = ~isempty(app.measData);
            measTableNonEmpty               = ~isempty(app.measTable);
            rowTableSelected                = ~isempty(app.UITable.Selection);
            reportFinalVersionGenerated     = ~isempty(app.projectData.modules.(app.Context).generatedFiles.lastHTMLDocFullPath);

            app.LocationListEdit.Enable     = measDataNonEmpty;
            app.tool_TableEdition.Enable    = measDataNonEmpty && rowTableSelected;
            app.tool_ExportFiles.Enable     = measDataNonEmpty;
            app.tool_GenerateReport.Enable  = measDataNonEmpty;
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

                if strcmp(locationGroups{ii}, app.projectData.modules.MONITORINGPLAN.ui.selectedGroup)
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
                updateTable(app, []);
                updatePanel(app, {}, [])
            end

            updateToolbar(app)
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
                plot.draw.Measures(app.UIAxes, app.measTable, app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold, app.mainApp.General);

                % Abaixo estabelece como limites do eixo os limites atuais,
                % configurados automaticamente pelo MATLAB. Ao fazer isso,
                % contudo, esses limites serão orientados às medidas e não às
                % estações.
                plotAxesDefaultLimits(app, 'measures')
            end

            % Stations/Points
            if ~isempty(app.UITable.Data)
                idxStations    = app.UITable.UserData;
                refPointsTable = app.projectData.modules.MONITORINGPLAN.stationTable(idxStations, :);
                plot.draw.Points(app.UIAxes, refPointsTable, 'Estações de referência PM-RNI', app.mainApp.General)
            end
            plotAxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plotSelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                selectedStationIdx = app.UITable.UserData(app.UITable.Selection);
                selectedPointTable = app.projectData.modules.MONITORINGPLAN.stationTable(selectedStationIdx, :);

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
        function [stationIdx, rowIdx] = getSelectedStationIndex(app)
            rowIdx     = app.UITable.Selection;
            stationIdx = app.UITable.UserData(rowIdx);
        end

        %-----------------------------------------------------------------%
        function [stationIdxs, locations] = getAnalyzedStationIndexes(app, eventName)
            arguments
                app
                eventName {mustBeMember(eventName, {'onSelectionChanging', 'onInspectSelection', 'onInspectAll'})}
            end

            switch eventName
                case 'onSelectionChanging'
                    fileIdxs    = getFileIndexes(app);
                    locations   = getFullListOfLocation(app.projectData, app.measData(fileIdxs), app.projectData.modules.MONITORINGPLAN.analysis.maxMeasurementDistanceKm);
                    stationIdxs = find(ismember(app.projectData.modules.MONITORINGPLAN.stationTable.Location, locations));

                case 'onInspectSelection'
                    locations   = {};
                    stationIdxs = app.UITable.UserData;

                case 'onInspectAll'
                    fileIdxs    = 1:numel(app.measData);
                    locations   = getFullListOfLocation(app.projectData, app.measData(fileIdxs), app.projectData.modules.MONITORINGPLAN.analysis.maxMeasurementDistanceKm);
                    stationIdxs = find(ismember(app.projectData.modules.MONITORINGPLAN.stationTable.Location, locations));
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

        % Callback function: EditSelectedUITableRow, tool_TableEdition
        function Toolbar_OpenPopUpEditionMode(app, event)
            
            if ~isempty(app.UITable.Selection)
                ipcMainMatlabOpenPopupApp(app.mainApp, app, 'StationInfo', app.Context)
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
                else
                    initialSelection = 'Todas';
                end

                stationIdxs = getAnalyzedStationIndexes(app, app.LOCATION_SELECTION_EVENT_MAPPING(initialSelection));
                invalidRowIndexes = validateAuditorClassification(app.projectData, context, app.mainApp.General, stationIdxs);                
                if ~isempty(invalidRowIndexes)
                    msgWarning = [
                        'Há registro de estações instaladas na(s) localidade(s) sob análise para as quais ' ...
                        'não foram identificadas medidas no entorno ou cuja operação foi indicada em local ' ...
                        'diferente, sem a devida especificação.<br><br>Deseja ignorar esse alerta, exportando ' ...
                        'PRÉVIA da análise?' ...
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

                % (b) Gera a tabela global de medidas (englobando as localidades 
                %     de agrupamento selecionadas), além do recorte da planilha
                %     de referência do PM-RNI (stationTable).
                measTableGlobal = buildMeasurementTable(app.measData(fileIdxs));
                stationTable    = app.projectData.modules.(context).stationTable(stationIdxs, :);
    
                % (c) Arquivo no formato .XLSX
                fileName_XLSX = fullfile(app.mainApp.General.fileFolder.tempPath, 'PM-RNI (Preview).xlsx');
                [status, msgError] = model.ProjectBase.exportAnalysisPreview(app.Context, stationTable, app.mainApp.General, timetable2table(measTableGlobal), fileName_XLSX, app.mainApp.General.context.MONITORINGPLAN.exportOptions.xlsx);
                if status
                    savedFiles{end+1} = fileName_XLSX;
                else
                    errorFiles{end+1} = msgError;
                end
        
                % (d) Arquivos no formato .KML: "Measures" e "Route" 
                if app.mainApp.General.context.MONITORINGPLAN.exportOptions.kml
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
            else
                initialSelection = 'Todas';
            end

            stationIdxs = getAnalyzedStationIndexes(app, app.LOCATION_SELECTION_EVENT_MAPPING(initialSelection));
            if isempty(stationIdxs)
                ui.Dialog(app.UIFigure, 'warning', [ ...
                    'Não há estações do PM-RNI associadas às medições. ' ...
                    'Ajuste o período de referência ou gere o resultado ' ...
                    'no módulo DEMANDA EXTERNA, no qual é possível adicionar ' ...
                    'manualmente pontos de interesse.' ...
                ]);
                return
            end

            msgWarning = {};
            if ~validateReportRequirements(app.projectData, context, 'issue')
                msgWarning{end+1} = sprintf('• O número da inspeção "%.0f" é inválido.', issue);
            end

            if ~validateReportRequirements(app.projectData, context, 'unit')
                msgWarning{end+1} = '• Unidade geradora do documento precisa ser selecionada.';
            end

            invalidRowIndexes = validateAuditorClassification(app.projectData, context, app.mainApp.General, stationIdxs);
            if ~isempty(invalidRowIndexes)
                msgWarning{end+1} = [
                    '• Há registro de estações instaladas na(s) localidade(s) sob análise para as quais ' ...
                    'não foram identificadas medidas no entorno ou cuja operação foi indicada em local ' ...
                    'diferente, sem a devida especificação.' ...
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
                msgInfo = model.ProjectBase.WARNING_VALIDATIONSRULES.MONITORINGPLAN;

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

            stationIdx = app.UITable.UserData(event.Indices(1));
            updateStationTable(app.projectData, 'onStationInfoChanged', stationIdx, event.NewData, {})
            
            applyTableStyle(app)

        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            
            if exist('event', 'var') && ~isempty(event.PreviousSelection) && isequal(event.Selection, event.PreviousSelection)
                return
            end

            if isempty(event.Selection)
                app.UITable.ContextMenu = [];
            else
                if isempty(app.UITable.ContextMenu)
                    app.UITable.ContextMenu = app.ContextMenu;
                end
            end

            updateToolbar(app)
            plotSelectedPoint(app)
            
        end

        % Image clicked function: LocationListEdit
        function LocationListEditClicked(app, event)

            ipcMainMatlabOpenPopupApp(app.mainApp, app, 'ListOfLocation', app.Context, getFileIndexes(app))

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
            app.Toolbar.ColumnWidth = {22, 5, 22, 22, 22, 5, 22, '1x', 22, 22, 22};
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

            % Create tool_TableEdition
            app.tool_TableEdition = uiimage(app.Toolbar);
            app.tool_TableEdition.ScaleMethod = 'none';
            app.tool_TableEdition.ImageClickedFcn = createCallbackFcn(app, @Toolbar_OpenPopUpEditionMode, true);
            app.tool_TableEdition.Enable = 'off';
            app.tool_TableEdition.Layout.Row = [1 3];
            app.tool_TableEdition.Layout.Column = 4;
            app.tool_TableEdition.ImageSource = 'Variable_edit_16.png';

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.Toolbar);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @Toolbar_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Layout.Row = [1 3];
            app.tool_ExportFiles.Layout.Column = 5;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create tool_Separator2
            app.tool_Separator2 = uiimage(app.Toolbar);
            app.tool_Separator2.ScaleMethod = 'none';
            app.tool_Separator2.Enable = 'off';
            app.tool_Separator2.Layout.Row = [1 3];
            app.tool_Separator2.Layout.Column = 6;
            app.tool_Separator2.ImageSource = 'LineV.svg';

            % Create tool_PeakIcon
            app.tool_PeakIcon = uiimage(app.Toolbar);
            app.tool_PeakIcon.ScaleMethod = 'none';
            app.tool_PeakIcon.ImageClickedFcn = createCallbackFcn(app, @Toolbar_InteractionImageClicked, true);
            app.tool_PeakIcon.Enable = 'off';
            app.tool_PeakIcon.Layout.Row = [1 3];
            app.tool_PeakIcon.Layout.Column = 7;
            app.tool_PeakIcon.ImageSource = 'Detection_18.png';

            % Create tool_PeakLabel
            app.tool_PeakLabel = uilabel(app.Toolbar);
            app.tool_PeakLabel.FontSize = 10;
            app.tool_PeakLabel.Visible = 'off';
            app.tool_PeakLabel.Layout.Row = [1 3];
            app.tool_PeakLabel.Layout.Column = 8;
            app.tool_PeakLabel.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create tool_OpenPopupProject
            app.tool_OpenPopupProject = uiimage(app.Toolbar);
            app.tool_OpenPopupProject.ScaleMethod = 'none';
            app.tool_OpenPopupProject.ImageClickedFcn = createCallbackFcn(app, @Toolbar_OpenPopupProjectImageClicked, true);
            app.tool_OpenPopupProject.Layout.Row = [1 3];
            app.tool_OpenPopupProject.Layout.Column = 9;
            app.tool_OpenPopupProject.ImageSource = 'organization-20px-black.svg';

            % Create tool_GenerateReport
            app.tool_GenerateReport = uiimage(app.Toolbar);
            app.tool_GenerateReport.ScaleMethod = 'none';
            app.tool_GenerateReport.ImageClickedFcn = createCallbackFcn(app, @Toolbar_GenerateReportImageClicked, true);
            app.tool_GenerateReport.Enable = 'off';
            app.tool_GenerateReport.Layout.Row = [1 3];
            app.tool_GenerateReport.Layout.Column = 10;
            app.tool_GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create tool_UploadFinalFile
            app.tool_UploadFinalFile = uiimage(app.Toolbar);
            app.tool_UploadFinalFile.ScaleMethod = 'none';
            app.tool_UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @Toolbar_UploadFinalFileImageClicked, true);
            app.tool_UploadFinalFile.Enable = 'off';
            app.tool_UploadFinalFile.Layout.Row = [1 3];
            app.tool_UploadFinalFile.Layout.Column = 11;
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
            app.UITable.BackgroundColor = [1 1 1;0.96078431372549 0.96078431372549 0.96078431372549];
            app.UITable.ColumnName = {'FISTEL'; 'ESTAÇÃO'; 'LOCALIDADE'; 'SERVIÇO'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Dmin|(km)'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'JUSTIFICATIVA'};
            app.UITable.ColumnWidth = {100, 75, 150, 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = [true true true true true true true true true true false];
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false false false true];
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
            app.SubTab1.Title = 'PM-RNI';

            % Create SubGrid1
            app.SubGrid1 = uigridlayout(app.SubTab1);
            app.SubGrid1.ColumnWidth = {144, 116, 18};
            app.SubGrid1.RowHeight = {30, 5, '1x', 20, 18, 5, '0.5x', 10, 83, 10, 83};
            app.SubGrid1.RowSpacing = 0;
            app.SubGrid1.BackgroundColor = [1 1 1];

            % Create config_geoAxesLabel_2
            app.config_geoAxesLabel_2 = uilabel(app.SubGrid1);
            app.config_geoAxesLabel_2.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel_2.WordWrap = 'on';
            app.config_geoAxesLabel_2.FontSize = 10;
            app.config_geoAxesLabel_2.Layout.Row = 1;
            app.config_geoAxesLabel_2.Layout.Column = [1 2];
            app.config_geoAxesLabel_2.Interpreter = 'html';
            app.config_geoAxesLabel_2.Text = {'LOCALIDADES DE AGRUPAMENTO:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.SubGrid1);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @TreeFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 3;
            app.TreeFileLocations.Layout.Column = [1 3];

            % Create LocationListLabel
            app.LocationListLabel = uilabel(app.SubGrid1);
            app.LocationListLabel.VerticalAlignment = 'bottom';
            app.LocationListLabel.FontSize = 10;
            app.LocationListLabel.Layout.Row = [4 5];
            app.LocationListLabel.Layout.Column = [1 2];
            app.LocationListLabel.Interpreter = 'html';
            app.LocationListLabel.Text = {'LOCALIDADES SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionadas às estações previstas no PM-RNI)</font>'};

            % Create LocationListEdit
            app.LocationListEdit = uiimage(app.SubGrid1);
            app.LocationListEdit.ImageClickedFcn = createCallbackFcn(app, @LocationListEditClicked, true);
            app.LocationListEdit.Enable = 'off';
            app.LocationListEdit.Layout.Row = 5;
            app.LocationListEdit.Layout.Column = 3;
            app.LocationListEdit.ImageSource = 'Edit_32.png';

            % Create LocationList
            app.LocationList = uitextarea(app.SubGrid1);
            app.LocationList.Editable = 'off';
            app.LocationList.FontSize = 11;
            app.LocationList.Layout.Row = 7;
            app.LocationList.Layout.Column = [1 3];

            % Create Card1_numberOfStations
            app.Card1_numberOfStations = uilabel(app.SubGrid1);
            app.Card1_numberOfStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card1_numberOfStations.VerticalAlignment = 'top';
            app.Card1_numberOfStations.WordWrap = 'on';
            app.Card1_numberOfStations.FontSize = 10;
            app.Card1_numberOfStations.FontColor = [0.502 0.502 0.502];
            app.Card1_numberOfStations.Layout.Row = 9;
            app.Card1_numberOfStations.Layout.Column = 1;
            app.Card1_numberOfStations.Interpreter = 'html';
            app.Card1_numberOfStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: BLACK; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NAS LOCALIDADES SOB ANÁLISE</p>'};

            % Create Card2_numberOfRiskStations
            app.Card2_numberOfRiskStations = uilabel(app.SubGrid1);
            app.Card2_numberOfRiskStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card2_numberOfRiskStations.VerticalAlignment = 'top';
            app.Card2_numberOfRiskStations.WordWrap = 'on';
            app.Card2_numberOfRiskStations.FontSize = 10;
            app.Card2_numberOfRiskStations.FontColor = [0.502 0.502 0.502];
            app.Card2_numberOfRiskStations.Layout.Row = 9;
            app.Card2_numberOfRiskStations.Layout.Column = [2 3];
            app.Card2_numberOfRiskStations.Interpreter = 'html';
            app.Card2_numberOfRiskStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE 14 V/m</p>'};

            % Create Card3_stationsOnRoute
            app.Card3_stationsOnRoute = uilabel(app.SubGrid1);
            app.Card3_stationsOnRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card3_stationsOnRoute.VerticalAlignment = 'top';
            app.Card3_stationsOnRoute.WordWrap = 'on';
            app.Card3_stationsOnRoute.FontSize = 10;
            app.Card3_stationsOnRoute.FontColor = [0.502 0.502 0.502];
            app.Card3_stationsOnRoute.Layout.Row = 11;
            app.Card3_stationsOnRoute.Layout.Column = 1;
            app.Card3_stationsOnRoute.Interpreter = 'html';
            app.Card3_stationsOnRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: black; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>'};

            % Create Card4_stationsOutRoute
            app.Card4_stationsOutRoute = uilabel(app.SubGrid1);
            app.Card4_stationsOutRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card4_stationsOutRoute.VerticalAlignment = 'top';
            app.Card4_stationsOutRoute.WordWrap = 'on';
            app.Card4_stationsOutRoute.FontSize = 10;
            app.Card4_stationsOutRoute.FontColor = [0.502 0.502 0.502];
            app.Card4_stationsOutRoute.Layout.Row = 11;
            app.Card4_stationsOutRoute.Layout.Column = [2 3];
            app.Card4_stationsOutRoute.Interpreter = 'html';
            app.Card4_stationsOutRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS FORA DA ROTA</p>'};

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'auxApp.winMonitoringPlan';

            % Create EditSelectedUITableRow
            app.EditSelectedUITableRow = uimenu(app.ContextMenu);
            app.EditSelectedUITableRow.MenuSelectedFcn = createCallbackFcn(app, @Toolbar_OpenPopUpEditionMode, true);
            app.EditSelectedUITableRow.Text = '✏️ Editar';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winMonitoringPlan_exported(Container, varargin)

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
