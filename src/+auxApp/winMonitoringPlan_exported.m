classdef winMonitoringPlan_exported < matlab.apps.AppBase

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
        Summary                    matlab.ui.control.Label
        LocationList               matlab.ui.control.TextArea
        LocationListButton         matlab.ui.control.Image
        LocationListLabel          matlab.ui.control.Label
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
        ManualMeasurementButton    matlab.ui.control.Image
        TableEditionButton         matlab.ui.control.Image
        ToolbarSeparator1          matlab.ui.control.Image
        PlotTableLayoutButton      matlab.ui.control.Image
        LeftPanelVisibilityButton  matlab.ui.control.Image
        ContextMenu                matlab.ui.container.ContextMenu
        EditSelectedUITableRow     matlab.ui.container.Menu
        ManualMeasurementMenu      matlab.ui.container.Menu
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
                            % winMonitorRNI >> auxApp.winMonitoringPlan
                            case {'onFileListAdded', 'onFileListRemoved', 'onFileListUnmerged', 'onFileListMerged', 'onProjectRestart', 'onProjectLoad'}
                                app.measData = getFullEMFieldData(app.projectData, app.mainApp.measData);
                                buildFileLocationTree(app)

                                if ~isempty(app.measData)
                                    if ~ismember(eventName, {'onFileListUnmerged', 'onFileListMerged'})
                                        updateAnalysis(app.projectData, app.measData, app.mainApp.General, eventName, app.Context);
                                    end

                                    refreshAnalysis(app)
                                end

                            % auxApp.winConfig >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case 'onAnalysisParameterChanged'
                                app.UITable.ColumnName{6} = sprintf('QTD.|>%.0fV/m', app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
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

                            case {'onPlotParameterChanged', 'onStationListChanged', 'onStationCoordinatesUpdated'}
                                refreshAnalysis(app)

                            % winMonitorRNI >> auxApp.winMonitoringPlan
                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winMonitoringPlan
                            case {'onReportGenerate', 'onFinalReportFileChanged'}
                                updateToolbar(app)

                            % auxApp.dockReportLib >> winMonitorRNI >> auxApp.winMonitoringPlan
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
                                forceTableSelection(app, varargin{1})

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
        function applyJSCustomizations(app)
            appName = class(app);
            elToModify = {
                app.AxesToolbar;
                app.AxesRestoreViewButton;
                app.AxesRegionZoomButton;
                app.AxesExportGraphicsButton;
                app.LocationListButton;
                app.LeftPanelVisibilityButton;
                app.PlotTableLayoutButton;
                app.TableEditionButton;
                app.ManualMeasurementButton;
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
                    ...
                    struct('appName', appName, 'dataTag', app.LocationListButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita lista de localidades sob análise')), ...
                    struct('appName', appName, 'dataTag', app.LeftPanelVisibilityButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna visibilidade do painel')), ...
                    struct('appName', appName, 'dataTag', app.PlotTableLayoutButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Alterna entre três layouts do conjunto plot+tabela<br>(apenas plot, apenas tabela ou plot+tabela)')), ...
                    struct('appName', appName, 'dataTag', app.TableEditionButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita, em formulário, as informações do registro selecionado na tabela')), ...
                    struct('appName', appName, 'dataTag', app.ManualMeasurementButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Explora medidas inseridas manualmente')), ...
                    struct('appName', appName, 'dataTag', app.ExportFilesButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Exporta análise (.xlsx, .kml)')), ...
                    struct('appName', appName, 'dataTag', app.PeakIconButton.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Aplica zoom em torno do local de valor máximo')), ...
                    struct('appName', appName, 'dataTag', app.OpenPopupProject.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Edita informações do projeto<br>(fiscalizada, arquivo de backup etc)')), ...
                    struct('appName', appName, 'dataTag', app.GenerateReport.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Gera relatório')), ...
                    struct('appName', appName, 'dataTag', app.UploadFinalFile.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Upload relatório')), ...
                    ...
                    struct('appName', appName, 'dataTag', app.AxesRestoreViewButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Restaura limites iniciais dos eixos')), ...
                    struct('appName', appName, 'dataTag', app.AxesRegionZoomButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Habilita zoom de região')), ...
                    struct('appName', appName, 'dataTag', app.AxesExportGraphicsButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Exporta plot')), ...
                    ...
                    struct('appName', appName, 'dataTag', app.DockUndockButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Reabre módulo em outra janela')), ...
                    struct('appName', appName, 'dataTag', app.DockCloseButton.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Fecha módulo')) ...
                });
            catch
            end
        end

        %-----------------------------------------------------------------%
        function initializeAppProperties(app)
            % ...
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.DockUndockButton.Enable = 1;
            end

            if app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold ~= 14
                app.UITable.ColumnName{6} = sprintf('QTD.|>%.0fV/m', app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
            end
            app.UITable.RowName = 'numbered';

            app.LeftPanelVisibilityButton.UserData.status = true;
            app.PlotTableLayoutButton.UserData.layout = 1;

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
                [~, selection] = ismember(initialSelection, app.UITable.UserData);
                if selection
                    forceTableSelection(app, selection)
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

                % Estações com medidas inseridas manualmente (auxApp.dockManualMeasurement).
                manualStations = app.projectData.modules.MONITORINGPLAN.manualMeasurement.Station;
                manualRowIdxs  = find(ismember(double(app.UITable.Data.("Estação")), manualStations));

                if ~isempty(manualRowIdxs)
                    columnIndex3 = find(ismember(app.UITable.Data.Properties.VariableNames, 'numberOfMeasures'));

                    s4 = uistyle('Icon', 'barras.svg', 'IconAlignment', 'leftmargin');
                    addStyle(app.UITable, s4, "cell", [manualRowIdxs, repmat(columnIndex3, numel(manualRowIdxs), 1)])
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

            app.Summary.Text = sprintf([ ...
                '<section>' ...
                    '<table>' ...
                        '<tr>' ...
                            '<td style="width: 3px; background: #7a7a7a;"></td>' ...
                            '<td style="padding-left: 5px;">' ...
                                '<font style="color: black;   font-size: 24px;">%d</font> ESTAÇÕES NAS LOCALIDADES<br>' ...
                                '<font style="color: black;   font-size: 24px;">%d</font> ESTAÇÕES NO ENTORNO DA ROTA<br>' ...
                                '<font style="color: #a2142f; font-size: 24px;">%d</font> ESTAÇÕES FORA DA ROTA<br>' ...
                                '<font style="color: #a2142f; font-size: 24px;">%d</font> ESTAÇÕES PRÓXIMAS NÍVEIS >%.0fV/m' ...
                            '</td>' ...
                        '</tr>' ...
                    '</table>' ...
                '</section>' ...
            ], nStations, nStationsOnRoute, nStationsOutRoute, nRiskStations, app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold);
        end

        %-----------------------------------------------------------------%
        function updateToolbar(app)
            measDataNonEmpty = ~isempty(app.measData);
            measTableNonEmpty = ~isempty(app.measTable);
            tableNonEmpty = ~isempty(app.UITable.Data);
            rowTableSelected = ~isempty(app.UITable.Selection);
            reportFinalVersionGenerated = ~isempty(app.projectData.modules.(app.Context).generatedFiles.lastHTMLDocFullPath);

            app.LocationListButton.Enable = measDataNonEmpty;
            app.TableEditionButton.Enable = measDataNonEmpty && tableNonEmpty;
            app.ManualMeasurementButton.Enable = measDataNonEmpty && rowTableSelected;
            app.ExportFilesButton.Enable = measDataNonEmpty;
            app.GenerateReport.Enable = measDataNonEmpty;
            app.UploadFinalFile.Enable = reportFinalVersionGenerated;

            app.PeakLabelButton.Visible = measTableNonEmpty;
            app.PeakIconButton.Enable = measTableNonEmpty;

            if measTableNonEmpty
                [~, maxIndex] = max(app.measTable.FieldValue);

                app.PeakLabelButton.Text = sprintf('%.2f V/m\n(%.6f, %.6f)', app.measTable.FieldValue(maxIndex), ...
                                                                             app.measTable.Latitude(maxIndex),   ...
                                                                             app.measTable.Longitude(maxIndex));
                app.PeakIconButton.UserData = struct('idxMax',    maxIndex,                         ...
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

                if strcmp(locationGroups{ii}, app.projectData.modules.MONITORINGPLAN.ui.selectedGroup)
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
                updateTable(app, []);
                updatePanel(app, {}, [])
            end

            updateToolbar(app)
        end

        %-----------------------------------------------------------------%
        function forceTableSelection(app, selection)
            app.UITable.Selection = selection;
            scroll(app.UITable, 'row', selection)

            onUITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', selection))
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
                plot.draw.Measures(app.UIAxes1, app.measTable, app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold, app.mainApp.General);

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
                plot.draw.Points(app.UIAxes1, refPointsTable, 'Estações de referência PM-RNI', app.mainApp.General)
            end
            plotAxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plotSelectedPoint(app)
            delete(findobj(app.UIAxes1.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                selectedStationIdx = app.UITable.UserData(app.UITable.Selection);
                selectedPointTable = app.projectData.modules.MONITORINGPLAN.stationTable(selectedStationIdx, :);

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
        function [stationIdx, rowIdx] = getSelectedStationIndex(app)
            rowIdx     = app.UITable.Selection;
            stationIdx = app.UITable.UserData(rowIdx);
        end

        %-----------------------------------------------------------------%
        function idxFile = getReportFileIndexes(app)
            idxFile = find(ismember({app.measData.Location}, app.reportLocations));
        end

        %-----------------------------------------------------------------%
        function [stationIdxs, locations] = getAnalyzedStationIndexes(app, eventName, fileIdxs)
            arguments
                app
                eventName {mustBeMember(eventName, {'onSelectionChanging', 'onInspectSelection', 'onInspectAll', 'onReportLocations'})}
                fileIdxs double = []
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

                case 'onReportLocations'
                    locations   = getFullListOfLocation(app.projectData, app.measData(fileIdxs), app.projectData.modules.MONITORINGPLAN.analysis.maxMeasurementDistanceKm);
                    stationIdxs = find(ismember(app.projectData.modules.MONITORINGPLAN.stationTable.Location, locations));
            end
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

        % Callback function: EditSelectedUITableRow, TableEditionButton
        function onToolbarEditionModuleButtonClicked(app, event)

            if ~isempty(app.UITable.Data)
                if isempty(app.UITable.Selection)
                    forceTableSelection(app, 1)
                end

                ipcMainMatlabOpenPopupApp(app.mainApp, app, 'StationInfo', app.Context)
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

            stationIdxs = getAnalyzedStationIndexes(app, 'onReportLocations', fileIdxs);
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

        % Image clicked function: LocationListButton
        function onLocationListButtonClicked(app, event)

            ipcMainMatlabOpenPopupApp(app.mainApp, app, 'ListOfLocation', app.Context, getFileIndexes(app))

        end

        % Selection changed function: UITable
        function onUITableSelectionChanged(app, event)
            
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

            plotSelectedPoint(app)
            updateToolbar(app)
            
        end

        % Cell edit callback: UITable
        function onUITableCellEdit(app, event)

            if isequal(event.PreviousData, event.NewData)
                return
            end

            stationIdx = app.UITable.UserData(event.Indices(1));
            updateStationTable(app.projectData, 'onStationInfoChanged', stationIdx, event.NewData, {})

            applyTableStyle(app)

        end

        % Double-clicked callback: UITable
        function onUITableDoubleClicked(app, event)

            if isempty(app.UITable.Selection)
                return
            end

            stationIdx = app.UITable.UserData(app.UITable.Selection);
            stationTable = app.projectData.modules.MONITORINGPLAN.stationTable;
            generalSettings = app.mainApp.General;
            referenceDistance_km = generalSettings.plot.selectedStation.automaticZoomFactor * ...
                                   generalSettings.context.MONITORINGPLAN.maxMeasurementDistanceKm;
            plot.zoom(app.UIAxes1, stationTable.("Latitude")(stationIdx), ...
                                   stationTable.("Longitude")(stationIdx), referenceDistance_km)

        end

        % Image clicked function: ManualMeasurementButton
        function onManualMeasurementButtonClicked(app, event)

            if ~isempty(app.UITable.Selection)
                stationIdx = app.UITable.UserData(app.UITable.Selection);
                ipcMainMatlabOpenPopupApp(app.mainApp, app, 'ManualMeasurement', app.Context, stationIdx)
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
            app.Toolbar.ColumnWidth = {22, 22, 5, 22, 22, 22, 5, 22, '1x', 22, 22, 22};
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

            % Create TableEditionButton
            app.TableEditionButton = uiimage(app.Toolbar);
            app.TableEditionButton.ScaleMethod = 'none';
            app.TableEditionButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarEditionModuleButtonClicked, true);
            app.TableEditionButton.Enable = 'off';
            app.TableEditionButton.Layout.Row = [1 3];
            app.TableEditionButton.Layout.Column = 4;
            app.TableEditionButton.ImageSource = 'Variable_edit_16.png';

            % Create ManualMeasurementButton
            app.ManualMeasurementButton = uiimage(app.Toolbar);
            app.ManualMeasurementButton.ScaleMethod = 'none';
            app.ManualMeasurementButton.ImageClickedFcn = createCallbackFcn(app, @onManualMeasurementButtonClicked, true);
            app.ManualMeasurementButton.Enable = 'off';
            app.ManualMeasurementButton.Layout.Row = [1 3];
            app.ManualMeasurementButton.Layout.Column = 5;
            app.ManualMeasurementButton.ImageSource = 'barras.svg';

            % Create ExportFilesButton
            app.ExportFilesButton = uiimage(app.Toolbar);
            app.ExportFilesButton.ScaleMethod = 'none';
            app.ExportFilesButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarTableResultsExportButtonClicked, true);
            app.ExportFilesButton.Enable = 'off';
            app.ExportFilesButton.Layout.Row = [1 3];
            app.ExportFilesButton.Layout.Column = 6;
            app.ExportFilesButton.ImageSource = 'Export_16.png';

            % Create ToolbarSeparator2
            app.ToolbarSeparator2 = uiimage(app.Toolbar);
            app.ToolbarSeparator2.ScaleMethod = 'none';
            app.ToolbarSeparator2.Enable = 'off';
            app.ToolbarSeparator2.Layout.Row = [1 3];
            app.ToolbarSeparator2.Layout.Column = 7;
            app.ToolbarSeparator2.ImageSource = 'LineV.svg';

            % Create PeakIconButton
            app.PeakIconButton = uiimage(app.Toolbar);
            app.PeakIconButton.ScaleMethod = 'none';
            app.PeakIconButton.ImageClickedFcn = createCallbackFcn(app, @onToolbarInteractionButtonClicked, true);
            app.PeakIconButton.Enable = 'off';
            app.PeakIconButton.Layout.Row = [1 3];
            app.PeakIconButton.Layout.Column = 8;
            app.PeakIconButton.ImageSource = 'Detection_18.png';

            % Create PeakLabelButton
            app.PeakLabelButton = uilabel(app.Toolbar);
            app.PeakLabelButton.FontSize = 10;
            app.PeakLabelButton.Visible = 'off';
            app.PeakLabelButton.Layout.Row = [1 3];
            app.PeakLabelButton.Layout.Column = 9;
            app.PeakLabelButton.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create OpenPopupProject
            app.OpenPopupProject = uiimage(app.Toolbar);
            app.OpenPopupProject.ScaleMethod = 'none';
            app.OpenPopupProject.ImageClickedFcn = createCallbackFcn(app, @onToolbarProjectModuleButtonClicked, true);
            app.OpenPopupProject.Layout.Row = [1 3];
            app.OpenPopupProject.Layout.Column = 10;
            app.OpenPopupProject.ImageSource = 'organization-20px-black.svg';

            % Create GenerateReport
            app.GenerateReport = uiimage(app.Toolbar);
            app.GenerateReport.ScaleMethod = 'none';
            app.GenerateReport.ImageClickedFcn = createCallbackFcn(app, @onToolbarGenerateReportButtonClicked, true);
            app.GenerateReport.Enable = 'off';
            app.GenerateReport.Layout.Row = [1 3];
            app.GenerateReport.Layout.Column = 11;
            app.GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create UploadFinalFile
            app.UploadFinalFile = uiimage(app.Toolbar);
            app.UploadFinalFile.ScaleMethod = 'none';
            app.UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @onToolbarUploadFinalFileButtonClicked, true);
            app.UploadFinalFile.Enable = 'off';
            app.UploadFinalFile.Layout.Row = [1 3];
            app.UploadFinalFile.Layout.Column = 12;
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
            app.LeftPanelGrid.ColumnWidth = {22, '1x', '1x', 22};
            app.LeftPanelGrid.RowHeight = {92, 5, 12, 18, 5, 134, 20, 18, 5, '1x', 10, 132};
            app.LeftPanelGrid.ColumnSpacing = 5;
            app.LeftPanelGrid.RowSpacing = 0;
            app.LeftPanelGrid.BackgroundColor = [1 1 1];

            % Create ModuleIcon
            app.ModuleIcon = uiimage(app.LeftPanelGrid);
            app.ModuleIcon.Layout.Row = 1;
            app.ModuleIcon.Layout.Column = 1;
            app.ModuleIcon.VerticalAlignment = 'top';
            app.ModuleIcon.ImageSource = 'route.svg';

            % Create ModuleIntro
            app.ModuleIntro = uilabel(app.LeftPanelGrid);
            app.ModuleIntro.VerticalAlignment = 'top';
            app.ModuleIntro.WordWrap = 'on';
            app.ModuleIntro.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.ModuleIntro.Layout.Row = 1;
            app.ModuleIntro.Layout.Column = [2 4];
            app.ModuleIntro.Interpreter = 'html';
            app.ModuleIntro.Text = {'<b>PM-RNI</b>'; '<p style="padding: 2px; text-align: justify; font-size: 10px; color: gray; line-height: 13px">Análise de medições de campo elétrico realizadas no entorno de estações definidas no Plano de Monitoração de Radiação Não Ionizante.</p>'};

            % Create TreeFileLocationsLabel
            app.TreeFileLocationsLabel = uilabel(app.LeftPanelGrid);
            app.TreeFileLocationsLabel.VerticalAlignment = 'bottom';
            app.TreeFileLocationsLabel.FontSize = 11;
            app.TreeFileLocationsLabel.Layout.Row = [3 4];
            app.TreeFileLocationsLabel.Layout.Column = [1 4];
            app.TreeFileLocationsLabel.Interpreter = 'html';
            app.TreeFileLocationsLabel.Text = {'Localidades de agrupamento:'; '<font style="color: gray; font-size: 10px;">(identificadas nos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.LeftPanelGrid);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @onFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 6;
            app.TreeFileLocations.Layout.Column = [1 4];

            % Create LocationListLabel
            app.LocationListLabel = uilabel(app.LeftPanelGrid);
            app.LocationListLabel.VerticalAlignment = 'bottom';
            app.LocationListLabel.FontSize = 11;
            app.LocationListLabel.Layout.Row = [7 8];
            app.LocationListLabel.Layout.Column = [1 3];
            app.LocationListLabel.Interpreter = 'html';
            app.LocationListLabel.Text = {'Localidades sob análise:'; '<font style="color: gray; font-size: 10px;">(com estações previstas no PM-RNI)</font>'};

            % Create LocationListButton
            app.LocationListButton = uiimage(app.LeftPanelGrid);
            app.LocationListButton.ImageClickedFcn = createCallbackFcn(app, @onLocationListButtonClicked, true);
            app.LocationListButton.Enable = 'off';
            app.LocationListButton.Layout.Row = 8;
            app.LocationListButton.Layout.Column = 4;
            app.LocationListButton.ImageSource = 'Edit_32.png';

            % Create LocationList
            app.LocationList = uitextarea(app.LeftPanelGrid);
            app.LocationList.Editable = 'off';
            app.LocationList.FontSize = 11;
            app.LocationList.Layout.Row = 10;
            app.LocationList.Layout.Column = [1 4];

            % Create Summary
            app.Summary = uilabel(app.LeftPanelGrid);
            app.Summary.VerticalAlignment = 'top';
            app.Summary.WordWrap = 'on';
            app.Summary.FontSize = 10;
            app.Summary.FontColor = [0.502 0.502 0.502];
            app.Summary.Layout.Row = 12;
            app.Summary.Layout.Column = [1 4];
            app.Summary.Interpreter = 'html';
            app.Summary.Text = {'<section><table><tr><td style="width: 3px; background: #7a7a7a;"></td><td style="padding-left: 4px;"><font style="color: BLACK; font-size: 24px;">0</font> ESTAÇÕES NAS LOCALIDADES'; '<font style="color: black; font-size: 24px;">0</font> ESTAÇÕES NO ENTORNO DA ROTA'; '<font style="color: #a2142f; font-size: 24px;">0</font> ESTAÇÕES FORA DA ROTA'; '<font style="color: #a2142f; font-size: 24px;">0</font> ESTAÇÕES PRÓXIMAS NÍVEIS >14V/m</td></table></section>'};

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
            app.UITable.BackgroundColor = [1 1 1;0.96078431372549 0.96078431372549 0.96078431372549];
            app.UITable.ColumnName = {'FISTEL'; 'ESTAÇÃO'; 'LOCALIDADE'; 'SERVIÇO'; 'QTD.|MEDIDAS'; 'QTD.|>14V/m'; 'Dₘᵢₙ|(km)'; 'Eₘᵢₙ|(V/m)'; 'Eₘₑₐₙ|(V/m)'; 'Eₘₐₓ|(V/m)'; 'JUSTIFICATIVA'};
            app.UITable.ColumnWidth = {100, 75, 'auto', 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = [true true true true true true true true true true false];
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @onUITableCellEdit, true);
            app.UITable.DoubleClickedFcn = createCallbackFcn(app, @onUITableDoubleClicked, true);
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
            app.ContextMenu.Tag = 'auxApp.winMonitoringPlan';

            % Create EditSelectedUITableRow
            app.EditSelectedUITableRow = uimenu(app.ContextMenu);
            app.EditSelectedUITableRow.MenuSelectedFcn = createCallbackFcn(app, @onToolbarEditionModuleButtonClicked, true);
            app.EditSelectedUITableRow.Text = '✏️ Editar';

            % Create ManualMeasurementMenu
            app.ManualMeasurementMenu = uimenu(app.ContextMenu);
            app.ManualMeasurementMenu.MenuSelectedFcn = createCallbackFcn(app, @onManualMeasurementButtonClicked, true);
            app.ManualMeasurementMenu.Text = '📶 Explorar medidas';

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
