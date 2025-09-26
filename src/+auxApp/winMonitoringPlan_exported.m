classdef winMonitoringPlan_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        TabGroup                     matlab.ui.container.TabGroup
        PMRNITab                     matlab.ui.container.Tab
        Control                      matlab.ui.container.GridLayout
        Card4_stationsOutRoute       matlab.ui.control.Label
        Card3_stationsOnRoute        matlab.ui.control.Label
        Card2_numberOfRiskStations   matlab.ui.control.Label
        Card1_numberOfStations       matlab.ui.control.Label
        LocationList                 matlab.ui.control.TextArea
        LocationListEdit             matlab.ui.control.Image
        LocationListLabel            matlab.ui.control.Label
        TreeFileLocations            matlab.ui.container.Tree
        config_geoAxesLabel_2        matlab.ui.control.Label
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
        tool_TableEdition            matlab.ui.control.Image
        tool_TableVisibility         matlab.ui.control.Image
        tool_ControlPanelVisibility  matlab.ui.control.Image
        ContextMenu                  matlab.ui.container.ContextMenu
        EditSelectedUITableRow       matlab.ui.container.Menu
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
        % ESPECIFICIDADES AUXAPP.WINMONITORINGPLAN
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

                            case 'MonitoringPlan:AnalysisParameterChanged'
                                app.UITable.ColumnName{5} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.MonitoringPlan.FieldValue);
                                updateAnalysis(app.projectData, app.measData, app.mainApp.General, operationType);
                                Analysis(app)

                            case 'MonitoringPlan:AxesParameterChanged'
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

                            case 'MonitoringPlan:PlotParameterChanged'
                                Analysis(app)

                            otherwise
                                error('UnexpectedCall')
                        end

                    case {'auxApp.dockStationInfo',    'auxApp.dockStationInfo_exported', ...
                          'auxApp.dockListOfLocation', 'auxApp.dockListOfLocation_exported'}

                        % Chamadas implementadas:
                        % (a) 'StationTableValueChanged: ReasonOrNote'
                        %     Atualizam-se as colunas "Justificativa" e "Observações" da "tabela mãe"
                        %     (app.projectData.modules.MonitoringPlan.stationTable), além da coluna "Justificativa" da uitable 
                        %     (já que a coluna "Observações" não é renderizada na uitable).
                        %
                        % (b) 'StationTableValueChanged: Location'
                        %     Atualizam-se as colunas "Latitude", "Longitude" e "AnalysisFlag" da "tabela mãe"
                        %     (app.projectData.modules.MonitoringPlan.stationTable), executando-se novamente a análise.
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
                                    app.projectData.modules.MonitoringPlan.stationTable.("Justificativa")(idxStation) = newReason;
                                    app.projectData.modules.MonitoringPlan.stationTable.("Observações"){idxStation}   = newObservation;
                                    app.UITable.Data.("Justificativa")(idxRow)             = newReason;
                                    layout_TableStyle(app)

                                case 'MonitoringPlan:StationCoordinatesEdited'
                                    newLatitude  = varargin{3};
                                    newLongitude = varargin{4};

                                    idxStation   = selectedStation(app);
                                    app.projectData.modules.MonitoringPlan.stationTable.("Latitude")(idxStation)  = newLatitude;
                                    app.projectData.modules.MonitoringPlan.stationTable.("Longitude")(idxStation) = newLongitude;
                                    app.projectData.modules.MonitoringPlan.stationTable.AnalysisFlag(idxStation)  = false;

                                    updateAnalysis(app.projectData, app.measData, app.mainApp.General, operationType)
                                    Analysis(app)

                                case 'UITableSelectionChanged'
                                    newRowSelection = varargin{3};
                                    app.UITable.Selection = newRowSelection;
                                    scroll(app.UITable, 'row', newRowSelection)

                                    UITableSelectionChanged(app, struct('PreviousSelection', [], 'Selection', newRowSelection))

                                case 'MonitoringPlan:ManualLocationListChanged'
                                    updateAnalysis(app.projectData, app.measData, app.mainApp.General, operationType)
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
                customizationStatus = [false];
            end

            switch tabIndex
                case 0 % STARTUP
                    if app.isDocked
                        app.progressDialog = app.mainApp.progressDialog;
                    else
                        sendEventToHTMLSource(app.jsBackDoor, 'startup', app.mainApp.executionMode);
                        app.progressDialog = ccTools.ProgressDialog(app.jsBackDoor);                        
                    end
                    customizationStatus = [false];

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
                            elToModify = {app.AxesToolbar};
                            elDataTag  = ui.CustomizationBase.getElementsDataTag(elToModify);
                            if ~isempty(elDataTag)
                                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                                    struct('appName', appName, 'dataTag', elDataTag{1}, 'styleImportant', struct('borderTopLeftRadius', '0', 'borderTopRightRadius', '0')), ...
                                });
                            end

                        otherwise
                            % Customização de componentes constantes nas outras abas, 
                            % os quais são renderizados completamente apenas após a 
                            % abertura da aba.
                            % ...
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
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.dockModule_Undock.Enable = 1;
            end

            if app.mainApp.General.MonitoringPlan.FieldValue ~= 14
                app.UITable.ColumnName{5} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.MonitoringPlan.FieldValue);
            end

            [app.UIAxes, app.restoreView] = plot.axesCreationController(app.plotPanel, app.mainApp.General);
            
            TreeFileLocationBuilding(app)
            if ~isempty(app.measData)
                Analysis(app)
            end
                        
            app.tool_TableVisibility.UserData = 1;
        end

        %-----------------------------------------------------------------%
        function menu_LayoutPopupApp(app, auxiliarApp, varargin)
            arguments
                app
                auxiliarApp char {mustBeMember(auxiliarApp, {'ListOfLocation', 'StationInfo'})}
            end

            arguments (Repeating)
                varargin 
            end

            % Inicialmente ajusta as dimensões do container.
            switch auxiliarApp
                case 'ListOfLocation'
                    screenWidth  = 540;
                    screenHeight = 440;
                case 'StationInfo'
                    screenWidth  = 540;
                    screenHeight = 440;
            end

            ui.PopUpContainer(app, class.Constants.appName, screenWidth, screenHeight)

            % Executa o app auxiliar.
            inputArguments = [{app}, varargin];
            
            if app.mainApp.General.operationMode.Debug
                eval(sprintf('auxApp.dock%s(inputArguments{:})', auxiliarApp))
            else
                eval(sprintf('auxApp.dock%s_exported(app.popupContainer, inputArguments{:})', auxiliarApp))
                app.popupContainer.Parent.Visible = 1;
            end            
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
                'MonitoringPlan' ...
            )

            fullListOfLocation = getFullListOfLocation( ...
                app.projectData, ...
                app.measData(idxFile), ...
                app.mainApp.General.MonitoringPlan.Distance_km ...
            );

            idxStations = find(ismember(app.projectData.modules.MonitoringPlan.stationTable.Location, fullListOfLocation));
            initialSelection = updateTable(app, idxStations);
            layout_TableStyle(app)

            % Atualiza outros elementos da GUI, inclusive painel com quantitativo 
            % de estações.
            updatePanel(app, fullListOfLocation, idxStations)

            % Atualiza plot.
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
            if ~isempty(app.TreeFileLocations.SelectedNodes)
                selectedFileLocations = {app.TreeFileLocations.SelectedNodes.Text};
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

            table2Render = app.projectData.modules.MonitoringPlan.stationTable(idxStations, {'Estação',               ...
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
            app.Card2_numberOfRiskStations.Text = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE %.0f V/m</p></p>', nRiskStations, app.mainApp.General.MonitoringPlan.FieldValue);
            app.Card3_stationsOnRoute .Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: black;   font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>',                           nStationsOnRoute);
            app.Card4_stationsOutRoute.Text     = sprintf('<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">%d</font>\nESTAÇÕES INSTALADAS FORA DA ROTA</p>',                                 nStationsOutRoute);
            layout_updatePeakInfo(app)
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
                refPointsTable = app.projectData.modules.MonitoringPlan.stationTable(idxStations, :);

                plot.draw.Points(app.UIAxes, refPointsTable, 'Estações de referência PM-RNI', app.mainApp.General)
            end
            plot_AxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plot_SelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.UserData(app.UITable.Selection);
                selectedPointTable = app.projectData.modules.MonitoringPlan.stationTable(idxSelectedPoint, :);

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
        function [idxMissingInfo, idxManualEdition, idxRiskMeasures, idxUpload2POST] = layout_searchUnexpectedTableValues(app)
            idxMissingInfo   = [];
            idxManualEdition = [];
            idxRiskMeasures  = [];
            idxUpload2POST   = [];

            if ~isempty(app.UITable.Data)
                % Tabela sob análise.                
                idxStations = app.UITable.UserData;
                relatedStationTable = app.projectData.modules.MonitoringPlan.stationTable(idxStations, :);

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
                    s2 = uistyle('Icon', 'Edit_32.png', 'IconAlignment', 'leftmargin');
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

                app.tool_UploadFinalFile.Enable = isempty(idxMissingInfo);
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
                set(app.tool_peakIcon,  'Enable',  1, 'UserData', struct('idxMax',    idxMax,                         ...
                                                                         'Latitude',  app.measTable.Latitude(idxMax), ...
                                                                         'Longitude', app.measTable.Longitude(idxMax)))
            else
                app.tool_peakLabel.Visible = 0;
                app.tool_peakIcon.Enable   = 0;
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

                if strcmp(locationGroups{ii}, app.projectData.modules.MonitoringPlan.ui.selectedGroup)
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
                updateTable(app, []);
                updatePanel(app, {}, [])

                app.tool_TableEdition.Enable    = false;
                app.tool_UploadFinalFile.Enable = false;
            end

            app.LocationListEdit.Enable    = measDataNonEmpty;
            app.tool_GenerateReport.Enable = measDataNonEmpty;
            app.tool_ExportFiles.Enable    = measDataNonEmpty;            
        end

        %-----------------------------------------------------------------%
        function [idxStation, idxRow] = selectedStation(app)
            idxRow     = app.UITable.Selection;
            idxStation = app.UITable.UserData(idxRow);
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
        function menu_DockButtonPushed(app, event)
            
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
        function tool_InteractionImageClicked(app, event)
            
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
            [status, msgError] = fileWriter.MonitoringPlan(fileName_XLSX, app.projectData.modules.MonitoringPlan.stationTable(idxStations, :), timetable2table(app.measTable), app.mainApp.General.MonitoringPlan.FieldValue, app.mainApp.General.MonitoringPlan.Export.XLSX);
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
            
            % <VALIDAÇÕES GERAIS>
            lastHTMLDocFullPath = getGeneratedDocumentFileName(app.projectData, '.html');

            msg = '';
            if ~isfolder(app.mainApp.General.fileFolder.DataHub_POST)
                msg = 'Pendente mapear pasta do Sharepoint';
            elseif ~report_checkEFiscalizaIssueId(app.mainApp, app.reportIssue.Value)
                msg = sprintf('O número da inspeção "%.0f" é inválido.', app.reportIssue.Value);
            elseif isempty(app.reportUnit.Value)
                msg = 'Unidade geradora do documento precisa ser selecionada.';
            elseif isempty(lastHTMLDocFullPath)
                msg = 'A versão definitiva do relatório ainda não foi gerada.';
            elseif ~isfile(lastHTMLDocFullPath)
                msg = sprintf('O arquivo "%s" não foi encontrado.', lastHTMLDocFullPath);
            end

            if ~isempty(msg)
                appUtil.modalWindow(app.UIFigure, 'warning', msg);
                return
            end
            % </VALIDAÇÕES GERAIS>

            % <VALIDAÇÕES ESPECÍFICAS>
            idxStations = app.UITable.UserData;
            relatedStationTable = app.projectData.modules.MonitoringPlan.stationTable(idxStations, :);

            if all(relatedStationTable.UploadResultFlag)
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

            else
                msgQuestion   = 'Confirma a exportação da análise para a pasta "POST" do Sharepoint?';
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end
            end
            % </VALIDAÇÕES ESPECÍFICAS>


            % <PROCESSO>
            app.mainApp.General.Report.userSelection.system        = app.reportSystem.Value;
            app.mainApp.General.Report.userSelection.unit          = app.reportUnit.Value;
            app.mainApp.General.Report.userSelection.issue         = app.reportIssue.Value;
            app.mainApp.General.Report.userSelection.model         = app.reportModelName.Value;
            app.mainApp.General.Report.userSelection.reportVersion = app.reportVersion.Value;


            if isempty(app.mainApp.eFiscalizaObj)
                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');
                sendEventToHTMLSource(app.jsBackDoor, 'customForm', struct('UUID', 'eFiscalizaSignInPage', 'Fields', dialogBox))
            else
                report_uploadInfoController(app.mainApp, [], 'uploadDocument')
            end
            % </PROCESSO>













            % SALVA ARQUIVOS NA PASTA "POST" DO SHAREPOINT (EXCETO QUANDO
            % EXECUTADO EM AMBIENTE DE DESENVOLVIMENTO)
            % if isdeployed()
            %     outputFolder = app.mainApp.General.fileFolder.DataHub_POST;
            %     outputFolderDescription = '"POST" do Sharepoint';
            % else
            %     outputFolder = app.mainApp.General.fileFolder.userPath;
            %     outputFolderDescription = 'do usuário (e não a pasta "POST" do Sharepoint), por se tratar de execução no ambiente de desenvolvimento';
            % end
            % 
            % savedFiles   = {};
            % errorFiles   = {};
            % 
            % % (a) PLANILHA EXCEL
            % fileName_XLSX = [appUtil.DefaultFileName(outputFolder, class.Constants.appName, '-1') '.xlsx'];
            % [status, msgError] = fileWriter.MonitoringPlan(fileName_XLSX, relatedStationTable, [], app.mainApp.General.MonitoringPlan.FieldValue);
            % if status
            %     app.projectData.modules.MonitoringPlan.stationTable.UploadResultFlag(idxStations) = true;
            %     layout_TableStyle(app)
            % 
            %     [~, fileName, fileExt] = fileparts(fileName_XLSX);
            %     savedFiles{end+1} = [fileName, fileExt];
            % else
            %     errorFiles{end+1} = msgError;
            % end
            % 
            % % (b) ARQUIVOS BRUTOS E ARQUIVOS DE METADADOS
            % idxFile = FileIndex(app);
            % for ii = idxFile
            %     % ARQUIVOS BRUTOS
            %     fileName_RAW = fullfile(app.measData(ii).Filepath, app.measData(ii).Filename);
            % 
            %     [status, msgError]    = copyfile(fileName_RAW, outputFolder, 'f');
            %     if status
            %         savedFiles{end+1} = app.measData(ii).Filename;
            %     else
            %         errorFiles{end+1} = msgError;
            %     end
            % 
            %     % ARQUIVOS DE METADADOS
            %     [~, fileName_JSON] = fileparts(fileName_RAW);
            %     fileName_JSON = [fileName_JSON '.json'];
            % 
            %     [status, msgError]    = fileWriter.RawFileMetaData(fullfile(outputFolder, fileName_JSON), app.measData(ii));
            %     if status
            %         savedFiles{end+1} = fileName_JSON;
            %     else
            %         errorFiles{end+1} = msgError;
            %     end
            % end
            % 
            % if ~isempty(savedFiles)
            %     savedFiles = strcat('•&thinsp;', savedFiles);
            %     appUtil.modalWindow(app.UIFigure, 'info', sprintf('Lista de arquivos copiados para a pasta %s:\n%s', outputFolderDescription, strjoin(savedFiles, '\n')));
            % end
            % 
            % if ~isempty(errorFiles)
            %     appUtil.modalWindow(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
            % end

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

            idxStations = app.UITable.UserData;
            idxSelectedStation = idxStations(event.Indices(1));
            
            if ~ismember(event.EditData, app.mainApp.General.MonitoringPlan.NoMeasureReasons)
                app.UITable.Data.("Justificativa") = app.projectData.modules.MonitoringPlan.stationTable.("Justificativa")(idxStations);
                return
            end
                        
            app.projectData.modules.MonitoringPlan.stationTable.("Justificativa")(idxSelectedStation) = event.NewData;
            
            layout_TableStyle(app)

        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            
            if exist('event', 'var') && ~isempty(event.PreviousSelection) && isequal(event.Selection, event.PreviousSelection)
                return
            end

            if isempty(event.Selection)
                app.tool_TableEdition.Enable = "off";
                app.UITable.ContextMenu = [];
            else
                app.tool_TableEdition.Enable = "on";
                if isempty(app.UITable.ContextMenu)
                    app.UITable.ContextMenu = app.ContextMenu;
                end
            end

            plot_SelectedPoint(app)
            
        end

        % Callback function: EditSelectedUITableRow, tool_TableEdition
        function UITableOpenPopUpEditionMode(app, event)
            
            if ~isempty(app.UITable.Selection)
                menu_LayoutPopupApp(app, 'StationInfo')
            end

        end

        % Image clicked function: LocationListEdit
        function LocationListEditClicked(app, event)
            
            menu_LayoutPopupApp(app, 'ListOfLocation', FileIndex(app))

        end

        % Image clicked function: tool_GenerateReport
        function tool_GenerateReportImageClicked(app, event)

            % <VALIDAÇÕES>
            msg = {};
            if ~report_checkEFiscalizaIssueId(app.mainApp, app.reportIssue.Value)
                msg{end+1} = sprintf('O número da inspeção "%.0f" é inválido.', app.reportIssue.Value);
            end
            
            if ~isempty(layout_searchUnexpectedTableValues(app))
                msg{end+1} = ['Há registro de estações instaladas na(s) localidade(s) sob análise para as quais '     ...
                              'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                              'o campo "Justificativa" e anotar os registros, caso aplicável.'];
            end

            msg = strjoin(msg, '<br><br>');

            if strcmp(app.reportVersion.Value, 'Definitiva')
                appUtil.modalWindow(app.UIFigure, "warning", msg);
                return
            end

            msg = [msg, '<br><br>Deseja ignorar esse alerta, gerando a versão prévia do relatório?'];                        
            userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msg, {'Sim', 'Não'}, 2, 2);
            if userSelection == "Não"
                return
            end
            % </VALIDAÇÕES>

            % <PROCESSO>
            indexes = FileIndex(app);
            if ~isempty(indexes)
                if numel(indexes) < numel(app.measData)
                    msgQuestion   = 'Deseja gerar relatório que apresente informações de TODAS as localidades de agrupamento, ou apenas da SELECIONADA?';
                    userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Todas', 'Selecionada', 'Cancelar'}, 1, 3);

                    switch userSelection
                        case 'Cancelar'
                            return
                        case 'Todas'
                            indexes = 1:numel(app.measData);
                    end
                end

                app.progressDialog.Visible = 'visible';

                try
                    preReportGenerator(app.projectData, 'MonitoringPlan', app.mainApp.General)
                    reportLibConnection.Controller.Run(app, app.projectData, app.measData(indexes), app.mainApp.General)
                catch ME
                    appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));
                end

                app.progressDialog.Visible = 'hidden';
            end
            % </PROCESSO>

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
            app.toolGrid.ColumnWidth = {22, 22, 22, 5, 22, '1x', 150, 22, 22, 22};
            app.toolGrid.RowHeight = {4, 17, '1x'};
            app.toolGrid.ColumnSpacing = 5;
            app.toolGrid.RowSpacing = 0;
            app.toolGrid.Padding = [5 5 10 5];
            app.toolGrid.Layout.Row = 6;
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

            % Create tool_TableEdition
            app.tool_TableEdition = uiimage(app.toolGrid);
            app.tool_TableEdition.ScaleMethod = 'none';
            app.tool_TableEdition.ImageClickedFcn = createCallbackFcn(app, @UITableOpenPopUpEditionMode, true);
            app.tool_TableEdition.Enable = 'off';
            app.tool_TableEdition.Tooltip = {'Edita tabela'};
            app.tool_TableEdition.Layout.Row = 2;
            app.tool_TableEdition.Layout.Column = 3;
            app.tool_TableEdition.ImageSource = 'Variable_edit_16.png';

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
            app.tool_peakIcon.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_peakIcon.Enable = 'off';
            app.tool_peakIcon.Tooltip = {'Zoom em torno do local de máximo'};
            app.tool_peakIcon.Layout.Row = [1 3];
            app.tool_peakIcon.Layout.Column = 5;
            app.tool_peakIcon.ImageSource = 'Detection_18.png';

            % Create tool_GenerateReport
            app.tool_GenerateReport = uiimage(app.toolGrid);
            app.tool_GenerateReport.ScaleMethod = 'none';
            app.tool_GenerateReport.ImageClickedFcn = createCallbackFcn(app, @tool_GenerateReportImageClicked, true);
            app.tool_GenerateReport.Enable = 'off';
            app.tool_GenerateReport.Tooltip = {'Gera relatório (.html)'};
            app.tool_GenerateReport.Layout.Row = 2;
            app.tool_GenerateReport.Layout.Column = 8;
            app.tool_GenerateReport.ImageSource = 'Publish_HTML_16.png';

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.toolGrid);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @tool_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Tooltip = {'Exporta análise (.xlsx, .kml)'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 9;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create tool_UploadFinalFile
            app.tool_UploadFinalFile = uiimage(app.toolGrid);
            app.tool_UploadFinalFile.ImageClickedFcn = createCallbackFcn(app, @tool_UploadFinalFileImageClicked, true);
            app.tool_UploadFinalFile.Enable = 'off';
            app.tool_UploadFinalFile.Tooltip = {'Upload relatório'};
            app.tool_UploadFinalFile.Layout.Row = 2;
            app.tool_UploadFinalFile.Layout.Column = 10;
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
            app.UITable.BackgroundColor = [1 1 1;0.96078431372549 0.96078431372549 0.96078431372549];
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
            app.axesTool_RestoreView.ImageClickedFcn = createCallbackFcn(app, @axesTool_InteractionImageClicked, true);
            app.axesTool_RestoreView.Tooltip = {'RestoreView'};
            app.axesTool_RestoreView.Layout.Row = 1;
            app.axesTool_RestoreView.Layout.Column = 1;
            app.axesTool_RestoreView.ImageSource = 'Home_18.png';

            % Create axesTool_RegionZoom
            app.axesTool_RegionZoom = uiimage(app.AxesToolbar);
            app.axesTool_RegionZoom.ScaleMethod = 'none';
            app.axesTool_RegionZoom.ImageClickedFcn = createCallbackFcn(app, @axesTool_InteractionImageClicked, true);
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
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Close.Tag = 'DRIVETEST';
            app.dockModule_Close.Tooltip = {'Fecha módulo'};
            app.dockModule_Close.Layout.Row = 1;
            app.dockModule_Close.Layout.Column = 2;
            app.dockModule_Close.ImageSource = 'Delete_12SVG_white.svg';

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.dockModuleGrid);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Undock.Tag = 'DRIVETEST';
            app.dockModule_Undock.Enable = 'off';
            app.dockModule_Undock.Tooltip = {'Reabre módulo em outra janela'};
            app.dockModule_Undock.Layout.Row = 1;
            app.dockModule_Undock.Layout.Column = 1;
            app.dockModule_Undock.ImageSource = 'Undock_18White.png';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Layout.Row = [3 4];
            app.TabGroup.Layout.Column = 2;

            % Create PMRNITab
            app.PMRNITab = uitab(app.TabGroup);
            app.PMRNITab.AutoResizeChildren = 'off';
            app.PMRNITab.Title = 'PM-RNI';

            % Create Control
            app.Control = uigridlayout(app.PMRNITab);
            app.Control.ColumnWidth = {144, 116, 18};
            app.Control.RowHeight = {30, 5, '1x', 42, 5, '0.5x', 10, 83, 10, 83};
            app.Control.RowSpacing = 0;
            app.Control.BackgroundColor = [1 1 1];

            % Create config_geoAxesLabel_2
            app.config_geoAxesLabel_2 = uilabel(app.Control);
            app.config_geoAxesLabel_2.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel_2.WordWrap = 'on';
            app.config_geoAxesLabel_2.FontSize = 10;
            app.config_geoAxesLabel_2.Layout.Row = 1;
            app.config_geoAxesLabel_2.Layout.Column = [1 2];
            app.config_geoAxesLabel_2.Interpreter = 'html';
            app.config_geoAxesLabel_2.Text = {'LOCALIDADES DE AGRUPAMENTO:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.Control);
            app.TreeFileLocations.SelectionChangedFcn = createCallbackFcn(app, @TreeFileLocationsSelectionChanged, true);
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 3;
            app.TreeFileLocations.Layout.Column = [1 3];

            % Create LocationListLabel
            app.LocationListLabel = uilabel(app.Control);
            app.LocationListLabel.VerticalAlignment = 'bottom';
            app.LocationListLabel.FontSize = 10;
            app.LocationListLabel.Layout.Row = 4;
            app.LocationListLabel.Layout.Column = [1 2];
            app.LocationListLabel.Interpreter = 'html';
            app.LocationListLabel.Text = {'LOCALIDADES SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionadas às estações previstas no PM-RNI)</font>'};

            % Create LocationListEdit
            app.LocationListEdit = uiimage(app.Control);
            app.LocationListEdit.ImageClickedFcn = createCallbackFcn(app, @LocationListEditClicked, true);
            app.LocationListEdit.Enable = 'off';
            app.LocationListEdit.Tooltip = {'Edita lista de localidades'};
            app.LocationListEdit.Layout.Row = 4;
            app.LocationListEdit.Layout.Column = 3;
            app.LocationListEdit.VerticalAlignment = 'bottom';
            app.LocationListEdit.ImageSource = 'Edit_32.png';

            % Create LocationList
            app.LocationList = uitextarea(app.Control);
            app.LocationList.Editable = 'off';
            app.LocationList.FontSize = 11;
            app.LocationList.Layout.Row = 6;
            app.LocationList.Layout.Column = [1 3];

            % Create Card1_numberOfStations
            app.Card1_numberOfStations = uilabel(app.Control);
            app.Card1_numberOfStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card1_numberOfStations.VerticalAlignment = 'top';
            app.Card1_numberOfStations.WordWrap = 'on';
            app.Card1_numberOfStations.FontSize = 10;
            app.Card1_numberOfStations.FontColor = [0.502 0.502 0.502];
            app.Card1_numberOfStations.Layout.Row = 8;
            app.Card1_numberOfStations.Layout.Column = 1;
            app.Card1_numberOfStations.Interpreter = 'html';
            app.Card1_numberOfStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: BLACK; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NAS LOCALIDADES SOB ANÁLISE</p>'};

            % Create Card2_numberOfRiskStations
            app.Card2_numberOfRiskStations = uilabel(app.Control);
            app.Card2_numberOfRiskStations.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card2_numberOfRiskStations.VerticalAlignment = 'top';
            app.Card2_numberOfRiskStations.WordWrap = 'on';
            app.Card2_numberOfRiskStations.FontSize = 10;
            app.Card2_numberOfRiskStations.FontColor = [0.502 0.502 0.502];
            app.Card2_numberOfRiskStations.Layout.Row = 8;
            app.Card2_numberOfRiskStations.Layout.Column = [2 3];
            app.Card2_numberOfRiskStations.Interpreter = 'html';
            app.Card2_numberOfRiskStations.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES NO ENTORNO DE REGISTROS DE NÍVEIS ACIMA DE 14 V/m</p>'};

            % Create Card3_stationsOnRoute
            app.Card3_stationsOnRoute = uilabel(app.Control);
            app.Card3_stationsOnRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card3_stationsOnRoute.VerticalAlignment = 'top';
            app.Card3_stationsOnRoute.WordWrap = 'on';
            app.Card3_stationsOnRoute.FontSize = 10;
            app.Card3_stationsOnRoute.FontColor = [0.502 0.502 0.502];
            app.Card3_stationsOnRoute.Layout.Row = 10;
            app.Card3_stationsOnRoute.Layout.Column = 1;
            app.Card3_stationsOnRoute.Interpreter = 'html';
            app.Card3_stationsOnRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: black; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS NO ENTORNO DA ROTA</p>'};

            % Create Card4_stationsOutRoute
            app.Card4_stationsOutRoute = uilabel(app.Control);
            app.Card4_stationsOutRoute.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Card4_stationsOutRoute.VerticalAlignment = 'top';
            app.Card4_stationsOutRoute.WordWrap = 'on';
            app.Card4_stationsOutRoute.FontSize = 10;
            app.Card4_stationsOutRoute.FontColor = [0.502 0.502 0.502];
            app.Card4_stationsOutRoute.Layout.Row = 10;
            app.Card4_stationsOutRoute.Layout.Column = [2 3];
            app.Card4_stationsOutRoute.Interpreter = 'html';
            app.Card4_stationsOutRoute.Text = {'<p style="margin: 10 2 0 2px;"><font style="color: #a2142f; font-size: 32px;">0</font>'; 'ESTAÇÕES INSTALADAS FORA DA ROTA</p>'};

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
            app.ContextMenu.Tag = 'auxApp.winMonitoringPlan';

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
