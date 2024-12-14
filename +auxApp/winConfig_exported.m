classdef winConfig_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        Toolbar                         matlab.ui.container.GridLayout
        jsBackDoor                      matlab.ui.control.HTML
        tool_RFDataHubButton            matlab.ui.control.Image
        tool_LeftPanelVisibility        matlab.ui.control.Image
        Document                        matlab.ui.container.GridLayout
        FolderGrid                      matlab.ui.container.GridLayout
        FolderPanel                     matlab.ui.container.Panel
        FolderPanelGrid                 matlab.ui.container.GridLayout
        tempPath                        matlab.ui.control.EditField
        tempPathLabel                   matlab.ui.control.Label
        userPathButton                  matlab.ui.control.Image
        userPath                        matlab.ui.control.EditField
        userPathLabel                   matlab.ui.control.Label
        FolderTitle                     matlab.ui.control.Label
        CustomPlotGrid                  matlab.ui.container.GridLayout
        CustomPlotPanel                 matlab.ui.container.Panel
        CustomPlotPanelGrid             matlab.ui.container.GridLayout
        AutomaticZoomFactor             matlab.ui.control.Spinner
        AutomaticZoomFactorLabel        matlab.ui.control.Label
        AutomaticZoom                   matlab.ui.control.CheckBox
        CircleEdgeAlpha                 matlab.ui.control.Spinner
        CircleFaceAlpha                 matlab.ui.control.Spinner
        CircleColorAlphaLabel           matlab.ui.control.Label
        CircleColor                     matlab.ui.control.DropDown
        CircleColorLabel                matlab.ui.control.Label
        PeakSize                        matlab.ui.control.Slider
        PeakColor                       matlab.ui.control.ColorPicker
        PeakLabel                       matlab.ui.control.Label
        SelectedStationSize             matlab.ui.control.Slider
        SelectedStationColor            matlab.ui.control.ColorPicker
        SelectedStationLabel            matlab.ui.control.Label
        StationsSize                    matlab.ui.control.Slider
        StationsColor                   matlab.ui.control.ColorPicker
        StationsLabel                   matlab.ui.control.Label
        Colorbar                        matlab.ui.control.DropDown
        ColorbarLabel                   matlab.ui.control.Label
        Colormap                        matlab.ui.control.DropDown
        ColormapLabel                   matlab.ui.control.Label
        Basemap                         matlab.ui.control.DropDown
        BasemapLabel                    matlab.ui.control.Label
        CustomPlotTitle                 matlab.ui.control.Label
        AnalysisGrid                    matlab.ui.container.GridLayout
        AnalysisPanel                   matlab.ui.container.Panel
        AnalysisPanelGrid               matlab.ui.container.GridLayout
        ExternalRequestPanel            matlab.ui.container.Panel
        ExternalRequestGrid             matlab.ui.container.GridLayout
        ExternalRequestLevel            matlab.ui.control.NumericEditField
        ExternalRequestLevelLabel       matlab.ui.control.Label
        ExternalRequestDistance         matlab.ui.control.NumericEditField
        ExternalRequestDistanceLabel    matlab.ui.control.Label
        ExternalRequestLabel            matlab.ui.control.Label
        MonitoringPlanPanel             matlab.ui.container.Panel
        MonitoringPlanGrid              matlab.ui.container.GridLayout
        MonitoringPlanReasonsList       matlab.ui.control.ListBox
        MonitoringPlanReasonsListLabel  matlab.ui.control.Label
        MonitoringPlanLevel             matlab.ui.control.NumericEditField
        MonitoringPlanLevelLabel        matlab.ui.control.Label
        MonitoringPlanDistance          matlab.ui.control.NumericEditField
        MonitoringPlanDistanceLabel     matlab.ui.control.Label
        MonitoringPlanLabel             matlab.ui.control.Label
        AnalysisTitle                   matlab.ui.control.Label
        GeneralGrid                     matlab.ui.container.GridLayout
        openAuxiliarApp2Debug           matlab.ui.control.CheckBox
        openAuxiliarAppAsDocked         matlab.ui.control.CheckBox
        gpuType                         matlab.ui.control.DropDown
        gpuTypeLabel                    matlab.ui.control.Label
        AppVersionPanel                 matlab.ui.container.Panel
        AppVersionGrid                  matlab.ui.container.GridLayout
        AppVersion                      matlab.ui.control.HTML
        AppVersionRefresh               matlab.ui.control.Image
        AppVersionLabel                 matlab.ui.control.Label
        ControlPanel                    matlab.ui.container.GridLayout
        RadioButtonGroupPanel           matlab.ui.container.Panel
        RadioButtonGroupGrid            matlab.ui.container.GridLayout
        RadioButtonGroup                matlab.ui.container.ButtonGroup
        btnFolder                       matlab.ui.control.RadioButton
        btnCustomPlot                   matlab.ui.control.RadioButton
        btnAnalysis                     matlab.ui.control.RadioButton
        btnGeneral                      matlab.ui.control.RadioButton
        ControlPanelGrid                matlab.ui.container.GridLayout
        ControlPanelTitle               matlab.ui.control.Label
        ControlPanelIcon                matlab.ui.control.Image
    end

    
    properties
        %-----------------------------------------------------------------%
        Container
        isDocked = false
        
        CallingApp
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

        stableVersion
    end


    properties (Access = private)
        %-----------------------------------------------------------------%
        DefaultValues = struct('File',      struct('DataType', true, 'DataTypeLabel', 'remove', 'Antenna', true, 'AntennaLabel', 'remove', 'AntennaAttributes', {{'Name', 'Azimuth', 'Elevation', 'Polarization', 'Height', 'SwitchPort', 'LNBChannel'}}, 'Distance', 100), ...
                               'Graphics',  struct('openGL', 'hardware', 'Format', 'jpeg', 'Resolution', '120', 'Dock', true),                               ...
                               'Elevation', struct('Points', '256', 'ForceSearch', false, 'Server', 'Open-Elevation'))
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
        end
    end


    methods (Access = private)
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

                startup_Controller(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Controller(app)
            drawnow
            
            % Customiza as aspectos estéticos de alguns dos componentes da GUI 
            % (diretamente em JS).
            jsBackDoor_Customizations(app)

            if ~strcmp(app.CallingApp.executionMode, 'webApp')
                app.AppVersionRefresh.Enable = 1;
                app.gpuType.Enable = 1;
                app.openAuxiliarAppAsDocked.Enable = 1;
            end

            if ~isdeployed
                app.openAuxiliarApp2Debug.Enable = 1;
            end

            % Atualização dos painéis...
            app.progressDialog.Visible = 'visible';

            General_updatePanel(app)
            Analysis_updatePanel(app)
            CustomPlot_updatePanel(app)
            Folder_updatePanel(app)

            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function General_updatePanel(app)
            % Versão
            htmlContent = auxApp.config.htmlCode_AppVersion(app.CallingApp.General, app.CallingApp.executionMode);
            app.AppVersion.HTMLSource = htmlContent;

            % Renderizador
            graphRender = opengl('data');
            switch graphRender.HardwareSupportLevel
                case 'basic'; graphRenderSupport = 'hardwarebasic';
                case 'full';  graphRenderSupport = 'hardware';
                case 'none';  graphRenderSupport = 'software';
                otherwise;    graphRenderSupport = graphRender.HardwareSupportLevel; % "driverissue"
            end

            if ~ismember(graphRenderSupport, app.gpuType.Items)
                app.gpuType.Items{end+1} = graphRenderSupport;
            end
            app.gpuType.Value = graphRenderSupport;

            % Modo de operação
            app.openAuxiliarAppAsDocked.Value   = app.CallingApp.General.operationMode.Dock;
            app.openAuxiliarApp2Debug.Value     = app.CallingApp.General.operationMode.Debug;
        end

        %-----------------------------------------------------------------%
        function Analysis_updatePanel(app)
            app.MonitoringPlanDistance.Value    = app.CallingApp.General.MonitoringPlan.Distance_km * 1000;
            app.MonitoringPlanLevel.Value       = app.CallingApp.General.MonitoringPlan.FieldValue;
            app.MonitoringPlanReasonsList.Items = app.CallingApp.General.MonitoringPlan.NoMeasureReasons;

            app.ExternalRequestDistance.Value   = app.CallingApp.General.ExternalRequest.Distance_km * 1000;
            app.ExternalRequestLevel.Value      = app.CallingApp.General.ExternalRequest.FieldValue;
        end

        %-----------------------------------------------------------------%
        function CustomPlot_updatePanel(app)
            app.Basemap.Value              = app.CallingApp.General.Plot.GeographicAxes.Basemap;
            app.Colormap.Value             = app.CallingApp.General.Plot.GeographicAxes.Colormap;
            app.Colorbar.Value             = app.CallingApp.General.Plot.GeographicAxes.Colorbar;

            app.StationsColor.Value        = app.CallingApp.General.Plot.Stations.Color;
            app.StationsSize.Value         = app.CallingApp.General.Plot.Stations.Size;

            app.SelectedStationColor.Value = app.CallingApp.General.Plot.SelectedStation.Color;
            app.SelectedStationSize.Value  = app.CallingApp.General.Plot.SelectedStation.Size;

            app.CircleColor.Value          = app.CallingApp.General.Plot.CircleRegion.Color;
            app.CircleFaceAlpha.Value      = app.CallingApp.General.Plot.CircleRegion.FaceAlpha;
            app.CircleEdgeAlpha.Value      = app.CallingApp.General.Plot.CircleRegion.EdgeAlpha;

            app.AutomaticZoom.Value        = app.CallingApp.General.Plot.SelectedStation.AutomaticZoom;
            if app.AutomaticZoom.Value
                set(app.AutomaticZoomFactor, 'Enable', 1, 'Value', app.CallingApp.General.Plot.SelectedStation.AutomaticZoomFactor)
            else
                set(app.AutomaticZoomFactor, 'Enable', 0, 'Value', 1)
            end

            app.PeakColor.Value            = app.CallingApp.General.Plot.FieldPeak.Color;
            app.PeakSize.Value             = app.CallingApp.General.Plot.FieldPeak.Size;
        end

        %-----------------------------------------------------------------%
        function Folder_updatePanel(app)
            if ~strcmp(app.CallingApp.executionMode, 'webApp')
                app.btnFolder.Enable = 1;
                app.userPath.Value = app.CallingApp.General.fileFolder.userPath;
                app.tempPath.Value = app.CallingApp.General.fileFolder.tempPath;
            end
        end

        %-----------------------------------------------------------------%
        function saveGeneralSettings(app)
            appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.CallingApp.General_I, app.CallingApp.executionMode)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            % A razão de ser deste app é possibilitar visualização/edição 
            % de algumas das informações do arquivo "GeneralSettings.json".
            app.CallingApp = mainapp;
            app.rootFolder = mainapp.rootFolder;

            jsBackDoor_Initialization(app)
            RadioButtonGroupSelectionChanged(app)

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
            
            appBackDoor(app.CallingApp, app, 'closeFcn', 'CONFIG')
            delete(app)
            
        end

        % Image clicked function: tool_LeftPanelVisibility
        function tool_LeftPanelVisibilityClicked(app, event)
            
            focus(app.jsBackDoor)

            if app.Document.ColumnWidth{1}
                app.tool_LeftPanelVisibility.ImageSource = 'ArrowRight_32.png';
                app.Document.ColumnWidth{1} = 0;
            else
                app.tool_LeftPanelVisibility.ImageSource = 'ArrowLeft_32.png';
                app.Document.ColumnWidth{1} = 325;
            end

        end

        % Image clicked function: tool_RFDataHubButton
        function tool_RFDataHubButtonPushed(app, event)
            
            if isequal(app.CallingApp.General.AppVersion.RFDataHub,  app.stableVersion.RFDataHub)
                app.tool_RFDataHubButton.Enable = 0;
                appUtil.modalWindow(app.UIFigure, 'warning', 'Módulo RFDataHub já atualizado!');
                return
            end

            d = appUtil.modalWindow(app.UIFigure, "progressdlg", 'Em andamento... esse processo pode demorar alguns minutos!');

            try
                [~, ~, rfdatahubLink] = fcn.PublicLinks(app.rootFolder);

                tempDir = tempname;
                mkdir(tempDir)

                websave(fullfile(tempDir, 'estacoes.parquet.gzip'), rfdatahubLink.Table);
                websave(fullfile(tempDir, 'log.parquet.gzip'),      rfdatahubLink.Log);
                websave(fullfile(tempDir, 'Release.json'),          rfdatahubLink.Release);

                if isfile(fullfile(app.rootFolder, 'DataBase', 'RFDataHub_old.mat'))
                    delete(fullfile(app.rootFolder, 'DataBase', 'RFDataHub_old.mat'))
                end

                while true
                    status = system(sprintf('rename "%s" "%s"', fullfile(app.rootFolder, 'DataBase', 'RFDataHub.mat'), 'RFDataHub_old.mat'));
                    if ~status
                        break
                    end
                    pause(.1)
                end

                % Apaga as variáveis globais, lendo os novos arquivos.
                clear global RFDataHub
                clear global RFDataHubLog
                clear global RFDataHub_info
                class.RFDataHub.read(app.rootFolder, tempDir)

                % Apaga os arquivos temporários.
                rmdir(tempDir, 's')

                % Atualiza versão.
                global RFDataHub_info
                app.CallingApp.General.AppVersion.RFDataHub = RFDataHub_info;
                app.tool_RFDataHubButton.Enable = 0;
                
            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);
            end

            General_updatePanel(app)

            delete(d)

        end

        % Selection changed function: RadioButtonGroup
        function RadioButtonGroupSelectionChanged(app, event)
            
            selectedButton = app.RadioButtonGroup.SelectedObject;
            switch selectedButton
                case app.btnGeneral;    app.Document.ColumnWidth(2:end) = {'1x',0,0,0};
                case app.btnAnalysis;   app.Document.ColumnWidth(2:end) = {0,'1x',0,0};
                case app.btnCustomPlot; app.Document.ColumnWidth(2:end) = {0,0,'1x',0};
                case app.btnFolder;     app.Document.ColumnWidth(2:end) = {0,0,0,'1x'};
            end
            
        end

        % Image clicked function: AppVersionRefresh
        function General_RefreshButtonPushed(app, event)
            
            app.progressDialog.Visible = 'visible';

            [htmlContent, app.stableVersion, updatedModule] = auxApp.config.htmlCode_CheckAvailableUpdate(app.CallingApp.General, app.rootFolder);
            appUtil.modalWindow(app.UIFigure, "info", htmlContent);
            
            if ~ismember('RFDataHub', updatedModule)
                app.tool_RFDataHubButton.Enable = 1;
            end         

            app.progressDialog.Visible = 'hidden';

        end

        % Value changed function: gpuType, openAuxiliarApp2Debug, 
        % ...and 1 other component
        function General_ParameterValueChanged(app, event)
            
            switch event.Source
                case app.gpuType
                    if ismember(app.gpuType.Value, {'software', 'hardware', 'hardwarebasic'})
                        eval(sprintf('opengl %s', app.gpuType.Value))

                        graphRender = opengl('data');
                        
                        app.CallingApp.General.openGL = app.gpuType.Value;
                        app.CallingApp.General.AppVersion.OpenGL = rmfield(graphRender, {'MaxTextureSize', 'Visual', 'SupportsGraphicsSmoothing', 'SupportsDepthPeelTransparency', 'SupportsAlignVertexCenters', 'Extensions', 'MaxFrameBufferSize'});
                    end

                case app.openAuxiliarAppAsDocked
                    app.CallingApp.General.operationMode.Dock  = app.openAuxiliarAppAsDocked.Value;

                case app.openAuxiliarApp2Debug
                    app.CallingApp.General.operationMode.Debug = app.openAuxiliarApp2Debug.Value;
            end

            app.CallingApp.General_I.openGL        = app.CallingApp.General.openGL;
            app.CallingApp.General_I.operationMode = app.CallingApp.General.operationMode;
            saveGeneralSettings(app)
            General_updatePanel(app)

        end

        % Value changed function: ExternalRequestDistance, 
        % ...and 3 other components
        function Analysis_ParameterValueChanged(app, event)
            
            switch event.Source
                case app.MonitoringPlanDistance
                    app.CallingApp.General.MonitoringPlan.Distance_km  = app.MonitoringPlanDistance.Value / 1000;

                case app.MonitoringPlanLevel
                    app.CallingApp.General.MonitoringPlan.FieldValue   = app.MonitoringPlanLevel.Value;

                case app.ExternalRequestDistance
                    app.CallingApp.General.ExternalRequest.Distance_km = app.ExternalRequestDistance.Value / 1000;

                case app.ExternalRequestLevel
                    app.CallingApp.General.ExternalRequest.FieldValue  = app.ExternalRequestLevel.Value;
            end

            app.CallingApp.General_I.MonitoringPlan  = app.CallingApp.General.MonitoringPlan;
            app.CallingApp.General_I.ExternalRequest = app.CallingApp.General.ExternalRequest;
            saveGeneralSettings(app)

            appBackDoor(app.CallingApp, app, 'updateAnalysis')
            
        end

        % Value changed function: AutomaticZoom, AutomaticZoomFactor, 
        % ...and 8 other components
        function CustomPlot_ParameterValueChanged(app, event)
            
            switch event.Source
                case app.Basemap
                    app.CallingApp.General.Plot.GeographicAxes.Basemap    = app.Basemap.Value;

                case app.Colormap
                    app.CallingApp.General.Plot.GeographicAxes.Colormap   = app.Colormap.Value;

                case app.Colorbar
                    app.CallingApp.General.Plot.GeographicAxes.Colorbar   = app.Colorbar.Value;

                case app.StationsSize
                    app.CallingApp.General.Plot.Stations.Size             = round(app.StationsSize.Value);

                case app.SelectedStationSize
                    app.CallingApp.General.Plot.SelectedStation.Size      = round(app.SelectedStationSize.Value);

                case app.PeakSize
                    app.CallingApp.General.Plot.FieldPeak.Size            = round(app.PeakSize.Value);

                case app.CircleFaceAlpha
                    app.CallingApp.General.Plot.CircleRegion.FaceAlpha    = app.CircleFaceAlpha.Value;

                case app.CircleEdgeAlpha
                    app.CallingApp.General.Plot.CircleRegion.EdgeAlpha    = app.CircleEdgeAlpha.Value;

                case app.AutomaticZoom
                    app.CallingApp.General.Plot.SelectedStation.AutomaticZoom = app.AutomaticZoom.Value;
                    if app.AutomaticZoom.Value
                        app.AutomaticZoomFactor.Enable = 1;
                    else
                        app.AutomaticZoomFactor.Enable = 0;
                    end

                case app.AutomaticZoomFactor
                    app.CallingApp.General.Plot.SelectedStation.AutomaticZoomFactor = app.AutomaticZoomFactor.Value;
            end

            app.CallingApp.General_I.Plot = app.CallingApp.General.Plot;
            saveGeneralSettings(app)
            
            appBackDoor(app.CallingApp, app, 'updatePlot')
            
        end

        % Value changed function: CircleColor
        function CustomPlot_CircleColorValueChanged(app, event)

            app.CallingApp.General.Plot.CircleRegion.Color = app.CircleColor.Value;

            app.CallingApp.General_I.Plot = app.CallingApp.General.Plot;
            saveGeneralSettings(app)
            
            appBackDoor(app.CallingApp, app, 'updatePlot')
            
        end

        % Callback function: PeakColor, SelectedStationColor, StationsColor
        function CustomPlot_ColorValueChanged(app, event)

            initialColor  = event.PreviousValue;
            selectedColor = event.Value;

            if ~isequal(initialColor, selectedColor)
                selectedColor = rgb2hex(selectedColor);
    
                switch event.Source
                    case app.StationsColor
                        app.CallingApp.General.Plot.Stations.Color        = selectedColor;
                    case app.SelectedStationColor
                        app.CallingApp.General.Plot.SelectedStation.Color = selectedColor;
                    case app.PeakColor
                        app.CallingApp.General.Plot.FieldPeak.Color       = selectedColor;
                end
            end

            app.CallingApp.General_I.Plot = app.CallingApp.General.Plot;
            saveGeneralSettings(app)

            appBackDoor(app.CallingApp, app, 'updatePlot')
            
        end

        % Image clicked function: userPathButton
        function Folder_ButtonPushed(app, event)
            
            selectedFolder = uigetdir(app.CallingApp.General.fileFolder.userPath);
            figure(app.UIFigure)

            if selectedFolder
                app.userPath.Value = selectedFolder;
                app.CallingApp.General.fileFolder.userPath = selectedFolder;

                app.CallingApp.General_I.fileFolder = app.CallingApp.General.fileFolder;
                saveGeneralSettings(app)
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
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x', 34};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create Document
            app.Document = uigridlayout(app.GridLayout);
            app.Document.ColumnWidth = {325, 0, 0, '1x', 0};
            app.Document.RowHeight = {'1x'};
            app.Document.Padding = [5 5 5 5];
            app.Document.Layout.Row = 1;
            app.Document.Layout.Column = 1;
            app.Document.BackgroundColor = [1 1 1];

            % Create ControlPanel
            app.ControlPanel = uigridlayout(app.Document);
            app.ControlPanel.ColumnWidth = {'1x'};
            app.ControlPanel.RowHeight = {22, '1x'};
            app.ControlPanel.RowSpacing = 5;
            app.ControlPanel.Padding = [0 0 0 0];
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;
            app.ControlPanel.BackgroundColor = [1 1 1];

            % Create ControlPanelGrid
            app.ControlPanelGrid = uigridlayout(app.ControlPanel);
            app.ControlPanelGrid.ColumnWidth = {18, '1x'};
            app.ControlPanelGrid.RowHeight = {'1x'};
            app.ControlPanelGrid.ColumnSpacing = 3;
            app.ControlPanelGrid.Padding = [2 0 0 0];
            app.ControlPanelGrid.Layout.Row = 1;
            app.ControlPanelGrid.Layout.Column = 1;
            app.ControlPanelGrid.BackgroundColor = [0.749 0.749 0.749];

            % Create ControlPanelIcon
            app.ControlPanelIcon = uiimage(app.ControlPanelGrid);
            app.ControlPanelIcon.ScaleMethod = 'none';
            app.ControlPanelIcon.Tag = '1';
            app.ControlPanelIcon.Layout.Row = 1;
            app.ControlPanelIcon.Layout.Column = 1;
            app.ControlPanelIcon.HorizontalAlignment = 'left';
            app.ControlPanelIcon.ImageSource = 'Settings_18.png';

            % Create ControlPanelTitle
            app.ControlPanelTitle = uilabel(app.ControlPanelGrid);
            app.ControlPanelTitle.FontSize = 11;
            app.ControlPanelTitle.Layout.Row = 1;
            app.ControlPanelTitle.Layout.Column = 2;
            app.ControlPanelTitle.Text = 'CONFIGURAÇÕES';

            % Create RadioButtonGroupPanel
            app.RadioButtonGroupPanel = uipanel(app.ControlPanel);
            app.RadioButtonGroupPanel.Layout.Row = 2;
            app.RadioButtonGroupPanel.Layout.Column = 1;

            % Create RadioButtonGroupGrid
            app.RadioButtonGroupGrid = uigridlayout(app.RadioButtonGroupPanel);
            app.RadioButtonGroupGrid.ColumnWidth = {'1x'};
            app.RadioButtonGroupGrid.RowHeight = {100, '1x'};
            app.RadioButtonGroupGrid.Padding = [0 0 0 0];
            app.RadioButtonGroupGrid.BackgroundColor = [1 1 1];

            % Create RadioButtonGroup
            app.RadioButtonGroup = uibuttongroup(app.RadioButtonGroupGrid);
            app.RadioButtonGroup.AutoResizeChildren = 'off';
            app.RadioButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @RadioButtonGroupSelectionChanged, true);
            app.RadioButtonGroup.BorderType = 'none';
            app.RadioButtonGroup.BackgroundColor = [1 1 1];
            app.RadioButtonGroup.Layout.Row = 1;
            app.RadioButtonGroup.Layout.Column = 1;
            app.RadioButtonGroup.FontSize = 11;

            % Create btnGeneral
            app.btnGeneral = uiradiobutton(app.RadioButtonGroup);
            app.btnGeneral.Text = 'Aspectos gerais';
            app.btnGeneral.FontSize = 11;
            app.btnGeneral.Position = [11 70 100 22];
            app.btnGeneral.Value = true;

            % Create btnAnalysis
            app.btnAnalysis = uiradiobutton(app.RadioButtonGroup);
            app.btnAnalysis.Text = 'Análise';
            app.btnAnalysis.FontSize = 11;
            app.btnAnalysis.Position = [11 47 168 22];

            % Create btnCustomPlot
            app.btnCustomPlot = uiradiobutton(app.RadioButtonGroup);
            app.btnCustomPlot.Text = 'Customização do plot';
            app.btnCustomPlot.FontSize = 11;
            app.btnCustomPlot.Position = [11 25 128 22];

            % Create btnFolder
            app.btnFolder = uiradiobutton(app.RadioButtonGroup);
            app.btnFolder.Enable = 'off';
            app.btnFolder.Text = 'Mapeamento de pastas';
            app.btnFolder.FontSize = 11;
            app.btnFolder.Position = [11 3 161 22];

            % Create GeneralGrid
            app.GeneralGrid = uigridlayout(app.Document);
            app.GeneralGrid.ColumnWidth = {'1x', 16};
            app.GeneralGrid.RowHeight = {22, 150, 22, '1x', 17, 22, 1, 22, 15};
            app.GeneralGrid.RowSpacing = 5;
            app.GeneralGrid.Padding = [0 0 0 0];
            app.GeneralGrid.Layout.Row = 1;
            app.GeneralGrid.Layout.Column = 2;
            app.GeneralGrid.BackgroundColor = [1 1 1];

            % Create AppVersionLabel
            app.AppVersionLabel = uilabel(app.GeneralGrid);
            app.AppVersionLabel.VerticalAlignment = 'bottom';
            app.AppVersionLabel.FontSize = 10;
            app.AppVersionLabel.Layout.Row = 1;
            app.AppVersionLabel.Layout.Column = 1;
            app.AppVersionLabel.Text = 'ASPECTOS GERAIS';

            % Create AppVersionRefresh
            app.AppVersionRefresh = uiimage(app.GeneralGrid);
            app.AppVersionRefresh.ImageClickedFcn = createCallbackFcn(app, @General_RefreshButtonPushed, true);
            app.AppVersionRefresh.Enable = 'off';
            app.AppVersionRefresh.Tooltip = {'Verifica atualizações'};
            app.AppVersionRefresh.Layout.Row = 1;
            app.AppVersionRefresh.Layout.Column = 2;
            app.AppVersionRefresh.VerticalAlignment = 'bottom';
            app.AppVersionRefresh.ImageSource = 'Refresh_18.png';

            % Create AppVersionPanel
            app.AppVersionPanel = uipanel(app.GeneralGrid);
            app.AppVersionPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AppVersionPanel.Layout.Row = [2 4];
            app.AppVersionPanel.Layout.Column = [1 2];

            % Create AppVersionGrid
            app.AppVersionGrid = uigridlayout(app.AppVersionPanel);
            app.AppVersionGrid.ColumnWidth = {'1x'};
            app.AppVersionGrid.RowHeight = {'1x'};
            app.AppVersionGrid.Padding = [0 0 0 0];
            app.AppVersionGrid.BackgroundColor = [1 1 1];

            % Create AppVersion
            app.AppVersion = uihtml(app.AppVersionGrid);
            app.AppVersion.HTMLSource = ' ';
            app.AppVersion.Layout.Row = 1;
            app.AppVersion.Layout.Column = 1;

            % Create gpuTypeLabel
            app.gpuTypeLabel = uilabel(app.GeneralGrid);
            app.gpuTypeLabel.VerticalAlignment = 'bottom';
            app.gpuTypeLabel.FontSize = 10;
            app.gpuTypeLabel.FontColor = [0.149 0.149 0.149];
            app.gpuTypeLabel.Layout.Row = 5;
            app.gpuTypeLabel.Layout.Column = [1 2];
            app.gpuTypeLabel.Text = 'Unidade gráfica:';

            % Create gpuType
            app.gpuType = uidropdown(app.GeneralGrid);
            app.gpuType.Items = {'hardwarebasic', 'hardware', 'software'};
            app.gpuType.ValueChangedFcn = createCallbackFcn(app, @General_ParameterValueChanged, true);
            app.gpuType.Enable = 'off';
            app.gpuType.FontSize = 11;
            app.gpuType.BackgroundColor = [1 1 1];
            app.gpuType.Layout.Row = 6;
            app.gpuType.Layout.Column = [1 2];
            app.gpuType.Value = 'hardware';

            % Create openAuxiliarAppAsDocked
            app.openAuxiliarAppAsDocked = uicheckbox(app.GeneralGrid);
            app.openAuxiliarAppAsDocked.ValueChangedFcn = createCallbackFcn(app, @General_ParameterValueChanged, true);
            app.openAuxiliarAppAsDocked.Enable = 'off';
            app.openAuxiliarAppAsDocked.Text = 'Modo DOCK: módulos auxiliares abertos na janela principal do app.';
            app.openAuxiliarAppAsDocked.WordWrap = 'on';
            app.openAuxiliarAppAsDocked.FontSize = 11;
            app.openAuxiliarAppAsDocked.Layout.Row = 8;
            app.openAuxiliarAppAsDocked.Layout.Column = [1 2];

            % Create openAuxiliarApp2Debug
            app.openAuxiliarApp2Debug = uicheckbox(app.GeneralGrid);
            app.openAuxiliarApp2Debug.ValueChangedFcn = createCallbackFcn(app, @General_ParameterValueChanged, true);
            app.openAuxiliarApp2Debug.Enable = 'off';
            app.openAuxiliarApp2Debug.Text = 'Modo DEBUG';
            app.openAuxiliarApp2Debug.FontSize = 11;
            app.openAuxiliarApp2Debug.Layout.Row = 9;
            app.openAuxiliarApp2Debug.Layout.Column = [1 2];

            % Create AnalysisGrid
            app.AnalysisGrid = uigridlayout(app.Document);
            app.AnalysisGrid.ColumnWidth = {'1x'};
            app.AnalysisGrid.RowHeight = {22, '1x'};
            app.AnalysisGrid.RowSpacing = 5;
            app.AnalysisGrid.Padding = [0 0 0 0];
            app.AnalysisGrid.Layout.Row = 1;
            app.AnalysisGrid.Layout.Column = 3;
            app.AnalysisGrid.BackgroundColor = [1 1 1];

            % Create AnalysisTitle
            app.AnalysisTitle = uilabel(app.AnalysisGrid);
            app.AnalysisTitle.VerticalAlignment = 'bottom';
            app.AnalysisTitle.FontSize = 10;
            app.AnalysisTitle.Layout.Row = 1;
            app.AnalysisTitle.Layout.Column = 1;
            app.AnalysisTitle.Text = 'ANÁLISE';

            % Create AnalysisPanel
            app.AnalysisPanel = uipanel(app.AnalysisGrid);
            app.AnalysisPanel.Layout.Row = 2;
            app.AnalysisPanel.Layout.Column = 1;

            % Create AnalysisPanelGrid
            app.AnalysisPanelGrid = uigridlayout(app.AnalysisPanel);
            app.AnalysisPanelGrid.ColumnWidth = {'1x'};
            app.AnalysisPanelGrid.RowHeight = {17, '1x', 22, '1x'};
            app.AnalysisPanelGrid.RowSpacing = 5;
            app.AnalysisPanelGrid.Padding = [10 10 10 5];
            app.AnalysisPanelGrid.BackgroundColor = [1 1 1];

            % Create MonitoringPlanLabel
            app.MonitoringPlanLabel = uilabel(app.AnalysisPanelGrid);
            app.MonitoringPlanLabel.VerticalAlignment = 'bottom';
            app.MonitoringPlanLabel.FontSize = 10;
            app.MonitoringPlanLabel.Layout.Row = 1;
            app.MonitoringPlanLabel.Layout.Column = 1;
            app.MonitoringPlanLabel.Text = 'PM-RNI';

            % Create MonitoringPlanPanel
            app.MonitoringPlanPanel = uipanel(app.AnalysisPanelGrid);
            app.MonitoringPlanPanel.Layout.Row = 2;
            app.MonitoringPlanPanel.Layout.Column = 1;

            % Create MonitoringPlanGrid
            app.MonitoringPlanGrid = uigridlayout(app.MonitoringPlanPanel);
            app.MonitoringPlanGrid.ColumnWidth = {190, 90, '1x'};
            app.MonitoringPlanGrid.RowHeight = {22, 22, 22, '1x'};
            app.MonitoringPlanGrid.RowSpacing = 5;
            app.MonitoringPlanGrid.BackgroundColor = [1 1 1];

            % Create MonitoringPlanDistanceLabel
            app.MonitoringPlanDistanceLabel = uilabel(app.MonitoringPlanGrid);
            app.MonitoringPlanDistanceLabel.WordWrap = 'on';
            app.MonitoringPlanDistanceLabel.FontSize = 10;
            app.MonitoringPlanDistanceLabel.Layout.Row = 1;
            app.MonitoringPlanDistanceLabel.Layout.Column = [1 2];
            app.MonitoringPlanDistanceLabel.Text = {'Distância limite entre ponto de medição e '; 'a estação sob análise (m):'};

            % Create MonitoringPlanDistance
            app.MonitoringPlanDistance = uieditfield(app.MonitoringPlanGrid, 'numeric');
            app.MonitoringPlanDistance.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.MonitoringPlanDistance.FontSize = 11;
            app.MonitoringPlanDistance.Layout.Row = 1;
            app.MonitoringPlanDistance.Layout.Column = 2;
            app.MonitoringPlanDistance.Value = 200;

            % Create MonitoringPlanLevelLabel
            app.MonitoringPlanLevelLabel = uilabel(app.MonitoringPlanGrid);
            app.MonitoringPlanLevelLabel.WordWrap = 'on';
            app.MonitoringPlanLevelLabel.FontSize = 10;
            app.MonitoringPlanLevelLabel.Layout.Row = 2;
            app.MonitoringPlanLevelLabel.Layout.Column = 1;
            app.MonitoringPlanLevelLabel.Text = 'Nível de referência de campo elétrico: (V/m)';

            % Create MonitoringPlanLevel
            app.MonitoringPlanLevel = uieditfield(app.MonitoringPlanGrid, 'numeric');
            app.MonitoringPlanLevel.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.MonitoringPlanLevel.FontSize = 11;
            app.MonitoringPlanLevel.Layout.Row = 2;
            app.MonitoringPlanLevel.Layout.Column = 2;
            app.MonitoringPlanLevel.Value = 14;

            % Create MonitoringPlanReasonsListLabel
            app.MonitoringPlanReasonsListLabel = uilabel(app.MonitoringPlanGrid);
            app.MonitoringPlanReasonsListLabel.VerticalAlignment = 'bottom';
            app.MonitoringPlanReasonsListLabel.FontSize = 10;
            app.MonitoringPlanReasonsListLabel.Layout.Row = 3;
            app.MonitoringPlanReasonsListLabel.Layout.Column = 1;
            app.MonitoringPlanReasonsListLabel.Text = 'Lista de jutificativas:';

            % Create MonitoringPlanReasonsList
            app.MonitoringPlanReasonsList = uilistbox(app.MonitoringPlanGrid);
            app.MonitoringPlanReasonsList.Items = {''};
            app.MonitoringPlanReasonsList.FontSize = 11;
            app.MonitoringPlanReasonsList.Layout.Row = 4;
            app.MonitoringPlanReasonsList.Layout.Column = [1 3];
            app.MonitoringPlanReasonsList.Value = '';

            % Create ExternalRequestLabel
            app.ExternalRequestLabel = uilabel(app.AnalysisPanelGrid);
            app.ExternalRequestLabel.VerticalAlignment = 'bottom';
            app.ExternalRequestLabel.FontSize = 10;
            app.ExternalRequestLabel.Layout.Row = 3;
            app.ExternalRequestLabel.Layout.Column = 1;
            app.ExternalRequestLabel.Text = 'DEMANDA EXTERNA';

            % Create ExternalRequestPanel
            app.ExternalRequestPanel = uipanel(app.AnalysisPanelGrid);
            app.ExternalRequestPanel.Layout.Row = 4;
            app.ExternalRequestPanel.Layout.Column = 1;

            % Create ExternalRequestGrid
            app.ExternalRequestGrid = uigridlayout(app.ExternalRequestPanel);
            app.ExternalRequestGrid.ColumnWidth = {190, 90, '1x'};
            app.ExternalRequestGrid.RowHeight = {22, 22};
            app.ExternalRequestGrid.RowSpacing = 5;
            app.ExternalRequestGrid.BackgroundColor = [1 1 1];

            % Create ExternalRequestDistanceLabel
            app.ExternalRequestDistanceLabel = uilabel(app.ExternalRequestGrid);
            app.ExternalRequestDistanceLabel.WordWrap = 'on';
            app.ExternalRequestDistanceLabel.FontSize = 10;
            app.ExternalRequestDistanceLabel.Layout.Row = 1;
            app.ExternalRequestDistanceLabel.Layout.Column = [1 2];
            app.ExternalRequestDistanceLabel.Text = {'Distância limite entre ponto de medição e '; 'a estação sob análise (m):'};

            % Create ExternalRequestDistance
            app.ExternalRequestDistance = uieditfield(app.ExternalRequestGrid, 'numeric');
            app.ExternalRequestDistance.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.ExternalRequestDistance.FontSize = 11;
            app.ExternalRequestDistance.Layout.Row = 1;
            app.ExternalRequestDistance.Layout.Column = 2;
            app.ExternalRequestDistance.Value = 200;

            % Create ExternalRequestLevelLabel
            app.ExternalRequestLevelLabel = uilabel(app.ExternalRequestGrid);
            app.ExternalRequestLevelLabel.WordWrap = 'on';
            app.ExternalRequestLevelLabel.FontSize = 10;
            app.ExternalRequestLevelLabel.Layout.Row = 2;
            app.ExternalRequestLevelLabel.Layout.Column = 1;
            app.ExternalRequestLevelLabel.Text = 'Nível de referência de campo elétrico: (V/m)';

            % Create ExternalRequestLevel
            app.ExternalRequestLevel = uieditfield(app.ExternalRequestGrid, 'numeric');
            app.ExternalRequestLevel.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.ExternalRequestLevel.FontSize = 11;
            app.ExternalRequestLevel.Layout.Row = 2;
            app.ExternalRequestLevel.Layout.Column = 2;
            app.ExternalRequestLevel.Value = 14;

            % Create CustomPlotGrid
            app.CustomPlotGrid = uigridlayout(app.Document);
            app.CustomPlotGrid.ColumnWidth = {'1x', 16};
            app.CustomPlotGrid.RowHeight = {22, '1x'};
            app.CustomPlotGrid.RowSpacing = 5;
            app.CustomPlotGrid.Padding = [0 0 0 0];
            app.CustomPlotGrid.Layout.Row = 1;
            app.CustomPlotGrid.Layout.Column = 4;
            app.CustomPlotGrid.BackgroundColor = [1 1 1];

            % Create CustomPlotTitle
            app.CustomPlotTitle = uilabel(app.CustomPlotGrid);
            app.CustomPlotTitle.VerticalAlignment = 'bottom';
            app.CustomPlotTitle.FontSize = 10;
            app.CustomPlotTitle.Layout.Row = 1;
            app.CustomPlotTitle.Layout.Column = 1;
            app.CustomPlotTitle.Text = 'CUSTOMIZAÇÃO DO PLOT';

            % Create CustomPlotPanel
            app.CustomPlotPanel = uipanel(app.CustomPlotGrid);
            app.CustomPlotPanel.Layout.Row = 2;
            app.CustomPlotPanel.Layout.Column = [1 2];

            % Create CustomPlotPanelGrid
            app.CustomPlotPanelGrid = uigridlayout(app.CustomPlotPanel);
            app.CustomPlotPanelGrid.ColumnWidth = {190, 36, 44, 90, '1x'};
            app.CustomPlotPanelGrid.RowHeight = {22, 22, 22, 22, 22, 22, 22, 22, 1, 22, 22, 22};
            app.CustomPlotPanelGrid.RowSpacing = 5;
            app.CustomPlotPanelGrid.BackgroundColor = [1 1 1];

            % Create BasemapLabel
            app.BasemapLabel = uilabel(app.CustomPlotPanelGrid);
            app.BasemapLabel.FontSize = 10;
            app.BasemapLabel.Layout.Row = 1;
            app.BasemapLabel.Layout.Column = 1;
            app.BasemapLabel.Text = 'Basemap:';

            % Create Basemap
            app.Basemap = uidropdown(app.CustomPlotPanelGrid);
            app.Basemap.Items = {'darkwater', 'streets-light', 'streets-dark', 'satellite', 'topographic', 'grayterrain'};
            app.Basemap.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.Basemap.FontSize = 11;
            app.Basemap.BackgroundColor = [1 1 1];
            app.Basemap.Layout.Row = 1;
            app.Basemap.Layout.Column = [2 4];
            app.Basemap.Value = 'streets-light';

            % Create ColormapLabel
            app.ColormapLabel = uilabel(app.CustomPlotPanelGrid);
            app.ColormapLabel.FontSize = 10;
            app.ColormapLabel.Layout.Row = 2;
            app.ColormapLabel.Layout.Column = 1;
            app.ColormapLabel.Text = 'Mapa de cor:';

            % Create Colormap
            app.Colormap = uidropdown(app.CustomPlotPanelGrid);
            app.Colormap.Items = {'winter', 'parula', 'turbo', 'gray', 'hot', 'jet', 'summer'};
            app.Colormap.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.Colormap.FontSize = 11;
            app.Colormap.BackgroundColor = [1 1 1];
            app.Colormap.Layout.Row = 2;
            app.Colormap.Layout.Column = [2 4];
            app.Colormap.Value = 'winter';

            % Create ColorbarLabel
            app.ColorbarLabel = uilabel(app.CustomPlotPanelGrid);
            app.ColorbarLabel.FontSize = 10;
            app.ColorbarLabel.Layout.Row = 3;
            app.ColorbarLabel.Layout.Column = 1;
            app.ColorbarLabel.Text = 'Legenda de cor:';

            % Create Colorbar
            app.Colorbar = uidropdown(app.CustomPlotPanelGrid);
            app.Colorbar.Items = {'off', 'east', 'eastoutside', 'south', 'southoutside'};
            app.Colorbar.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.Colorbar.FontSize = 11;
            app.Colorbar.BackgroundColor = [1 1 1];
            app.Colorbar.Layout.Row = 3;
            app.Colorbar.Layout.Column = [2 4];
            app.Colorbar.Value = 'off';

            % Create StationsLabel
            app.StationsLabel = uilabel(app.CustomPlotPanelGrid);
            app.StationsLabel.WordWrap = 'on';
            app.StationsLabel.FontSize = 10;
            app.StationsLabel.Layout.Row = 4;
            app.StationsLabel.Layout.Column = [1 2];
            app.StationsLabel.Text = 'Estações de referência:';

            % Create StationsColor
            app.StationsColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.StationsColor.Value = [0 1 1];
            app.StationsColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ColorValueChanged, true);
            app.StationsColor.Layout.Row = 4;
            app.StationsColor.Layout.Column = 2;
            app.StationsColor.BackgroundColor = [1 1 1];

            % Create StationsSize
            app.StationsSize = uislider(app.CustomPlotPanelGrid);
            app.StationsSize.Limits = [1 36];
            app.StationsSize.MajorTicks = [];
            app.StationsSize.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.StationsSize.MinorTicks = [];
            app.StationsSize.FontSize = 10;
            app.StationsSize.Tooltip = {'Tamanho do marcador'};
            app.StationsSize.Layout.Row = 4;
            app.StationsSize.Layout.Column = [3 4];
            app.StationsSize.Value = 1;

            % Create SelectedStationLabel
            app.SelectedStationLabel = uilabel(app.CustomPlotPanelGrid);
            app.SelectedStationLabel.WordWrap = 'on';
            app.SelectedStationLabel.FontSize = 10;
            app.SelectedStationLabel.Layout.Row = 5;
            app.SelectedStationLabel.Layout.Column = 1;
            app.SelectedStationLabel.Text = 'Estação sob análise:';

            % Create SelectedStationColor
            app.SelectedStationColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.SelectedStationColor.Value = [0.7882 0.2784 0.3412];
            app.SelectedStationColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ColorValueChanged, true);
            app.SelectedStationColor.Layout.Row = 5;
            app.SelectedStationColor.Layout.Column = 2;
            app.SelectedStationColor.BackgroundColor = [1 1 1];

            % Create SelectedStationSize
            app.SelectedStationSize = uislider(app.CustomPlotPanelGrid);
            app.SelectedStationSize.Limits = [1 36];
            app.SelectedStationSize.MajorTicks = [];
            app.SelectedStationSize.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.SelectedStationSize.MinorTicks = [];
            app.SelectedStationSize.FontSize = 10;
            app.SelectedStationSize.Tooltip = {'Tamanho do marcador'};
            app.SelectedStationSize.Layout.Row = 5;
            app.SelectedStationSize.Layout.Column = [3 4];
            app.SelectedStationSize.Value = 1;

            % Create PeakLabel
            app.PeakLabel = uilabel(app.CustomPlotPanelGrid);
            app.PeakLabel.WordWrap = 'on';
            app.PeakLabel.FontSize = 10;
            app.PeakLabel.Layout.Row = 6;
            app.PeakLabel.Layout.Column = 1;
            app.PeakLabel.Text = 'Pico em torno da estação:';

            % Create PeakColor
            app.PeakColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.PeakColor.Value = [0.7882 0.2784 0.3373];
            app.PeakColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ColorValueChanged, true);
            app.PeakColor.Layout.Row = 6;
            app.PeakColor.Layout.Column = 2;
            app.PeakColor.BackgroundColor = [1 1 1];

            % Create PeakSize
            app.PeakSize = uislider(app.CustomPlotPanelGrid);
            app.PeakSize.Limits = [1 36];
            app.PeakSize.MajorTicks = [];
            app.PeakSize.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.PeakSize.MinorTicks = [];
            app.PeakSize.FontSize = 10;
            app.PeakSize.Tooltip = {'Tamanho do marcador'};
            app.PeakSize.Layout.Row = 6;
            app.PeakSize.Layout.Column = [3 4];
            app.PeakSize.Value = 1;

            % Create CircleColorLabel
            app.CircleColorLabel = uilabel(app.CustomPlotPanelGrid);
            app.CircleColorLabel.WordWrap = 'on';
            app.CircleColorLabel.FontSize = 10;
            app.CircleColorLabel.Layout.Row = 7;
            app.CircleColorLabel.Layout.Column = 1;
            app.CircleColorLabel.Text = {'Região circular em torno da estação: '; '(cor)'};

            % Create CircleColor
            app.CircleColor = uidropdown(app.CustomPlotPanelGrid);
            app.CircleColor.Items = {'black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow'};
            app.CircleColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_CircleColorValueChanged, true);
            app.CircleColor.FontSize = 11;
            app.CircleColor.BackgroundColor = [1 1 1];
            app.CircleColor.Layout.Row = 7;
            app.CircleColor.Layout.Column = [2 4];
            app.CircleColor.Value = 'black';

            % Create CircleColorAlphaLabel
            app.CircleColorAlphaLabel = uilabel(app.CustomPlotPanelGrid);
            app.CircleColorAlphaLabel.WordWrap = 'on';
            app.CircleColorAlphaLabel.FontSize = 10;
            app.CircleColorAlphaLabel.Layout.Row = 8;
            app.CircleColorAlphaLabel.Layout.Column = 1;
            app.CircleColorAlphaLabel.Text = {'Região circular em torno da estação: '; '(transparência da face e borda)'};

            % Create CircleFaceAlpha
            app.CircleFaceAlpha = uispinner(app.CustomPlotPanelGrid);
            app.CircleFaceAlpha.Step = 0.05;
            app.CircleFaceAlpha.Limits = [0 1];
            app.CircleFaceAlpha.ValueDisplayFormat = '%.2f';
            app.CircleFaceAlpha.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.CircleFaceAlpha.FontSize = 11;
            app.CircleFaceAlpha.Layout.Row = 8;
            app.CircleFaceAlpha.Layout.Column = [2 3];

            % Create CircleEdgeAlpha
            app.CircleEdgeAlpha = uispinner(app.CustomPlotPanelGrid);
            app.CircleEdgeAlpha.Step = 0.05;
            app.CircleEdgeAlpha.Limits = [0 1];
            app.CircleEdgeAlpha.ValueDisplayFormat = '%.2f';
            app.CircleEdgeAlpha.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.CircleEdgeAlpha.FontSize = 11;
            app.CircleEdgeAlpha.Layout.Row = 8;
            app.CircleEdgeAlpha.Layout.Column = 4;

            % Create AutomaticZoom
            app.AutomaticZoom = uicheckbox(app.CustomPlotPanelGrid);
            app.AutomaticZoom.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.AutomaticZoom.Text = 'Habilitar zoom automático em torno da estação sob análise.';
            app.AutomaticZoom.FontSize = 11;
            app.AutomaticZoom.Layout.Row = 10;
            app.AutomaticZoom.Layout.Column = [1 5];

            % Create AutomaticZoomFactorLabel
            app.AutomaticZoomFactorLabel = uilabel(app.CustomPlotPanelGrid);
            app.AutomaticZoomFactorLabel.FontSize = 10;
            app.AutomaticZoomFactorLabel.Layout.Row = 11;
            app.AutomaticZoomFactorLabel.Layout.Column = 1;
            app.AutomaticZoomFactorLabel.Text = {'Fator do zoom: '; '(distância referência)'};

            % Create AutomaticZoomFactor
            app.AutomaticZoomFactor = uispinner(app.CustomPlotPanelGrid);
            app.AutomaticZoomFactor.Limits = [1 10];
            app.AutomaticZoomFactor.RoundFractionalValues = 'on';
            app.AutomaticZoomFactor.ValueDisplayFormat = '%d';
            app.AutomaticZoomFactor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
            app.AutomaticZoomFactor.FontSize = 11;
            app.AutomaticZoomFactor.Enable = 'off';
            app.AutomaticZoomFactor.Layout.Row = 11;
            app.AutomaticZoomFactor.Layout.Column = [2 3];
            app.AutomaticZoomFactor.Value = 1;

            % Create FolderGrid
            app.FolderGrid = uigridlayout(app.Document);
            app.FolderGrid.ColumnWidth = {'1x'};
            app.FolderGrid.RowHeight = {22, 5, '1x', 1};
            app.FolderGrid.RowSpacing = 0;
            app.FolderGrid.Padding = [0 0 0 0];
            app.FolderGrid.Layout.Row = 1;
            app.FolderGrid.Layout.Column = 5;
            app.FolderGrid.BackgroundColor = [1 1 1];

            % Create FolderTitle
            app.FolderTitle = uilabel(app.FolderGrid);
            app.FolderTitle.VerticalAlignment = 'bottom';
            app.FolderTitle.FontSize = 10;
            app.FolderTitle.Layout.Row = 1;
            app.FolderTitle.Layout.Column = 1;
            app.FolderTitle.Text = 'MAPEAMENTO DE PASTAS';

            % Create FolderPanel
            app.FolderPanel = uipanel(app.FolderGrid);
            app.FolderPanel.AutoResizeChildren = 'off';
            app.FolderPanel.Layout.Row = 3;
            app.FolderPanel.Layout.Column = 1;

            % Create FolderPanelGrid
            app.FolderPanelGrid = uigridlayout(app.FolderPanel);
            app.FolderPanelGrid.ColumnWidth = {'1x', 20};
            app.FolderPanelGrid.RowHeight = {17, 22, 17, 22, '1x'};
            app.FolderPanelGrid.ColumnSpacing = 5;
            app.FolderPanelGrid.RowSpacing = 5;
            app.FolderPanelGrid.BackgroundColor = [1 1 1];

            % Create userPathLabel
            app.userPathLabel = uilabel(app.FolderPanelGrid);
            app.userPathLabel.VerticalAlignment = 'bottom';
            app.userPathLabel.FontSize = 10;
            app.userPathLabel.Layout.Row = 1;
            app.userPathLabel.Layout.Column = 1;
            app.userPathLabel.Text = 'Pasta do usuário:';

            % Create userPath
            app.userPath = uieditfield(app.FolderPanelGrid, 'text');
            app.userPath.Editable = 'off';
            app.userPath.FontSize = 11;
            app.userPath.Layout.Row = 2;
            app.userPath.Layout.Column = 1;

            % Create userPathButton
            app.userPathButton = uiimage(app.FolderPanelGrid);
            app.userPathButton.ImageClickedFcn = createCallbackFcn(app, @Folder_ButtonPushed, true);
            app.userPathButton.Tag = 'userPath';
            app.userPathButton.Layout.Row = 2;
            app.userPathButton.Layout.Column = 2;
            app.userPathButton.ImageSource = 'OpenFile_36x36.png';

            % Create tempPathLabel
            app.tempPathLabel = uilabel(app.FolderPanelGrid);
            app.tempPathLabel.VerticalAlignment = 'bottom';
            app.tempPathLabel.FontSize = 10;
            app.tempPathLabel.Layout.Row = 3;
            app.tempPathLabel.Layout.Column = 1;
            app.tempPathLabel.Text = 'Pasta temporária:';

            % Create tempPath
            app.tempPath = uieditfield(app.FolderPanelGrid, 'text');
            app.tempPath.Editable = 'off';
            app.tempPath.FontSize = 11;
            app.tempPath.Layout.Row = 4;
            app.tempPath.Layout.Column = 1;

            % Create Toolbar
            app.Toolbar = uigridlayout(app.GridLayout);
            app.Toolbar.ColumnWidth = {22, 22, '1x', 22};
            app.Toolbar.RowHeight = {4, 17, '1x'};
            app.Toolbar.ColumnSpacing = 5;
            app.Toolbar.RowSpacing = 0;
            app.Toolbar.Padding = [0 5 5 5];
            app.Toolbar.Layout.Row = 2;
            app.Toolbar.Layout.Column = 1;
            app.Toolbar.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create tool_LeftPanelVisibility
            app.tool_LeftPanelVisibility = uiimage(app.Toolbar);
            app.tool_LeftPanelVisibility.ImageClickedFcn = createCallbackFcn(app, @tool_LeftPanelVisibilityClicked, true);
            app.tool_LeftPanelVisibility.Layout.Row = 2;
            app.tool_LeftPanelVisibility.Layout.Column = 1;
            app.tool_LeftPanelVisibility.ImageSource = 'ArrowLeft_32.png';

            % Create tool_RFDataHubButton
            app.tool_RFDataHubButton = uiimage(app.Toolbar);
            app.tool_RFDataHubButton.ImageClickedFcn = createCallbackFcn(app, @tool_RFDataHubButtonPushed, true);
            app.tool_RFDataHubButton.Enable = 'off';
            app.tool_RFDataHubButton.Tooltip = {'Atualiza RFDataHub'};
            app.tool_RFDataHubButton.Layout.Row = 2;
            app.tool_RFDataHubButton.Layout.Column = 2;
            app.tool_RFDataHubButton.ImageSource = 'mosaic_32.png';

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.Toolbar);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 4;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winConfig_exported(Container, varargin)

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
