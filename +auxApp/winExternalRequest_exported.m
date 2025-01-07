classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        GridLayout2                  matlab.ui.container.GridLayout
        Panel_2                      matlab.ui.container.Panel
        GridLayout5                  matlab.ui.container.GridLayout
        EditField_LongGrau_2         matlab.ui.control.NumericEditField
        TipologiaLabel               matlab.ui.control.Label
        EditField_LatGrau_2          matlab.ui.control.NumericEditField
        DropDown_Tipo                matlab.ui.control.DropDown
        LongitudeLabel_4             matlab.ui.control.Label
        LatitudeLabel_2              matlab.ui.control.Label
        PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel  matlab.ui.control.Label
        Tree_CoordEnd                matlab.ui.container.Tree
        Panel                        matlab.ui.container.Panel
        GridLayout4                  matlab.ui.container.GridLayout
        EditField_DistPont           matlab.ui.control.NumericEditField
        DistnciamLabel               matlab.ui.control.Label
        DropDown_Local               matlab.ui.control.DropDown
        LocalidadeLabel              matlab.ui.control.Label
        DropDown_Serv                matlab.ui.control.DropDown
        ServioLabel                  matlab.ui.control.Label
        DropDown_UF                  matlab.ui.control.DropDown
        UFLabel                      matlab.ui.control.Label
        EditField_LongGrau           matlab.ui.control.NumericEditField
        EditFieldNEstPont            matlab.ui.control.NumericEditField
        EditField_LatGrau            matlab.ui.control.NumericEditField
        LongitudeLabel_3             matlab.ui.control.Label
        LatitudeLabel                matlab.ui.control.Label
        NEstaoLabel                  matlab.ui.control.Label
        Image                        matlab.ui.control.Image
        ESTAOSOBANLISELabel          matlab.ui.control.Label
        play_ControlsTab1Grid_2      matlab.ui.container.GridLayout
        menu_Button1Label            matlab.ui.control.Label
        play_ControlsTab1Image_2     matlab.ui.control.Image
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
        Data_Localidades       % Dados da Tabela das Localidades do Brasil
        Data_Serv_Rad_Tel      % Dados dos serviços de Radiodifusão e de Telecom fiscalizados pela Anatel 
        %Incremento das estações pontuais
        IncrPoints = 0;  
        Data_Points            % Dados dos pontos (locais) de interesses nas demandas pontuais        
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
            % Analysis(app)

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
            % startup_TreeBuilding(app)

            app.tool_TableVisibility.UserData = 1;

            % Armazena no vetor app.Data_Localidades as localidades do Brasil
            app.Data_Localidades  = fcn.ReadFile_Loc_Serv(app.rootFolder, "Local");

            % Armazena no vetor app.Data_Serv_Rad_Tel a lista de seviços de Radiod. e de Telecom fiscalizados pela Anatel.
            app.Data_Serv_Rad_Tel = fcn.ReadFile_Loc_Serv(app.rootFolder, "Serv");

            % Insere em app.DropDown_UF a lista das UFs do Brasil
            app.DropDown_UF.Items = {'', 'AC', 'AL', 'AM', 'AP', 'BA', 'CE',	'ES', 'GO', 'MA', 'MG', 'MS', 'MT',	'PA', 'PB',	'PE', 'PI',	'PR', 'RJ', 'RN', 'RO',	'RR', 'RS', 'SC', 'SE',	'SP', 'TO'};

            % Insere em app.DropDown_Tipo.Items os tipos de locais
            app.DropDown_Tipo.Items = {'', 'Escola', 'Hospital', 'Creche', 'Escola', 'Casa', 'Apartamento', 'Outros'};
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
                DIST_km = app.General.MonitoringPlan.Distance_km;

                Lat_Point = app.EditField_LatGrau_2.Value;
                Long_Point = app.EditField_LongGrau_2.Value;

                idxStations = [Lat_Point Long_Point];
                identifyMeasuresForEachStation(app, idxStations, DIST_km)

                % Aplica estilo à tabela...
                layout_TableStyle(app)

                % PLOT
                prePlot(app)
                plot_Measures(app)
                plot_Stations(app)

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
                % idxStations    = app.UITable.UserData;
                latitudeArray  = app.CallingApp.stationTable.("Latitude da Estação")(app.IncrPoints);
                longitudeArray = app.CallingApp.stationTable.("Longitude da Estação")(app.IncrPoints);

                geoscatter(app.UIAxes, latitudeArray, longitudeArray, ...
                    'Marker', '^', 'MarkerFaceColor', app.General.Plot.Stations.Color, ...
                    'MarkerEdgeColor', app.General.Plot.Stations.Color,           ...
                    'SizeData',        app.General.Plot.Stations.Size,            ...
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
                stationLatitude    = app.CallingApp.stationTable.("Latitude da Estação")(Station);
                stationLongitude   = app.CallingApp.stationTable.("Longitude da Estação")(Station);
                stationNumber      = sprintf('Estação nº %d', app.CallingApp.stationTable.("N° da Estacao")(Station));

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
                maxFieldValue      = app.CallingApp.stationTable.maxFieldValue(Station);
                if maxFieldValue > 0
                    maxFieldLatitude   = app.CallingApp.stationTable.maxFieldLatitude(Station);
                    maxFieldLongitude  = app.CallingApp.stationTable.maxFieldLongitude(Station);
    
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
                % if app.CallingApp.stationTable.AnalysisFlag(ii)
                %     continue
                % end


                % Inicialmente, afere a distância da estação a cada uma das
                % medidas, identificando aquelas no entorno.
                DIST_km = app.EditField_DistPont.Value;
                stationDistance    = deg2km(distance(idxStations(1), idxStations(2), app.measTable.Latitude, app.measTable.Longitude));                
                idxLogicalMeasures = stationDistance <= DIST_km;

                % if any(idxLogicalMeasures)
                    stationMeasures = app.measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(stationMeasures.FieldValue);

                 if app.IncrPoints ==1
                    app.CallingApp.stationTable = app.CallingApp.stationTable([], :); % Remove todas as linhas
                 end
                    
                    app.CallingApp.stationTable.('Location')(app.IncrPoints) = {[app.DropDown_Local.Value '/' app.DropDown_UF.Value]};
                    app.CallingApp.stationTable.('Latitude da Estação')(app.IncrPoints) = app.EditField_LatGrau_2.Value;
                    app.CallingApp.stationTable.('Longitude da Estação')(app.IncrPoints) = app.EditField_LongGrau_2.Value;

                    app.CallingApp.stationTable.('Serviço')(app.IncrPoints) = {app.DropDown_Serv.Value};
                    app.CallingApp.stationTable.('N° da Estacao')(app.IncrPoints) = app.EditFieldNEstPont.Value;

                    app.CallingApp.stationTable.('numberOfMeasures')(app.IncrPoints) = height(stationMeasures);
                    app.CallingApp.stationTable.('numberOfRiskMeasures')(app.IncrPoints) = sum(stationMeasures.FieldValue > app.General.MonitoringPlan.FieldValue);
                    if ~isempty(stationMeasures)
                        app.CallingApp.stationTable.('minFieldValue')(app.IncrPoints) = min(stationMeasures.FieldValue);
                        app.CallingApp.stationTable.('meanFieldValue')(app.IncrPoints) = mean(stationMeasures.FieldValue);
                        app.CallingApp.stationTable.('maxFieldValue')(app.IncrPoints) = maxFieldValue;
                    end


                 % app.UITable.Data = app.CallingApp.stationTable;
                 selectedColumns = {'Location', 'Serviço','N° da Estacao','numberOfMeasures', 'numberOfRiskMeasures', 'minFieldValue',   'meanFieldValue', 'maxFieldValue', 'Justificativa'};
                 set(app.UITable, 'Data', app.CallingApp.stationTable(:, selectedColumns));

                 % app.UITable.Data = app.UITable.Data([],:);

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

        % Callback function
        function UITreeCheckedNodesChanged(app, event)
            
            app.progressDialog.Visible = 'visible';
            % Analysis(app)
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
            
            EditFieldRow = event.InteractionInformation.DisplayRow;
            plot_SelectedStation(app,EditFieldRow)

        end

        % Image clicked function: Image
        function Button_AddPointsPushed(app, event)
             Incr_Node = app.IncrPoints+1;

            % % Criar um nó raiz 'Locais'
            % rootNode = uitreenode(app.Tree_CoordEnd, 'Text', 'Locais');
            
            struct_points = struct('Type_Point', app.DropDown_Tipo.Value, ...
                                   'Latitude'  , app.EditField_LatGrau_2.Value, ...
                                   'Longitude' , app.EditField_LongGrau_2.Value);

            AllValues = sprintf('%dº) Tipo: %s: Lat = %.6f, Long = %.6f',Incr_Node,app.DropDown_Tipo.Value, app.EditField_LatGrau_2.Value, app.EditField_LongGrau_2.Value);

            app.Data_Points = [app.Data_Points, struct_points];

            % Escreve na app.Tree as informações relacionadas a localidade correpondente a Unidade Regional selecionada 
            uitreenode(app.Tree_CoordEnd, 'Text', AllValues);
           
            expand(app.Tree_CoordEnd)

            app.IncrPoints = app.IncrPoints +1;

            % if app.IncrPoints == 1
                % Dist_Max_Level = app.EditField_DistPont.Value;
                % Latitude_Pont  = app.EditField_LatGrau.Value ; 
                % Longitude_Pont = app.EditField_LongGrau.Value;

                Analysis(app)

     
        end

        % Value changed function: DropDown_UF
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
            app.GridLayout2.ColumnWidth = {'1x', 22};
            app.GridLayout2.RowHeight = {22, 22, 180, 22, '1x', 12, 260};
            app.GridLayout2.ColumnSpacing = 5;
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
            app.play_ControlsTab1Grid_2.Layout.Column = [1 2];
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

            % Create ESTAOSOBANLISELabel
            app.ESTAOSOBANLISELabel = uilabel(app.GridLayout2);
            app.ESTAOSOBANLISELabel.VerticalAlignment = 'bottom';
            app.ESTAOSOBANLISELabel.FontSize = 10;
            app.ESTAOSOBANLISELabel.Layout.Row = 2;
            app.ESTAOSOBANLISELabel.Layout.Column = 1;
            app.ESTAOSOBANLISELabel.Text = 'ESTAÇÃO SOB ANÁLISE';

            % Create Image
            app.Image = uiimage(app.GridLayout2);
            app.Image.ImageClickedFcn = createCallbackFcn(app, @Button_AddPointsPushed, true);
            app.Image.Layout.Row = 6;
            app.Image.Layout.Column = 2;
            app.Image.VerticalAlignment = 'bottom';
            app.Image.ImageSource = 'addSymbol_32.png';

            % Create Panel
            app.Panel = uipanel(app.GridLayout2);
            app.Panel.Layout.Row = 3;
            app.Panel.Layout.Column = [1 2];

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.Panel);
            app.GridLayout4.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout4.RowHeight = {'fit', 22, 'fit', 22, 'fit', 22, 22, 17, 22};
            app.GridLayout4.BackgroundColor = [1 1 1];

            % Create NEstaoLabel
            app.NEstaoLabel = uilabel(app.GridLayout4);
            app.NEstaoLabel.VerticalAlignment = 'bottom';
            app.NEstaoLabel.FontSize = 10;
            app.NEstaoLabel.Layout.Row = 1;
            app.NEstaoLabel.Layout.Column = 1;
            app.NEstaoLabel.Text = 'Nº Estação:';

            % Create LatitudeLabel
            app.LatitudeLabel = uilabel(app.GridLayout4);
            app.LatitudeLabel.VerticalAlignment = 'bottom';
            app.LatitudeLabel.FontSize = 10;
            app.LatitudeLabel.Layout.Row = 1;
            app.LatitudeLabel.Layout.Column = 2;
            app.LatitudeLabel.Text = 'Latitude:';

            % Create LongitudeLabel_3
            app.LongitudeLabel_3 = uilabel(app.GridLayout4);
            app.LongitudeLabel_3.VerticalAlignment = 'bottom';
            app.LongitudeLabel_3.FontSize = 10;
            app.LongitudeLabel_3.Layout.Row = 1;
            app.LongitudeLabel_3.Layout.Column = 3;
            app.LongitudeLabel_3.Text = 'Longitude:';

            % Create EditField_LatGrau
            app.EditField_LatGrau = uieditfield(app.GridLayout4, 'numeric');
            app.EditField_LatGrau.ValueDisplayFormat = '%.6f';
            app.EditField_LatGrau.HorizontalAlignment = 'left';
            app.EditField_LatGrau.FontSize = 11;
            app.EditField_LatGrau.Layout.Row = 2;
            app.EditField_LatGrau.Layout.Column = 2;

            % Create EditFieldNEstPont
            app.EditFieldNEstPont = uieditfield(app.GridLayout4, 'numeric');
            app.EditFieldNEstPont.ValueDisplayFormat = '%d';
            app.EditFieldNEstPont.HorizontalAlignment = 'left';
            app.EditFieldNEstPont.FontSize = 11;
            app.EditFieldNEstPont.Layout.Row = 2;
            app.EditFieldNEstPont.Layout.Column = 1;

            % Create EditField_LongGrau
            app.EditField_LongGrau = uieditfield(app.GridLayout4, 'numeric');
            app.EditField_LongGrau.ValueDisplayFormat = '%.6f';
            app.EditField_LongGrau.HorizontalAlignment = 'left';
            app.EditField_LongGrau.FontSize = 11;
            app.EditField_LongGrau.Layout.Row = 2;
            app.EditField_LongGrau.Layout.Column = 3;

            % Create UFLabel
            app.UFLabel = uilabel(app.GridLayout4);
            app.UFLabel.VerticalAlignment = 'bottom';
            app.UFLabel.FontSize = 10;
            app.UFLabel.Layout.Row = 3;
            app.UFLabel.Layout.Column = 1;
            app.UFLabel.Text = 'UF:';

            % Create DropDown_UF
            app.DropDown_UF = uidropdown(app.GridLayout4);
            app.DropDown_UF.Items = {};
            app.DropDown_UF.ValueChangedFcn = createCallbackFcn(app, @DropDown_UFValueChanged, true);
            app.DropDown_UF.FontSize = 11;
            app.DropDown_UF.BackgroundColor = [1 1 1];
            app.DropDown_UF.Layout.Row = 4;
            app.DropDown_UF.Layout.Column = 1;
            app.DropDown_UF.Value = {};

            % Create ServioLabel
            app.ServioLabel = uilabel(app.GridLayout4);
            app.ServioLabel.VerticalAlignment = 'bottom';
            app.ServioLabel.FontSize = 10;
            app.ServioLabel.Layout.Row = 5;
            app.ServioLabel.Layout.Column = 1;
            app.ServioLabel.Text = 'Serviço:';

            % Create DropDown_Serv
            app.DropDown_Serv = uidropdown(app.GridLayout4);
            app.DropDown_Serv.Items = {''};
            app.DropDown_Serv.FontSize = 11;
            app.DropDown_Serv.BackgroundColor = [1 1 1];
            app.DropDown_Serv.Layout.Row = 6;
            app.DropDown_Serv.Layout.Column = [1 2];
            app.DropDown_Serv.Value = '';

            % Create LocalidadeLabel
            app.LocalidadeLabel = uilabel(app.GridLayout4);
            app.LocalidadeLabel.VerticalAlignment = 'bottom';
            app.LocalidadeLabel.FontSize = 10;
            app.LocalidadeLabel.Layout.Row = 3;
            app.LocalidadeLabel.Layout.Column = 2;
            app.LocalidadeLabel.Text = 'Localidade:';

            % Create DropDown_Local
            app.DropDown_Local = uidropdown(app.GridLayout4);
            app.DropDown_Local.Items = {};
            app.DropDown_Local.FontSize = 11;
            app.DropDown_Local.BackgroundColor = [1 1 1];
            app.DropDown_Local.Layout.Row = 4;
            app.DropDown_Local.Layout.Column = [2 3];
            app.DropDown_Local.Value = {};

            % Create DistnciamLabel
            app.DistnciamLabel = uilabel(app.GridLayout4);
            app.DistnciamLabel.FontSize = 10;
            app.DistnciamLabel.Layout.Row = 5;
            app.DistnciamLabel.Layout.Column = 3;
            app.DistnciamLabel.Text = 'Distância (m):';

            % Create EditField_DistPont
            app.EditField_DistPont = uieditfield(app.GridLayout4, 'numeric');
            app.EditField_DistPont.ValueDisplayFormat = '%.1f';
            app.EditField_DistPont.HorizontalAlignment = 'left';
            app.EditField_DistPont.FontSize = 11;
            app.EditField_DistPont.Layout.Row = 6;
            app.EditField_DistPont.Layout.Column = 3;

            % Create Tree_CoordEnd
            app.Tree_CoordEnd = uitree(app.GridLayout2);
            app.Tree_CoordEnd.Layout.Row = 7;
            app.Tree_CoordEnd.Layout.Column = [1 2];

            % Create PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel = uilabel(app.GridLayout2);
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.VerticalAlignment = 'bottom';
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.FontSize = 10;
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Layout.Row = 4;
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Layout.Column = [1 2];
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Text = 'PONTOS CRÍTICOS NO ENTORNO DA ESTAÇÃO SOB ANÁLISE';

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout2);
            app.Panel_2.Layout.Row = 5;
            app.Panel_2.Layout.Column = [1 2];

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.Panel_2);
            app.GridLayout5.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout5.RowHeight = {17, '1x'};
            app.GridLayout5.BackgroundColor = [1 1 1];

            % Create LatitudeLabel_2
            app.LatitudeLabel_2 = uilabel(app.GridLayout5);
            app.LatitudeLabel_2.VerticalAlignment = 'bottom';
            app.LatitudeLabel_2.FontSize = 10;
            app.LatitudeLabel_2.Layout.Row = 1;
            app.LatitudeLabel_2.Layout.Column = 2;
            app.LatitudeLabel_2.Text = 'Latitude:';

            % Create LongitudeLabel_4
            app.LongitudeLabel_4 = uilabel(app.GridLayout5);
            app.LongitudeLabel_4.VerticalAlignment = 'bottom';
            app.LongitudeLabel_4.FontSize = 10;
            app.LongitudeLabel_4.Layout.Row = 1;
            app.LongitudeLabel_4.Layout.Column = 3;
            app.LongitudeLabel_4.Text = 'Longitude:';

            % Create DropDown_Tipo
            app.DropDown_Tipo = uidropdown(app.GridLayout5);
            app.DropDown_Tipo.Items = {''};
            app.DropDown_Tipo.FontSize = 11;
            app.DropDown_Tipo.BackgroundColor = [1 1 1];
            app.DropDown_Tipo.Layout.Row = 2;
            app.DropDown_Tipo.Layout.Column = 1;
            app.DropDown_Tipo.Value = '';

            % Create EditField_LatGrau_2
            app.EditField_LatGrau_2 = uieditfield(app.GridLayout5, 'numeric');
            app.EditField_LatGrau_2.ValueDisplayFormat = '%.6f';
            app.EditField_LatGrau_2.HorizontalAlignment = 'left';
            app.EditField_LatGrau_2.FontSize = 11;
            app.EditField_LatGrau_2.Layout.Row = 2;
            app.EditField_LatGrau_2.Layout.Column = 2;

            % Create TipologiaLabel
            app.TipologiaLabel = uilabel(app.GridLayout5);
            app.TipologiaLabel.VerticalAlignment = 'bottom';
            app.TipologiaLabel.FontSize = 10;
            app.TipologiaLabel.Layout.Row = 1;
            app.TipologiaLabel.Layout.Column = 1;
            app.TipologiaLabel.Text = 'Tipologia:';

            % Create EditField_LongGrau_2
            app.EditField_LongGrau_2 = uieditfield(app.GridLayout5, 'numeric');
            app.EditField_LongGrau_2.ValueDisplayFormat = '%.6f';
            app.EditField_LongGrau_2.HorizontalAlignment = 'left';
            app.EditField_LongGrau_2.FontSize = 11;
            app.EditField_LongGrau_2.Layout.Row = 2;
            app.EditField_LongGrau_2.Layout.Column = 3;

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
