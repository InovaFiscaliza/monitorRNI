classdef winMonitoringPlan_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        toolGrid                     matlab.ui.container.GridLayout
        tool_peakIcon                matlab.ui.control.Image
        tool_peakLabel               matlab.ui.control.Label
        tool_UploadFinalFile         matlab.ui.control.Image
        jsBackDoor                   matlab.ui.control.HTML
        tool_ExportFiles             matlab.ui.control.Image
        tool_TableVisibility         matlab.ui.control.Image
        tool_ControlPanelVisibility  matlab.ui.control.Image
        Document                     matlab.ui.container.GridLayout
        LocationListLabel            matlab.ui.control.Label
        LocationListEdit             matlab.ui.control.Image
        LocationList                 matlab.ui.control.TextArea
        Card4_stationsOutRoute       matlab.ui.control.Label
        Card3_stationsOnRoute        matlab.ui.control.Label
        Card2_numberOfRiskStations   matlab.ui.control.Label
        Card1_numberOfStations       matlab.ui.control.Label
        TreeFileLocations            matlab.ui.container.CheckBoxTree
        config_geoAxesLabel_2        matlab.ui.control.Label
        play_ControlsTab1Grid_2      matlab.ui.container.GridLayout
        play_ControlsTab1Label_2     matlab.ui.control.Label
        play_ControlsTab1Image_2     matlab.ui.control.Image
        UITable                      matlab.ui.control.Table
        axesToolbarGrid              matlab.ui.container.GridLayout
        axesTool_RegionZoom          matlab.ui.control.Image
        axesTool_RestoreView         matlab.ui.control.Image
        plotPanel                    matlab.ui.container.Panel
        ContextMenu                  matlab.ui.container.ContextMenu
        EditSelectedUITableRow       matlab.ui.container.Menu
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = false

        mainApp
        rootFolder
        
        % A função do timer é executada uma única vez após a renderização
        % da figura, lendo arquivos de configuração, iniciando modo de operação
        % paralelo etc. A ideia é deixar o MATLAB focar apenas na criação dos 
        % componentes essenciais da GUI (especificados em "createComponents"), 
        % mostrando a GUI para o usuário o mais rápido possível.
        timerObj

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog
        popupContainer
        
        %-----------------------------------------------------------------%
        % ESPECIFICIDADES
        %-----------------------------------------------------------------%
        projectData

        % Instância da classe class.metaData contendo a organização da
        % informação lida dos arquivos de medida. 
        measData  = class.measData.empty

        % measTable é a concatenação de todas as timetables de measData,
        % uma para cada arquivo.
        measTable

        % Handle do eixo e propriedade que armazena os limites automáticos
        UIAxes
        restoreView = struct('ID', {}, 'xLim', {}, 'yLim', {}, 'cLim', {})
    end

    
    methods (Access = private)
        %-----------------------------------------------------------------%
        % JSBACKDOOR
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            if app.isDocked
                delete(app.jsBackDoor)
                app.jsBackDoor = app.mainApp.jsBackDoor;
            else
                app.jsBackDoor.HTMLSource = appUtil.jsBackDoorHTMLSource();
            end
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app)
            if app.isDocked
                app.progressDialog = app.mainApp.progressDialog;
            else
                app.progressDialog = ccTools.ProgressDialog(app.jsBackDoor);

                sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        'body',                           ...
                                                                                       'classAttributes', ['--tabButton-border-color: #fff;' ...
                                                                                                           '--tabContainer-border-color: #fff;']));
    
                sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        '.mw-theme-light',                                                   ...
                                                                                       'classAttributes', ['--mw-backgroundColor-dataWidget-selected: rgb(180 222 255 / 45%); ' ...
                                                                                                           '--mw-backgroundColor-selected: rgb(180 222 255 / 45%); '            ...
                                                                                                           '--mw-backgroundColor-selectedFocus: rgb(180 222 255 / 45%);'        ...
                                                                                                           '--mw-backgroundColor-tab: #fff;']));
    
                sendEventToHTMLSource(app.jsBackDoor, 'htmlClassCustomization', struct('className',        '.mw-default-header-cell', ...
                                                                                       'classAttributes',  'font-size: 10px; white-space: pre-wrap; margin-bottom: 5px;'));
            end

            ccTools.compCustomizationV2(app.jsBackDoor, app.axesToolbarGrid, 'borderBottomLeftRadius', '5px', 'borderBottomRightRadius', '5px')
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO
        %-----------------------------------------------------------------%
        function startup_timerCreation(app)            
            % A criação desse timer tem como objetivo garantir uma renderização 
            % mais rápida dos componentes principais da GUI, possibilitando a 
            % visualização da sua tela inicialpelo usuário. Trata-se de aspecto 
            % essencial quando o app é compilado como webapp.

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

                startup_Controller(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Controller(app)
            drawnow

            % Customiza aspectos estéticos de alguns dos componentes da GUI 
            % (diretamente em JS).
            jsBackDoor_Customizations(app)

            % Define tamanho mínimo do app (não aplicável à versão webapp).
            if ~strcmp(app.mainApp.executionMode, 'webApp') && ~app.isDocked
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            app.progressDialog.Visible = 'visible';

            startup_GUIComponents(app)
            Analysis(app)

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            if app.mainApp.General.MonitoringPlan.FieldValue ~= 14
                app.UITable.ColumnName{5} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.MonitoringPlan.FieldValue);
            end

            startup_AxesCreation(app)
            layout_TreeFileLocationBuilding(app)
                        
            app.tool_TableVisibility.UserData = 1;
        end

        %-----------------------------------------------------------------%
        function startup_AxesCreation(app)
            % Eixo geográfico: MAPA
            app.plotPanel.AutoResizeChildren = 'off';
            app.UIAxes = plot.axes.Creation(app.plotPanel, 'Geographic', {'Units',    'normalized',                                    ...
                                                                          'Position', [0 0 1 1 ],                                      ...
                                                                          'Basemap',  app.mainApp.General.Plot.GeographicAxes.Basemap, ...
                                                                          'UserData', struct('CLimMode', 'auto', 'Colormap', '')});

            set(app.UIAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
            set(app.UIAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
            
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');

            plot.axes.Colormap(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colormap)
            plot.axes.Colorbar(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colorbar)

            % Legenda
            legend(app.UIAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5)

            % Axes interactions:
            plot.axes.Interactivity.DefaultCreation(app.UIAxes, [dataTipInteraction, zoomInteraction, panInteraction])
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function Analysis(app)
            app.progressDialog.Visible = 'visible';

            [idxFile, selectedFileLocations] = FileIndex(app);

            if ~isempty(idxFile)
                % Concatena as tabelas de LATITUDE, LONGITUDE E NÍVEL de cada um
                % dos arquivos cuja localidade coincide com o que foi selecionado
                % em tela. Além disso, insere o nome do próprio arquivo p/ fins de 
                % mapeamento entre os dados e os arquivos brutos.
                listOfTables  = {app.measData(idxFile).Data};
                listOfFiles   = cellfun(@(x,y) repmat({x}, y, 1), {app.measData(idxFile).Filename}, {app.measData(idxFile).Measures}, 'UniformOutput', false);
                tempMeasTable = vertcat(listOfTables{:});
                tempMeasTable.FileSource = vertcat(listOfFiles{:});

                app.measTable = sortrows(tempMeasTable, 'Timestamp');
                
                % Identifica localidades relacionadas à monitoração sob análise.
                listOfLocations = {};
                DIST_km = app.mainApp.General.MonitoringPlan.Distance_km;
    
                for ii = idxFile
                    % Limites de latitude e longitude relacionados à rota, acrescentando 
                    % a distância máxima à estação p/ fins de cômputo de medidas válidas 
                    % no entorno de uma estação.
                    [maxLatitude, maxLongitude] = reckon(app.measData(ii).LatitudeLimits(2), app.measData(ii).LongitudeLimits(2), km2deg(DIST_km), 45);
                    [minLatitude, minLongitude] = reckon(app.measData(ii).LatitudeLimits(1), app.measData(ii).LongitudeLimits(1), km2deg(DIST_km), 225);
    
                    idxLogicalStation = app.mainApp.stationTable.Latitude  >= minLatitude  & ...
                                        app.mainApp.stationTable.Latitude  <= maxLatitude  & ...
                                        app.mainApp.stationTable.Longitude >= minLongitude & ...
                                        app.mainApp.stationTable.Longitude <= maxLongitude;
    
                    if any(idxLogicalStation)
                        listOfLocations = [listOfLocations; unique(app.mainApp.stationTable.Location(idxLogicalStation))];
                    end
                end
                listOfLocation = unique(listOfLocations);
            else
                app.measTable  = [];
                listOfLocation = {};
            end

            app.projectData.selectedFileLocations     = selectedFileLocations;
            app.projectData.listOfLocations.Automatic = listOfLocation;

            fullListOfLocation = union(app.projectData.listOfLocations.Manual, app.projectData.listOfLocations.Automatic);

            idxStations = find(ismember(app.mainApp.stationTable.Location, fullListOfLocation));
            if ~isempty(app.measTable)
                identifyMeasuresForEachStation(app, idxStations)
            end
            initialSelection = updateTable(app, idxStations);
            layout_TableStyle(app)

            if ~isempty(fullListOfLocation)
                app.LocationList.Value = fullListOfLocation;
            else
                app.LocationList.Value = '';
            end
            
            nStations         = numel(idxStations);
            nRiskStations     = sum(app.UITable.Data.numberOfRiskMeasures > 0);
            nStationsOnRoute  = sum(app.UITable.Data.numberOfMeasures > 0);
            nStationsOutRoute = nStations - nStationsOnRoute;

            % Atualiza painel com quantitativo de estações...
            app.Card1_numberOfStations.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NAS LOCALIDADES SOB ANÁLISE</p>',                  nStations);
            app.Card2_numberOfRiskStations.Text = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE %.0f V/m</p></p>', nRiskStations, app.mainApp.General.MonitoringPlan.FieldValue);
            app.Card3_stationsOnRoute .Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>',                           nStationsOnRoute);
            app.Card4_stationsOutRoute.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS FORA DA ROTA</p>',                                 nStationsOutRoute);
            layout_updatePeakInfo(app)

            % PLOT
            plot_MeasuresAndPoints(app)

            if ~isempty(initialSelection)
                [~, idxRow] = ismember(initialSelection, app.UITable.UserData);
                if idxRow
                    app.UITable.Selection = idxRow;
                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', idxRow))
                end
            end

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function [idxFile, selectedFileLocations] = FileIndex(app)
            if ~isempty(app.TreeFileLocations.CheckedNodes)
                selectedFileLocations = {app.TreeFileLocations.CheckedNodes.Text};
                idxFile = find(ismember({app.measData.Location}, selectedFileLocations));
            else
                selectedFileLocations = {};
                idxFile = [];
            end
        end

        %-----------------------------------------------------------------%
        function initialSelection = updateTable(app, idxStations)
            initialSelection = [];
            if ~isempty(app.UITable.Selection)
                initialSelection = app.UITable.UserData(app.UITable.Selection);
            end

            table2Render = app.mainApp.stationTable(idxStations, {'N° estacao',            ...
                                                                  'Location',              ...
                                                                  'Serviço',               ...                                                                                      
                                                                  'numberOfMeasures',      ...
                                                                  'numberOfRiskMeasures',  ...
                                                                  'minDistanceForMeasure', ...
                                                                  'minFieldValue',         ...
                                                                  'meanFieldValue',        ...
                                                                  'maxFieldValue',         ...
                                                                  'Justificativa'});
            set(app.UITable, 'Data', table2Render, 'UserData', idxStations, 'Selection', [])
        end

        %-----------------------------------------------------------------%
        function plot_MeasuresAndPoints(app)
            % prePlot
            cla(app.UIAxes)
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');

            % Measures
            if ~isempty(app.measTable)
                plot.draw.Measures(app.UIAxes, app.measTable, app.mainApp.General.MonitoringPlan.FieldValue, app.mainApp.General);

                % Abaixo estabelece como limites do eixo os limites atuais,
                % configurados automaticamente pelo MATLAB. Ao fazer isso,
                % contudo, esses limites serão orientados às medidas e não às
                % estações.
                plot_AxesDefaultLimits(app, 'measures')
            end

            % Stations/Points
            if ~isempty(app.UITable.Data)
                idxStations    = app.UITable.UserData;
                refPointsTable = app.mainApp.stationTable(idxStations, :);

                plot.draw.Points(app.UIAxes, refPointsTable, 'Estações de referência PM-RNI', app.mainApp.General)
            end
            plot_AxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plot_SelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.UserData(app.UITable.Selection);
                selectedPointTable = app.mainApp.stationTable(idxSelectedPoint, :);

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
        function identifyMeasuresForEachStation(app, idxStations)
            DIST_km = app.mainApp.General.MonitoringPlan.Distance_km;

            for ii = idxStations'
                if app.mainApp.stationTable.AnalysisFlag(ii)
                    continue
                end

                app.mainApp.stationTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância da estação a cada uma das
                % medidas, identificando aquelas no entorno.
                stationDistance    = deg2km(distance(app.mainApp.stationTable.Latitude(ii), app.mainApp.stationTable.Longitude(ii), app.measTable.Latitude, app.measTable.Longitude));                
                idxLogicalMeasures = stationDistance <= DIST_km;

                if any(idxLogicalMeasures)
                    stationMeasures = app.measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(stationMeasures.FieldValue);

                    app.mainApp.stationTable.numberOfMeasures(ii)     = height(stationMeasures);
                    app.mainApp.stationTable.numberOfRiskMeasures(ii) = sum(stationMeasures.FieldValue > app.mainApp.General.MonitoringPlan.FieldValue);
                    app.mainApp.stationTable.minFieldValue(ii)        = min(stationMeasures.FieldValue);
                    app.mainApp.stationTable.meanFieldValue(ii)       = mean(stationMeasures.FieldValue);
                    app.mainApp.stationTable.maxFieldValue(ii)        = maxFieldValue;
                    app.mainApp.stationTable.maxFieldTimestamp(ii)    = stationMeasures.Timestamp(idxMaxFieldValue);
                    app.mainApp.stationTable.maxFieldLatitude(ii)     = stationMeasures.Latitude(idxMaxFieldValue);
                    app.mainApp.stationTable.maxFieldLongitude(ii)    = stationMeasures.Longitude(idxMaxFieldValue);
                    app.mainApp.stationTable.("Fonte de dados"){ii}   = jsonencode(unique(stationMeasures.FileSource));

                else
                    app.mainApp.stationTable.numberOfMeasures(ii)     = 0;
                    app.mainApp.stationTable.numberOfRiskMeasures(ii) = 0;
                    app.mainApp.stationTable.minFieldValue(ii)        = 0;
                    app.mainApp.stationTable.meanFieldValue(ii)       = 0;
                    app.mainApp.stationTable.maxFieldValue(ii)        = 0;
                    app.mainApp.stationTable.maxFieldTimestamp(ii)    = NaT;
                    app.mainApp.stationTable.maxFieldLatitude(ii)     = 0;
                    app.mainApp.stationTable.maxFieldLongitude(ii)    = 0;
                    app.mainApp.stationTable.("Fonte de dados"){ii}   = jsonencode({''});       % '[""]'
                end

                app.mainApp.stationTable.minDistanceForMeasure(ii)    = min(stationDistance);   % km
            end
        end

        %-----------------------------------------------------------------%
        function [idxMissingInfo, idxManualEdition, idxRiskMeasures, idxUpload2POST] = layout_searchUnexpectedTableValues(app)
            idxMissingInfo   = [];
            idxManualEdition = [];
            idxRiskMeasures  = [];
            idxUpload2POST   = [];

            if ~isempty(app.UITable.Data)
                % Tabela sob análise.                
                idxStations = app.UITable.UserData;
                relatedStationTable = app.mainApp.stationTable(idxStations, :);

                % "Registros anotados" por meio da inclusão de uma observação 
                % ou da edição das coordenadas geográficas da estação.
                addedObservationLogical = cellfun(@(x) ~isempty(x), relatedStationTable.("Observações"));
                editedLocationLogical   = (relatedStationTable.("Lat") ~= relatedStationTable.("Latitude")) | (relatedStationTable.("Long") ~= relatedStationTable.("Longitude"));                

                % Registros ainda pendentes de edição, seja por não ter sido 
                % especificada uma "Justificativa" válida (precisa ser diferente 
                % de "-1" quando não identificada medição no entorno da estação) 
                % ou porque foi especificada uma válida, porém que demanda a 
                % inclusão de uma observação ou a edição das coordenadas da estação.
                reasonsThatRequireObservation = app.mainApp.General.MonitoringPlan.ReasonsThatRequireObservation;
                reasonsThatRequireNewLocation = app.mainApp.General.MonitoringPlan.ReasonsThatRequireEditionOfLocation;

                idxMissingInfo   = find(((relatedStationTable.numberOfMeasures == 0) & (relatedStationTable.("Justificativa") == "-1"))             | ...
                                        (ismember(relatedStationTable.("Justificativa"), reasonsThatRequireObservation) & ~addedObservationLogical) | ...
                                        (ismember(relatedStationTable.("Justificativa"), reasonsThatRequireNewLocation) & ~editedLocationLogical));
                idxManualEdition = find(addedObservationLogical | editedLocationLogical);
                idxRiskMeasures  = find(relatedStationTable.numberOfRiskMeasures > 0);
                idxUpload2POST   = find(relatedStationTable.UploadResultFlag);
            end
        end

        %-----------------------------------------------------------------%
        function layout_TableStyle(app)
            removeStyle(app.UITable)

            if ~isempty(app.UITable.Data)
                % Identifica estações que NÃO tiveram medições no seu entorno, 
                % apesar da rota englobar o município em que está instalada a
                % estação. Ou estações que apresentaram medições com níveis
                % acima de 14 V/m.
                [idxMissingInfo, idxManualEdition, idxRiskMeasures, idxUpload2POST] = layout_searchUnexpectedTableValues(app);

                if ~isempty(idxMissingInfo)
                    columnIndex1 = find(ismember(app.UITable.Data.Properties.VariableNames, 'Justificativa'));
                    s1 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');                
                    addStyle(app.UITable, s1, "cell", [idxMissingInfo, repmat(columnIndex1, numel(idxMissingInfo), 1)])
                end

                if ~isempty(idxManualEdition)
                    s2 = uistyle('Icon', 'Edit_18Gray.png', 'IconAlignment', 'leftmargin');
                    addStyle(app.UITable, s2, "cell", [idxManualEdition, ones(numel(idxManualEdition), 1)])
                end

                if ~isempty(idxRiskMeasures)
                    columnIndex2 = find(ismember(app.UITable.Data.Properties.VariableNames, 'numberOfRiskMeasures'));

                    s3 = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');
                    addStyle(app.UITable, s3, "cell", [idxRiskMeasures, repmat(columnIndex2, numel(idxRiskMeasures), 1)])
                end

                if ~isempty(idxUpload2POST)
                    s4 = uistyle('FontColor', [.5,.5,.5]);
                    addStyle(app.UITable, s4, "row", idxUpload2POST)
                end

                app.tool_ExportFiles.Enable = 1;
                if isempty(idxMissingInfo)
                    app.tool_UploadFinalFile.Enable = 1;
                else
                    app.tool_UploadFinalFile.Enable = 0;
                end

            else
                app.tool_ExportFiles.Enable     = 0;
                app.tool_UploadFinalFile.Enable = 0;
            end
        end

        %-----------------------------------------------------------------%
        function layout_updatePeakInfo(app)
            if ~isempty(app.measTable)
                [~, idxMax] = max(app.measTable.FieldValue);
                peakLabel   = sprintf('%.2f V/m\n(%.6f, %.6f)', app.measTable.FieldValue(idxMax), ...
                                                                app.measTable.Latitude(idxMax),   ...
                                                                app.measTable.Longitude(idxMax));

                set(app.tool_peakLabel, 'Visible', 1, 'Text', peakLabel)
                set(app.tool_peakIcon,  'Visible', 1, 'UserData', struct('idxMax',    idxMax,                         ...
                                                                         'Latitude',  app.measTable.Latitude(idxMax), ...
                                                                         'Longitude', app.measTable.Longitude(idxMax)))
            else
                app.tool_peakLabel.Visible = 0;
                app.tool_peakIcon.Visible  = 0;
            end
        end

        %-----------------------------------------------------------------%
        function layout_TreeFileLocationBuilding(app)
            if ~isempty(app.TreeFileLocations.Children)
                delete(app.TreeFileLocations.Children)
            end

            listOfFileLocations = unique({app.measData.Location});
            for ii = 1:numel(listOfFileLocations)
                treeNode = uitreenode(app.TreeFileLocations, 'Text', listOfFileLocations{ii});

                if ismember(listOfFileLocations{ii}, app.projectData.selectedFileLocations)
                    app.TreeFileLocations.CheckedNodes = [app.TreeFileLocations.CheckedNodes; treeNode];
                end
            end

            if isempty(app.TreeFileLocations.CheckedNodes)
                app.TreeFileLocations.CheckedNodes = app.TreeFileLocations.Children(1);
            end
        end

        %-----------------------------------------------------------------%
        function createPopUpContainer(app)
            if isempty(app.popupContainer)
                popupContainerGrid = uigridlayout(app.UIFigure, [1, 1], "BackgroundColor", "white", "ColumnWidth", {'1x', 540, '1x'}, "RowHeight", {'1x', 440, '1x'}, "Visible", "off");
                app.popupContainer = uipanel(popupContainerGrid, "Title", "");
                app.popupContainer.Layout.Row = 2;
                app.popupContainer.Layout.Column = 2;
                drawnow

                ccTools.compCustomizationV2(app.jsBackDoor, popupContainerGrid, 'backgroundColor', 'rgba(255,255,255,0.65)')
                sendEventToHTMLSource(app.jsBackDoor, "panelDialog", struct('componentDataTag', struct(app.popupContainer).Controller.ViewModel.Id))
            end
        end

        %-----------------------------------------------------------------%
        function [idxStation, idxRow] = selectedStation(app)
            idxRow     = app.UITable.Selection;
            idxStation = app.UITable.UserData(idxRow);
        end
    end


    methods
        %-----------------------------------------------------------------%
        function appBackDoor(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    case {'winMonitorRNI', 'winMonitorRNI_exported'}
                        switch operationType
                            case {'PM-RNI: updateReferenceTable', 'PM-RNI: updatePlot'}
                                Analysis(app)

                            case 'PM-RNI: updateAnalysis'
                                app.UITable.ColumnName{5} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.MonitoringPlan.FieldValue);

                                idxStations = app.UITable.UserData;
                                if ~isempty(idxStations)
                                    app.mainApp.stationTable.AnalysisFlag(idxStations) = false;
                                end
                                Analysis(app)

                            case 'PM-RNI: updateAxes'
                                if ~isequal(app.UIAxes.Basemap, app.mainApp.General.Plot.GeographicAxes.Basemap)
                                    app.UIAxes.Basemap = app.mainApp.General.Plot.GeographicAxes.Basemap;
                                end

                                plot.axes.Colormap(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colormap)
                                plot.axes.Colorbar(app.UIAxes, app.mainApp.General.Plot.GeographicAxes.Colorbar)

                            otherwise
                                error('UnexpectedCall')
                        end

                    case {'auxApp.dockStationInfo',    'auxApp.dockStationInfo_exported', ...
                          'auxApp.dockListOfLocation', 'auxApp.dockListOfLocation_exported'}

                        % Chamadas implementadas:
                        % (a) 'StationTableValueChanged: ReasonOrNote'
                        %     Atualizam-se as colunas "Justificativa" e "Observações" da "tabela mãe"
                        %     (app.mainApp.stationTable), além da coluna "Justificativa" da uitable 
                        %     (já que a coluna "Observações" não é renderizada na uitable).
                        %
                        % (b) 'StationTableValueChanged: Location'
                        %     Atualizam-se as colunas "Latitude", "Longitude" e "AnalysisFlag" da "tabela mãe"
                        %     (app.mainApp.stationTable), executando-se novamente a análise.
                        %
                        % (c) 'UITableSelectionChanged'
                        %     Troca-se a seleção da uitable.
                        %
                        % (d) 'ListOfLocationChanged'

                        updateFlag = varargin{1};
                        returnFlag = varargin{2};

                        if updateFlag
                            switch operationType
                                case 'StationTableValueChanged: ReasonOrNote'
                                    newReason      = varargin{3};
                                    newObservation = varargin{4};

                                    [idxStation, idxRow] = selectedStation(app);
                                    app.mainApp.stationTable.("Justificativa")(idxStation) = newReason;
                                    app.mainApp.stationTable.("Observações"){idxStation}   = newObservation;
                                    app.UITable.Data.("Justificativa")(idxRow)             = newReason;
                                    layout_TableStyle(app)

                                case 'StationTableValueChanged: Location'
                                    newLatitude  = varargin{3};
                                    newLongitude = varargin{4};

                                    idxStation   = selectedStation(app);
                                    app.mainApp.stationTable.("Latitude")(idxStation)  = newLatitude;
                                    app.mainApp.stationTable.("Longitude")(idxStation) = newLongitude;
                                    app.mainApp.stationTable.AnalysisFlag(idxStation)  = false;

                                    Analysis(app)

                                case 'UITableSelectionChanged'
                                    newRowSelection = varargin{3};
                                    app.UITable.Selection = newRowSelection;
                                    scroll(app.UITable, 'row', newRowSelection)

                                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', newRowSelection))

                                case 'ListOfLocationChanged'
                                    Analysis(app)

                                otherwise
                                    error('UnexpectedCall')
                            end
                        end

                        if returnFlag
                            return
                        end
                        
                        app.popupContainer.Parent.Visible = 0;
    
                    otherwise
                        error('UnexpectedCall')
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, callingApp)

            app.mainApp     = callingApp;
            app.rootFolder  = callingApp.rootFolder;
            app.projectData = callingApp.projectData;
            app.measData    = callingApp.measData;

            jsBackDoor_Initialization(app)

            if app.isDocked
                app.GridLayout.Padding(4) = 21;
                startup_Controller(app)
            else
                appUtil.winPosition(app.UIFigure)
                startup_timerCreation(app)
            end

        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            appBackDoor(app.mainApp, app, 'closeFcn', 'MONITORINGPLAN')
            delete(app)
            
        end

        % Image clicked function: tool_ControlPanelVisibility, 
        % ...and 2 other components
        function tool_InteractionImageClicked(app, event)
            
            focus(app.jsBackDoor)
            
            switch event.Source
                case app.tool_ControlPanelVisibility
                    if app.GridLayout.ColumnWidth{2}
                        app.tool_ControlPanelVisibility.ImageSource = 'ArrowRight_32.png';
                        app.GridLayout.ColumnWidth(2:3) = {0,0};
                    else
                        app.tool_ControlPanelVisibility.ImageSource = 'ArrowLeft_32.png';
                        app.GridLayout.ColumnWidth(2:3) = {325,10};
                    end

                case app.tool_TableVisibility
                    app.tool_TableVisibility.UserData = mod(app.tool_TableVisibility.UserData+1, 3);

                    switch app.tool_TableVisibility.UserData
                        case 0
                            app.UITable.Visible = 0;
                            app.GridLayout.RowHeight(2:5) = {22,'1x', 0, 0};
                        case 1
                            app.UITable.Visible = 1;
                            app.GridLayout.RowHeight(2:5) = {22, '1x', 10, 175};
                        case 2
                            app.UITable.Visible = 1;
                            app.GridLayout.RowHeight(2:5) = {0, 0, 0, '1x'};
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
        function tool_ExportTableAsExcelSheet(app, event)
            
            % VALIDAÇÕES
            % (a) Inicialmente, verifica se o campo "Justificativa" foi devidamente 
            %     preenchido...
            if ~isempty(layout_searchUnexpectedTableValues(app))
                msgQuestion   = ['Há registro de estações instaladas na(s) localidade(s) sob análise para as quais '     ...
                                 'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                                 'o campo "Justificativa" e anotar os registros, caso aplicável.'                        ...
                                 '<br><br>Deseja ignorar esse alerta, exportando o resultado?'];
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end
            end

            % (b) Solicita ao usuário nome do arquivo de saída...
            appName       = class.Constants.appName;
            nameFormatMap = {'*.zip', [appName, ' (*.zip)']};
            defaultName   = appUtil.DefaultFileName(app.mainApp.General.fileFolder.userPath, appName, '-1');
            fileZIP       = appUtil.modalWindow(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
            if isempty(fileZIP)
                return
            end

            % ARQUIVOS DE SAÍDA
            d = appUtil.modalWindow(app.UIFigure, 'progressdlg', 'Em andamento a criação do arquivo de medidas no formato "xlsx".');

            savedFiles   = {};
            errorFiles   = {};

            defaultTempName = appUtil.DefaultFileName(app.mainApp.General.fileFolder.tempPath, appName, '-1');
            idxStations  = app.UITable.UserData;

            % (a) Arquivo no formato .XLSX
            %     (um único arquivo de saída)
            fileName_XLSX = [defaultTempName '.xlsx'];
            [status, msgError] = fileWriter.MonitoringPlan(fileName_XLSX, app.mainApp.stationTable(idxStations, :), timetable2table(app.measTable), app.mainApp.General.MonitoringPlan.FieldValue, app.mainApp.General.MonitoringPlan.Export.XLSX);
            if status
                savedFiles{end+1} = fileName_XLSX;
            else
                errorFiles{end+1} = msgError;
            end
    
            % (b) Arquivos no formato .KML: "Measures" e "Route"
            %     (um único arquivo de medições, além de um arquivo de rota 
            %      por arquivo de medição)
            if app.mainApp.General.MonitoringPlan.Export.KML
                hMeasPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');

                % (b.1) KML:Measures
                d.Message = 'Em andamento a criação do arquivo de medidas no formato "kml".';

                fileName_KML1 = sprintf('%s_Measures.kml', defaultTempName);
                [status, msgError] = fileWriter.KML(fileName_KML1, 'Measures', timetable2table(app.measTable), hMeasPlot);
                if status
                    savedFiles{end+1} = fileName_KML1;
                else
                    errorFiles{end+1} = msgError;
                end

                % (b.2) KML:Route
                d.Message = 'Em andamento a criação do arquivo de rotas no formato "kml".';

                idxFile = FileIndex(app);
                for ii = 1:numel(idxFile)
                    fileName_KML2 = sprintf('%s_Route (%d).kml', defaultTempName, ii);
                    [status, msgError] = fileWriter.KML(fileName_KML2, 'Route', timetable2table(app.measData(idxFile(ii)).Data));
                    if status
                        savedFiles{end+1} = fileName_KML2;
                    else
                        errorFiles{end+1} = msgError;
                    end
                end
            end

            % (c) Arquivo no formato .ZIP
            if ~isempty(savedFiles)
                zip(fileZIP, savedFiles)

                [~, fileName, fileExt] = fileparts(savedFiles);
                savedFiles = strcat('•&thinsp;', fileName, fileExt);
                appUtil.modalWindow(app.UIFigure, 'info', sprintf('Lista de arquivos criados:\n%s', strjoin(savedFiles, '\n')));
            end

            if ~isempty(errorFiles)
                appUtil.modalWindow(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
            end

            delete(d)

        end

        % Image clicked function: tool_UploadFinalFile
        function tool_UploadFinalFileImageClicked(app, event)
            
            % VALIDAÇÕES
            % (a) O botão app.tool_UploadFinalFile só está ATIVO quando a tabela 
            %     sob análise é não vazia, e o campo "Justificativa" foi corretamente 
            %     preenchido. Implementado em layout_TableStyle(app)

            % (b) A pasta "POST" do Sharepoint" deve ter sido mapeada.
            if ~isfolder(app.mainApp.General.fileFolder.DataHub_POST)
                appUtil.modalWindow(app.UIFigure, 'warning', 'Pendente mapear pasta do Sharepoint.');
                return
            end

            % (c) Verifica se já foi feito o upload de registros da tabela
            %     na presente sessão do app.
            idxStations = app.UITable.UserData;
            relatedStationTable = app.mainApp.stationTable(idxStations, :);

            if     all(relatedStationTable.UploadResultFlag)
                msgQuestion   = ['Todos os registros de estações já tiveram os seus resultados exportados para a pasta "POST" ' ...
                                 'do Sharepoint na presente sessão. Esses registros estão destacados com a fonte cinza.' ...
                                 '<br><br>Deseja realizar uma nova exportação?'];
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end

            elseif any(relatedStationTable.UploadResultFlag)
                msgQuestion   = ['Há registros de estações que já tiveram os seus resultados exportados para a pasta "POST" ' ...
                                 'do Sharepoint na presente sessão. Esses registros estão destacados com a fonte cinza.' ...
                                 '<br><br>O que deseja fazer?'];
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Exportar tabela completa', 'Exportar novos registros', 'Cancelar'}, 3, 3);
                switch userSelection
                    case 'Exportar novos registros'
                        relatedStationTable(relatedStationTable.UploadResultFlag, :) = [];
                    case 'Cancelar'
                        return
                end
            end

            % SALVA ARQUIVOS NA PASTA "POST" DO SHAREPOINT
            savedFiles   = {};
            errorFiles   = {};

            % (a) PLANILHA EXCEL
            fileName_XLSX = [appUtil.DefaultFileName(app.mainApp.General.fileFolder.DataHub_POST, class.Constants.appName, '-1') '.xlsx'];
            [status, msgError] = fileWriter.MonitoringPlan(fileName_XLSX, relatedStationTable, [], app.mainApp.General.MonitoringPlan.FieldValue);
            if status
                app.mainApp.stationTable.UploadResultFlag(idxStations) = true;
                layout_TableStyle(app)

                [~, fileName, fileExt] = fileparts(fileName_XLSX);
                savedFiles{end+1} = [fileName, fileExt];
            else
                errorFiles{end+1} = msgError;
            end

            % (b) ARQUIVOS BRUTOS
            idxFile = FileIndex(app);
            for ii = idxFile
                fileName_RAW = fullfile(app.measData(ii).Filepath, app.measData(ii).Filename);
                [status, msgError] = copyfile(fileName_RAW, app.mainApp.General.fileFolder.DataHub_POST, 'f');
                if status
                    savedFiles{end+1} = app.measData(ii).Filename;
                else
                    errorFiles{end+1} = msgError;
                end
            end

            if ~isempty(savedFiles)
                savedFiles = strcat('•&thinsp;', savedFiles);
                appUtil.modalWindow(app.UIFigure, 'info', sprintf('Lista de arquivos copiados para o Sharepoint:\n%s', strjoin(savedFiles, '\n')));
            end

            if ~isempty(errorFiles)
                appUtil.modalWindow(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
            end

        end

        % Image clicked function: axesTool_RegionZoom, axesTool_RestoreView
        function axesTool_InteractionImageClicked(app, event)
            
            switch event.Source
                case app.axesTool_RestoreView
                    geolimits(app.UIAxes, app.restoreView(1).xLim, app.restoreView(1).yLim)

                case app.axesTool_RegionZoom
                    plot.axes.Interactivity.GeographicRegionZoomInteraction(app.UIAxes, app.axesTool_RegionZoom)
            end

        end

        % Callback function: TreeFileLocations
        function TreeFileLocationsCheckedNodesChanged(app, event)
            
            if isempty(app.TreeFileLocations.CheckedNodes)
                app.TreeFileLocations.CheckedNodes = event.PreviousCheckedNodes;
                return
            end

            Analysis(app)

        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)

            idxStations = app.UITable.UserData;
            idxSelectedStation = idxStations(event.Indices(1));
            
            if ~ismember(event.EditData, app.mainApp.General.MonitoringPlan.NoMeasureReasons)
                app.UITable.Data.("Justificativa") = app.mainApp.stationTable.("Justificativa")(idxStations);
                return
            end
                        
            app.mainApp.stationTable.("Justificativa")(idxSelectedStation) = event.NewData;
            
            layout_TableStyle(app)

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

            plot_SelectedPoint(app)
            
        end

        % Menu selected function: EditSelectedUITableRow
        function UITableOpenPopUpEditionMode(app, event)
            
            if ~isempty(app.UITable.Selection)
                app.progressDialog.Visible = 'visible';

                createPopUpContainer(app)
                auxApp.dockStationInfo_exported(app.popupContainer, app)
                app.popupContainer.Parent.Visible = "on";

                app.progressDialog.Visible = 'hidden';
            end

        end

        % Image clicked function: LocationListEdit
        function LocationListEditClicked(app, event)
            
            app.progressDialog.Visible = 'visible';

            createPopUpContainer(app)
            auxApp.dockListOfLocation_exported(app.popupContainer, app)
            app.popupContainer.Parent.Visible = "on";

            app.progressDialog.Visible = 'hidden';

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
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {5, 325, 10, 5, 50, '1x', 5};
            app.GridLayout.RowHeight = {5, 22, '1x', 10, 175, 5, 34};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create plotPanel
            app.plotPanel = uipanel(app.GridLayout);
            app.plotPanel.BorderType = 'none';
            app.plotPanel.BackgroundColor = [1 1 1];
            app.plotPanel.Layout.Row = [2 3];
            app.plotPanel.Layout.Column = [4 6];

            % Create axesToolbarGrid
            app.axesToolbarGrid = uigridlayout(app.GridLayout);
            app.axesToolbarGrid.ColumnWidth = {22, 22};
            app.axesToolbarGrid.RowHeight = {'1x'};
            app.axesToolbarGrid.ColumnSpacing = 0;
            app.axesToolbarGrid.Padding = [2 2 2 7];
            app.axesToolbarGrid.Layout.Row = [1 2];
            app.axesToolbarGrid.Layout.Column = 5;
            app.axesToolbarGrid.BackgroundColor = [1 1 1];

            % Create axesTool_RestoreView
            app.axesTool_RestoreView = uiimage(app.axesToolbarGrid);
            app.axesTool_RestoreView.ImageClickedFcn = createCallbackFcn(app, @axesTool_InteractionImageClicked, true);
            app.axesTool_RestoreView.Tooltip = {'RestoreView'};
            app.axesTool_RestoreView.Layout.Row = 1;
            app.axesTool_RestoreView.Layout.Column = 1;
            app.axesTool_RestoreView.ImageSource = 'Home_18.png';

            % Create axesTool_RegionZoom
            app.axesTool_RegionZoom = uiimage(app.axesToolbarGrid);
            app.axesTool_RegionZoom.ImageClickedFcn = createCallbackFcn(app, @axesTool_InteractionImageClicked, true);
            app.axesTool_RegionZoom.Tooltip = {'RegionZoom'};
            app.axesTool_RegionZoom.Layout.Row = 1;
            app.axesTool_RegionZoom.Layout.Column = 2;
            app.axesTool_RegionZoom.ImageSource = 'ZoomRegion_20.png';

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'Estação'; 'Localidade'; 'Serviço'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Dmin|(km)'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'Justificativa'};
            app.UITable.ColumnWidth = {90, 150, 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = [true true true true true true true true true false];
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.FontName = 'MS Sans Serif';
            app.UITable.Layout.Row = 5;
            app.UITable.Layout.Column = [4 6];
            app.UITable.FontSize = 10;

            % Create Document
            app.Document = uigridlayout(app.GridLayout);
            app.Document.ColumnWidth = {160, '1x', 16};
            app.Document.RowHeight = {22, 32, '1x', 32, 170, 85, 85};
            app.Document.ColumnSpacing = 5;
            app.Document.RowSpacing = 5;
            app.Document.Padding = [0 0 0 0];
            app.Document.Layout.Row = [2 5];
            app.Document.Layout.Column = 2;
            app.Document.BackgroundColor = [1 1 1];

            % Create play_ControlsTab1Grid_2
            app.play_ControlsTab1Grid_2 = uigridlayout(app.Document);
            app.play_ControlsTab1Grid_2.ColumnWidth = {18, '1x'};
            app.play_ControlsTab1Grid_2.RowHeight = {'1x'};
            app.play_ControlsTab1Grid_2.ColumnSpacing = 5;
            app.play_ControlsTab1Grid_2.RowSpacing = 5;
            app.play_ControlsTab1Grid_2.Padding = [2 2 2 2];
            app.play_ControlsTab1Grid_2.Tag = 'COLORLOCKED';
            app.play_ControlsTab1Grid_2.Layout.Row = 1;
            app.play_ControlsTab1Grid_2.Layout.Column = [1 3];
            app.play_ControlsTab1Grid_2.BackgroundColor = [0.749 0.749 0.749];

            % Create play_ControlsTab1Image_2
            app.play_ControlsTab1Image_2 = uiimage(app.play_ControlsTab1Grid_2);
            app.play_ControlsTab1Image_2.Layout.Row = 1;
            app.play_ControlsTab1Image_2.Layout.Column = 1;
            app.play_ControlsTab1Image_2.HorizontalAlignment = 'left';
            app.play_ControlsTab1Image_2.ImageSource = 'Playback_32.png';

            % Create play_ControlsTab1Label_2
            app.play_ControlsTab1Label_2 = uilabel(app.play_ControlsTab1Grid_2);
            app.play_ControlsTab1Label_2.FontSize = 11;
            app.play_ControlsTab1Label_2.Layout.Row = 1;
            app.play_ControlsTab1Label_2.Layout.Column = 2;
            app.play_ControlsTab1Label_2.Text = 'PM-RNI';

            % Create config_geoAxesLabel_2
            app.config_geoAxesLabel_2 = uilabel(app.Document);
            app.config_geoAxesLabel_2.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel_2.WordWrap = 'on';
            app.config_geoAxesLabel_2.FontSize = 10;
            app.config_geoAxesLabel_2.Layout.Row = 2;
            app.config_geoAxesLabel_2.Layout.Column = [1 2];
            app.config_geoAxesLabel_2.Interpreter = 'html';
            app.config_geoAxesLabel_2.Text = {'LOCALIDADES:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.Document, 'checkbox');
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 3;
            app.TreeFileLocations.Layout.Column = [1 3];

            % Assign Checked Nodes
            app.TreeFileLocations.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeFileLocationsCheckedNodesChanged, true);

            % Create Card1_numberOfStations
            app.Card1_numberOfStations = uilabel(app.Document);
            app.Card1_numberOfStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card1_numberOfStations.VerticalAlignment = 'top';
            app.Card1_numberOfStations.WordWrap = 'on';
            app.Card1_numberOfStations.FontSize = 10;
            app.Card1_numberOfStations.FontColor = [0.502 0.502 0.502];
            app.Card1_numberOfStations.Layout.Row = 6;
            app.Card1_numberOfStations.Layout.Column = 1;
            app.Card1_numberOfStations.Interpreter = 'html';
            app.Card1_numberOfStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: BLACK; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NAS LOCALIDADES SOB ANÁLISE</p>'};

            % Create Card2_numberOfRiskStations
            app.Card2_numberOfRiskStations = uilabel(app.Document);
            app.Card2_numberOfRiskStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card2_numberOfRiskStations.VerticalAlignment = 'top';
            app.Card2_numberOfRiskStations.WordWrap = 'on';
            app.Card2_numberOfRiskStations.FontSize = 10;
            app.Card2_numberOfRiskStations.FontColor = [0.502 0.502 0.502];
            app.Card2_numberOfRiskStations.Layout.Row = 6;
            app.Card2_numberOfRiskStations.Layout.Column = [2 3];
            app.Card2_numberOfRiskStations.Interpreter = 'html';
            app.Card2_numberOfRiskStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE 14 V/m</p>'};

            % Create Card3_stationsOnRoute
            app.Card3_stationsOnRoute = uilabel(app.Document);
            app.Card3_stationsOnRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card3_stationsOnRoute.VerticalAlignment = 'top';
            app.Card3_stationsOnRoute.WordWrap = 'on';
            app.Card3_stationsOnRoute.FontSize = 10;
            app.Card3_stationsOnRoute.FontColor = [0.502 0.502 0.502];
            app.Card3_stationsOnRoute.Layout.Row = 7;
            app.Card3_stationsOnRoute.Layout.Column = 1;
            app.Card3_stationsOnRoute.Interpreter = 'html';
            app.Card3_stationsOnRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: black; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>'};

            % Create Card4_stationsOutRoute
            app.Card4_stationsOutRoute = uilabel(app.Document);
            app.Card4_stationsOutRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card4_stationsOutRoute.VerticalAlignment = 'top';
            app.Card4_stationsOutRoute.WordWrap = 'on';
            app.Card4_stationsOutRoute.FontSize = 10;
            app.Card4_stationsOutRoute.FontColor = [0.502 0.502 0.502];
            app.Card4_stationsOutRoute.Layout.Row = 7;
            app.Card4_stationsOutRoute.Layout.Column = [2 3];
            app.Card4_stationsOutRoute.Interpreter = 'html';
            app.Card4_stationsOutRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS FORA DA ROTA</p>'};

            % Create LocationList
            app.LocationList = uitextarea(app.Document);
            app.LocationList.Editable = 'off';
            app.LocationList.FontSize = 11;
            app.LocationList.Layout.Row = 5;
            app.LocationList.Layout.Column = [1 3];

            % Create LocationListEdit
            app.LocationListEdit = uiimage(app.Document);
            app.LocationListEdit.ImageClickedFcn = createCallbackFcn(app, @LocationListEditClicked, true);
            app.LocationListEdit.Tooltip = {'Edita lista de localidades'};
            app.LocationListEdit.Layout.Row = 4;
            app.LocationListEdit.Layout.Column = 3;
            app.LocationListEdit.VerticalAlignment = 'bottom';
            app.LocationListEdit.ImageSource = 'Edit_32.png';

            % Create LocationListLabel
            app.LocationListLabel = uilabel(app.Document);
            app.LocationListLabel.VerticalAlignment = 'bottom';
            app.LocationListLabel.FontSize = 10;
            app.LocationListLabel.Layout.Row = 4;
            app.LocationListLabel.Layout.Column = [1 2];
            app.LocationListLabel.Interpreter = 'html';
            app.LocationListLabel.Text = {'LOCALIDADES SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionadas às estações previstas no PM-RNI)</font>'};

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, 22, 22, 22, '1x', 150, 22};
            app.toolGrid.RowHeight = {4, 17, '1x'};
            app.toolGrid.ColumnSpacing = 5;
            app.toolGrid.RowSpacing = 0;
            app.toolGrid.Padding = [0 5 5 5];
            app.toolGrid.Layout.Row = 7;
            app.toolGrid.Layout.Column = [1 7];
            app.toolGrid.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create tool_ControlPanelVisibility
            app.tool_ControlPanelVisibility = uiimage(app.toolGrid);
            app.tool_ControlPanelVisibility.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_ControlPanelVisibility.Layout.Row = 2;
            app.tool_ControlPanelVisibility.Layout.Column = 1;
            app.tool_ControlPanelVisibility.ImageSource = 'ArrowLeft_32.png';

            % Create tool_TableVisibility
            app.tool_TableVisibility = uiimage(app.toolGrid);
            app.tool_TableVisibility.ScaleMethod = 'none';
            app.tool_TableVisibility.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_TableVisibility.Tooltip = {'Visibilidade da tabela'};
            app.tool_TableVisibility.Layout.Row = 2;
            app.tool_TableVisibility.Layout.Column = 2;
            app.tool_TableVisibility.ImageSource = 'View_16.png';

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.toolGrid);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @tool_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Tooltip = {'Exporta análise'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 3;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.toolGrid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 5;

            % Create tool_UploadFinalFile
            app.tool_UploadFinalFile = uiimage(app.toolGrid);
            app.tool_UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @tool_UploadFinalFileImageClicked, true);
            app.tool_UploadFinalFile.Enable = 'off';
            app.tool_UploadFinalFile.Tooltip = {'Upload do arquivo final para o Sharepoint'};
            app.tool_UploadFinalFile.Layout.Row = 2;
            app.tool_UploadFinalFile.Layout.Column = 4;
            app.tool_UploadFinalFile.ImageSource = 'Up_24.png';

            % Create tool_peakLabel
            app.tool_peakLabel = uilabel(app.toolGrid);
            app.tool_peakLabel.HorizontalAlignment = 'right';
            app.tool_peakLabel.FontSize = 10;
            app.tool_peakLabel.Visible = 'off';
            app.tool_peakLabel.Layout.Row = [1 3];
            app.tool_peakLabel.Layout.Column = 7;
            app.tool_peakLabel.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create tool_peakIcon
            app.tool_peakIcon = uiimage(app.toolGrid);
            app.tool_peakIcon.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_peakIcon.Visible = 'off';
            app.tool_peakIcon.Tooltip = {'Zoom em torno do local de máximo'};
            app.tool_peakIcon.Layout.Row = [1 3];
            app.tool_peakIcon.Layout.Column = 8;
            app.tool_peakIcon.HorizontalAlignment = 'right';
            app.tool_peakIcon.ImageSource = 'Detection_128.png';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create EditSelectedUITableRow
            app.EditSelectedUITableRow = uimenu(app.ContextMenu);
            app.EditSelectedUITableRow.MenuSelectedFcn = createCallbackFcn(app, @UITableOpenPopUpEditionMode, true);
            app.EditSelectedUITableRow.Text = 'Editar';

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
