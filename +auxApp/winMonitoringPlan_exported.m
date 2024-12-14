classdef winMonitoringPlan_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        GridLayout2                  matlab.ui.container.GridLayout
        play_ControlsTab1Grid_2      matlab.ui.container.GridLayout
        play_ControlsTab1Label_2     matlab.ui.control.Label
        play_ControlsTab1Image_2     matlab.ui.control.Image
        Card4_stationsOutRoute       matlab.ui.control.Label
        Card3_stationsOnRoute        matlab.ui.control.Label
        Card2_numberOfRiskStations   matlab.ui.control.Label
        Card1_numberOfStations       matlab.ui.control.Label
        UITree                       matlab.ui.container.CheckBoxTree
        config_geoAxesLabel_2        matlab.ui.control.Label
        toolGrid                     matlab.ui.container.GridLayout
        jsBackDoor                   matlab.ui.control.HTML
        tool_ExportFiles             matlab.ui.control.Image
        tool_TableVisibility         matlab.ui.control.Image
        tool_ControlPanelVisibility  matlab.ui.control.Image
        UITable                      matlab.ui.control.Table
        axesToolbarGrid              matlab.ui.container.GridLayout
        axesTool_RegionZoom          matlab.ui.control.Image
        axesTool_RestoreView         matlab.ui.control.Image
        plotPanel                    matlab.ui.container.Panel
        filter_ContextMenu           matlab.ui.container.ContextMenu
        filter_delButton             matlab.ui.container.Menu
        filter_delAllButton          matlab.ui.container.Menu
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = false

        CallingApp
        General
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
        
        %-----------------------------------------------------------------%
        % ESPECIFICIDADES
        %-----------------------------------------------------------------%
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
            app.jsBackDoor.HTMLSource = ccTools.fcn.jsBackDoorHTMLSource();
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app)
            if app.isDocked
                app.progressDialog = app.CallingApp.progressDialog;
            else
                app.progressDialog = ccTools.ProgressDialog(app.jsBackDoor);
            end

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
            if ~strcmp(app.CallingApp.executionMode, 'webApp') && ~app.isDocked
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            app.progressDialog.Visible = 'visible';

            startup_AppProperties(app)
            startup_GUIComponents(app)
            Analysis(app)

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            if isempty(app.CallingApp.stationTable)
                app.CallingApp.stationTable = fileReader.MonitoringPlanStations(fullfile(app.rootFolder, 'DataBase', 'PA_RNI', 'Dados_PA_RNI.csv'), app.General);
            end
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            startup_AxesCreation(app)
            startup_TreeBuilding(app)

            app.tool_TableVisibility.UserData = 1;
        end

        %-----------------------------------------------------------------%
        function startup_AxesCreation(app)
            % Eixo geográfico: MAPA
            app.plotPanel.AutoResizeChildren = 'off';
            app.UIAxes = plot.axes.Creation(app.plotPanel, 'Geographic', {'Units',    'normalized',             ...
                                                                           'Position', [0 0 1 1 ],               ...
                                                                           'Basemap',  app.General.Plot.GeographicAxes.Basemap, ...
                                                                           'UserData', struct('CLimMode', 'auto', 'Colormap', '')});

            set(app.UIAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
            set(app.UIAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
            
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');

            plot.axes.Colormap(app.UIAxes, app.General.Plot.GeographicAxes.Colormap)
            plot.axes.Colorbar(app.UIAxes, app.General.Plot.GeographicAxes.Colorbar)

            % Legenda
            legend(app.UIAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5)

            % Axes interactions:
            plot.axes.Interactivity.DefaultCreation(app.UIAxes, [dataTipInteraction, zoomInteraction, panInteraction])
        end

        %-----------------------------------------------------------------%
        function startup_TreeBuilding(app)
            if ~isempty(app.UITree.Children)
                delete(app.UITree.Children)
            end

            listOfLocations = unique({app.measData.Location});
            for ii = 1:numel(listOfLocations)
                uitreenode(app.UITree, 'Text', listOfLocations{ii});
            end

            app.UITree.CheckedNodes = app.UITree.Children(1);
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function Analysis(app)
            if ~isempty(app.UITree.CheckedNodes)
                selectedLocations = {app.UITree.CheckedNodes.Text};
                idxFile = find(ismember({app.measData.Location}, selectedLocations));
    
                % Concatena as tabelas de LATITUDE, LONGITUDE E NÍVEL de cada um
                % dos arquivos cuja localidade coincide com o que foi selecionado
                % em tela. 
                listOfTables = {app.measData(idxFile).Data};            
                app.measTable = sortrows(vertcat(listOfTables{:}), 'Timestamp');
                
                % Identifica localidades relacionadas à monitoração sob análise.
                listOfLocations = {};
                DIST_km = app.General.MonitoringPlan.Distance_km;
    
                for ii = idxFile
                    % Limites de latitude e longitude relacionados à rota, acrescentando 
                    % a distância máxima à estação p/ fins de cômputo de medidas válidas 
                    % no entorno de uma estação.
                    [maxLatitude, maxLongitude] = reckon(app.measData(ii).LatitudeLimits(2), app.measData(ii).LongitudeLimits(2), km2deg(DIST_km), 45);
                    [minLatitude, minLongitude] = reckon(app.measData(ii).LatitudeLimits(1), app.measData(ii).LongitudeLimits(1), km2deg(DIST_km), 225);
    
                    idxLogicalStation = app.CallingApp.stationTable.("Latitude da Estação")  >= minLatitude  & ...
                                        app.CallingApp.stationTable.("Latitude da Estação")  <= maxLatitude  & ...
                                        app.CallingApp.stationTable.("Longitude da Estação") >= minLongitude & ...
                                        app.CallingApp.stationTable.("Longitude da Estação") <= maxLongitude;
    
                    if any(idxLogicalStation)
                        listOfLocations = [listOfLocations; unique(app.CallingApp.stationTable.Location(idxLogicalStation))];
                    end
                end
    
                idxStations = find(ismember(app.CallingApp.stationTable.Location, listOfLocations));
                identifyMeasuresForEachStation(app, idxStations, DIST_km)
    
                [table2Render, ...
                 table2RenderIndex] = sortrows(app.CallingApp.stationTable(idxStations, {'Location',             ...
                                                                                         'Serviço',              ...
                                                                                         'N° da Estacao',        ...
                                                                                         'numberOfMeasures',     ...
                                                                                         'numberOfRiskMeasures', ...
                                                                                         'minFieldValue',        ...
                                                                                         'meanFieldValue',       ...
                                                                                         'maxFieldValue',        ...
                                                                                         'Justificativa'}), 'numberOfMeasures', 'descend');
                set(app.UITable, 'Data', table2Render, 'UserData', idxStations(table2RenderIndex))
    
                % Aplica estilo à tabela...
                layout_TableStyle(app)
                
                % Atualiza painel com quantitativo de estações...
                nStations         = numel(idxStations);
                nRiskStations     = sum(app.UITable.Data.numberOfRiskMeasures > 0);
                nStationsOnRoute  = sum(app.UITable.Data.numberOfMeasures > 0);
                nStationsOutRoute = nStations - nStationsOnRoute;
    
                app.Card1_numberOfStations.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES LOCALIZADAS NOS MUNICÍPIOS SOB ANÁLISE</p>',                nStations);
                app.Card2_numberOfRiskStations.Text = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE 14 V/m</p></p>', nRiskStations);
                app.Card3_stationsOnRoute .Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>',                         nStationsOnRoute);
                app.Card4_stationsOutRoute.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS FORA DA ROTA</p>',                               nStationsOutRoute);
    
                % PLOT
                prePlot(app)
                plot_Measures(app)
                plot_Stations(app)

            else
                prePlot(app)
                app.UITable.Data(:,:) = [];
                app.UITable.UserData  = [];
            end

            layout_ToolbarButtonVisibility(app)
        end

        %-----------------------------------------------------------------%
        function prePlot(app)
            cla(app.UIAxes)
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function plot_Measures(app)
            hPlot = geoscatter(app.UIAxes, app.measTable.Latitude, app.measTable.Longitude, [], app.measTable.FieldValue, 'filled', 'DisplayName', 'Medidas', 'Tag', 'Measures');
            hPlot.DataTipTemplate.DataTipRows(3).Label  = 'Nivel';
            hPlot.DataTipTemplate.DataTipRows(3).Format = '%0.2f V/m';

            % Abaixo estabelece como limites do eixo os limites atuais,
            % configurados automaticamente pelo MATLAB. Ao fazer isso,
            % contudo, esses limites serão orientados às medidas e não às
            % estações.
            geolimits(app.UIAxes, app.UIAxes.LatitudeLimits, app.UIAxes.LongitudeLimits)
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function plot_Stations(app)            
            if ~isempty(app.UITable.Data)
                idxStations    = app.UITable.UserData;
                latitudeArray  = app.CallingApp.stationTable.("Latitude da Estação")(idxStations);
                longitudeArray = app.CallingApp.stationTable.("Longitude da Estação")(idxStations);

                geoscatter(app.UIAxes, latitudeArray, longitudeArray, ...
                    'Marker', '^', 'MarkerFaceColor', app.General.Plot.Stations.Color, ...
                    'MarkerEdgeColor', app.General.Plot.Stations.Color,           ...
                    'SizeData',        app.General.Plot.Stations.Size,            ...
                    'DisplayName',     'Estações de referência PM-RNI',           ...
                    'Tag',             'Stations');
            end
        end

        %-----------------------------------------------------------------%
        function plot_SelectedStation(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedStation', '-or', 'Tag', 'FieldPeak'))

            if ~isempty(app.UITable.Selection)
                idxTable = app.UITable.Selection(1);

                % (a) Estação selecionada
                idxSelectedStation = app.UITable.UserData(idxTable);
                stationLatitude    = app.CallingApp.stationTable.("Latitude da Estação")(idxSelectedStation);
                stationLongitude   = app.CallingApp.stationTable.("Longitude da Estação")(idxSelectedStation);
                stationNumber      = sprintf('Estação nº %d', app.CallingApp.stationTable.("N° da Estacao")(idxSelectedStation));

                geoscatter(app.UIAxes, stationLatitude, stationLongitude,      ...
                    'Marker',          '^',                                    ...
                    'MarkerFaceColor', app.General.Plot.SelectedStation.Color, ...
                    'MarkerEdgeColor', app.General.Plot.SelectedStation.Color, ...
                    'SizeData',        app.General.Plot.SelectedStation.Size,  ...
                    'DisplayName',     stationNumber,                          ...
                    'Tag',             'SelectedStation');
    
                % (b) Círculo entorno da estação
                drawcircle(app.UIAxes,                                                 ...
                    'Position',        [stationLatitude, stationLongitude],            ...
                    'Radius',          km2deg(app.General.MonitoringPlan.Distance_km), ...
                    'Color',           app.General.Plot.CircleRegion.Color,            ...
                    'FaceAlpha',       app.General.Plot.CircleRegion.FaceAlpha,        ...
                    'EdgeAlpha',       app.General.Plot.CircleRegion.EdgeAlpha,        ...
                    'FaceSelectable',  0, 'InteractionsAllowed', 'none',               ...
                    'Tag',            'SelectedStation');
    
                % (c) Maior nível em torno da estação
                maxFieldValue      = app.CallingApp.stationTable.maxFieldValue(idxSelectedStation);
                if maxFieldValue > 0
                    maxFieldLatitude   = app.CallingApp.stationTable.maxFieldLatitude(idxSelectedStation);
                    maxFieldLongitude  = app.CallingApp.stationTable.maxFieldLongitude(idxSelectedStation);
    
                    geoscatter(app.UIAxes, maxFieldLatitude, maxFieldLongitude, maxFieldValue, ...
                        'Marker',          'square',                          ...
                        'MarkerFaceColor', app.General.Plot.FieldPeak.Color,  ...
                        'SizeData',        app.General.Plot.FieldPeak.Size,   ...
                        'DisplayName',     'Maior nível em torno da estação', ...
                        'Tag',             'FieldPeak');
                end

                % Zoom automático em torno da estação
                if app.General.Plot.SelectedStation.AutomaticZoom
                    arclen         = km2deg(app.General.Plot.SelectedStation.AutomaticZoomFactor * app.General.MonitoringPlan.Distance_km);
                    [~, lim_long1] = reckon(stationLatitude, stationLongitude, arclen, -90);
                    [~, lim_long2] = reckon(stationLatitude, stationLongitude, arclen,  90);    
                    [lim_lat1, ~]  = reckon(stationLatitude, stationLongitude, arclen, 180);
                    [lim_lat2, ~]  = reckon(stationLatitude, stationLongitude, arclen,   0);
        
                    geolimits(app.UIAxes, [lim_lat1, lim_lat2], [lim_long1, lim_long2]);
                end
            end
        end
        
        %-----------------------------------------------------------------%
        function identifyMeasuresForEachStation(app, idxStations, DIST_km)
            for ii = idxStations'
                if app.CallingApp.stationTable.AnalysisFlag(ii)
                    continue
                end

                app.CallingApp.stationTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância da estação a cada uma das
                % medidas, identificando aquelas no entorno.
                stationDistance    = deg2km(distance(app.CallingApp.stationTable.('Latitude da Estação')(ii), app.CallingApp.stationTable.('Longitude da Estação')(ii), app.measTable.Latitude, app.measTable.Longitude));                
                idxLogicalMeasures = stationDistance <= DIST_km;

                if any(idxLogicalMeasures)
                    stationMeasures = app.measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(stationMeasures.FieldValue);

                    app.CallingApp.stationTable.numberOfMeasures(ii)     = height(stationMeasures);
                    app.CallingApp.stationTable.numberOfRiskMeasures(ii) = sum(stationMeasures.FieldValue > app.General.MonitoringPlan.FieldValue);
                    app.CallingApp.stationTable.minFieldValue(ii)        = min(stationMeasures.FieldValue);
                    app.CallingApp.stationTable.meanFieldValue(ii)       = mean(stationMeasures.FieldValue);
                    app.CallingApp.stationTable.maxFieldValue(ii)        = maxFieldValue;
                    app.CallingApp.stationTable.maxFieldTimestamp(ii)    = stationMeasures.Timestamp(idxMaxFieldValue);
                    app.CallingApp.stationTable.maxFieldLatitude(ii)     = stationMeasures.Latitude(idxMaxFieldValue);
                    app.CallingApp.stationTable.maxFieldLongitude(ii)    = stationMeasures.Longitude(idxMaxFieldValue);        
                end
            end
        end

        %-----------------------------------------------------------------%
        function idxTableRow = layout_searchUnexpectedTableValues(app, operationType)
            switch operationType
                case 'TableLayout'
                    idxTableRow = find(app.UITable.Data.numberOfRiskMeasures > 0 | ...
                                      ((app.UITable.Data.numberOfMeasures == 0) & (app.UITable.Data.("Justificativa") == "-1")));

                case 'TableExport'
                    idxTableRow = find((app.UITable.Data.numberOfMeasures == 0) & (app.UITable.Data.("Justificativa") == "-1"));
            end
        end

        %-----------------------------------------------------------------%
        function layout_TableStyle(app)
            removeStyle(app.UITable)

            % Identifica estações que NÃO tiveram medições no seu entorno, 
            % apesar da rota englobar o município em que está instalada a
            % estação. Ou estações que apresentaram medições com níveis
            % acima de 14 V/m.
            idxTableRow = layout_searchUnexpectedTableValues(app, 'TableLayout');
            columnIndex = find(ismember(app.UITable.Data.Properties.VariableNames, 'Justificativa'));
            cellList    = [idxTableRow, repmat(columnIndex, numel(idxTableRow), 1)];
            
            % Neste caso, passa a ser obrigatório o preenchimento do campo
            % "Justificativa" da tabela.
            s = uistyle('BackgroundColor', '#c80b0f', 'FontColor', 'white');
            addStyle(app.UITable, s, "cell", cellList)
        end

        %-----------------------------------------------------------------%
        function layout_ToolbarButtonVisibility(app)
            if isempty(app.UITable.Data)
                app.tool_ExportFiles.Enable = 0;
            else
                app.tool_ExportFiles.Enable = 1;
            end        
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            app.CallingApp = mainapp;
            app.General    = mainapp.General;
            app.rootFolder = mainapp.rootFolder;            
            app.measData   = mainapp.measData;

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

            appBackDoor(app.CallingApp, app, 'closeFcn', 'MONITORINGPLAN')
            delete(app)
            
        end

        % Image clicked function: tool_ControlPanelVisibility, 
        % ...and 1 other component
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
            end

        end

        % Image clicked function: tool_ExportFiles
        function tool_ExportTableAsExcelSheet(app, event)
            
            % Inicialmente, verifica se o campo "Justificativa" foi devidamente 
            % preenchido...
            if ~isempty(layout_searchUnexpectedTableValues(app, 'TableExport'))
                msgQuestion   = ['Há registro de estações instaladas na(s) localidade(s) sob análise para as quais '     ...
                                 'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                                 'o campo "Justificativa".<br><br>Deseja ignorar esse alerta, exportando plot e tabela como arquivos (.KML e .XLSX)?'];
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end
            end

            % Usuário escolhe nome do arquivo a ser salvo...       
            nameFormatMap = {'*.zip', 'RNI (*.zip)'};
            defaultName   = appUtil.DefaultFileName(app.General.fileFolder.userPath, 'RNI', '-1');
            fileZIP       = appUtil.modalWindow(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
            if isempty(fileZIP)
                return
            end

            app.progressDialog.Visible = 'visible';

            try
                fileBasename = appUtil.DefaultFileName(app.General.fileFolder.userPath, 'RNI', '-1');
                hPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');
                msgWarning = fileWriter.KML(app.CallingApp.stationTable, app.UITable.UserData, app.measTable, fileBasename, fileZIP, hPlot);
                appUtil.modalWindow(app.UIFigure, 'info', msgWarning);
            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);
            end

            app.progressDialog.Visible = 'hidden';

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

        % Callback function: UITree
        function UITreeCheckedNodesChanged(app, event)
            
            app.progressDialog.Visible = 'visible';
            Analysis(app)
            app.progressDialog.Visible = 'hidden';

        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)

            idxStation = app.UITable.UserData(event.Indices(1));
            app.CallingApp.stationTable.("Justificativa")(idxStation) = event.NewData;
            
            layout_TableStyle(app)

        end

        % Double-clicked callback: UITable
        function UITableDoubleClicked(app, event)
            
            plot_SelectedStation(app)

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
                app.UIFigure.Name = 'RNI';
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
            app.UITable.ColumnName = {'Localidade'; 'Serviço'; 'Estação'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'Justificativa'};
            app.UITable.ColumnWidth = {150, 'auto', 90, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = [true true true true true true true true false];
            app.UITable.ColumnEditable = [false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.DoubleClickedFcn = createCallbackFcn(app, @UITableDoubleClicked, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 5;
            app.UITable.Layout.Column = [4 6];
            app.UITable.FontSize = 10;

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, '1x', 22, 22};
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
            app.tool_ExportFiles.Tooltip = {'Exporta plot e tabela como arquivos'; '(.KML e .XLSX)'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 5;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.toolGrid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 4;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.GridLayout);
            app.GridLayout2.RowHeight = {22, 22, '1x', 85, 85};
            app.GridLayout2.ColumnSpacing = 5;
            app.GridLayout2.RowSpacing = 5;
            app.GridLayout2.Padding = [0 0 0 0];
            app.GridLayout2.Layout.Row = [2 5];
            app.GridLayout2.Layout.Column = 2;
            app.GridLayout2.BackgroundColor = [1 1 1];

            % Create config_geoAxesLabel_2
            app.config_geoAxesLabel_2 = uilabel(app.GridLayout2);
            app.config_geoAxesLabel_2.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel_2.WordWrap = 'on';
            app.config_geoAxesLabel_2.FontSize = 10;
            app.config_geoAxesLabel_2.Layout.Row = 2;
            app.config_geoAxesLabel_2.Layout.Column = 1;
            app.config_geoAxesLabel_2.Text = 'LOCALIDADES';

            % Create UITree
            app.UITree = uitree(app.GridLayout2, 'checkbox');
            app.UITree.FontSize = 11;
            app.UITree.Layout.Row = 3;
            app.UITree.Layout.Column = [1 2];

            % Assign Checked Nodes
            app.UITree.CheckedNodesChangedFcn = createCallbackFcn(app, @UITreeCheckedNodesChanged, true);

            % Create Card1_numberOfStations
            app.Card1_numberOfStations = uilabel(app.GridLayout2);
            app.Card1_numberOfStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card1_numberOfStations.VerticalAlignment = 'top';
            app.Card1_numberOfStations.WordWrap = 'on';
            app.Card1_numberOfStations.FontSize = 10;
            app.Card1_numberOfStations.FontColor = [0.502 0.502 0.502];
            app.Card1_numberOfStations.Layout.Row = 4;
            app.Card1_numberOfStations.Layout.Column = 1;
            app.Card1_numberOfStations.Interpreter = 'html';
            app.Card1_numberOfStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: BLACK; font-size: 32px;">0</font>'; 'ESTAÇÕES LOCALIZADAS NOS MUNICÍPIOS SOB ANÁLISE</p>'};

            % Create Card2_numberOfRiskStations
            app.Card2_numberOfRiskStations = uilabel(app.GridLayout2);
            app.Card2_numberOfRiskStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card2_numberOfRiskStations.VerticalAlignment = 'top';
            app.Card2_numberOfRiskStations.WordWrap = 'on';
            app.Card2_numberOfRiskStations.FontSize = 10;
            app.Card2_numberOfRiskStations.FontColor = [0.502 0.502 0.502];
            app.Card2_numberOfRiskStations.Layout.Row = 4;
            app.Card2_numberOfRiskStations.Layout.Column = 2;
            app.Card2_numberOfRiskStations.Interpreter = 'html';
            app.Card2_numberOfRiskStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE 14 V/m</p>'};

            % Create Card3_stationsOnRoute
            app.Card3_stationsOnRoute = uilabel(app.GridLayout2);
            app.Card3_stationsOnRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card3_stationsOnRoute.VerticalAlignment = 'top';
            app.Card3_stationsOnRoute.WordWrap = 'on';
            app.Card3_stationsOnRoute.FontSize = 10;
            app.Card3_stationsOnRoute.FontColor = [0.502 0.502 0.502];
            app.Card3_stationsOnRoute.Layout.Row = 5;
            app.Card3_stationsOnRoute.Layout.Column = 1;
            app.Card3_stationsOnRoute.Interpreter = 'html';
            app.Card3_stationsOnRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: black; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>'};

            % Create Card4_stationsOutRoute
            app.Card4_stationsOutRoute = uilabel(app.GridLayout2);
            app.Card4_stationsOutRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card4_stationsOutRoute.VerticalAlignment = 'top';
            app.Card4_stationsOutRoute.WordWrap = 'on';
            app.Card4_stationsOutRoute.FontSize = 10;
            app.Card4_stationsOutRoute.FontColor = [0.502 0.502 0.502];
            app.Card4_stationsOutRoute.Layout.Row = 5;
            app.Card4_stationsOutRoute.Layout.Column = 2;
            app.Card4_stationsOutRoute.Interpreter = 'html';
            app.Card4_stationsOutRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS FORA DA ROTA</p>'};

            % Create play_ControlsTab1Grid_2
            app.play_ControlsTab1Grid_2 = uigridlayout(app.GridLayout2);
            app.play_ControlsTab1Grid_2.ColumnWidth = {18, '1x'};
            app.play_ControlsTab1Grid_2.RowHeight = {'1x'};
            app.play_ControlsTab1Grid_2.ColumnSpacing = 5;
            app.play_ControlsTab1Grid_2.RowSpacing = 5;
            app.play_ControlsTab1Grid_2.Padding = [2 2 2 2];
            app.play_ControlsTab1Grid_2.Tag = 'COLORLOCKED';
            app.play_ControlsTab1Grid_2.Layout.Row = 1;
            app.play_ControlsTab1Grid_2.Layout.Column = [1 2];
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
            app.play_ControlsTab1Label_2.Text = 'MEDIDAS';

            % Create filter_ContextMenu
            app.filter_ContextMenu = uicontextmenu(app.UIFigure);

            % Create filter_delButton
            app.filter_delButton = uimenu(app.filter_ContextMenu);
            app.filter_delButton.Text = 'Excluir';

            % Create filter_delAllButton
            app.filter_delAllButton = uimenu(app.filter_ContextMenu);
            app.filter_delAllButton.Text = 'Excluir todos';

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
