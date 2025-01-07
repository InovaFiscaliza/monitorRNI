classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        GridLayout2                  matlab.ui.container.GridLayout
        DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel  matlab.ui.control.Label
        EditField_DistPont           matlab.ui.control.NumericEditField
        LocationListLabel            matlab.ui.control.Label
        Panel_2                      matlab.ui.container.Panel
        GridLayout5                  matlab.ui.container.GridLayout
        pointDescription             matlab.ui.control.EditField
        pointDescriptionLabel        matlab.ui.control.Label
        pointLongitude               matlab.ui.control.NumericEditField
        pointLongitudeLabel          matlab.ui.control.Label
        pointLatitude                matlab.ui.control.NumericEditField
        pointLatitudeLabel           matlab.ui.control.Label
        pointStation                 matlab.ui.control.NumericEditField
        pointStationLabel            matlab.ui.control.Label
        pointType                    matlab.ui.control.DropDown
        pointTypeLabel               matlab.ui.control.Label
        pointTree                    matlab.ui.container.Tree
        pointAddImage                matlab.ui.control.Image
        play_ControlsTab1Grid_2      matlab.ui.container.GridLayout
        menu_Button1Label            matlab.ui.control.Label
        play_ControlsTab1Image_2     matlab.ui.control.Image
        toolGrid                     matlab.ui.container.GridLayout
        tool_ExportFiles             matlab.ui.control.Image
        jsBackDoor                   matlab.ui.control.HTML
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

        mainApp
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
        Data_Localidades       % Dados da Tabela das Localidades do Brasil
        Data_Serv_Rad_Tel      % Dados dos serviços de Radiodifusão e de Telecom fiscalizados pela Anatel 
        %Incremento das estações pontuais
        IncrPoints = 0;  

        
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
                app.progressDialog = app.mainApp.progressDialog;
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
            if ~strcmp(app.mainApp.executionMode, 'webApp') && ~app.isDocked
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            app.progressDialog.Visible = 'visible';

            startup_AppProperties(app)
            startup_GUIComponents(app)
            % Analysis(app)

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            % ...
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            startup_AxesCreation(app)
            TreeBuilding(app)

            app.tool_TableVisibility.UserData = 1;

            % Insere em app.pointType.Items os tipos de locais
            app.pointType.Items = [{''}; app.mainApp.General.ExternalRequest.TypeOfLocation];
        end

        %-----------------------------------------------------------------%
        function startup_AxesCreation(app)
            % Eixo geográfico: MAPA
            app.plotPanel.AutoResizeChildren = 'off';
            app.UIAxes = plot.axes.Creation(app.plotPanel, 'Geographic', {'Units',    'normalized',             ...
                                                                           'Position', [0 0 1 1 ],               ...
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

        %-----------------------------------------------------------------%
        % function startup_TreeBuilding(app)
        %     if ~isempty(app.UITree.Children)
        %         delete(app.UITree.Children)
        %     end
        % 
        %     listOfLocations = unique({app.measData.Location});
        %     for ii = 1:numel(listOfLocations)
        %         uitreenode(app.UITree, 'Text', listOfLocations{ii});
        %     end
        % 
        %     app.UITree.CheckedNodes = app.UITree.Children(1);
        % end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function Analysis(app)

                listOfTables = {app.measData.Data};            
                app.measTable = sortrows(vertcat(listOfTables{:}), 'Timestamp');
                DIST_km = app.EditField_DistPont.Value / 1000; % m >> km

                identifyMeasuresForEachPoint(app, DIST_km)

                % Aplica estilo à tabela...
                layout_TableStyle(app)

                % PLOT
                prePlot(app)
                plot_Measures(app)
                plot_Stations(app)

            layout_ToolbarButtonVisibility(app)
        end

        %-----------------------------------------------------------------%
        function TreeBuilding(app)
            if ~isempty(app.pointTree.Children)
                delete(app.pointTree.Children)
            end

            for ii = 1:height(app.mainApp.pointsTable)
                uitreenode(app.pointTree, 'Text', app.mainApp.pointsTable.ID{ii});
            end
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
                % idxStations    = app.UITable.UserData;
                latitudeArray  = app.mainApp.stationTable.("Latitude da Estação")(app.IncrPoints);
                longitudeArray = app.mainApp.stationTable.("Longitude da Estação")(app.IncrPoints);

                geoscatter(app.UIAxes, latitudeArray, longitudeArray, ...
                    'Marker', '^', 'MarkerFaceColor', app.mainApp.General.Plot.Stations.Color, ...
                    'MarkerEdgeColor', app.mainApp.General.Plot.Stations.Color,           ...
                    'SizeData',        app.mainApp.General.Plot.Stations.Size,            ...
                    'DisplayName',     'Estações de referência PM-RNI',           ...
                    'Tag',             'Stations');
            end
        end
        %-----------------------------------------------------------------%
        function plot_SelectedStation(app, Station)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedStation', '-or', 'Tag', 'FieldPeak'))

            if ~isempty(app.UITable.Selection)
                idxTable = app.UITable.Selection(1);

                % (a) Estação selecionada
                % idxSelectedStation = app.UITable.UserData(idxTable);
                stationLatitude    = app.mainApp.stationTable.("Latitude da Estação")(Station);
                stationLongitude   = app.mainApp.stationTable.("Longitude da Estação")(Station);
                stationNumber      = sprintf('Estação nº %d', app.mainApp.stationTable.("N° da Estacao")(Station));

                geoscatter(app.UIAxes, stationLatitude, stationLongitude,      ...
                    'Marker',          '^',                                    ...
                    'MarkerFaceColor', app.mainApp.General.Plot.SelectedStation.Color, ...
                    'MarkerEdgeColor', app.mainApp.General.Plot.SelectedStation.Color, ...
                    'SizeData',        app.mainApp.General.Plot.SelectedStation.Size,  ...
                    'DisplayName',     stationNumber,                          ...
                    'Tag',             'SelectedStation');
    
                % (b) Círculo entorno da estação
                drawcircle(app.UIAxes,                                                 ...
                    'Position',        [stationLatitude, stationLongitude],            ...
                    'Radius',          km2deg(app.mainApp.General.MonitoringPlan.Distance_km), ...
                    'Color',           app.mainApp.General.Plot.CircleRegion.Color,            ...
                    'FaceAlpha',       app.mainApp.General.Plot.CircleRegion.FaceAlpha,        ...
                    'EdgeAlpha',       app.mainApp.General.Plot.CircleRegion.EdgeAlpha,        ...
                    'FaceSelectable',  0, 'InteractionsAllowed', 'none',               ...
                    'Tag',            'SelectedStation');
    
                % (c) Maior nível em torno da estação
                maxFieldValue      = app.mainApp.stationTable.maxFieldValue(Station);
                if maxFieldValue > 0
                    maxFieldLatitude   = app.mainApp.stationTable.maxFieldLatitude(Station);
                    maxFieldLongitude  = app.mainApp.stationTable.maxFieldLongitude(Station);
    
                    geoscatter(app.UIAxes, maxFieldLatitude, maxFieldLongitude, maxFieldValue, ...
                        'Marker',          'square',                          ...
                        'MarkerFaceColor', app.mainApp.General.Plot.FieldPeak.Color,  ...
                        'SizeData',        app.mainApp.General.Plot.FieldPeak.Size,   ...
                        'DisplayName',     'Maior nível em torno da estação', ...
                        'Tag',             'FieldPeak');
                end

                % Zoom automático em torno da estação
                if app.mainApp.General.Plot.SelectedStation.AutomaticZoom
                    arclen         = km2deg(app.mainApp.General.Plot.SelectedStation.AutomaticZoomFactor * app.mainApp.General.MonitoringPlan.Distance_km);
                    [~, lim_long1] = reckon(stationLatitude, stationLongitude, arclen, -90);
                    [~, lim_long2] = reckon(stationLatitude, stationLongitude, arclen,  90);    
                    [lim_lat1, ~]  = reckon(stationLatitude, stationLongitude, arclen, 180);
                    [lim_lat2, ~]  = reckon(stationLatitude, stationLongitude, arclen,   0);
        
                    geolimits(app.UIAxes, [lim_lat1, lim_lat2], [lim_long1, lim_long2]);
                end
            end
        end
        
        %-----------------------------------------------------------------%
        function identifyMeasuresForEachPoint(app)
            DIST_km = app.EditField_DistPont.Value;

            for ii = 1:height(app.mainApp.pointsTable)
                if app.mainApp.pointsTable.AnalysisFlag(ii)
                    continue
                end

                app.mainApp.pointsTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância do ponto a cada uma das
                % medidas, identificando aquelas no entorno.
                stationDistance    = deg2km(distance(app.mainApp.pointsTable.Latitude(ii), app.mainApp.pointsTable.Longitude(ii), app.measTable.Latitude, app.measTable.Longitude));                
                idxLogicalMeasures = stationDistance <= DIST_km;

                if any(idxLogicalMeasures)
                    stationMeasures = app.measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(stationMeasures.FieldValue);

                    app.mainApp.pointsTable.numberOfMeasures(ii)     = height(stationMeasures);
                    app.mainApp.pointsTable.numberOfRiskMeasures(ii) = sum(stationMeasures.FieldValue > app.mainApp.General.ExternalRequest.FieldValue);
                    app.mainApp.pointsTable.minFieldValue(ii)        = min(stationMeasures.FieldValue);
                    app.mainApp.pointsTable.meanFieldValue(ii)       = mean(stationMeasures.FieldValue);
                    app.mainApp.pointsTable.maxFieldValue(ii)        = maxFieldValue;
                    app.mainApp.pointsTable.maxFieldLatitude(ii)     = stationMeasures.Latitude(idxMaxFieldValue);
                    app.mainApp.pointsTable.maxFieldLongitude(ii)    = stationMeasures.Longitude(idxMaxFieldValue);

                else
                    app.mainApp.pointsTable.numberOfMeasures(ii)     = 0;
                    app.mainApp.pointsTable.numberOfRiskMeasures(ii) = 0;
                    app.mainApp.pointsTable.minFieldValue(ii)        = 0;
                    app.mainApp.pointsTable.meanFieldValue(ii)       = 0;
                    app.mainApp.pointsTable.maxFieldValue(ii)        = 0;
                    app.mainApp.pointsTable.maxFieldLatitude(ii)     = 0;
                    app.mainApp.pointsTable.maxFieldLongitude(ii)    = 0;
                end

                app.mainApp.pointsTable.minDistanceForMeasure(ii)= min(stationDistance); % km
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
            
            app.mainApp    = mainapp;
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

            appBackDoor(app.mainApp, app, 'closeFcn', 'EXTERNALREQUEST')
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
            defaultName   = appUtil.DefaultFileName(app.mainApp.General.fileFolder.userPath, 'RNI', '-1');
            fileZIP       = appUtil.modalWindow(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
            if isempty(fileZIP)
                return
            end

            app.progressDialog.Visible = 'visible';

            try
                fileBasename = appUtil.DefaultFileName(app.mainApp.General.fileFolder.userPath, 'RNI', '-1');
                hPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');
                msgWarning = fileWriter.KML(app.mainApp.stationTable, app.UITable.UserData, app.measTable, fileBasename, fileZIP, hPlot);
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

        % Callback function
        function UITreeCheckedNodesChanged(app, event)
            
            app.progressDialog.Visible = 'visible';
            % Analysis(app)
            app.progressDialog.Visible = 'hidden';

        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)

            idxStation = app.UITable.UserData(event.Indices(1));
            app.mainApp.stationTable.("Justificativa")(idxStation) = event.NewData;
            
            layout_TableStyle(app)

        end

        % Double-clicked callback: UITable
        function UITableDoubleClicked(app, event)
            
            EditFieldRow = event.InteractionInformation.DisplayRow;
            plot_SelectedStation(app,EditFieldRow)

        end

        % Image clicked function: pointAddImage
        function Button_AddPointsPushed(app, event)
             
            % VALIDAÇÃO
            if (app.pointLatitude.Value == -1) && (app.pointLongitude.Value == -1)
                msgQuestion   = 'Os valores de latitude e longitude não foram editados. Deseja continuar?';
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end
            end

            % ADICIONA REGISTRO DE PONTO CRÍTICO
            switch app.pointType.Value
                case 'Estação'
                    ID = sprintf('Estação nº %d', app.pointStation.Value);
                otherwise
                    ID = app.pointType.Value;
            end
            ID = sprintf('%s @ (%.6f, %.6f)', ID, app.pointLatitude.Value, app.pointLongitude.Value);

            app.mainApp.pointsTable(end+1,[1:6, end]) = {ID,                         ...
                                                         app.pointType.Value,        ...
                                                         app.pointStation.Value,     ...
                                                         app.pointLatitude.Value,    ...
                                                         app.pointLongitude.Value,   ...
                                                         app.pointDescription.Value, ...
                                                         false};

            % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
            TreeBuilding(app)

            % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
            % Analysis(app)

     
        end

        % Callback function
        function DropDown_UFValueChanged(app, event)
            %Armazena em ER_UO as informações das URs da tabela do PA_RNI  
            RNI_UF = app.Data_Localidades.('UF');
            
            %Busca na Base de dados do PA_RNI as localidades da Unidade Operacional selecionada 
            Index_Local_UF   = find(strcmp(RNI_UF, app.DropDown_UF.Value));

            RNI_Localidades  = unique(app.Data_Localidades.Municipios(Index_Local_UF)); 

            app.DropDown_Local.Items = "";

            app.DropDown_Local.Items = [""; RNI_Localidades];

            %Armazena em ER_UO as informações das URs da tabela do PA_RNI  
            RNI_Serv = app.Data_Serv_Rad_Tel.Servico;

            app.DropDown_Serv.Items = "";

            app.DropDown_Serv.Items = [""; RNI_Serv];
        end

        % Value changed function: pointType
        function pointTypeValueChanged(app, event)
            
            switch app.pointType.Value
                case 'Estação'
                    app.pointStation.Enable = 1;
                    set(app.pointLatitude,  'Value', -1, 'Enable', 0)
                    set(app.pointLongitude, 'Value', -1, 'Enable', 0)

                otherwise
                    set(app.pointStation, 'Value', -1, 'Enable', 0)
                    app.pointLatitude.Enable  = 1;
                    app.pointLongitude.Enable = 1;
            end

            if isempty(app.pointType.Value)
                app.pointAddImage.Enable = 0;
            else
                app.pointAddImage.Enable = 1;
            end

        end

        % Value changed function: pointStation
        function pointStationValueChanged(app, event)
            
            idxRFDataHub = find(app.mainApp.rfDataHub.Station == app.pointStation.Value, 1);

            if ~isempty(idxRFDataHub)
                latStation  = app.mainApp.rfDataHub.Latitude(idxRFDataHub);
                longStation = app.mainApp.rfDataHub.Longitude(idxRFDataHub);

                set(app.pointLatitude,  'Value', latStation,  'Enable', 1)
                set(app.pointLongitude, 'Value', longStation, 'Enable', 1)
            else
                set(app.pointLatitude,  'Value', -1, 'Enable', 1)
                set(app.pointLongitude, 'Value', -1, 'Enable', 1)
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
            app.plotPanel.Layout.Row = [2 4];
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
            app.UITable.ColumnName = {'ID'; 'Descrição'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Dmin|(km)'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'Justificativa'};
            app.UITable.ColumnWidth = {'auto', 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.ColumnEditable = [false true false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.DoubleClickedFcn = createCallbackFcn(app, @UITableDoubleClicked, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 5;
            app.UITable.Layout.Column = [4 6];
            app.UITable.FontSize = 10;

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, 22, '1x', 22};
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

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.toolGrid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 5;

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.toolGrid);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @tool_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Tooltip = {'Exporta plot e tabela como arquivos'; '(.KML e .XLSX)'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 3;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.GridLayout);
            app.GridLayout2.ColumnWidth = {'1x', 68, 12};
            app.GridLayout2.RowHeight = {22, 32, 168, 12, '1x', 22};
            app.GridLayout2.RowSpacing = 5;
            app.GridLayout2.Padding = [0 0 0 0];
            app.GridLayout2.Layout.Row = [2 5];
            app.GridLayout2.Layout.Column = 2;
            app.GridLayout2.BackgroundColor = [1 1 1];

            % Create play_ControlsTab1Grid_2
            app.play_ControlsTab1Grid_2 = uigridlayout(app.GridLayout2);
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
            app.play_ControlsTab1Image_2.ImageSource = 'Classification_128.png';

            % Create menu_Button1Label
            app.menu_Button1Label = uilabel(app.play_ControlsTab1Grid_2);
            app.menu_Button1Label.FontSize = 11;
            app.menu_Button1Label.Layout.Row = 1;
            app.menu_Button1Label.Layout.Column = 2;
            app.menu_Button1Label.Text = 'DEMANDAS EXTERNAS';

            % Create pointAddImage
            app.pointAddImage = uiimage(app.GridLayout2);
            app.pointAddImage.ImageClickedFcn = createCallbackFcn(app, @Button_AddPointsPushed, true);
            app.pointAddImage.Enable = 'off';
            app.pointAddImage.Layout.Row = 4;
            app.pointAddImage.Layout.Column = 3;
            app.pointAddImage.VerticalAlignment = 'bottom';
            app.pointAddImage.ImageSource = 'addSymbol_32.png';

            % Create pointTree
            app.pointTree = uitree(app.GridLayout2);
            app.pointTree.FontSize = 11;
            app.pointTree.Layout.Row = 5;
            app.pointTree.Layout.Column = [1 3];

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout2);
            app.Panel_2.Layout.Row = 3;
            app.Panel_2.Layout.Column = [1 3];

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.Panel_2);
            app.GridLayout5.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout5.RowHeight = {17, 22, 22, 22, 22, 22};
            app.GridLayout5.RowSpacing = 5;
            app.GridLayout5.Padding = [10 10 10 5];
            app.GridLayout5.BackgroundColor = [1 1 1];

            % Create pointTypeLabel
            app.pointTypeLabel = uilabel(app.GridLayout5);
            app.pointTypeLabel.VerticalAlignment = 'bottom';
            app.pointTypeLabel.FontSize = 10;
            app.pointTypeLabel.Layout.Row = 1;
            app.pointTypeLabel.Layout.Column = 1;
            app.pointTypeLabel.Text = 'Tipologia:';

            % Create pointType
            app.pointType = uidropdown(app.GridLayout5);
            app.pointType.Items = {''};
            app.pointType.ValueChangedFcn = createCallbackFcn(app, @pointTypeValueChanged, true);
            app.pointType.FontSize = 11;
            app.pointType.BackgroundColor = [1 1 1];
            app.pointType.Layout.Row = 2;
            app.pointType.Layout.Column = [1 3];
            app.pointType.Value = '';

            % Create pointStationLabel
            app.pointStationLabel = uilabel(app.GridLayout5);
            app.pointStationLabel.VerticalAlignment = 'bottom';
            app.pointStationLabel.FontSize = 10;
            app.pointStationLabel.Layout.Row = 3;
            app.pointStationLabel.Layout.Column = 1;
            app.pointStationLabel.Text = 'Estação:';

            % Create pointStation
            app.pointStation = uieditfield(app.GridLayout5, 'numeric');
            app.pointStation.Limits = [-1 Inf];
            app.pointStation.RoundFractionalValues = 'on';
            app.pointStation.ValueDisplayFormat = '%d';
            app.pointStation.ValueChangedFcn = createCallbackFcn(app, @pointStationValueChanged, true);
            app.pointStation.HorizontalAlignment = 'left';
            app.pointStation.FontSize = 11;
            app.pointStation.Enable = 'off';
            app.pointStation.Layout.Row = 4;
            app.pointStation.Layout.Column = 1;
            app.pointStation.Value = -1;

            % Create pointLatitudeLabel
            app.pointLatitudeLabel = uilabel(app.GridLayout5);
            app.pointLatitudeLabel.VerticalAlignment = 'bottom';
            app.pointLatitudeLabel.FontSize = 10;
            app.pointLatitudeLabel.Layout.Row = 3;
            app.pointLatitudeLabel.Layout.Column = 2;
            app.pointLatitudeLabel.Text = 'Latitude:';

            % Create pointLatitude
            app.pointLatitude = uieditfield(app.GridLayout5, 'numeric');
            app.pointLatitude.Limits = [-90 90];
            app.pointLatitude.ValueDisplayFormat = '%.6f';
            app.pointLatitude.HorizontalAlignment = 'left';
            app.pointLatitude.FontSize = 11;
            app.pointLatitude.Layout.Row = 4;
            app.pointLatitude.Layout.Column = 2;
            app.pointLatitude.Value = -1;

            % Create pointLongitudeLabel
            app.pointLongitudeLabel = uilabel(app.GridLayout5);
            app.pointLongitudeLabel.VerticalAlignment = 'bottom';
            app.pointLongitudeLabel.FontSize = 10;
            app.pointLongitudeLabel.Layout.Row = 3;
            app.pointLongitudeLabel.Layout.Column = 3;
            app.pointLongitudeLabel.Text = 'Longitude:';

            % Create pointLongitude
            app.pointLongitude = uieditfield(app.GridLayout5, 'numeric');
            app.pointLongitude.Limits = [-180 180];
            app.pointLongitude.ValueDisplayFormat = '%.6f';
            app.pointLongitude.HorizontalAlignment = 'left';
            app.pointLongitude.FontSize = 11;
            app.pointLongitude.Layout.Row = 4;
            app.pointLongitude.Layout.Column = 3;
            app.pointLongitude.Value = -1;

            % Create pointDescriptionLabel
            app.pointDescriptionLabel = uilabel(app.GridLayout5);
            app.pointDescriptionLabel.VerticalAlignment = 'bottom';
            app.pointDescriptionLabel.FontSize = 10;
            app.pointDescriptionLabel.Layout.Row = 5;
            app.pointDescriptionLabel.Layout.Column = 1;
            app.pointDescriptionLabel.Text = 'Descrição:';

            % Create pointDescription
            app.pointDescription = uieditfield(app.GridLayout5, 'text');
            app.pointDescription.FontSize = 11;
            app.pointDescription.Layout.Row = 6;
            app.pointDescription.Layout.Column = [1 3];

            % Create LocationListLabel
            app.LocationListLabel = uilabel(app.GridLayout2);
            app.LocationListLabel.VerticalAlignment = 'bottom';
            app.LocationListLabel.FontSize = 10;
            app.LocationListLabel.Layout.Row = 2;
            app.LocationListLabel.Layout.Column = [1 2];
            app.LocationListLabel.Interpreter = 'html';
            app.LocationListLabel.Text = {'PONTOS CRÍTICOS SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionados àquilo que fora pedido pelo demandante)</font>'};

            % Create EditField_DistPont
            app.EditField_DistPont = uieditfield(app.GridLayout2, 'numeric');
            app.EditField_DistPont.ValueDisplayFormat = '%.1f';
            app.EditField_DistPont.HorizontalAlignment = 'left';
            app.EditField_DistPont.FontSize = 11;
            app.EditField_DistPont.Layout.Row = 6;
            app.EditField_DistPont.Layout.Column = [2 3];

            % Create DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel = uilabel(app.GridLayout2);
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel.WordWrap = 'on';
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel.FontSize = 10;
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel.Layout.Row = 6;
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel.Layout.Column = 1;
            app.DistncialimiteentrepontodemedioepontoscrticossobanlisemLabel.Text = 'Distância limite entre ponto de medição e pontos críticos sob análise (m):';

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
