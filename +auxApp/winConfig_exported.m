classdef winConfig_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        Toolbar                       matlab.ui.container.GridLayout
        jsBackDoor                    matlab.ui.control.HTML
        tool_RFDataHubButton          matlab.ui.control.Image
        tool_LeftPanelVisibility      matlab.ui.control.Image
        Document                      matlab.ui.container.GridLayout
        AnalysisPanelGrid             matlab.ui.container.GridLayout
        ExternalRequestPanel          matlab.ui.container.Panel
        ExternalRequestGrid           matlab.ui.container.GridLayout
        ExternalRequestLevel          matlab.ui.control.NumericEditField
        ExternalRequestLevelLabel     matlab.ui.control.Label
        ExternalRequestDistance       matlab.ui.control.NumericEditField
        ExternalRequestDistanceLabel  matlab.ui.control.Label
        ExternalRequestLabel          matlab.ui.control.Label
        MonitoringPlanPanel           matlab.ui.container.Panel
        MonitoringPlanGrid            matlab.ui.container.GridLayout
        MonitoringPlanExportKML       matlab.ui.control.CheckBox
        MonitoringPlanExportXLSX      matlab.ui.control.CheckBox
        MonitoringPlanPeriod          matlab.ui.container.CheckBoxTree
        MonitoringPlanOpenFile        matlab.ui.control.Image
        MonitoringPlanFileName        matlab.ui.control.EditField
        MonitoringPlanFileLabel       matlab.ui.control.Label
        MonitoringPlanLevel           matlab.ui.control.NumericEditField
        MonitoringPlanLevelLabel      matlab.ui.control.Label
        MonitoringPlanDistance        matlab.ui.control.NumericEditField
        MonitoringPlanDistanceLabel   matlab.ui.control.Label
        MonitoringPlanLabel           matlab.ui.control.Label
        FolderGrid                    matlab.ui.container.GridLayout
        FolderPanel                   matlab.ui.container.Panel
        FolderPanelGrid               matlab.ui.container.GridLayout
        tempPath                      matlab.ui.control.EditField
        tempPathLabel                 matlab.ui.control.Label
        userPathButton                matlab.ui.control.Image
        userPath                      matlab.ui.control.EditField
        userPathLabel                 matlab.ui.control.Label
        DataHubPOSTButton             matlab.ui.control.Image
        DataHubPOST                   matlab.ui.control.EditField
        DataHubPOSTLabel              matlab.ui.control.Label
        FolderTitle                   matlab.ui.control.Label
        CustomPlotGrid                matlab.ui.container.GridLayout
        CustomPlotPanel               matlab.ui.container.Panel
        CustomPlotPanelGrid           matlab.ui.container.GridLayout
        AutomaticZoomFactor           matlab.ui.control.Spinner
        AutomaticZoomFactorLabel      matlab.ui.control.Label
        AutomaticZoom                 matlab.ui.control.CheckBox
        CircleEdgeAlpha               matlab.ui.control.Spinner
        CircleFaceAlpha               matlab.ui.control.Spinner
        CircleColorAlphaLabel         matlab.ui.control.Label
        CircleColor                   matlab.ui.control.DropDown
        CircleColorLabel              matlab.ui.control.Label
        PeakSize                      matlab.ui.control.Slider
        PeakColor                     matlab.ui.control.ColorPicker
        PeakLabel                     matlab.ui.control.Label
        SelectedStationSize           matlab.ui.control.Slider
        SelectedStationColor          matlab.ui.control.ColorPicker
        SelectedStationLabel          matlab.ui.control.Label
        StationsSize                  matlab.ui.control.Slider
        StationsColor                 matlab.ui.control.ColorPicker
        StationsLabel                 matlab.ui.control.Label
        Colorbar                      matlab.ui.control.DropDown
        ColorbarLabel                 matlab.ui.control.Label
        Colormap                      matlab.ui.control.DropDown
        ColormapLabel                 matlab.ui.control.Label
        Basemap                       matlab.ui.control.DropDown
        BasemapLabel                  matlab.ui.control.Label
        CustomPlotRefresh             matlab.ui.control.Image
        CustomPlotTitle               matlab.ui.control.Label
        GeneralGrid                   matlab.ui.container.GridLayout
        openAuxiliarApp2Debug         matlab.ui.control.CheckBox
        openAuxiliarAppAsDocked       matlab.ui.control.CheckBox
        gpuType                       matlab.ui.control.DropDown
        gpuTypeLabel                  matlab.ui.control.Label
        AppVersionPanel               matlab.ui.container.Panel
        AppVersionGrid                matlab.ui.container.GridLayout
        AppVersion                    matlab.ui.control.HTML
        AppVersionRefresh             matlab.ui.control.Image
        AppVersionLabel               matlab.ui.control.Label
        ControlPanel                  matlab.ui.container.GridLayout
        RadioButtonGroupPanel         matlab.ui.container.Panel
        RadioButtonGroupGrid          matlab.ui.container.GridLayout
        RadioButtonGroup              matlab.ui.container.ButtonGroup
        btnFolder                     matlab.ui.control.RadioButton
        btnCustomPlot                 matlab.ui.control.RadioButton
        btnAnalysis                   matlab.ui.control.RadioButton
        btnGeneral                    matlab.ui.control.RadioButton
        ControlPanelGrid              matlab.ui.container.GridLayout
        ControlPanelTitle             matlab.ui.control.Label
        ControlPanelIcon              matlab.ui.control.Image
    end

    
    properties
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
                app.progressDialog = app.mainApp.progressDialog;
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

            if ~strcmp(app.mainApp.executionMode, 'webApp')
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
            htmlContent = auxApp.config.htmlCode_AppVersion(app.mainApp.General, app.mainApp.executionMode);
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
            app.openAuxiliarAppAsDocked.Value   = app.mainApp.General.operationMode.Dock;
            app.openAuxiliarApp2Debug.Value     = app.mainApp.General.operationMode.Debug;
        end

        %-----------------------------------------------------------------%
        function Analysis_updatePanel(app)
            % PM-RNI
            app.MonitoringPlanDistance.Value    = app.mainApp.General.MonitoringPlan.Distance_km * 1000;
            app.MonitoringPlanLevel.Value       = app.mainApp.General.MonitoringPlan.FieldValue;
            app.MonitoringPlanFileName.Value    = app.mainApp.General.MonitoringPlan.ReferenceFile;
            
            MonitoringPlanYearsOptions          = app.mainApp.projectData.rawListOfYears;
            MonitoringPlanYearsValue            = app.mainApp.General.MonitoringPlan.Period;
            for ii = 1:numel(MonitoringPlanYearsOptions)                
                treeNode = uitreenode(app.MonitoringPlanPeriod, 'Text', string(MonitoringPlanYearsOptions(ii)));
                if ismember(MonitoringPlanYearsOptions(ii), MonitoringPlanYearsValue)
                    app.MonitoringPlanPeriod.CheckedNodes = [app.MonitoringPlanPeriod.CheckedNodes; treeNode];
                end
            end

            app.MonitoringPlanExportXLSX.Value  = app.mainApp.General.MonitoringPlan.Export.XLSX;
            app.MonitoringPlanExportKML.Value   = app.mainApp.General.MonitoringPlan.Export.KML;

            % External Request
            app.ExternalRequestDistance.Value   = app.mainApp.General.ExternalRequest.Distance_km * 1000;
            app.ExternalRequestLevel.Value      = app.mainApp.General.ExternalRequest.FieldValue;
        end

        %-----------------------------------------------------------------%
        function CustomPlot_updatePanel(app)
            app.Basemap.Value              = app.mainApp.General.Plot.GeographicAxes.Basemap;
            app.Colormap.Value             = app.mainApp.General.Plot.GeographicAxes.Colormap;
            app.Colorbar.Value             = app.mainApp.General.Plot.GeographicAxes.Colorbar;

            app.StationsColor.Value        = app.mainApp.General.Plot.Stations.Color;
            app.StationsSize.Value         = app.mainApp.General.Plot.Stations.Size;

            app.SelectedStationColor.Value = app.mainApp.General.Plot.SelectedStation.Color;
            app.SelectedStationSize.Value  = app.mainApp.General.Plot.SelectedStation.Size;

            app.CircleColor.Value          = app.mainApp.General.Plot.CircleRegion.Color;
            app.CircleFaceAlpha.Value      = app.mainApp.General.Plot.CircleRegion.FaceAlpha;
            app.CircleEdgeAlpha.Value      = app.mainApp.General.Plot.CircleRegion.EdgeAlpha;

            app.AutomaticZoom.Value        = app.mainApp.General.Plot.SelectedStation.AutomaticZoom;
            app.AutomaticZoomFactor.Value  = app.mainApp.General.Plot.SelectedStation.AutomaticZoomFactor;
            if app.AutomaticZoom.Value
                app.AutomaticZoomFactor.Enable = 1;
            else
                app.AutomaticZoomFactor.Enable = 0;
            end

            app.PeakColor.Value            = app.mainApp.General.Plot.FieldPeak.Color;
            app.PeakSize.Value             = app.mainApp.General.Plot.FieldPeak.Size;
        end

        %-----------------------------------------------------------------%
        function Folder_updatePanel(app)
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.btnFolder.Enable       = 1;
                app.DataHubPOST.Value      = app.mainApp.General.fileFolder.DataHub_POST;
                app.userPath.Value         = app.mainApp.General.fileFolder.userPath;
                app.tempPath.Value         = app.mainApp.General.fileFolder.tempPath;
            end
        end

        %-----------------------------------------------------------------%
        function saveGeneralSettings(app)
            appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.mainApp.General_I, app.mainApp.executionMode)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            % A razão de ser deste app é possibilitar visualização/edição 
            % de algumas das informações do arquivo "GeneralSettings.json".
            app.mainApp    = mainapp;
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
            
            appBackDoor(app.mainApp, app, 'closeFcn', 'CONFIG')
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
            
            if isequal(app.mainApp.General.AppVersion.RFDataHub,  app.stableVersion.RFDataHub)
                app.tool_RFDataHubButton.Enable = 0;
                appUtil.modalWindow(app.UIFigure, 'warning', 'Módulo RFDataHub já atualizado!');
                return
            end

            d = appUtil.modalWindow(app.UIFigure, "progressdlg", 'Em andamento... esse processo pode demorar alguns minutos!');

            try
                [~, ~, rfdatahubLink] = fcn.PublicLinks(app.rootFolder);
                tempDir = app.mainApp.General.fileFolder.tempPath;
                websave(fullfile(tempDir, 'estacoes.parquet.gzip'), rfdatahubLink.Table);
                websave(fullfile(tempDir, 'log.parquet.gzip'),      rfdatahubLink.Log);
                websave(fullfile(tempDir, 'Release.json'),          rfdatahubLink.Release);

                appName = class.Constants.appName;
                [~, ...
                 programDataFolder] = appUtil.Path(appName, app.rootFolder);

                if isfile(fullfile(programDataFolder, 'RFDataHub_old.mat'))
                    delete(fullfile(programDataFolder, 'RFDataHub_old.mat'))
                end

                if isfile(fullfile(programDataFolder, 'RFDataHub.mat'))
                    movefile(fullfile(programDataFolder, 'RFDataHub.mat'), fullfile(programDataFolder, 'RFDataHub_old.mat'), 'f');
                end

                % Apaga as variáveis globais, lendo os novos arquivos.
                clear global RFDataHub
                clear global RFDataHubLog
                clear global RFDataHub_info
                RF.RFDataHub.read(appName, app.rootFolder, tempDir)

                % Atualiza versão.
                global RFDataHub_info
                app.mainApp.General.AppVersion.RFDataHub = RFDataHub_info;
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

            [htmlContent, app.stableVersion, updatedModule] = auxApp.config.htmlCode_CheckAvailableUpdate(app.mainApp.General, app.rootFolder);
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
                        
                        app.mainApp.General.openGL = app.gpuType.Value;
                        app.mainApp.General.AppVersion.OpenGL = rmfield(graphRender, {'MaxTextureSize', 'Visual', 'SupportsGraphicsSmoothing', 'SupportsDepthPeelTransparency', 'SupportsAlignVertexCenters', 'Extensions', 'MaxFrameBufferSize'});
                    end

                case app.openAuxiliarAppAsDocked
                    app.mainApp.General.operationMode.Dock  = app.openAuxiliarAppAsDocked.Value;

                case app.openAuxiliarApp2Debug
                    app.mainApp.General.operationMode.Debug = app.openAuxiliarApp2Debug.Value;
            end

            app.mainApp.General_I.openGL        = app.mainApp.General.openGL;
            app.mainApp.General_I.operationMode = app.mainApp.General.operationMode;
            saveGeneralSettings(app)
            General_updatePanel(app)

        end

        % Callback function: ExternalRequestDistance, ExternalRequestLevel,
        % 
        % ...and 5 other components
        function Analysis_ParameterValueChanged(app, event)
            
            updateAnalysisName = '';

            switch event.Source
                case app.MonitoringPlanDistance
                    app.mainApp.General.MonitoringPlan.Distance_km  = app.MonitoringPlanDistance.Value / 1000;
                    updateAnalysisName = 'PM-RNI: updateAnalysis';

                case app.MonitoringPlanLevel
                    app.mainApp.General.MonitoringPlan.FieldValue   = app.MonitoringPlanLevel.Value;
                    updateAnalysisName = 'PM-RNI: updateAnalysis';

                case app.MonitoringPlanPeriod
                    if isempty(app.MonitoringPlanPeriod.CheckedNodes)
                        app.MonitoringPlanPeriod.CheckedNodes = event.PreviousCheckedNodes;
                        return
                    end
                    app.mainApp.General.MonitoringPlan.Period       = str2double({app.MonitoringPlanPeriod.CheckedNodes.Text});
                    updateAnalysisName = 'PM-RNI: updateReferenceTable';

                case app.MonitoringPlanExportXLSX
                    app.mainApp.General.MonitoringPlan.Export.XLSX  = app.MonitoringPlanExportXLSX.Value;

                case app.MonitoringPlanExportKML
                    app.mainApp.General.MonitoringPlan.Export.KML   = app.MonitoringPlanExportKML.Value;

                case app.ExternalRequestDistance
                    app.mainApp.General.ExternalRequest.Distance_km = app.ExternalRequestDistance.Value / 1000;
                    updateAnalysisName = 'ExternalRequest: updateAnalysis';

                case app.ExternalRequestLevel
                    app.mainApp.General.ExternalRequest.FieldValue  = app.ExternalRequestLevel.Value;
                    updateAnalysisName = 'ExternalRequest: updateAnalysis';
            end

            app.mainApp.General_I.MonitoringPlan  = app.mainApp.General.MonitoringPlan;
            app.mainApp.General_I.ExternalRequest = app.mainApp.General.ExternalRequest;
            saveGeneralSettings(app)

            if ~isempty(updateAnalysisName)
                appBackDoor(app.mainApp, app, updateAnalysisName)
            end
            
        end

        % Image clicked function: MonitoringPlanOpenFile
        function Analysis_OpenReferenceFile(app, event)
            
            fileName = fullfile(ccTools.fcn.OperationSystem('programData'), 'ANATEL', class.Constants.appName, app.MonitoringPlanFileName.Value);
            
            switch app.mainApp.executionMode
                case 'webApp'
                    web(fileName, '-new')
                otherwise
                    ccTools.fcn.OperationSystem('openFile', fileName)
            end

        end

        % Image clicked function: CustomPlotRefresh
        function CustomPlot_RefreshImageClicked(app, event)
            
            % Lê a versão de "GeneralSettings.json" que vem junto ao
            % projeto (e não a versão armazenada em "ProgramData").
            projectFolder      = appUtil.Path(class.Constants.appName, app.rootFolder);
            projectFilePath    = fullfile(projectFolder, 'GeneralSettings.json');
            projectFileContent = jsondecode(fileread(projectFilePath));

            app.mainApp.General.Plot   = projectFileContent.Plot;
            CustomPlot_updatePanel(app)
            
            app.mainApp.General_I.Plot = app.mainApp.General.Plot;
            saveGeneralSettings(app)

            appBackDoor(app.mainApp, app, 'PM-RNI: updateAxes')
            appBackDoor(app.mainApp, app, 'PM-RNI: updatePlot')
            appBackDoor(app.mainApp, app, 'ExternalRequest: updateAxes')
            appBackDoor(app.mainApp, app, 'ExternalRequest: updatePlot')

        end

        % Value changed function: Basemap, Colorbar, Colormap
        function CustomPlot_AxesValueChanged(app, event)
            
            switch event.Source
                case app.Basemap
                    app.mainApp.General.Plot.GeographicAxes.Basemap    = app.Basemap.Value;

                case app.Colormap
                    app.mainApp.General.Plot.GeographicAxes.Colormap   = app.Colormap.Value;

                case app.Colorbar
                    app.mainApp.General.Plot.GeographicAxes.Colorbar   = app.Colorbar.Value;
            end

            app.mainApp.General_I.Plot = app.mainApp.General.Plot;
            saveGeneralSettings(app)
            
            appBackDoor(app.mainApp, app, 'PM-RNI: updateAxes')
            appBackDoor(app.mainApp, app, 'ExternalRequest: updateAxes')

        end

        % Value changed function: AutomaticZoom, AutomaticZoomFactor, 
        % ...and 9 other components
        function CustomPlot_ParameterValueChanged(app, event)
            
            switch event.Source
                case app.StationsSize
                    app.mainApp.General.Plot.Stations.Size             = round(app.StationsSize.Value);

                case app.SelectedStationSize
                    app.mainApp.General.Plot.SelectedStation.Size      = round(app.SelectedStationSize.Value);

                case app.PeakSize
                    app.mainApp.General.Plot.FieldPeak.Size            = round(app.PeakSize.Value);

                case app.CircleColor
                    app.mainApp.General.Plot.CircleRegion.Color        = app.CircleColor.Value;

                case app.CircleFaceAlpha
                    app.mainApp.General.Plot.CircleRegion.FaceAlpha    = app.CircleFaceAlpha.Value;

                case app.CircleEdgeAlpha
                    app.mainApp.General.Plot.CircleRegion.EdgeAlpha    = app.CircleEdgeAlpha.Value;

                case app.AutomaticZoom
                    app.mainApp.General.Plot.SelectedStation.AutomaticZoom = app.AutomaticZoom.Value;
                    if app.AutomaticZoom.Value
                        app.AutomaticZoomFactor.Enable = 1;
                    else
                        app.AutomaticZoomFactor.Enable = 0;
                    end

                case app.AutomaticZoomFactor
                    app.mainApp.General.Plot.SelectedStation.AutomaticZoomFactor = app.AutomaticZoomFactor.Value;

                case {app.PeakColor, app.SelectedStationColor, app.StationsColor}
                    initialColor  = event.PreviousValue;
                    selectedColor = event.Value;
        
                    if ~isequal(initialColor, selectedColor)
                        selectedColor = rgb2hex(selectedColor);
            
                        switch event.Source
                            case app.StationsColor
                                app.mainApp.General.Plot.Stations.Color        = selectedColor;
                            case app.SelectedStationColor
                                app.mainApp.General.Plot.SelectedStation.Color = selectedColor;
                            case app.PeakColor
                                app.mainApp.General.Plot.FieldPeak.Color       = selectedColor;
                        end
                    end
            end

            app.mainApp.General_I.Plot = app.mainApp.General.Plot;
            saveGeneralSettings(app)
            
            appBackDoor(app.mainApp, app, 'PM-RNI: updatePlot')
            appBackDoor(app.mainApp, app, 'ExternalRequest: updatePlot')
            
        end

        % Image clicked function: DataHubPOSTButton, userPathButton
        function Folder_ButtonPushed(app, event)
            
            try
                relatedFolder = eval(sprintf('app.%s.Value', event.Source.Tag));
            catch
                relatedFolder = app.mainApp.General.fileFolder.(event.Source.Tag);
            end
            
            if isfolder(relatedFolder)
                initialFolder = relatedFolder;
            elseif isfile(relatedFolder)
                initialFolder = fileparts(relatedFolder);
            else
                initialFolder = app.userPath.Value;
            end

            selectedFolder = uigetdir(initialFolder);
            figure(app.UIFigure)

            if selectedFolder
                switch event.Source
                    case app.DataHubPOSTButton
                        if strcmp(app.mainApp.General.fileFolder.DataHub_POST, selectedFolder) 
                            return
                        else
                            appName  = class.Constants.appName;
                            repoName = 'DataHub - POST';

                            if all(cellfun(@(x) contains(selectedFolder, x), {repoName, appName})) || contains(selectedFolder, appName)
                                % .\OneDrive - ANATEL\DataHub - POST\monitorRNI
                                % .\OneDrive - ANATEL\monitorRNI

                                app.DataHubPOST.Value = selectedFolder;
                                app.mainApp.General.fileFolder.DataHub_POST = selectedFolder;
                                appBackDoor(app.mainApp, app, 'updateDataHubWarningLamp')
                            else
                                appUtil.modalWindow(app.UIFigure, 'error', sprintf('Não identificado se tratar da pasta "%s" do repositório "%s".', appName, repoName));
                                return
                            end
                        end

                    case app.userPathButton
                        if strcmp(app.mainApp.General.fileFolder.userPath, selectedFolder) 
                            return
                        else
                            app.userPath.Value = selectedFolder;
                            app.mainApp.General.fileFolder.userPath = selectedFolder;
                        end
                end

                app.mainApp.General_I.fileFolder = app.mainApp.General.fileFolder;
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
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x', 34};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create Document
            app.Document = uigridlayout(app.GridLayout);
            app.Document.ColumnWidth = {325, '1x', 0, 0, 0};
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

            % Create CustomPlotRefresh
            app.CustomPlotRefresh = uiimage(app.CustomPlotGrid);
            app.CustomPlotRefresh.ImageClickedFcn = createCallbackFcn(app, @CustomPlot_RefreshImageClicked, true);
            app.CustomPlotRefresh.Layout.Row = 1;
            app.CustomPlotRefresh.Layout.Column = 2;
            app.CustomPlotRefresh.VerticalAlignment = 'bottom';
            app.CustomPlotRefresh.ImageSource = 'Refresh_18.png';

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
            app.Basemap.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_AxesValueChanged, true);
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
            app.Colormap.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_AxesValueChanged, true);
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
            app.Colorbar.Items = {'off', 'on'};
            app.Colorbar.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_AxesValueChanged, true);
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
            app.StationsLabel.Text = 'Estações/pontos de referência:';

            % Create StationsColor
            app.StationsColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.StationsColor.Value = [0 1 1];
            app.StationsColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
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
            app.SelectedStationLabel.Text = 'Estação/ponto sob análise:';

            % Create SelectedStationColor
            app.SelectedStationColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.SelectedStationColor.Value = [0.7882 0.2784 0.3412];
            app.SelectedStationColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
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
            app.PeakLabel.Text = 'Pico em torno da estação/ponto:';

            % Create PeakColor
            app.PeakColor = uicolorpicker(app.CustomPlotPanelGrid);
            app.PeakColor.Value = [0.7882 0.2784 0.3373];
            app.PeakColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
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
            app.CircleColorLabel.Layout.Column = [1 4];
            app.CircleColorLabel.Text = 'Região circular em torno da estação/ponto:';

            % Create CircleColor
            app.CircleColor = uidropdown(app.CustomPlotPanelGrid);
            app.CircleColor.Items = {'black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow'};
            app.CircleColor.ValueChangedFcn = createCallbackFcn(app, @CustomPlot_ParameterValueChanged, true);
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
            app.CircleColorAlphaLabel.Layout.Column = [1 3];
            app.CircleColorAlphaLabel.Text = {'Região circular em torno da estação/ponto: '; '(transparência da face e borda)'};

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
            app.AutomaticZoom.Text = 'Habilitar zoom automático em torno da estação/ponto sob análise.';
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
            app.FolderPanelGrid.RowHeight = {22, 22, 22, 22, 22, 22, '1x'};
            app.FolderPanelGrid.ColumnSpacing = 5;
            app.FolderPanelGrid.RowSpacing = 5;
            app.FolderPanelGrid.Padding = [10 10 10 5];
            app.FolderPanelGrid.BackgroundColor = [1 1 1];

            % Create DataHubPOSTLabel
            app.DataHubPOSTLabel = uilabel(app.FolderPanelGrid);
            app.DataHubPOSTLabel.VerticalAlignment = 'bottom';
            app.DataHubPOSTLabel.FontSize = 10;
            app.DataHubPOSTLabel.Layout.Row = 1;
            app.DataHubPOSTLabel.Layout.Column = 1;
            app.DataHubPOSTLabel.Text = 'DataHub - POST:';

            % Create DataHubPOST
            app.DataHubPOST = uieditfield(app.FolderPanelGrid, 'text');
            app.DataHubPOST.Editable = 'off';
            app.DataHubPOST.FontSize = 11;
            app.DataHubPOST.Layout.Row = 2;
            app.DataHubPOST.Layout.Column = 1;

            % Create DataHubPOSTButton
            app.DataHubPOSTButton = uiimage(app.FolderPanelGrid);
            app.DataHubPOSTButton.ImageClickedFcn = createCallbackFcn(app, @Folder_ButtonPushed, true);
            app.DataHubPOSTButton.Tag = 'DataHub_POST';
            app.DataHubPOSTButton.Layout.Row = 2;
            app.DataHubPOSTButton.Layout.Column = 2;
            app.DataHubPOSTButton.ImageSource = 'OpenFile_36x36.png';

            % Create userPathLabel
            app.userPathLabel = uilabel(app.FolderPanelGrid);
            app.userPathLabel.VerticalAlignment = 'bottom';
            app.userPathLabel.FontSize = 10;
            app.userPathLabel.Layout.Row = 3;
            app.userPathLabel.Layout.Column = 1;
            app.userPathLabel.Text = 'Pasta do usuário:';

            % Create userPath
            app.userPath = uieditfield(app.FolderPanelGrid, 'text');
            app.userPath.Editable = 'off';
            app.userPath.FontSize = 11;
            app.userPath.Layout.Row = 4;
            app.userPath.Layout.Column = 1;

            % Create userPathButton
            app.userPathButton = uiimage(app.FolderPanelGrid);
            app.userPathButton.ImageClickedFcn = createCallbackFcn(app, @Folder_ButtonPushed, true);
            app.userPathButton.Tag = 'userPath';
            app.userPathButton.Layout.Row = 4;
            app.userPathButton.Layout.Column = 2;
            app.userPathButton.ImageSource = 'OpenFile_36x36.png';

            % Create tempPathLabel
            app.tempPathLabel = uilabel(app.FolderPanelGrid);
            app.tempPathLabel.VerticalAlignment = 'bottom';
            app.tempPathLabel.FontSize = 10;
            app.tempPathLabel.Layout.Row = 5;
            app.tempPathLabel.Layout.Column = 1;
            app.tempPathLabel.Text = 'Pasta temporária:';

            % Create tempPath
            app.tempPath = uieditfield(app.FolderPanelGrid, 'text');
            app.tempPath.Editable = 'off';
            app.tempPath.FontSize = 11;
            app.tempPath.Layout.Row = 6;
            app.tempPath.Layout.Column = 1;

            % Create AnalysisPanelGrid
            app.AnalysisPanelGrid = uigridlayout(app.Document);
            app.AnalysisPanelGrid.ColumnWidth = {'1x'};
            app.AnalysisPanelGrid.RowHeight = {22, '1x', 22, '1x'};
            app.AnalysisPanelGrid.RowSpacing = 5;
            app.AnalysisPanelGrid.Padding = [0 0 0 0];
            app.AnalysisPanelGrid.Layout.Row = 1;
            app.AnalysisPanelGrid.Layout.Column = 3;
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
            app.MonitoringPlanGrid.ColumnWidth = {310, 90, '1x', 16};
            app.MonitoringPlanGrid.RowHeight = {22, 22, 22, '1x', 1, 22, 22};
            app.MonitoringPlanGrid.ColumnSpacing = 5;
            app.MonitoringPlanGrid.RowSpacing = 5;
            app.MonitoringPlanGrid.BackgroundColor = [1 1 1];

            % Create MonitoringPlanDistanceLabel
            app.MonitoringPlanDistanceLabel = uilabel(app.MonitoringPlanGrid);
            app.MonitoringPlanDistanceLabel.WordWrap = 'on';
            app.MonitoringPlanDistanceLabel.FontSize = 10;
            app.MonitoringPlanDistanceLabel.Layout.Row = 1;
            app.MonitoringPlanDistanceLabel.Layout.Column = [1 2];
            app.MonitoringPlanDistanceLabel.Text = 'Distância limite entre ponto de medição e a estação sob análise (m):';

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

            % Create MonitoringPlanFileLabel
            app.MonitoringPlanFileLabel = uilabel(app.MonitoringPlanGrid);
            app.MonitoringPlanFileLabel.WordWrap = 'on';
            app.MonitoringPlanFileLabel.FontSize = 10;
            app.MonitoringPlanFileLabel.Layout.Row = 3;
            app.MonitoringPlanFileLabel.Layout.Column = 1;
            app.MonitoringPlanFileLabel.Text = 'Arquivo de referência:';

            % Create MonitoringPlanFileName
            app.MonitoringPlanFileName = uieditfield(app.MonitoringPlanGrid, 'text');
            app.MonitoringPlanFileName.Editable = 'off';
            app.MonitoringPlanFileName.FontSize = 11;
            app.MonitoringPlanFileName.Layout.Row = 3;
            app.MonitoringPlanFileName.Layout.Column = [2 3];

            % Create MonitoringPlanOpenFile
            app.MonitoringPlanOpenFile = uiimage(app.MonitoringPlanGrid);
            app.MonitoringPlanOpenFile.ImageClickedFcn = createCallbackFcn(app, @Analysis_OpenReferenceFile, true);
            app.MonitoringPlanOpenFile.Tooltip = {'Abrir no Excel a planilha de referência'};
            app.MonitoringPlanOpenFile.Layout.Row = 3;
            app.MonitoringPlanOpenFile.Layout.Column = 4;
            app.MonitoringPlanOpenFile.ImageSource = 'Sheet_32.png';

            % Create MonitoringPlanPeriod
            app.MonitoringPlanPeriod = uitree(app.MonitoringPlanGrid, 'checkbox');
            app.MonitoringPlanPeriod.FontSize = 11;
            app.MonitoringPlanPeriod.Layout.Row = 4;
            app.MonitoringPlanPeriod.Layout.Column = [2 3];

            % Assign Checked Nodes
            app.MonitoringPlanPeriod.CheckedNodesChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);

            % Create MonitoringPlanExportXLSX
            app.MonitoringPlanExportXLSX = uicheckbox(app.MonitoringPlanGrid);
            app.MonitoringPlanExportXLSX.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.MonitoringPlanExportXLSX.Text = 'Ao exportar a tabela de dados, cria uma segunda aba na planilha com as medidas brutas.';
            app.MonitoringPlanExportXLSX.FontSize = 11;
            app.MonitoringPlanExportXLSX.Layout.Row = 6;
            app.MonitoringPlanExportXLSX.Layout.Column = [1 3];

            % Create MonitoringPlanExportKML
            app.MonitoringPlanExportKML = uicheckbox(app.MonitoringPlanGrid);
            app.MonitoringPlanExportKML.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.MonitoringPlanExportKML.Text = 'Ao exportar a tabela de dados, cria arquivos no formato "kml".';
            app.MonitoringPlanExportKML.FontSize = 11;
            app.MonitoringPlanExportKML.Layout.Row = 7;
            app.MonitoringPlanExportKML.Layout.Column = [1 3];

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
            app.ExternalRequestGrid.ColumnWidth = {310, 90};
            app.ExternalRequestGrid.RowHeight = {22, 22};
            app.ExternalRequestGrid.RowSpacing = 5;
            app.ExternalRequestGrid.BackgroundColor = [1 1 1];

            % Create ExternalRequestDistanceLabel
            app.ExternalRequestDistanceLabel = uilabel(app.ExternalRequestGrid);
            app.ExternalRequestDistanceLabel.VerticalAlignment = 'top';
            app.ExternalRequestDistanceLabel.WordWrap = 'on';
            app.ExternalRequestDistanceLabel.FontSize = 10;
            app.ExternalRequestDistanceLabel.Layout.Row = [1 2];
            app.ExternalRequestDistanceLabel.Layout.Column = [1 2];
            app.ExternalRequestDistanceLabel.Text = {'Distância limite entre ponto de medição e a estação sob análise (m):'; '(valor padrão)'};

            % Create ExternalRequestDistance
            app.ExternalRequestDistance = uieditfield(app.ExternalRequestGrid, 'numeric');
            app.ExternalRequestDistance.ValueChangedFcn = createCallbackFcn(app, @Analysis_ParameterValueChanged, true);
            app.ExternalRequestDistance.FontSize = 11;
            app.ExternalRequestDistance.Layout.Row = 1;
            app.ExternalRequestDistance.Layout.Column = 2;
            app.ExternalRequestDistance.Value = 1000;

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
