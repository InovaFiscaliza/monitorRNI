classdef winExternalRequest_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        GridLayout2                  matlab.ui.container.GridLayout
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
        TreeFileLocations            matlab.ui.container.CheckBoxTree
        config_geoAxesLabel          matlab.ui.control.Label
        play_ControlsTab1Grid_2      matlab.ui.container.GridLayout
        menu_Button1Label            matlab.ui.control.Label
        play_ControlsTab1Image_2     matlab.ui.control.Image
        toolGrid                     matlab.ui.container.GridLayout
        tool_peakIcon                matlab.ui.control.Image
        tool_peakLabel               matlab.ui.control.Label
        tool_ExportFiles             matlab.ui.control.Image
        jsBackDoor                   matlab.ui.control.HTML
        tool_TableVisibility         matlab.ui.control.Image
        tool_ControlPanelVisibility  matlab.ui.control.Image
        UITable                      matlab.ui.control.Table
        axesToolbarGrid              matlab.ui.container.GridLayout
        axesTool_RegionZoom          matlab.ui.control.Image
        axesTool_RestoreView         matlab.ui.control.Image
        plotPanel                    matlab.ui.container.Panel
        ContextMenu                  matlab.ui.container.ContextMenu
        DeletePoint                  matlab.ui.container.Menu
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
                app.jsBackDoor.HTMLEventReceivedFcn = @(~, evt)jsBackDoor_Listener(app, evt);
            end
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Listener(app, event)
            switch event.HTMLEventName
                case 'auxApp.winExternalRequest.TreePoints'
                    DeleteSelectedPoint(app, struct('ContextObject', app.TreePoints))
                otherwise
                    % ...
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

            app.TreePoints.UserData = struct(app.TreePoints).Controller.ViewModel.Id;
            sendEventToHTMLSource(app.jsBackDoor, 'addKeyDownListener', struct('componentName', 'auxApp.winExternalRequest.TreePoints', 'componentDataTag', app.TreePoints.UserData, 'keyEvents', ["Delete", "Backspace"]))
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
            if app.mainApp.General.ExternalRequest.FieldValue ~= 14
                app.UITable.ColumnName{5} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.ExternalRequest.FieldValue);
            end

            [app.UIAxes, app.restoreView] = plot.axesCreationController(app.plotPanel, app.mainApp.General);
            layout_TreeFileLocationBuilding(app)
            
            app.tool_TableVisibility.UserData = 1;

            % Especificidades do auxApp.winExternalRequest em relação ao
            % auxApp.winMonitoringPlan:
            layout_TreePointsBuilding(app)
            app.NewPointType.Items = [{''}; app.mainApp.General.ExternalRequest.TypeOfLocation];
            layout_newPointPanel(app, 'off')
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
                % em tela. 
                listOfTables = {app.measData(idxFile).Data};            
                app.measTable = sortrows(vertcat(listOfTables{:}), 'Timestamp');

            else
                app.measTable = [];
            end

            app.projectData.selectedFileLocations     = selectedFileLocations;

            identifyMeasuresForEachPoint(app)

            initialSelection = updateTable(app);
            layout_TableStyle(app)
            layout_updatePeakInfo(app)

            % PLOT
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
            if ~isempty(app.TreeFileLocations.CheckedNodes)
                selectedFileLocations = {app.TreeFileLocations.CheckedNodes.Text};
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

            table2Render = app.mainApp.pointsTable(:, {'ID',                    ...
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
        function plot_MeasuresAndPoints(app)
            % prePlot
            cla(app.UIAxes)
            geolimits(app.UIAxes, 'auto')
            app.restoreView = struct('ID', 'app.UIAxes', 'xLim', app.UIAxes.LatitudeLimits, 'yLim', app.UIAxes.LongitudeLimits, 'cLim', 'auto');

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
                refPointsTable = app.mainApp.pointsTable;

                plot.draw.Points(app.UIAxes, refPointsTable, 'Pontos críticos', app.mainApp.General)
            end
            plot_AxesDefaultLimits(app, 'stations/points')
        end

        %-----------------------------------------------------------------%
        function plot_SelectedPoint(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'SelectedPoint'))

            if ~isempty(app.UITable.Selection)
                idxSelectedPoint   = app.UITable.Selection;
                selectedPointTable = app.mainApp.pointsTable(idxSelectedPoint, :);

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
        function identifyMeasuresForEachPoint(app)
            DIST_km = app.mainApp.General.ExternalRequest.Distance_km;

            for ii = 1:height(app.mainApp.pointsTable)
                if app.mainApp.pointsTable.AnalysisFlag(ii)
                    continue
                end

                app.mainApp.pointsTable.AnalysisFlag(ii) = true;

                % Inicialmente, afere a distância do ponto a cada uma das
                % medidas, identificando aquelas no entorno.
                pointDistance      = deg2km(distance(app.mainApp.pointsTable.Latitude(ii), app.mainApp.pointsTable.Longitude(ii), app.measTable.Latitude, app.measTable.Longitude));                
                idxLogicalMeasures = pointDistance <= DIST_km;

                if any(idxLogicalMeasures)
                    pointMeasures = app.measTable(idxLogicalMeasures, :);
                    [maxFieldValue, idxMaxFieldValue] = max(pointMeasures.FieldValue);

                    app.mainApp.pointsTable.numberOfMeasures(ii)     = height(pointMeasures);
                    app.mainApp.pointsTable.numberOfRiskMeasures(ii) = sum(pointMeasures.FieldValue > app.mainApp.General.ExternalRequest.FieldValue);
                    app.mainApp.pointsTable.minFieldValue(ii)        = min(pointMeasures.FieldValue);
                    app.mainApp.pointsTable.meanFieldValue(ii)       = mean(pointMeasures.FieldValue);
                    app.mainApp.pointsTable.maxFieldValue(ii)        = maxFieldValue;
                    app.mainApp.pointsTable.maxFieldLatitude(ii)     = pointMeasures.Latitude(idxMaxFieldValue);
                    app.mainApp.pointsTable.maxFieldLongitude(ii)    = pointMeasures.Longitude(idxMaxFieldValue);

                else
                    app.mainApp.pointsTable.numberOfMeasures(ii)     = 0;
                    app.mainApp.pointsTable.numberOfRiskMeasures(ii) = 0;
                    app.mainApp.pointsTable.minFieldValue(ii)        = 0;
                    app.mainApp.pointsTable.meanFieldValue(ii)       = 0;
                    app.mainApp.pointsTable.maxFieldValue(ii)        = 0;
                    app.mainApp.pointsTable.maxFieldLatitude(ii)     = 0;
                    app.mainApp.pointsTable.maxFieldLongitude(ii)    = 0;
                end

                app.mainApp.pointsTable.minDistanceForMeasure(ii)    = min(pointDistance); % km
            end
        end

        %-----------------------------------------------------------------%
        function [idxMissingInfo, idxRiskMeasures] = layout_searchUnexpectedTableValues(app)
            idxMissingInfo   = [];
            idxRiskMeasures  = [];

            if ~isempty(app.UITable.Data)
                idxMissingInfo  = find(((app.mainApp.pointsTable.numberOfMeasures == 0) & (app.mainApp.pointsTable.("Justificativa") == "-1")));
                idxRiskMeasures = find(app.mainApp.pointsTable.numberOfRiskMeasures > 0);
            end
        end

        %-----------------------------------------------------------------%
        function layout_TableStyle(app)
            removeStyle(app.UITable)

            if ~isempty(app.UITable.Data)
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
                
                app.tool_ExportFiles.Enable = 1;

            else
                app.tool_ExportFiles.Enable = 0;
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
        function layout_TreePointsBuilding(app)
            if ~isempty(app.TreePoints.Children)
                delete(app.TreePoints.Children)
            end

            for ii = 1:height(app.mainApp.pointsTable)
                uitreenode(app.TreePoints, 'Text', app.mainApp.pointsTable.ID{ii}, 'NodeData', ii, 'ContextMenu', app.ContextMenu);
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
                    
                    app.GridLayout2.RowHeight{5} = 170;
                    app.GridLayout2.ColumnWidth(end-1:end) = {16,16};
                    app.AddNewPointConfirm.Enable = 1;
                    app.AddNewPointCancel.Enable  = 1;

                case 'off'
                    set(app.AddNewPointMode, 'ImageSource', 'addFiles_32.png',       'Tooltip', 'Habilita painel de inclusão de ponto',   'UserData', false)

                    app.GridLayout2.RowHeight{5} = 0;
                    app.GridLayout2.ColumnWidth(end-1:end) = {0,0};
                    app.AddNewPointConfirm.Enable = 0;
                    app.AddNewPointCancel.Enable  = 0;
            end
        end
    end


    methods
        %-----------------------------------------------------------------%
        function appBackDoor(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    case {'winMonitorRNI', 'winMonitorRNI_exported'}
                        switch operationType
                            case 'ExternalRequest: updatePlot'
                                Analysis(app)

                            case 'ExternalRequest: updateAnalysis'
                                app.UITable.ColumnName{4} = sprintf('Qtd.|> %.0f V/m', app.mainApp.General.ExternalRequest.FieldValue);

                                if ~isempty(app.mainApp.pointsTable)
                                    app.mainApp.pointsTable.AnalysisFlag(:) = false;
                                end
                                Analysis(app)

                            case 'ExternalRequest: updateAxes'
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

                            case 'ExternalRequest: DeletePoint'
                                DeleteSelectedPoint(app, struct('ContextObject', app.TreePoints))

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

            appBackDoor(app.mainApp, app, 'closeFcn', 'EXTERNALREQUEST')
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
                msgQuestion   = ['Há registro de pontos críticos sob análise para os quais '                             ...
                                 'não foram identificadas medidas no entorno. Nesse caso específico, deve-se preencher ' ...
                                 'o campo "Justificativa".'                                                              ...
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

            baseName     = appUtil.DefaultFileName(app.mainApp.General.fileFolder.userPath, appName, '-1');


            % (a) Arquivo no formato .XLSX
            %     (um único arquivo de saída)
            fileName_XLSX = [baseName '.xlsx'];
            [status, msgError] = fileWriter.ExternalRequest(fileName_XLSX, app.mainApp.pointsTable, timetable2table(app.measTable), app.mainApp.General.ExternalRequest.FieldValue, app.mainApp.General.ExternalRequest.Export.XLSX);
            if status
                savedFiles{end+1} = fileName_XLSX;
            else
                errorFiles{end+1} = msgError;
            end

            % (b) Arquivos no formato .KML: "Measures" e "Route"
            %     (um único arquivo de medições, além de um arquivo de rota 
            %      por arquivo de medição)
            if app.mainApp.General.ExternalRequest.Export.KML
                hMeasPlot = findobj(app.UIAxes.Children, 'Tag', 'Measures');

                % (b.1) KML:Measures
                d.Message = 'Em andamento a criação do arquivo de medidas no formato "kml".';

                fileName_KML1 = sprintf('%s_Measures.kml', baseName);
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
                    fileName_KML2 = sprintf('%s_Route (%d).kml', baseName, ii);
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

                fileFolder = fileparts(baseName);
                savedFiles = replace(savedFiles, fileFolder, '.');
                appUtil.modalWindow(app.UIFigure, 'info', sprintf('Lista de arquivos criados:\n%s', strjoin(savedFiles, '\n')));
            end

            if ~isempty(errorFiles)
                appUtil.modalWindow(app.UIFigure, 'error', strjoin(errorFiles, '\n'));
            end

            delete(d)

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
            
            if ~ismember(event.EditData, app.mainApp.General.ExternalRequest.NoMeasureReasons)
                app.UITable.Data.("Justificativa") = app.mainApp.pointsTable.("Justificativa");
                return
            end

            idxPoint = event.Indices(1);
            app.mainApp.pointsTable.("Justificativa")(idxPoint) = event.NewData;
            
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

        % Image clicked function: AddNewPointCancel, AddNewPointConfirm, 
        % ...and 1 other component
        function AddNewPointEditionModeCallbacks(app, event)
            
            switch event.Source
                case app.AddNewPointMode
                    app.AddNewPointMode.UserData = ~app.AddNewPointMode.UserData;
                    
                    if app.AddNewPointMode.UserData
                        layout_newPointPanel(app, 'on')
                        focus(app.NewPointType)
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
                            ID = sprintf('Estação nº %d', app.NewPointStation.Value);
                        otherwise
                            ID = app.NewPointType.Value;
                    end
                    ID = sprintf('%s @ (%.6f, %.6f)', ID, app.NewPointLatitude.Value, app.NewPointLongitude.Value);
        
                    % VERIFICA SE ESSE ID JÁ TINHA SIDO INCLUÍDO
                    if any(strcmp(app.mainApp.pointsTable.ID, ID))
                        appUtil.modalWindow(app.UIFigure, 'warning', 'Registro já consta na lista de pontos sob análise.');
                        return
                    end

                    columsn2Fill = {'ID', 'Type', 'Station', 'Latitude', 'Longitude', 'Description', 'Justificativa', 'AnalysisFlag'};        
                    app.mainApp.pointsTable(end+1, columsn2Fill) = {ID,                            ...
                                                                    app.NewPointType.Value,        ...
                                                                    app.NewPointStation.Value,     ...
                                                                    app.NewPointLatitude.Value,    ...
                                                                    app.NewPointLongitude.Value,   ...
                                                                    app.NewPointDescription.Value, ...
                                                                    categorical("-1"),             ...
                                                                    false};
        
        
                    % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                    layout_TreePointsBuilding(app)
        
                    % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                    Analysis(app)

                    % DESABILITA MODO DE INCLUSÃO DE PONTO
                    layout_newPointPanel(app, 'off')

                case app.AddNewPointCancel
                    layout_newPointPanel(app, 'off')
            end

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
                app.mainApp.pointsTable(idxPoint, :) = [];

                % ATUALIZA ÁRVORE DE PONTOS CRÍTICOS
                layout_TreePointsBuilding(app)
    
                % ANÁLISA DOS PONTOS CRÍTICOS, ATUALIZANDO TABELA E PLOT
                Analysis(app)
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
            app.UITable.ColumnName = {'ID'; 'Descrição'; 'Qtd.|Medidas'; 'Qtd.|> 14 V/m'; 'Dmin|(km)'; 'Emin|(V/m)'; 'Emean|(V/m)'; 'Emax|(V/m)'; 'Justificativa'};
            app.UITable.ColumnWidth = {210, 'auto', 70, 70, 70, 70, 70, 70, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.SelectionType = 'row';
            app.UITable.ColumnEditable = [false false false false false false false false true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 5;
            app.UITable.Layout.Column = [4 6];
            app.UITable.FontSize = 10;

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, 22, 22, '1x', 150, 22};
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
            app.jsBackDoor.Layout.Column = 4;

            % Create tool_ExportFiles
            app.tool_ExportFiles = uiimage(app.toolGrid);
            app.tool_ExportFiles.ScaleMethod = 'none';
            app.tool_ExportFiles.ImageClickedFcn = createCallbackFcn(app, @tool_ExportTableAsExcelSheet, true);
            app.tool_ExportFiles.Enable = 'off';
            app.tool_ExportFiles.Tooltip = {'Exporta análise'};
            app.tool_ExportFiles.Layout.Row = 2;
            app.tool_ExportFiles.Layout.Column = 3;
            app.tool_ExportFiles.ImageSource = 'Export_16.png';

            % Create tool_peakLabel
            app.tool_peakLabel = uilabel(app.toolGrid);
            app.tool_peakLabel.HorizontalAlignment = 'right';
            app.tool_peakLabel.FontSize = 10;
            app.tool_peakLabel.Visible = 'off';
            app.tool_peakLabel.Layout.Row = [1 3];
            app.tool_peakLabel.Layout.Column = 6;
            app.tool_peakLabel.Text = {'5.3 V/m'; '(-12.354321, -38.123456)'};

            % Create tool_peakIcon
            app.tool_peakIcon = uiimage(app.toolGrid);
            app.tool_peakIcon.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_peakIcon.Visible = 'off';
            app.tool_peakIcon.Tooltip = {'Zoom em torno do local de máximo'};
            app.tool_peakIcon.Layout.Row = [1 3];
            app.tool_peakIcon.Layout.Column = 7;
            app.tool_peakIcon.HorizontalAlignment = 'right';
            app.tool_peakIcon.ImageSource = 'Detection_128.png';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.GridLayout);
            app.GridLayout2.ColumnWidth = {'1x', 16, 16, 16};
            app.GridLayout2.RowHeight = {22, 32, '1x', 32, 170, 175};
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
            app.play_ControlsTab1Grid_2.Layout.Column = [1 4];
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

            % Create config_geoAxesLabel
            app.config_geoAxesLabel = uilabel(app.GridLayout2);
            app.config_geoAxesLabel.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel.WordWrap = 'on';
            app.config_geoAxesLabel.FontSize = 10;
            app.config_geoAxesLabel.Layout.Row = 2;
            app.config_geoAxesLabel.Layout.Column = 1;
            app.config_geoAxesLabel.Interpreter = 'html';
            app.config_geoAxesLabel.Text = {'LOCALIDADES:'; '<font style="color: gray; font-size: 9px;">(relacionadas aos arquivos de medição)</font>'};

            % Create TreeFileLocations
            app.TreeFileLocations = uitree(app.GridLayout2, 'checkbox');
            app.TreeFileLocations.FontSize = 11;
            app.TreeFileLocations.Layout.Row = 3;
            app.TreeFileLocations.Layout.Column = [1 4];

            % Assign Checked Nodes
            app.TreeFileLocations.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeFileLocationsCheckedNodesChanged, true);

            % Create TreePointsLabel
            app.TreePointsLabel = uilabel(app.GridLayout2);
            app.TreePointsLabel.VerticalAlignment = 'bottom';
            app.TreePointsLabel.FontSize = 10;
            app.TreePointsLabel.Layout.Row = 4;
            app.TreePointsLabel.Layout.Column = 1;
            app.TreePointsLabel.Interpreter = 'html';
            app.TreePointsLabel.Text = {'PONTOS CRÍTICOS SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionados àquilo que fora pedido pelo demandante)</font>'};

            % Create AddNewPointMode
            app.AddNewPointMode = uiimage(app.GridLayout2);
            app.AddNewPointMode.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointMode.Tooltip = {'Habilita painel de inclusão de ponto'};
            app.AddNewPointMode.Layout.Row = 4;
            app.AddNewPointMode.Layout.Column = 2;
            app.AddNewPointMode.VerticalAlignment = 'bottom';
            app.AddNewPointMode.ImageSource = 'addFiles_32.png';

            % Create AddNewPointConfirm
            app.AddNewPointConfirm = uiimage(app.GridLayout2);
            app.AddNewPointConfirm.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointConfirm.Enable = 'off';
            app.AddNewPointConfirm.Tooltip = {'Confirma edição'};
            app.AddNewPointConfirm.Layout.Row = 4;
            app.AddNewPointConfirm.Layout.Column = 3;
            app.AddNewPointConfirm.VerticalAlignment = 'bottom';
            app.AddNewPointConfirm.ImageSource = 'Ok_32Green.png';

            % Create AddNewPointCancel
            app.AddNewPointCancel = uiimage(app.GridLayout2);
            app.AddNewPointCancel.ImageClickedFcn = createCallbackFcn(app, @AddNewPointEditionModeCallbacks, true);
            app.AddNewPointCancel.Enable = 'off';
            app.AddNewPointCancel.Tooltip = {'Cancela edição'};
            app.AddNewPointCancel.Layout.Row = 4;
            app.AddNewPointCancel.Layout.Column = 4;
            app.AddNewPointCancel.VerticalAlignment = 'bottom';
            app.AddNewPointCancel.ImageSource = 'Delete_32Red.png';

            % Create AddNewPointPanel
            app.AddNewPointPanel = uipanel(app.GridLayout2);
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
            app.TreePoints = uitree(app.GridLayout2);
            app.TreePoints.SelectionChangedFcn = createCallbackFcn(app, @TreePointsSelectionChanged, true);
            app.TreePoints.FontSize = 11;
            app.TreePoints.Layout.Row = 6;
            app.TreePoints.Layout.Column = [1 4];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create DeletePoint
            app.DeletePoint = uimenu(app.ContextMenu);
            app.DeletePoint.MenuSelectedFcn = createCallbackFcn(app, @DeleteSelectedPoint, true);
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
