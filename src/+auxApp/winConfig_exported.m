classdef winConfig_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        DockModule                    matlab.ui.container.GridLayout
        dockModule_Close              matlab.ui.control.Image
        dockModule_Undock             matlab.ui.control.Image
        SubTabGroup                   matlab.ui.container.TabGroup
        SubTab1                       matlab.ui.container.Tab
        SubGrid1                      matlab.ui.container.GridLayout
        openAuxiliarApp2Debug         matlab.ui.control.CheckBox
        openAuxiliarAppAsDocked       matlab.ui.control.CheckBox
        tool_RFDataHubButton          matlab.ui.control.Image
        tool_versionInfoRefresh       matlab.ui.control.Image
        versionInfo                   matlab.ui.control.Label
        versionInfoLabel              matlab.ui.control.Label
        SubTab2                       matlab.ui.container.Tab
        SubGrid2                      matlab.ui.container.GridLayout
        configAnalysisPanel3          matlab.ui.container.Panel
        configAnalysisGrid3           matlab.ui.container.GridLayout
        ExternalRequestExportKML      matlab.ui.control.CheckBox
        ExternalRequestExportXLSX     matlab.ui.control.CheckBox
        ExternalRequestLevel          matlab.ui.control.NumericEditField
        ExternalRequestLevelLabel     matlab.ui.control.Label
        ExternalRequestDistance       matlab.ui.control.NumericEditField
        ExternalRequestDistanceLabel  matlab.ui.control.Label
        configAnalysisPanel3Label     matlab.ui.control.Label
        configAnalysisPanel2          matlab.ui.container.Panel
        configAnalysisGrid2           matlab.ui.container.GridLayout
        MonitoringPlanExportKML       matlab.ui.control.CheckBox
        MonitoringPlanExportXLSX      matlab.ui.control.CheckBox
        MonitoringPlanPeriod          matlab.ui.container.CheckBoxTree
        MonitoringPlanFileSubLabel    matlab.ui.control.Label
        MonitoringPlanOpenFile        matlab.ui.control.Image
        MonitoringPlanFileName        matlab.ui.control.EditField
        MonitoringPlanFileLabel       matlab.ui.control.Label
        MonitoringPlanLevel           matlab.ui.control.NumericEditField
        MonitoringPlanLevelLabel      matlab.ui.control.Label
        MonitoringPlanDistance        matlab.ui.control.NumericEditField
        MonitoringPlanDistanceLabel   matlab.ui.control.Label
        configAnalysisPanel2Label     matlab.ui.control.Label
        configAnalysisPanel1          matlab.ui.container.Panel
        configAnalysisGrid1           matlab.ui.container.GridLayout
        SortMethod                    matlab.ui.control.DropDown
        SortMethodLabel               matlab.ui.control.Label
        InputType                     matlab.ui.control.DropDown
        InputTypeLabel                matlab.ui.control.Label
        configAnalysisRefresh         matlab.ui.control.Image
        configAnalysisPanel1Label     matlab.ui.control.Label
        SubTab3                       matlab.ui.container.Tab
        SubGrid3                      matlab.ui.container.GridLayout
        configPlotPanel2              matlab.ui.container.Panel
        configPlotGrid2               matlab.ui.container.GridLayout
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
        configPlotTitle2              matlab.ui.control.Label
        configPlotPanel1              matlab.ui.container.Panel
        configPlotGrid1               matlab.ui.container.GridLayout
        AutomaticZoomFactor           matlab.ui.control.Spinner
        AutomaticZoomFactorLabel      matlab.ui.control.Label
        AutomaticZoomMode             matlab.ui.control.CheckBox
        ZoomOrientation               matlab.ui.control.DropDown
        ZoomOrientationLabel          matlab.ui.control.Label
        Colorbar                      matlab.ui.control.DropDown
        ColorbarLabel                 matlab.ui.control.Label
        Colormap                      matlab.ui.control.DropDown
        ColormapLabel                 matlab.ui.control.Label
        Basemap                       matlab.ui.control.DropDown
        BasemapLabel                  matlab.ui.control.Label
        configPlotRefresh             matlab.ui.control.Image
        configPlotTitle1              matlab.ui.control.Label
        SubTab4                       matlab.ui.container.Tab
        SubGrid4                      matlab.ui.container.GridLayout
        reportPanel                   matlab.ui.container.Panel
        reportGrid                    matlab.ui.container.GridLayout
        prjFileCompressionMode        matlab.ui.control.DropDown
        prjFileCompressionModeLabel   matlab.ui.control.Label
        reportBinningPanel            matlab.ui.container.Panel
        reportBinningGrid             matlab.ui.container.GridLayout
        reportBinningFcn              matlab.ui.control.DropDown
        reportBinningFcnLabel         matlab.ui.control.Label
        reportBinningLength           matlab.ui.control.Spinner
        reportBinningLengthLabel      matlab.ui.control.Label
        reportBinningLabel            matlab.ui.control.Label
        reportImgDpi                  matlab.ui.control.DropDown
        reportImgFormat               matlab.ui.control.DropDown
        reportImageLabel              matlab.ui.control.Label
        reportBasemap                 matlab.ui.control.DropDown
        reportBasemapLabel            matlab.ui.control.Label
        reportLabel                   matlab.ui.control.Label
        eFiscalizaPanel               matlab.ui.container.Panel
        eFiscalizaGrid                matlab.ui.container.GridLayout
        reportUnit                    matlab.ui.control.DropDown
        reportUnitLabel               matlab.ui.control.Label
        reportSystem                  matlab.ui.control.DropDown
        reportSystemLabel             matlab.ui.control.Label
        eFiscalizaRefresh             matlab.ui.control.Image
        eFiscalizaLabel               matlab.ui.control.Label
        SubTab5                       matlab.ui.container.Tab
        SubGrid5                      matlab.ui.container.GridLayout
        userPathButton                matlab.ui.control.Image
        userPath                      matlab.ui.control.EditField
        userPathLabel                 matlab.ui.control.Label
        DataHubPOSTButton             matlab.ui.control.Image
        DataHubPOST                   matlab.ui.control.EditField
        DATAHUBPOSTLabel              matlab.ui.control.Label
        Toolbar                       matlab.ui.container.GridLayout
        tool_openDevTools             matlab.ui.control.Image
        tool_simulationMode           matlab.ui.control.Image
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'secondaryApp'
        Context = 'CONFIG'
    end


    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = false
        mainApp
        jsBackDoor
        progressDialog
    end


    properties (Access = private)
        %-----------------------------------------------------------------%
        defaultValues
        stableVersion
    end


    methods (Access = public)
        %-----------------------------------------------------------------%
        function ipcSecondaryJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    case 'renderer'
                        appEngine.activate(app, app.Role)

                    otherwise
                        error('UnexpectedEvent')
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
                        app.versionInfo;
                        app.tool_simulationMode;
                        app.tool_openDevTools;
                        app.dockModule_Undock;
                        app.dockModule_Close
                    };
                    ui.CustomizationBase.getElementsDataTag(elToModify);

                    try
                        ui.TextView.startup(app.jsBackDoor, app.versionInfo, appName);
                    catch
                    end

                    try
                        sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                            struct('appName', appName, 'dataTag', app.tool_simulationMode.UserData.id, 'tooltip', struct('defaultPosition', 'top',    'textContent', 'Leitura arquivos de simulação')), ...
                            struct('appName', appName, 'dataTag', app.tool_openDevTools.UserData.id,   'tooltip', struct('defaultPosition', 'top',    'textContent', 'Abre DevTools')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Undock.UserData.id,   'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Reabre módulo em outra janela')), ...
                            struct('appName', appName, 'dataTag', app.dockModule_Close.UserData.id,    'tooltip', struct('defaultPosition', 'bottom', 'textContent', 'Fecha módulo')) ...
                        });
                    catch
                    end

                case 2
                    updatePanel_Analysis(app)

                case 3
                    updatePanel_Plot(app)

                case 4
                    updatePanel_Report(app)

                case 5
                    if ~strcmp(app.mainApp.executionMode, 'webApp')
                        set([app.DataHubPOSTButton, app.userPathButton], 'Enable', 1)
                    end
                    updatePanel_Folder(app)
            end
        end

        %-----------------------------------------------------------------%
        function initializeAppProperties(app)
            % Lê a versão de "GeneralSettings.json" que vem junto ao
            % projeto (e não a versão armazenada em "ProgramData").
            projectFolder     = appEngine.util.Path(class.Constants.appName, app.mainApp.rootFolder);
            projectFilePath   = fullfile(projectFolder, 'GeneralSettings.json');
            projectGeneral    = jsondecode(fileread(projectFilePath));

            app.defaultValues = struct( ...
                'FILE', projectGeneral.context.FILE, ...
                'MONITORINGPLAN', struct( ...
                    'maxMeasurementDistanceKm', projectGeneral.context.MONITORINGPLAN.maxMeasurementDistanceKm, ...
                    'electricFieldStrengthThreshold',  projectGeneral.context.MONITORINGPLAN.electricFieldStrengthThreshold, ...
                    'exportOptions',      projectGeneral.context.MONITORINGPLAN.exportOptions ...
                ), ...
               'EXTERNALREQUEST', struct( ...
                    'maxMeasurementDistanceKm', projectGeneral.context.EXTERNALREQUEST.maxMeasurementDistanceKm, ...
                    'electricFieldStrengthThreshold',  projectGeneral.context.EXTERNALREQUEST.electricFieldStrengthThreshold, ...
                    'exportOptions',      projectGeneral.context.EXTERNALREQUEST.exportOptions), ...
               'plot', projectGeneral.plot, ...
               'reportLib', projectGeneral.reportLib ...
           );
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                app.dockModule_Undock.Enable       = 1;
                app.tool_openDevTools.Enable       = 1;
                app.tool_versionInfoRefresh.Enable = 1;
                app.openAuxiliarAppAsDocked.Enable = 1;
            end

            if ~isdeployed
                app.openAuxiliarApp2Debug.Enable   = 1;
            end
        end

        %-----------------------------------------------------------------%
        function applyInitialLayout(app)
            % Versão
            ui.TextView.update(app.versionInfo, ...
                util.HtmlTextGenerator.AppInfo( ...
                    app.mainApp.General, ...
                    app.mainApp.rootFolder, ...
                    app.mainApp.executionMode, ...
                    app.mainApp.renderCount, ...
                    app.mainApp.projectData, ...
                    "textview" ...
                ) ...
            );

            % Modo de operação
            app.openAuxiliarAppAsDocked.Value = app.mainApp.General.operationMode.Dock;
            app.openAuxiliarApp2Debug.Value   = app.mainApp.General.operationMode.Debug;
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function updatePanel_Analysis(app)
            % FILE
            app.InputType.Value                 = app.mainApp.General.context.FILE.input;
            app.SortMethod.Value                = app.mainApp.General.context.FILE.sortMethod;

            % PM-RNI
            app.MonitoringPlanDistance.Value    = app.mainApp.General.context.MONITORINGPLAN.maxMeasurementDistanceKm * 1000;
            app.MonitoringPlanLevel.Value       = app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold;
            app.MonitoringPlanFileName.Value    = [app.mainApp.General.context.MONITORINGPLAN.referenceFile '.xlsx'];
            
            databaseYears = app.mainApp.projectData.modules.MONITORINGPLAN.referenceData.years;
            initialSelectedYears = "[ " + strjoin(string(app.mainApp.projectData.modules.MONITORINGPLAN.referenceData.selectedYears), ', ') + " ]";
            currentSelectedYears = app.mainApp.General.context.MONITORINGPLAN.periodYears;

            app.MonitoringPlanFileSubLabel.Text = sprintf('Sessão corrente: %s\n(eventuais alterações nos anos de referência só terão efeito após a reinicialização do aplicativo)', initialSelectedYears);

            if ~isempty(app.MonitoringPlanPeriod.Children)
                delete(app.MonitoringPlanPeriod.Children)
            end

            for ii = 1:numel(databaseYears)                
                treeNode = uitreenode(app.MonitoringPlanPeriod, 'Text', string(databaseYears(ii)));
                if ismember(databaseYears(ii), currentSelectedYears)
                    app.MonitoringPlanPeriod.CheckedNodes = [app.MonitoringPlanPeriod.CheckedNodes; treeNode];
                end
            end

            app.MonitoringPlanExportXLSX.Value  = app.mainApp.General.context.MONITORINGPLAN.exportOptions.xlsx;
            app.MonitoringPlanExportKML.Value   = app.mainApp.General.context.MONITORINGPLAN.exportOptions.kml;

            % External Request
            app.ExternalRequestDistance.Value   = app.mainApp.General.context.EXTERNALREQUEST.maxMeasurementDistanceKm * 1000;
            app.ExternalRequestLevel.Value      = app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold;
            app.ExternalRequestExportXLSX.Value = app.mainApp.General.context.EXTERNALREQUEST.exportOptions.xlsx;
            app.ExternalRequestExportKML.Value  = app.mainApp.General.context.EXTERNALREQUEST.exportOptions.kml;

            if checkEdition(app, 'ANALYSIS')
                app.configAnalysisRefresh.Visible = 1;
            else
                app.configAnalysisRefresh.Visible = 0;
            end
        end

        %-----------------------------------------------------------------%
        function updatePanel_Plot(app)
            app.Basemap.Value              = app.mainApp.General.plot.geographicAxes.basemap;
            app.Colormap.Value             = app.mainApp.General.plot.geographicAxes.colormap;
            app.Colorbar.Value             = app.mainApp.General.plot.geographicAxes.colorbar;
            app.ZoomOrientation.Value      = app.mainApp.General.plot.geographicAxes.zoomOrientation;

            app.StationsColor.Value        = app.mainApp.General.plot.stations.color;
            app.StationsSize.Value         = app.mainApp.General.plot.stations.size;

            app.SelectedStationColor.Value = app.mainApp.General.plot.selectedStation.color;
            app.SelectedStationSize.Value  = app.mainApp.General.plot.selectedStation.size;

            app.CircleColor.Value          = app.mainApp.General.plot.circleRegion.color;
            app.CircleFaceAlpha.Value      = app.mainApp.General.plot.circleRegion.faceAlpha;
            app.CircleEdgeAlpha.Value      = app.mainApp.General.plot.circleRegion.edgeAlpha;

            app.AutomaticZoomMode.Value    = app.mainApp.General.plot.selectedStation.automaticZoom;
            app.AutomaticZoomFactor.Value  = app.mainApp.General.plot.selectedStation.automaticZoomFactor;
            if app.AutomaticZoomMode.Value
                app.AutomaticZoomFactor.Enable = 1;
            else
                app.AutomaticZoomFactor.Enable = 0;
            end

            app.PeakColor.Value            = app.mainApp.General.plot.fieldPeak.color;
            app.PeakSize.Value             = app.mainApp.General.plot.fieldPeak.size;

            if checkEdition(app, 'PLOT')
                app.configPlotRefresh.Visible = 1;
            else
                app.configPlotRefresh.Visible = 0;
            end
        end

        %-----------------------------------------------------------------%
        function updatePanel_Report(app)
            app.reportSystem.Value        = app.mainApp.General.reportLib.system;
            set(app.reportUnit, 'Items', app.mainApp.General.eFiscaliza.defaultValues.unit, 'Value', app.mainApp.General.reportLib.unit)

            app.reportBasemap.Value       = app.mainApp.General.reportLib.basemap;
            app.reportImgFormat.Value     = app.mainApp.General.reportLib.image.format;
            app.reportImgDpi.Value        = num2str(app.mainApp.General.reportLib.image.resolutionDpi);
            app.reportBinningLength.Value = app.mainApp.General.reportLib.dataBinning.binLengthMeters;
            app.reportBinningFcn.Value    = app.mainApp.General.reportLib.dataBinning.aggregationFunction;

            if ismember(app.mainApp.General.reportLib.outputCompressionMode, app.prjFileCompressionMode.Items)
                app.prjFileCompressionMode.Value = app.mainApp.General.reportLib.outputCompressionMode;
            end

            app.eFiscalizaRefresh.Visible = checkEdition(app, 'REPORT');
        end

        %-----------------------------------------------------------------%
        function updatePanel_Folder(app)
            DataHub_POST = app.mainApp.General.fileFolder.DataHub_POST;    
            if isfolder(DataHub_POST)
                app.DataHubPOST.Value = DataHub_POST;
            end

            app.userPath.Value = app.mainApp.General.fileFolder.userPath;                
        end

        %-----------------------------------------------------------------%
        function editionFlag = checkEdition(app, tabName)
            editionFlag   = false;
            currentValues = struct( ...
                'FILE', app.mainApp.General.context.FILE, ...
                'MONITORINGPLAN', struct( ...
                    'maxMeasurementDistanceKm', app.mainApp.General.context.MONITORINGPLAN.maxMeasurementDistanceKm, ...
                    'electricFieldStrengthThreshold',  app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold, ...
                    'exportOptions',      app.mainApp.General.context.MONITORINGPLAN.exportOptions ...
                ), ...
                'EXTERNALREQUEST', struct( ...
                    'maxMeasurementDistanceKm', app.mainApp.General.context.EXTERNALREQUEST.maxMeasurementDistanceKm, ...
                    'electricFieldStrengthThreshold',  app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold, ...
                    'exportOptions',      app.mainApp.General.context.EXTERNALREQUEST.exportOptions ...
                ), ...
               'plot', app.mainApp.General.plot, ...
               'reportLib', app.mainApp.General.reportLib ...
           );

            switch tabName
                case 'ANALYSIS'
                    if ~isequal(rmfield(currentValues, {'plot', 'reportLib'}), rmfield(app.defaultValues, {'plot', 'reportLib'}))
                        editionFlag = true;
                    end
                case 'PLOT'
                    if ~isequal(currentValues.plot, app.defaultValues.plot)
                        editionFlag = true;
                    end
                case 'REPORT'
                    if ~isequal(currentValues.reportLib, app.defaultValues.reportLib)
                        editionFlag = true;
                    end
            end
        end

        %-----------------------------------------------------------------%
        function saveGeneralSettings(app)
            appEngine.util.generalSettingsSave(class.Constants.appName, app.mainApp.rootFolder, app.mainApp.General_I, app.mainApp.executionMode)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            
            try
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

        % Selection change function: SubTabGroup
        function SubTabGroup_TabSelectionChanged(app, event)
            
            [~, tabIndex] = ismember(app.SubTabGroup.SelectedTab, app.SubTabGroup.Children);
            applyJSCustomizations(app, tabIndex)

        end

        % Image clicked function: tool_versionInfoRefresh
        function Toolbar_AppEnvRefreshButtonPushed(app, event)
            
            app.progressDialog.Visible = 'visible';

            [htmlContent, app.stableVersion, updatedModule] = util.HtmlTextGenerator.checkAvailableUpdate(app.mainApp.General, app.mainApp.rootFolder);
            ui.Dialog(app.UIFigure, "info", htmlContent);
            app.tool_RFDataHubButton.Enable = ~ismember('RFDataHub', updatedModule);

            app.progressDialog.Visible = 'hidden';

        end

        % Image clicked function: tool_RFDataHubButton
        function Toolbar_RFDataHubButtonPushed(app, event)
            
            if isequal(rmfield(app.mainApp.General.AppVersion.database, 'name'),  app.stableVersion.rfDataHub)
                app.tool_RFDataHubButton.Enable = 0;
                ui.Dialog(app.UIFigure, 'warning', 'Módulo RFDataHub já atualizado!');
                return
            end

            d = ui.Dialog(app.UIFigure, "progressdlg", 'Em andamento... esse processo pode demorar alguns minutos!');

            try
                appName = class.Constants.appName;
                rfDataHubLink = util.publicLink(appName, app.mainApp.rootFolder, 'RFDataHub');
                model.RFDataHub.update(appName, app.mainApp.rootFolder, app.mainApp.General.fileFolder.tempPath, rfDataHubLink)

                % Atualiza versão.
                global RFDataHub_info

                app.mainApp.General.AppVersion.database      = RFDataHub_info;
                app.mainApp.General.AppVersion.database.name = 'RFDataHub';
                app.stableVersion.rfDataHub = RFDataHub_info;
                app.tool_RFDataHubButton.Enable = 0;
                
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onRFDataHubUpdate')
                
            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end

            applyInitialLayout(app)
            delete(d)

        end

        % Image clicked function: tool_simulationMode
        function Toolbar_SimulationModeButtonPushed(app, event)
            
            msgQuestion   = 'Deseja abrir arquivos de <b>simulação</b>?';
            userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);
            
            if strcmp(userSelection, 'Não')
                return
            end

            app.mainApp.General.operationMode.Simulation = true;
            ipcMainMatlabCallsHandler(app.mainApp, app, 'onSimulationMode')

        end

        % Image clicked function: tool_openDevTools
        function Toolbar_OpenDevToolsClicked(app, event)
            
            ipcMainMatlabCallsHandler(app.mainApp, app, 'openDevTools')

        end

        % Value changed function: openAuxiliarApp2Debug, 
        % ...and 1 other component
        function Config_GeneralParameterValueChanged(app, event)
            
            switch event.Source
                case app.openAuxiliarAppAsDocked
                    app.mainApp.General.operationMode.Dock  = app.openAuxiliarAppAsDocked.Value;

                case app.openAuxiliarApp2Debug
                    app.mainApp.General.operationMode.Debug = app.openAuxiliarApp2Debug.Value;
            end

            app.mainApp.General_I.operationMode = app.mainApp.General.operationMode;
            saveGeneralSettings(app)

        end

        % Image clicked function: configAnalysisRefresh
        function Config_AnalysisRefreshImageClicked(app, event)
            
            if ~checkEdition(app, 'ANALYSIS')
                app.configAnalysisRefresh.Visible = 0;
                return

            else
                app.mainApp.General.context.FILE = app.defaultValues.FILE;

                app.mainApp.General.context.MONITORINGPLAN.maxMeasurementDistanceKm = app.defaultValues.MONITORINGPLAN.maxMeasurementDistanceKm;
                app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold = app.defaultValues.MONITORINGPLAN.electricFieldStrengthThreshold;
                app.mainApp.General.context.MONITORINGPLAN.exportOptions = app.defaultValues.MONITORINGPLAN.exportOptions;
                
                app.mainApp.General.context.EXTERNALREQUEST.maxMeasurementDistanceKm = app.defaultValues.EXTERNALREQUEST.maxMeasurementDistanceKm;
                app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold = app.defaultValues.EXTERNALREQUEST.electricFieldStrengthThreshold;
                app.mainApp.General.context.EXTERNALREQUEST.exportOptions = app.defaultValues.EXTERNALREQUEST.exportOptions;

                app.mainApp.General_I.context.FILE = app.mainApp.General.context.FILE;
                app.mainApp.General_I.context.MONITORINGPLAN = app.mainApp.General.context.MONITORINGPLAN;
                app.mainApp.General_I.context.EXTERNALREQUEST = app.mainApp.General.context.EXTERNALREQUEST;

                updatePanel_Analysis(app)
                saveGeneralSettings(app)
                
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onAnalysisParameterChanged', 'MONITORINGPLAN')
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onAnalysisParameterChanged', 'EXTERNALREQUEST')
            end

        end

        % Callback function: ExternalRequestDistance, 
        % ...and 10 other components
        function Config_AnalysisParameterValueChanged(app, event)
            
            context = '';
            eventName = '';
            
            switch event.Source
                case app.InputType
                    app.mainApp.General.context.FILE.input = app.InputType.Value;

                case app.SortMethod
                    app.mainApp.General.context.FILE.sortMethod = app.SortMethod.Value;
                    ipcMainMatlabCallsHandler(app.mainApp, app, 'onFileSortMethodChanged')

                case app.MonitoringPlanDistance
                    context = 'MONITORINGPLAN';
                    eventName = 'onAnalysisParameterChanged';
                    app.mainApp.General.context.MONITORINGPLAN.maxMeasurementDistanceKm = app.MonitoringPlanDistance.Value / 1000;

                case app.MonitoringPlanLevel
                    context = 'MONITORINGPLAN';
                    eventName = 'onAnalysisParameterChanged';
                    app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold = app.MonitoringPlanLevel.Value;

                case app.MonitoringPlanPeriod
                    if isempty(app.MonitoringPlanPeriod.CheckedNodes)
                        app.MonitoringPlanPeriod.CheckedNodes = event.PreviousCheckedNodes;
                        return
                    end
                    app.mainApp.General.context.MONITORINGPLAN.periodYears = str2double({app.MonitoringPlanPeriod.CheckedNodes.Text});

                case app.MonitoringPlanExportXLSX
                    app.mainApp.General.context.MONITORINGPLAN.exportOptions.xlsx = app.MonitoringPlanExportXLSX.Value;

                case app.MonitoringPlanExportKML
                    app.mainApp.General.context.MONITORINGPLAN.exportOptions.kml = app.MonitoringPlanExportKML.Value;

                case app.ExternalRequestDistance
                    context = 'EXTERNALREQUEST';
                    eventName = 'onAnalysisParameterChanged';
                    app.mainApp.General.context.EXTERNALREQUEST.maxMeasurementDistanceKm = app.ExternalRequestDistance.Value / 1000;

                case app.ExternalRequestLevel
                    context = 'EXTERNALREQUEST';
                    eventName = 'onAnalysisParameterChanged';
                    app.mainApp.General.context.EXTERNALREQUEST.electricFieldStrengthThreshold = app.ExternalRequestLevel.Value;

                case app.ExternalRequestExportXLSX
                    app.mainApp.General.context.EXTERNALREQUEST.exportOptions.xlsx = app.ExternalRequestExportXLSX.Value;

                case app.ExternalRequestExportKML
                    app.mainApp.General.context.EXTERNALREQUEST.exportOptions.kml = app.ExternalRequestExportKML.Value;
            end

            app.mainApp.General_I.context.FILE = app.mainApp.General.context.FILE;
            app.mainApp.General_I.context.MONITORINGPLAN = app.mainApp.General.context.MONITORINGPLAN;
            app.mainApp.General_I.context.EXTERNALREQUEST = app.mainApp.General.context.EXTERNALREQUEST;

            updatePanel_Analysis(app)
            saveGeneralSettings(app)

            if ~isempty(eventName)
                ipcMainMatlabCallsHandler(app.mainApp, app, eventName, context)
            end
            
        end

        % Image clicked function: MonitoringPlanOpenFile
        function Config_AnalysisOpenReferenceFile(app, event)
            
            fileName = fullfile(appEngine.util.OperationSystem('programData'), 'ANATEL', class.Constants.appName, 'DataBase', app.MonitoringPlanFileName.Value);
            
            switch app.mainApp.executionMode
                case 'webApp'
                    web(fileName, '-new')
                otherwise
                    appEngine.util.OperationSystem('openFile', fileName)
            end

        end

        % Image clicked function: configPlotRefresh
        function Config_PlotRefreshImageClicked(app, event)
            
            if ~checkEdition(app, 'PLOT')
                app.configPlotRefresh.Visible = 0;
                return
            
            else
                app.mainApp.General.plot = app.defaultValues.plot;
                app.mainApp.General_I.plot = app.mainApp.General.plot;
                
                updatePanel_Plot(app)
                saveGeneralSettings(app)
    
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onAxesParameterChanged', 'MONITORINGPLAN')
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onPlotParameterChanged', 'MONITORINGPLAN')
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onAxesParameterChanged', 'EXTERNALREQUEST')
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onPlotParameterChanged', 'EXTERNALREQUEST')
            end

        end

        % Value changed function: Basemap, Colorbar, Colormap
        function Config_PlotAxesValueChanged(app, event)
            
            switch event.Source
                case app.Basemap
                    app.mainApp.General.plot.geographicAxes.basemap  = app.Basemap.Value;

                case app.Colormap
                    app.mainApp.General.plot.geographicAxes.colormap = app.Colormap.Value;

                case app.Colorbar
                    app.mainApp.General.plot.geographicAxes.colorbar = app.Colorbar.Value;
            end

            app.mainApp.General_I.plot = app.mainApp.General.plot;

            updatePanel_Plot(app)
            saveGeneralSettings(app)
            
            ipcMainMatlabCallsHandler(app.mainApp, app, 'onAxesParameterChanged', 'MONITORINGPLAN')
            ipcMainMatlabCallsHandler(app.mainApp, app, 'onAxesParameterChanged', 'EXTERNALREQUEST')

        end

        % Value changed function: AutomaticZoomFactor, AutomaticZoomMode, 
        % ...and 10 other components
        function Config_PlotParameterValueChanged(app, event)
            
            switch event.Source
                case app.StationsSize
                    app.mainApp.General.plot.stations.size          = round(app.StationsSize.Value);

                case app.SelectedStationSize
                    app.mainApp.General.plot.selectedStation.size   = round(app.SelectedStationSize.Value);

                case app.PeakSize
                    app.mainApp.General.plot.fieldPeak.size         = round(app.PeakSize.Value);

                case app.CircleColor
                    app.mainApp.General.plot.circleRegion.color     = app.CircleColor.Value;

                case app.CircleFaceAlpha
                    app.mainApp.General.plot.circleRegion.faceAlpha = app.CircleFaceAlpha.Value;

                case app.CircleEdgeAlpha
                    app.mainApp.General.plot.circleRegion.edgeAlpha = app.CircleEdgeAlpha.Value;

                case app.ZoomOrientation
                    app.mainApp.General.plot.geographicAxes.zoomOrientation = app.ZoomOrientation.Value;

                case app.AutomaticZoomMode
                    app.mainApp.General.plot.selectedStation.automaticZoom  = app.AutomaticZoomMode.Value;
                    if app.AutomaticZoomMode.Value
                        app.AutomaticZoomFactor.Enable = 1;
                    else
                        app.AutomaticZoomFactor.Enable = 0;
                    end

                case app.AutomaticZoomFactor
                    app.mainApp.General.plot.selectedStation.automaticZoomFactor = app.AutomaticZoomFactor.Value;

                case {app.PeakColor, app.SelectedStationColor, app.StationsColor}
                    initialColor  = event.PreviousValue;
                    selectedColor = event.Value;
        
                    if ~isequal(initialColor, selectedColor)
                        selectedColor = rgb2hex(selectedColor);
            
                        switch event.Source
                            case app.StationsColor
                                app.mainApp.General.plot.stations.color = selectedColor;
                            case app.SelectedStationColor
                                app.mainApp.General.plot.selectedStation.color = selectedColor;
                            case app.PeakColor
                                app.mainApp.General.plot.fieldPeak.color = selectedColor;
                        end
                    end
            end

            app.mainApp.General_I.plot = app.mainApp.General.plot;

            updatePanel_Plot(app)
            saveGeneralSettings(app)

            ipcMainMatlabCallsHandler(app.mainApp, app, 'onPlotParameterChanged', 'MONITORINGPLAN')
            ipcMainMatlabCallsHandler(app.mainApp, app, 'onPlotParameterChanged', 'EXTERNALREQUEST')
            
        end

        % Image clicked function: eFiscalizaRefresh
        function Config_ProjectRefreshImageClicked(app, event)
            
            if ~checkEdition(app, 'REPORT')
                app.eFiscalizaRefresh.Visible = 0;
                return
            
            else
                app.mainApp.General.reportLib = app.defaultValues.reportLib;
                app.mainApp.General_I.reportLib = app.mainApp.General.reportLib;
                
                updatePanel_Report(app)
                saveGeneralSettings(app)
            end

        end

        % Value changed function: reportBasemap, reportBinningFcn, 
        % ...and 5 other components
        function Config_ProjectParameterValueChanged(app, event)

            switch event.Source
                case app.reportSystem
                    app.mainApp.General.reportLib.system = event.Value;

                case app.reportUnit
                    app.mainApp.General.reportLib.unit = event.Value;

                case app.prjFileCompressionMode
                    app.mainApp.General.reportLib.outputCompressionMode = event.Value;

                case app.reportBasemap
                    app.mainApp.General.reportLib.basemap = event.Value;

                case app.reportImgFormat
                    app.mainApp.General.reportLib.image.format = event.Value;

                case app.reportImgDpi
                    app.mainApp.General.reportLib.image.resolutionDpi = str2double(event.Value);

                case app.reportBinningLength
                    app.mainApp.General.reportLib.dataBinning.binLengthMeters = event.Value;

                case app.reportBinningFcn
                    app.mainApp.General.reportLib.dataBinning.aggregationFunction = event.Value;
            end

            app.mainApp.General_I.reportLib = app.mainApp.General.reportLib;

            updatePanel_Report(app)
            saveGeneralSettings(app)
            
        end

        % Image clicked function: DataHubPOSTButton, userPathButton
        function Config_FolderButtonPushed(app, event)
            
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
            if ~strcmp(app.mainApp.executionMode, 'webApp')
                figure(app.UIFigure)
            end

            if selectedFolder
                switch event.Source
                    case app.DataHubPOSTButton
                        if strcmp(app.mainApp.General.fileFolder.DataHub_POST, selectedFolder) 
                            return
                        else
                            selectedFolderFiles = dir(selectedFolder);
                            if ~ismember('.monitorrni_post', {selectedFolderFiles.name})
                                ui.Dialog(app.UIFigure, 'error', 'Não se trata da pasta "DataHub - POST", do monitorRNI.');
                                return
                            end

                            app.DataHubPOST.Value = selectedFolder;
                            app.mainApp.General.fileFolder.DataHub_POST = selectedFolder;
    
                            ipcMainMatlabCallsHandler(app.mainApp, app, 'checkDataHubLampStatus')
                        end

                    case app.userPathButton
                        app.userPath.Value = selectedFolder;
                        app.mainApp.General.fileFolder.userPath = selectedFolder;
                end

                app.mainApp.General_I.fileFolder = app.mainApp.General.fileFolder;

                updatePanel_Folder(app)
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
                if ~isprop(Container, 'RunningAppInstance')
                    addprop(app.Container, 'RunningAppInstance');
                end
                app.Container.RunningAppInstance = app;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {10, '1x', 48, 8, 2};
            app.GridLayout.RowHeight = {2, 8, 24, '1x', 10, 34};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create Toolbar
            app.Toolbar = uigridlayout(app.GridLayout);
            app.Toolbar.ColumnWidth = {22, '1x', 22, 22};
            app.Toolbar.RowHeight = {4, 17, '1x'};
            app.Toolbar.ColumnSpacing = 5;
            app.Toolbar.RowSpacing = 0;
            app.Toolbar.Padding = [10 5 10 5];
            app.Toolbar.Layout.Row = 6;
            app.Toolbar.Layout.Column = [1 5];
            app.Toolbar.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create tool_simulationMode
            app.tool_simulationMode = uiimage(app.Toolbar);
            app.tool_simulationMode.ScaleMethod = 'none';
            app.tool_simulationMode.ImageClickedFcn = createCallbackFcn(app, @Toolbar_SimulationModeButtonPushed, true);
            app.tool_simulationMode.Layout.Row = [1 3];
            app.tool_simulationMode.Layout.Column = 1;
            app.tool_simulationMode.ImageSource = 'Import_16.png';

            % Create tool_openDevTools
            app.tool_openDevTools = uiimage(app.Toolbar);
            app.tool_openDevTools.ScaleMethod = 'none';
            app.tool_openDevTools.ImageClickedFcn = createCallbackFcn(app, @Toolbar_OpenDevToolsClicked, true);
            app.tool_openDevTools.Enable = 'off';
            app.tool_openDevTools.Layout.Row = [1 3];
            app.tool_openDevTools.Layout.Column = 4;
            app.tool_openDevTools.ImageSource = 'Debug_18.png';

            % Create SubTabGroup
            app.SubTabGroup = uitabgroup(app.GridLayout);
            app.SubTabGroup.AutoResizeChildren = 'off';
            app.SubTabGroup.SelectionChangedFcn = createCallbackFcn(app, @SubTabGroup_TabSelectionChanged, true);
            app.SubTabGroup.Layout.Row = [3 4];
            app.SubTabGroup.Layout.Column = [2 3];

            % Create SubTab1
            app.SubTab1 = uitab(app.SubTabGroup);
            app.SubTab1.AutoResizeChildren = 'off';
            app.SubTab1.Title = 'ASPECTOS GERAIS';
            app.SubTab1.BackgroundColor = 'none';

            % Create SubGrid1
            app.SubGrid1 = uigridlayout(app.SubTab1);
            app.SubGrid1.ColumnWidth = {'1x', 22, 22};
            app.SubGrid1.RowHeight = {17, '1x', 1, 22, 15};
            app.SubGrid1.ColumnSpacing = 5;
            app.SubGrid1.RowSpacing = 5;
            app.SubGrid1.BackgroundColor = [1 1 1];

            % Create versionInfoLabel
            app.versionInfoLabel = uilabel(app.SubGrid1);
            app.versionInfoLabel.VerticalAlignment = 'bottom';
            app.versionInfoLabel.FontSize = 10;
            app.versionInfoLabel.Layout.Row = 1;
            app.versionInfoLabel.Layout.Column = 1;
            app.versionInfoLabel.Text = 'AMBIENTE:';

            % Create versionInfo
            app.versionInfo = uilabel(app.SubGrid1);
            app.versionInfo.BackgroundColor = [1 1 1];
            app.versionInfo.VerticalAlignment = 'top';
            app.versionInfo.WordWrap = 'on';
            app.versionInfo.FontSize = 11;
            app.versionInfo.Layout.Row = 2;
            app.versionInfo.Layout.Column = [1 3];
            app.versionInfo.Interpreter = 'html';
            app.versionInfo.Text = '';

            % Create tool_versionInfoRefresh
            app.tool_versionInfoRefresh = uiimage(app.SubGrid1);
            app.tool_versionInfoRefresh.ScaleMethod = 'none';
            app.tool_versionInfoRefresh.ImageClickedFcn = createCallbackFcn(app, @Toolbar_AppEnvRefreshButtonPushed, true);
            app.tool_versionInfoRefresh.Enable = 'off';
            app.tool_versionInfoRefresh.Tooltip = {'Verifica atualizações'};
            app.tool_versionInfoRefresh.Layout.Row = 1;
            app.tool_versionInfoRefresh.Layout.Column = 2;
            app.tool_versionInfoRefresh.VerticalAlignment = 'bottom';
            app.tool_versionInfoRefresh.ImageSource = 'Refresh_18.png';

            % Create tool_RFDataHubButton
            app.tool_RFDataHubButton = uiimage(app.SubGrid1);
            app.tool_RFDataHubButton.ImageClickedFcn = createCallbackFcn(app, @Toolbar_RFDataHubButtonPushed, true);
            app.tool_RFDataHubButton.Enable = 'off';
            app.tool_RFDataHubButton.Tooltip = {'Atualiza RFDataHub'};
            app.tool_RFDataHubButton.Layout.Row = 1;
            app.tool_RFDataHubButton.Layout.Column = 3;
            app.tool_RFDataHubButton.ImageSource = 'mosaic_32.png';

            % Create openAuxiliarAppAsDocked
            app.openAuxiliarAppAsDocked = uicheckbox(app.SubGrid1);
            app.openAuxiliarAppAsDocked.ValueChangedFcn = createCallbackFcn(app, @Config_GeneralParameterValueChanged, true);
            app.openAuxiliarAppAsDocked.Enable = 'off';
            app.openAuxiliarAppAsDocked.Text = 'Modo DOCK: módulos auxiliares abertos na janela principal do app';
            app.openAuxiliarAppAsDocked.FontSize = 11;
            app.openAuxiliarAppAsDocked.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.openAuxiliarAppAsDocked.Layout.Row = 4;
            app.openAuxiliarAppAsDocked.Layout.Column = 1;

            % Create openAuxiliarApp2Debug
            app.openAuxiliarApp2Debug = uicheckbox(app.SubGrid1);
            app.openAuxiliarApp2Debug.ValueChangedFcn = createCallbackFcn(app, @Config_GeneralParameterValueChanged, true);
            app.openAuxiliarApp2Debug.Enable = 'off';
            app.openAuxiliarApp2Debug.Text = 'Modo DEBUG';
            app.openAuxiliarApp2Debug.FontSize = 11;
            app.openAuxiliarApp2Debug.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.openAuxiliarApp2Debug.Layout.Row = 5;
            app.openAuxiliarApp2Debug.Layout.Column = 1;

            % Create SubTab2
            app.SubTab2 = uitab(app.SubTabGroup);
            app.SubTab2.AutoResizeChildren = 'off';
            app.SubTab2.Title = 'ANÁLISE';
            app.SubTab2.BackgroundColor = 'none';

            % Create SubGrid2
            app.SubGrid2 = uigridlayout(app.SubTab2);
            app.SubGrid2.ColumnWidth = {'1x', 22};
            app.SubGrid2.RowHeight = {17, 69, 22, 224, 22, '1x'};
            app.SubGrid2.RowSpacing = 5;
            app.SubGrid2.BackgroundColor = [1 1 1];

            % Create configAnalysisPanel1Label
            app.configAnalysisPanel1Label = uilabel(app.SubGrid2);
            app.configAnalysisPanel1Label.VerticalAlignment = 'bottom';
            app.configAnalysisPanel1Label.FontSize = 10;
            app.configAnalysisPanel1Label.Layout.Row = 1;
            app.configAnalysisPanel1Label.Layout.Column = 1;
            app.configAnalysisPanel1Label.Text = 'PROCESSO DE LEITURA DOS ARQUIVOS E VISUALIZAÇÃO DOS SEUS METADADOS';

            % Create configAnalysisRefresh
            app.configAnalysisRefresh = uiimage(app.SubGrid2);
            app.configAnalysisRefresh.ScaleMethod = 'none';
            app.configAnalysisRefresh.ImageClickedFcn = createCallbackFcn(app, @Config_AnalysisRefreshImageClicked, true);
            app.configAnalysisRefresh.Visible = 'off';
            app.configAnalysisRefresh.Tooltip = {'Retorna às configurações iniciais'};
            app.configAnalysisRefresh.Layout.Row = 1;
            app.configAnalysisRefresh.Layout.Column = 2;
            app.configAnalysisRefresh.VerticalAlignment = 'bottom';
            app.configAnalysisRefresh.ImageSource = 'Refresh_18.png';

            % Create configAnalysisPanel1
            app.configAnalysisPanel1 = uipanel(app.SubGrid2);
            app.configAnalysisPanel1.AutoResizeChildren = 'off';
            app.configAnalysisPanel1.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
            app.configAnalysisPanel1.Layout.Row = 2;
            app.configAnalysisPanel1.Layout.Column = [1 2];

            % Create configAnalysisGrid1
            app.configAnalysisGrid1 = uigridlayout(app.configAnalysisPanel1);
            app.configAnalysisGrid1.ColumnWidth = {350, 230};
            app.configAnalysisGrid1.RowHeight = {22, 22};
            app.configAnalysisGrid1.RowSpacing = 5;
            app.configAnalysisGrid1.BackgroundColor = [1 1 1];

            % Create InputTypeLabel
            app.InputTypeLabel = uilabel(app.configAnalysisGrid1);
            app.InputTypeLabel.FontSize = 11;
            app.InputTypeLabel.Layout.Row = 1;
            app.InputTypeLabel.Layout.Column = 1;
            app.InputTypeLabel.Text = 'Entrada:';

            % Create InputType
            app.InputType = uidropdown(app.configAnalysisGrid1);
            app.InputType.Items = {'file', 'folder'};
            app.InputType.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.InputType.FontSize = 11;
            app.InputType.BackgroundColor = [1 1 1];
            app.InputType.Layout.Row = 1;
            app.InputType.Layout.Column = 2;
            app.InputType.Value = 'file';

            % Create SortMethodLabel
            app.SortMethodLabel = uilabel(app.configAnalysisGrid1);
            app.SortMethodLabel.FontSize = 11;
            app.SortMethodLabel.Layout.Row = 2;
            app.SortMethodLabel.Layout.Column = 1;
            app.SortMethodLabel.Text = 'Visualização árvore:';

            % Create SortMethod
            app.SortMethod = uidropdown(app.configAnalysisGrid1);
            app.SortMethod.Items = {'ARQUIVO', 'LOCALIDADE'};
            app.SortMethod.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.SortMethod.FontSize = 11;
            app.SortMethod.BackgroundColor = [1 1 1];
            app.SortMethod.Layout.Row = 2;
            app.SortMethod.Layout.Column = 2;
            app.SortMethod.Value = 'LOCALIDADE';

            % Create configAnalysisPanel2Label
            app.configAnalysisPanel2Label = uilabel(app.SubGrid2);
            app.configAnalysisPanel2Label.VerticalAlignment = 'bottom';
            app.configAnalysisPanel2Label.FontSize = 10;
            app.configAnalysisPanel2Label.Layout.Row = 3;
            app.configAnalysisPanel2Label.Layout.Column = 1;
            app.configAnalysisPanel2Label.Text = 'PM-RNI';

            % Create configAnalysisPanel2
            app.configAnalysisPanel2 = uipanel(app.SubGrid2);
            app.configAnalysisPanel2.AutoResizeChildren = 'off';
            app.configAnalysisPanel2.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.configAnalysisPanel2.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
            app.configAnalysisPanel2.Layout.Row = 4;
            app.configAnalysisPanel2.Layout.Column = [1 2];

            % Create configAnalysisGrid2
            app.configAnalysisGrid2 = uigridlayout(app.configAnalysisPanel2);
            app.configAnalysisGrid2.ColumnWidth = {350, 90, '1x', 20};
            app.configAnalysisGrid2.RowHeight = {22, 22, 22, '1x', 1, 17, 17};
            app.configAnalysisGrid2.ColumnSpacing = 5;
            app.configAnalysisGrid2.RowSpacing = 5;
            app.configAnalysisGrid2.BackgroundColor = [1 1 1];

            % Create MonitoringPlanDistanceLabel
            app.MonitoringPlanDistanceLabel = uilabel(app.configAnalysisGrid2);
            app.MonitoringPlanDistanceLabel.WordWrap = 'on';
            app.MonitoringPlanDistanceLabel.FontSize = 11;
            app.MonitoringPlanDistanceLabel.Layout.Row = 1;
            app.MonitoringPlanDistanceLabel.Layout.Column = 1;
            app.MonitoringPlanDistanceLabel.Text = 'Distância limite entre ponto de medição e a estação sob análise (m):';

            % Create MonitoringPlanDistance
            app.MonitoringPlanDistance = uieditfield(app.configAnalysisGrid2, 'numeric');
            app.MonitoringPlanDistance.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.MonitoringPlanDistance.FontSize = 11;
            app.MonitoringPlanDistance.Layout.Row = 1;
            app.MonitoringPlanDistance.Layout.Column = 2;
            app.MonitoringPlanDistance.Value = 200;

            % Create MonitoringPlanLevelLabel
            app.MonitoringPlanLevelLabel = uilabel(app.configAnalysisGrid2);
            app.MonitoringPlanLevelLabel.WordWrap = 'on';
            app.MonitoringPlanLevelLabel.FontSize = 11;
            app.MonitoringPlanLevelLabel.Layout.Row = 2;
            app.MonitoringPlanLevelLabel.Layout.Column = 1;
            app.MonitoringPlanLevelLabel.Text = 'Nível de referência de campo elétrico: (V/m)';

            % Create MonitoringPlanLevel
            app.MonitoringPlanLevel = uieditfield(app.configAnalysisGrid2, 'numeric');
            app.MonitoringPlanLevel.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.MonitoringPlanLevel.FontSize = 11;
            app.MonitoringPlanLevel.Layout.Row = 2;
            app.MonitoringPlanLevel.Layout.Column = 2;
            app.MonitoringPlanLevel.Value = 14;

            % Create MonitoringPlanFileLabel
            app.MonitoringPlanFileLabel = uilabel(app.configAnalysisGrid2);
            app.MonitoringPlanFileLabel.WordWrap = 'on';
            app.MonitoringPlanFileLabel.FontSize = 11;
            app.MonitoringPlanFileLabel.Layout.Row = 3;
            app.MonitoringPlanFileLabel.Layout.Column = 1;
            app.MonitoringPlanFileLabel.Text = 'Base de referência das estações sob análise:';

            % Create MonitoringPlanFileName
            app.MonitoringPlanFileName = uieditfield(app.configAnalysisGrid2, 'text');
            app.MonitoringPlanFileName.Editable = 'off';
            app.MonitoringPlanFileName.FontSize = 11;
            app.MonitoringPlanFileName.Layout.Row = 3;
            app.MonitoringPlanFileName.Layout.Column = [2 3];

            % Create MonitoringPlanOpenFile
            app.MonitoringPlanOpenFile = uiimage(app.configAnalysisGrid2);
            app.MonitoringPlanOpenFile.ScaleMethod = 'none';
            app.MonitoringPlanOpenFile.ImageClickedFcn = createCallbackFcn(app, @Config_AnalysisOpenReferenceFile, true);
            app.MonitoringPlanOpenFile.Tooltip = {'Abrir no Excel a planilha de referência'};
            app.MonitoringPlanOpenFile.Layout.Row = 3;
            app.MonitoringPlanOpenFile.Layout.Column = 4;
            app.MonitoringPlanOpenFile.ImageSource = 'Import_16.png';

            % Create MonitoringPlanFileSubLabel
            app.MonitoringPlanFileSubLabel = uilabel(app.configAnalysisGrid2);
            app.MonitoringPlanFileSubLabel.VerticalAlignment = 'top';
            app.MonitoringPlanFileSubLabel.WordWrap = 'on';
            app.MonitoringPlanFileSubLabel.FontSize = 11;
            app.MonitoringPlanFileSubLabel.FontColor = [0.502 0.502 0.502];
            app.MonitoringPlanFileSubLabel.Layout.Row = 4;
            app.MonitoringPlanFileSubLabel.Layout.Column = 1;
            app.MonitoringPlanFileSubLabel.Text = {'Sessão corrente: [ 2026 ]'; '(eventuais alterações nos anos de referência só terão efeito após a reinicialização do aplicativo)'};

            % Create MonitoringPlanPeriod
            app.MonitoringPlanPeriod = uitree(app.configAnalysisGrid2, 'checkbox');
            app.MonitoringPlanPeriod.FontSize = 11;
            app.MonitoringPlanPeriod.Layout.Row = 4;
            app.MonitoringPlanPeriod.Layout.Column = [2 3];

            % Assign Checked Nodes
            app.MonitoringPlanPeriod.CheckedNodesChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);

            % Create MonitoringPlanExportXLSX
            app.MonitoringPlanExportXLSX = uicheckbox(app.configAnalysisGrid2);
            app.MonitoringPlanExportXLSX.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.MonitoringPlanExportXLSX.Text = 'Ao exportar a tabela de dados, cria uma segunda aba na planilha com as medidas brutas.';
            app.MonitoringPlanExportXLSX.FontSize = 11;
            app.MonitoringPlanExportXLSX.Layout.Row = 6;
            app.MonitoringPlanExportXLSX.Layout.Column = [1 3];

            % Create MonitoringPlanExportKML
            app.MonitoringPlanExportKML = uicheckbox(app.configAnalysisGrid2);
            app.MonitoringPlanExportKML.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.MonitoringPlanExportKML.Text = 'Ao exportar a tabela de dados, cria arquivos no formato "kml".';
            app.MonitoringPlanExportKML.FontSize = 11;
            app.MonitoringPlanExportKML.Layout.Row = 7;
            app.MonitoringPlanExportKML.Layout.Column = [1 3];

            % Create configAnalysisPanel3Label
            app.configAnalysisPanel3Label = uilabel(app.SubGrid2);
            app.configAnalysisPanel3Label.VerticalAlignment = 'bottom';
            app.configAnalysisPanel3Label.FontSize = 10;
            app.configAnalysisPanel3Label.Layout.Row = 5;
            app.configAnalysisPanel3Label.Layout.Column = 1;
            app.configAnalysisPanel3Label.Text = 'DEMANDA EXTERNA';

            % Create configAnalysisPanel3
            app.configAnalysisPanel3 = uipanel(app.SubGrid2);
            app.configAnalysisPanel3.AutoResizeChildren = 'off';
            app.configAnalysisPanel3.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.configAnalysisPanel3.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
            app.configAnalysisPanel3.Layout.Row = 6;
            app.configAnalysisPanel3.Layout.Column = [1 2];

            % Create configAnalysisGrid3
            app.configAnalysisGrid3 = uigridlayout(app.configAnalysisPanel3);
            app.configAnalysisGrid3.ColumnWidth = {350, 90, 130};
            app.configAnalysisGrid3.RowHeight = {22, 22, 1, 17, 17};
            app.configAnalysisGrid3.RowSpacing = 5;
            app.configAnalysisGrid3.BackgroundColor = [1 1 1];

            % Create ExternalRequestDistanceLabel
            app.ExternalRequestDistanceLabel = uilabel(app.configAnalysisGrid3);
            app.ExternalRequestDistanceLabel.WordWrap = 'on';
            app.ExternalRequestDistanceLabel.FontSize = 11;
            app.ExternalRequestDistanceLabel.Layout.Row = 1;
            app.ExternalRequestDistanceLabel.Layout.Column = [1 2];
            app.ExternalRequestDistanceLabel.Text = 'Distância limite entre ponto de medição e a estação sob análise (m):';

            % Create ExternalRequestDistance
            app.ExternalRequestDistance = uieditfield(app.configAnalysisGrid3, 'numeric');
            app.ExternalRequestDistance.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.ExternalRequestDistance.FontSize = 11;
            app.ExternalRequestDistance.Layout.Row = 1;
            app.ExternalRequestDistance.Layout.Column = 2;
            app.ExternalRequestDistance.Value = 1000;

            % Create ExternalRequestLevelLabel
            app.ExternalRequestLevelLabel = uilabel(app.configAnalysisGrid3);
            app.ExternalRequestLevelLabel.WordWrap = 'on';
            app.ExternalRequestLevelLabel.FontSize = 11;
            app.ExternalRequestLevelLabel.Layout.Row = 2;
            app.ExternalRequestLevelLabel.Layout.Column = 1;
            app.ExternalRequestLevelLabel.Text = 'Nível de referência de campo elétrico: (V/m)';

            % Create ExternalRequestLevel
            app.ExternalRequestLevel = uieditfield(app.configAnalysisGrid3, 'numeric');
            app.ExternalRequestLevel.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.ExternalRequestLevel.FontSize = 11;
            app.ExternalRequestLevel.Layout.Row = 2;
            app.ExternalRequestLevel.Layout.Column = 2;
            app.ExternalRequestLevel.Value = 14;

            % Create ExternalRequestExportXLSX
            app.ExternalRequestExportXLSX = uicheckbox(app.configAnalysisGrid3);
            app.ExternalRequestExportXLSX.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.ExternalRequestExportXLSX.Text = 'Ao exportar a tabela de dados, cria uma segunda aba na planilha com as medidas brutas.';
            app.ExternalRequestExportXLSX.FontSize = 11;
            app.ExternalRequestExportXLSX.Layout.Row = 4;
            app.ExternalRequestExportXLSX.Layout.Column = [1 3];

            % Create ExternalRequestExportKML
            app.ExternalRequestExportKML = uicheckbox(app.configAnalysisGrid3);
            app.ExternalRequestExportKML.ValueChangedFcn = createCallbackFcn(app, @Config_AnalysisParameterValueChanged, true);
            app.ExternalRequestExportKML.Text = 'Ao exportar a tabela de dados, cria arquivos no formato "kml".';
            app.ExternalRequestExportKML.FontSize = 11;
            app.ExternalRequestExportKML.Layout.Row = 5;
            app.ExternalRequestExportKML.Layout.Column = [1 3];

            % Create SubTab3
            app.SubTab3 = uitab(app.SubTabGroup);
            app.SubTab3.AutoResizeChildren = 'off';
            app.SubTab3.Title = 'PLOT';

            % Create SubGrid3
            app.SubGrid3 = uigridlayout(app.SubTab3);
            app.SubGrid3.ColumnWidth = {'1x', 22};
            app.SubGrid3.RowHeight = {17, 182, 22, '1x'};
            app.SubGrid3.RowSpacing = 5;
            app.SubGrid3.BackgroundColor = [1 1 1];

            % Create configPlotTitle1
            app.configPlotTitle1 = uilabel(app.SubGrid3);
            app.configPlotTitle1.VerticalAlignment = 'bottom';
            app.configPlotTitle1.FontSize = 10;
            app.configPlotTitle1.Layout.Row = 1;
            app.configPlotTitle1.Layout.Column = 1;
            app.configPlotTitle1.Text = 'EIXO GEOGRÁFICO';

            % Create configPlotRefresh
            app.configPlotRefresh = uiimage(app.SubGrid3);
            app.configPlotRefresh.ScaleMethod = 'none';
            app.configPlotRefresh.ImageClickedFcn = createCallbackFcn(app, @Config_PlotRefreshImageClicked, true);
            app.configPlotRefresh.Visible = 'off';
            app.configPlotRefresh.Tooltip = {'Retorna às configurações iniciais'};
            app.configPlotRefresh.Layout.Row = 1;
            app.configPlotRefresh.Layout.Column = 2;
            app.configPlotRefresh.VerticalAlignment = 'bottom';
            app.configPlotRefresh.ImageSource = 'Refresh_18.png';

            % Create configPlotPanel1
            app.configPlotPanel1 = uipanel(app.SubGrid3);
            app.configPlotPanel1.AutoResizeChildren = 'off';
            app.configPlotPanel1.Layout.Row = 2;
            app.configPlotPanel1.Layout.Column = [1 2];

            % Create configPlotGrid1
            app.configPlotGrid1 = uigridlayout(app.configPlotPanel1);
            app.configPlotGrid1.ColumnWidth = {350, 110, 110};
            app.configPlotGrid1.RowHeight = {22, 22, 22, 22, 22, 22, 1};
            app.configPlotGrid1.RowSpacing = 5;
            app.configPlotGrid1.BackgroundColor = [1 1 1];

            % Create BasemapLabel
            app.BasemapLabel = uilabel(app.configPlotGrid1);
            app.BasemapLabel.FontSize = 11;
            app.BasemapLabel.Layout.Row = 1;
            app.BasemapLabel.Layout.Column = 1;
            app.BasemapLabel.Text = 'Basemap:';

            % Create Basemap
            app.Basemap = uidropdown(app.configPlotGrid1);
            app.Basemap.Items = {'darkwater', 'none', 'satellite', 'streets-dark', 'streets-light', 'topographic'};
            app.Basemap.ValueChangedFcn = createCallbackFcn(app, @Config_PlotAxesValueChanged, true);
            app.Basemap.FontSize = 11;
            app.Basemap.BackgroundColor = [1 1 1];
            app.Basemap.Layout.Row = 1;
            app.Basemap.Layout.Column = [2 3];
            app.Basemap.Value = 'satellite';

            % Create ColormapLabel
            app.ColormapLabel = uilabel(app.configPlotGrid1);
            app.ColormapLabel.FontSize = 11;
            app.ColormapLabel.Layout.Row = 2;
            app.ColormapLabel.Layout.Column = 1;
            app.ColormapLabel.Text = 'Mapa de cor:';

            % Create Colormap
            app.Colormap = uidropdown(app.configPlotGrid1);
            app.Colormap.Items = {'winter', 'parula', 'turbo', 'gray', 'hot', 'jet', 'summer'};
            app.Colormap.ValueChangedFcn = createCallbackFcn(app, @Config_PlotAxesValueChanged, true);
            app.Colormap.FontSize = 11;
            app.Colormap.BackgroundColor = [1 1 1];
            app.Colormap.Layout.Row = 2;
            app.Colormap.Layout.Column = [2 3];
            app.Colormap.Value = 'turbo';

            % Create ColorbarLabel
            app.ColorbarLabel = uilabel(app.configPlotGrid1);
            app.ColorbarLabel.FontSize = 11;
            app.ColorbarLabel.Layout.Row = 3;
            app.ColorbarLabel.Layout.Column = 1;
            app.ColorbarLabel.Text = 'Legenda de cor:';

            % Create Colorbar
            app.Colorbar = uidropdown(app.configPlotGrid1);
            app.Colorbar.Items = {'off', 'on'};
            app.Colorbar.ValueChangedFcn = createCallbackFcn(app, @Config_PlotAxesValueChanged, true);
            app.Colorbar.FontSize = 11;
            app.Colorbar.BackgroundColor = [1 1 1];
            app.Colorbar.Layout.Row = 3;
            app.Colorbar.Layout.Column = 2;
            app.Colorbar.Value = 'on';

            % Create ZoomOrientationLabel
            app.ZoomOrientationLabel = uilabel(app.configPlotGrid1);
            app.ZoomOrientationLabel.WordWrap = 'on';
            app.ZoomOrientationLabel.FontSize = 11;
            app.ZoomOrientationLabel.Layout.Row = 4;
            app.ZoomOrientationLabel.Layout.Column = 1;
            app.ZoomOrientationLabel.Text = 'Orientação do zoom:';

            % Create ZoomOrientation
            app.ZoomOrientation = uidropdown(app.configPlotGrid1);
            app.ZoomOrientation.Items = {'measures', 'stations/points'};
            app.ZoomOrientation.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.ZoomOrientation.FontSize = 11;
            app.ZoomOrientation.BackgroundColor = [1 1 1];
            app.ZoomOrientation.Layout.Row = 4;
            app.ZoomOrientation.Layout.Column = 2;
            app.ZoomOrientation.Value = 'measures';

            % Create AutomaticZoomMode
            app.AutomaticZoomMode = uicheckbox(app.configPlotGrid1);
            app.AutomaticZoomMode.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.AutomaticZoomMode.Text = 'Habilitar zoom automático em torno da estação/ponto sob análise.';
            app.AutomaticZoomMode.FontSize = 11;
            app.AutomaticZoomMode.Layout.Row = 5;
            app.AutomaticZoomMode.Layout.Column = [1 3];

            % Create AutomaticZoomFactorLabel
            app.AutomaticZoomFactorLabel = uilabel(app.configPlotGrid1);
            app.AutomaticZoomFactorLabel.FontSize = 11;
            app.AutomaticZoomFactorLabel.Layout.Row = [6 7];
            app.AutomaticZoomFactorLabel.Layout.Column = 1;
            app.AutomaticZoomFactorLabel.Interpreter = 'html';
            app.AutomaticZoomFactorLabel.Text = {'Fator do zoom: '; '<font style="font-size: 10px;">(distância referência)</font>'};

            % Create AutomaticZoomFactor
            app.AutomaticZoomFactor = uispinner(app.configPlotGrid1);
            app.AutomaticZoomFactor.Limits = [1 10];
            app.AutomaticZoomFactor.RoundFractionalValues = 'on';
            app.AutomaticZoomFactor.ValueDisplayFormat = '%d';
            app.AutomaticZoomFactor.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.AutomaticZoomFactor.FontSize = 11;
            app.AutomaticZoomFactor.Enable = 'off';
            app.AutomaticZoomFactor.Layout.Row = 6;
            app.AutomaticZoomFactor.Layout.Column = 2;
            app.AutomaticZoomFactor.Value = 4;

            % Create configPlotTitle2
            app.configPlotTitle2 = uilabel(app.SubGrid3);
            app.configPlotTitle2.VerticalAlignment = 'bottom';
            app.configPlotTitle2.FontSize = 10;
            app.configPlotTitle2.Layout.Row = 3;
            app.configPlotTitle2.Layout.Column = 1;
            app.configPlotTitle2.Text = 'ESTAÇÃO/PONTO';

            % Create configPlotPanel2
            app.configPlotPanel2 = uipanel(app.SubGrid3);
            app.configPlotPanel2.AutoResizeChildren = 'off';
            app.configPlotPanel2.Layout.Row = 4;
            app.configPlotPanel2.Layout.Column = [1 2];

            % Create configPlotGrid2
            app.configPlotGrid2 = uigridlayout(app.configPlotPanel2);
            app.configPlotGrid2.ColumnWidth = {350, 36, 64, 110};
            app.configPlotGrid2.RowHeight = {22, 22, 22, 22, 22, 1};
            app.configPlotGrid2.RowSpacing = 5;
            app.configPlotGrid2.BackgroundColor = [1 1 1];

            % Create StationsLabel
            app.StationsLabel = uilabel(app.configPlotGrid2);
            app.StationsLabel.WordWrap = 'on';
            app.StationsLabel.FontSize = 11;
            app.StationsLabel.Layout.Row = 1;
            app.StationsLabel.Layout.Column = 1;
            app.StationsLabel.Text = 'Estações/pontos de referência:';

            % Create StationsColor
            app.StationsColor = uicolorpicker(app.configPlotGrid2);
            app.StationsColor.Value = [0 1 1];
            app.StationsColor.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.StationsColor.Layout.Row = 1;
            app.StationsColor.Layout.Column = 2;
            app.StationsColor.BackgroundColor = [1 1 1];

            % Create StationsSize
            app.StationsSize = uislider(app.configPlotGrid2);
            app.StationsSize.Limits = [1 36];
            app.StationsSize.MajorTicks = [];
            app.StationsSize.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.StationsSize.MinorTicks = [];
            app.StationsSize.FontSize = 10;
            app.StationsSize.Tooltip = {'Tamanho do marcador'};
            app.StationsSize.Layout.Row = 1;
            app.StationsSize.Layout.Column = [3 4];
            app.StationsSize.Value = 12;

            % Create SelectedStationLabel
            app.SelectedStationLabel = uilabel(app.configPlotGrid2);
            app.SelectedStationLabel.WordWrap = 'on';
            app.SelectedStationLabel.FontSize = 11;
            app.SelectedStationLabel.Layout.Row = 2;
            app.SelectedStationLabel.Layout.Column = 1;
            app.SelectedStationLabel.Text = 'Estação/ponto sob análise:';

            % Create SelectedStationColor
            app.SelectedStationColor = uicolorpicker(app.configPlotGrid2);
            app.SelectedStationColor.Value = [0 1 1];
            app.SelectedStationColor.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.SelectedStationColor.Layout.Row = 2;
            app.SelectedStationColor.Layout.Column = 2;
            app.SelectedStationColor.BackgroundColor = [1 1 1];

            % Create SelectedStationSize
            app.SelectedStationSize = uislider(app.configPlotGrid2);
            app.SelectedStationSize.Limits = [1 36];
            app.SelectedStationSize.MajorTicks = [];
            app.SelectedStationSize.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.SelectedStationSize.MinorTicks = [];
            app.SelectedStationSize.FontSize = 10;
            app.SelectedStationSize.Tooltip = {'Tamanho do marcador'};
            app.SelectedStationSize.Layout.Row = 2;
            app.SelectedStationSize.Layout.Column = [3 4];
            app.SelectedStationSize.Value = 32;

            % Create PeakLabel
            app.PeakLabel = uilabel(app.configPlotGrid2);
            app.PeakLabel.WordWrap = 'on';
            app.PeakLabel.FontSize = 11;
            app.PeakLabel.Layout.Row = 3;
            app.PeakLabel.Layout.Column = 1;
            app.PeakLabel.Text = 'Pico em torno da estação/ponto:';

            % Create PeakColor
            app.PeakColor = uicolorpicker(app.configPlotGrid2);
            app.PeakColor.Value = [1 1 0];
            app.PeakColor.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.PeakColor.Layout.Row = 3;
            app.PeakColor.Layout.Column = 2;
            app.PeakColor.BackgroundColor = [1 1 1];

            % Create PeakSize
            app.PeakSize = uislider(app.configPlotGrid2);
            app.PeakSize.Limits = [1 36];
            app.PeakSize.MajorTicks = [];
            app.PeakSize.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.PeakSize.MinorTicks = [];
            app.PeakSize.FontSize = 10;
            app.PeakSize.Tooltip = {'Tamanho do marcador'};
            app.PeakSize.Layout.Row = 3;
            app.PeakSize.Layout.Column = [3 4];
            app.PeakSize.Value = 32;

            % Create CircleColorLabel
            app.CircleColorLabel = uilabel(app.configPlotGrid2);
            app.CircleColorLabel.WordWrap = 'on';
            app.CircleColorLabel.FontSize = 11;
            app.CircleColorLabel.Layout.Row = 4;
            app.CircleColorLabel.Layout.Column = 1;
            app.CircleColorLabel.Text = 'Região circular em torno da estação/ponto:';

            % Create CircleColor
            app.CircleColor = uidropdown(app.configPlotGrid2);
            app.CircleColor.Items = {'black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow'};
            app.CircleColor.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.CircleColor.FontSize = 11;
            app.CircleColor.BackgroundColor = [1 1 1];
            app.CircleColor.Layout.Row = 4;
            app.CircleColor.Layout.Column = [2 4];
            app.CircleColor.Value = 'cyan';

            % Create CircleColorAlphaLabel
            app.CircleColorAlphaLabel = uilabel(app.configPlotGrid2);
            app.CircleColorAlphaLabel.WordWrap = 'on';
            app.CircleColorAlphaLabel.FontSize = 11;
            app.CircleColorAlphaLabel.Layout.Row = [5 6];
            app.CircleColorAlphaLabel.Layout.Column = 1;
            app.CircleColorAlphaLabel.Interpreter = 'html';
            app.CircleColorAlphaLabel.Text = {'Região circular em torno da estação/ponto: '; '<font style="font-size: 10px;">(transparência da face e borda)</font>'};

            % Create CircleFaceAlpha
            app.CircleFaceAlpha = uispinner(app.configPlotGrid2);
            app.CircleFaceAlpha.Step = 0.05;
            app.CircleFaceAlpha.Limits = [0 1];
            app.CircleFaceAlpha.ValueDisplayFormat = '%.2f';
            app.CircleFaceAlpha.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.CircleFaceAlpha.FontSize = 11;
            app.CircleFaceAlpha.Layout.Row = 5;
            app.CircleFaceAlpha.Layout.Column = [2 3];
            app.CircleFaceAlpha.Value = 0.25;

            % Create CircleEdgeAlpha
            app.CircleEdgeAlpha = uispinner(app.configPlotGrid2);
            app.CircleEdgeAlpha.Step = 0.05;
            app.CircleEdgeAlpha.Limits = [0 1];
            app.CircleEdgeAlpha.ValueDisplayFormat = '%.2f';
            app.CircleEdgeAlpha.ValueChangedFcn = createCallbackFcn(app, @Config_PlotParameterValueChanged, true);
            app.CircleEdgeAlpha.FontSize = 11;
            app.CircleEdgeAlpha.Layout.Row = 5;
            app.CircleEdgeAlpha.Layout.Column = 4;
            app.CircleEdgeAlpha.Value = 0.4;

            % Create SubTab4
            app.SubTab4 = uitab(app.SubTabGroup);
            app.SubTab4.Title = 'PROJETO';

            % Create SubGrid4
            app.SubGrid4 = uigridlayout(app.SubTab4);
            app.SubGrid4.ColumnWidth = {'1x', 22};
            app.SubGrid4.RowHeight = {17, 70, 22, '1x'};
            app.SubGrid4.RowSpacing = 5;
            app.SubGrid4.BackgroundColor = [1 1 1];

            % Create eFiscalizaLabel
            app.eFiscalizaLabel = uilabel(app.SubGrid4);
            app.eFiscalizaLabel.VerticalAlignment = 'bottom';
            app.eFiscalizaLabel.FontSize = 10;
            app.eFiscalizaLabel.Layout.Row = 1;
            app.eFiscalizaLabel.Layout.Column = 1;
            app.eFiscalizaLabel.Text = 'INICIALIZAÇÃO eFISCALIZA';

            % Create eFiscalizaRefresh
            app.eFiscalizaRefresh = uiimage(app.SubGrid4);
            app.eFiscalizaRefresh.ScaleMethod = 'none';
            app.eFiscalizaRefresh.ImageClickedFcn = createCallbackFcn(app, @Config_ProjectRefreshImageClicked, true);
            app.eFiscalizaRefresh.Visible = 'off';
            app.eFiscalizaRefresh.Tooltip = {'Retorna às configurações iniciais'};
            app.eFiscalizaRefresh.Layout.Row = 1;
            app.eFiscalizaRefresh.Layout.Column = 2;
            app.eFiscalizaRefresh.VerticalAlignment = 'bottom';
            app.eFiscalizaRefresh.ImageSource = 'Refresh_18.png';

            % Create eFiscalizaPanel
            app.eFiscalizaPanel = uipanel(app.SubGrid4);
            app.eFiscalizaPanel.Layout.Row = 2;
            app.eFiscalizaPanel.Layout.Column = [1 2];

            % Create eFiscalizaGrid
            app.eFiscalizaGrid = uigridlayout(app.eFiscalizaPanel);
            app.eFiscalizaGrid.ColumnWidth = {350, 110, 110};
            app.eFiscalizaGrid.RowHeight = {22, 22};
            app.eFiscalizaGrid.RowSpacing = 5;
            app.eFiscalizaGrid.BackgroundColor = [1 1 1];

            % Create reportSystemLabel
            app.reportSystemLabel = uilabel(app.eFiscalizaGrid);
            app.reportSystemLabel.WordWrap = 'on';
            app.reportSystemLabel.FontSize = 11;
            app.reportSystemLabel.Layout.Row = 1;
            app.reportSystemLabel.Layout.Column = 1;
            app.reportSystemLabel.Text = 'Ambiente do sistema de gestão à fiscalização:';

            % Create reportSystem
            app.reportSystem = uidropdown(app.eFiscalizaGrid);
            app.reportSystem.Items = {'eFiscaliza', 'eFiscaliza TS', 'eFiscaliza HM', 'eFiscaliza DS'};
            app.reportSystem.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportSystem.FontSize = 11;
            app.reportSystem.BackgroundColor = [1 1 1];
            app.reportSystem.Layout.Row = 1;
            app.reportSystem.Layout.Column = [2 3];
            app.reportSystem.Value = 'eFiscaliza';

            % Create reportUnitLabel
            app.reportUnitLabel = uilabel(app.eFiscalizaGrid);
            app.reportUnitLabel.WordWrap = 'on';
            app.reportUnitLabel.FontSize = 11;
            app.reportUnitLabel.Layout.Row = 2;
            app.reportUnitLabel.Layout.Column = 1;
            app.reportUnitLabel.Text = 'Unidade responsável pela fiscalização:';

            % Create reportUnit
            app.reportUnit = uidropdown(app.eFiscalizaGrid);
            app.reportUnit.Items = {};
            app.reportUnit.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportUnit.FontSize = 11;
            app.reportUnit.BackgroundColor = [1 1 1];
            app.reportUnit.Layout.Row = 2;
            app.reportUnit.Layout.Column = 2;
            app.reportUnit.Value = {};

            % Create reportLabel
            app.reportLabel = uilabel(app.SubGrid4);
            app.reportLabel.VerticalAlignment = 'bottom';
            app.reportLabel.FontSize = 10;
            app.reportLabel.Layout.Row = 3;
            app.reportLabel.Layout.Column = 1;
            app.reportLabel.Text = 'RELATÓRIO + BASEMAP + IMAGEM + DATABINNING';

            % Create reportPanel
            app.reportPanel = uipanel(app.SubGrid4);
            app.reportPanel.BackgroundColor = [1 1 1];
            app.reportPanel.Layout.Row = 4;
            app.reportPanel.Layout.Column = [1 2];

            % Create reportGrid
            app.reportGrid = uigridlayout(app.reportPanel);
            app.reportGrid.ColumnWidth = {350, 110, 110};
            app.reportGrid.RowHeight = {22, 22, 22, 48, 22, '1x'};
            app.reportGrid.RowSpacing = 5;
            app.reportGrid.BackgroundColor = [1 1 1];

            % Create reportBasemapLabel
            app.reportBasemapLabel = uilabel(app.reportGrid);
            app.reportBasemapLabel.FontSize = 11;
            app.reportBasemapLabel.Layout.Row = 1;
            app.reportBasemapLabel.Layout.Column = 1;
            app.reportBasemapLabel.Text = 'Basemap do eixo geográfico dos plots:';

            % Create reportBasemap
            app.reportBasemap = uidropdown(app.reportGrid);
            app.reportBasemap.Items = {'darkwater', 'none', 'satellite', 'streets-dark', 'streets-light', 'topographic'};
            app.reportBasemap.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportBasemap.FontSize = 11;
            app.reportBasemap.BackgroundColor = [1 1 1];
            app.reportBasemap.Layout.Row = 1;
            app.reportBasemap.Layout.Column = [2 3];
            app.reportBasemap.Value = 'streets-dark';

            % Create reportImageLabel
            app.reportImageLabel = uilabel(app.reportGrid);
            app.reportImageLabel.FontSize = 11;
            app.reportImageLabel.Layout.Row = 2;
            app.reportImageLabel.Layout.Column = 1;
            app.reportImageLabel.Text = 'Formato e resolução (dpi) das imagens:';

            % Create reportImgFormat
            app.reportImgFormat = uidropdown(app.reportGrid);
            app.reportImgFormat.Items = {'jpeg', 'png'};
            app.reportImgFormat.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportImgFormat.FontSize = 11;
            app.reportImgFormat.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportImgFormat.BackgroundColor = [1 1 1];
            app.reportImgFormat.Layout.Row = 2;
            app.reportImgFormat.Layout.Column = 2;
            app.reportImgFormat.Value = 'jpeg';

            % Create reportImgDpi
            app.reportImgDpi = uidropdown(app.reportGrid);
            app.reportImgDpi.Items = {'100', '120', '150', '200'};
            app.reportImgDpi.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportImgDpi.FontSize = 11;
            app.reportImgDpi.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportImgDpi.BackgroundColor = [1 1 1];
            app.reportImgDpi.Layout.Row = 2;
            app.reportImgDpi.Layout.Column = 3;
            app.reportImgDpi.Value = '100';

            % Create reportBinningLabel
            app.reportBinningLabel = uilabel(app.reportGrid);
            app.reportBinningLabel.VerticalAlignment = 'top';
            app.reportBinningLabel.FontSize = 11;
            app.reportBinningLabel.Layout.Row = [3 4];
            app.reportBinningLabel.Layout.Column = 1;
            app.reportBinningLabel.Text = {'Sumarização de pontos com níveis superiores ao limiar:'; '(Data-Binning)'};

            % Create reportBinningPanel
            app.reportBinningPanel = uipanel(app.reportGrid);
            app.reportBinningPanel.AutoResizeChildren = 'off';
            app.reportBinningPanel.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportBinningPanel.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
            app.reportBinningPanel.Layout.Row = [3 4];
            app.reportBinningPanel.Layout.Column = [2 3];

            % Create reportBinningGrid
            app.reportBinningGrid = uigridlayout(app.reportBinningPanel);
            app.reportBinningGrid.ColumnWidth = {100, 100};
            app.reportBinningGrid.RowHeight = {'1x', 22};
            app.reportBinningGrid.RowSpacing = 5;
            app.reportBinningGrid.Padding = [10 10 10 5];
            app.reportBinningGrid.BackgroundColor = [1 1 1];

            % Create reportBinningLengthLabel
            app.reportBinningLengthLabel = uilabel(app.reportBinningGrid);
            app.reportBinningLengthLabel.VerticalAlignment = 'bottom';
            app.reportBinningLengthLabel.WordWrap = 'on';
            app.reportBinningLengthLabel.FontSize = 11;
            app.reportBinningLengthLabel.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportBinningLengthLabel.Layout.Row = 1;
            app.reportBinningLengthLabel.Layout.Column = 1;
            app.reportBinningLengthLabel.Text = 'Comprimento quadrícula (metros):';

            % Create reportBinningLength
            app.reportBinningLength = uispinner(app.reportBinningGrid);
            app.reportBinningLength.Step = 50;
            app.reportBinningLength.Limits = [50 1500];
            app.reportBinningLength.RoundFractionalValues = 'on';
            app.reportBinningLength.ValueDisplayFormat = '%.0f';
            app.reportBinningLength.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportBinningLength.FontSize = 11;
            app.reportBinningLength.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportBinningLength.Layout.Row = 2;
            app.reportBinningLength.Layout.Column = 1;
            app.reportBinningLength.Value = 100;

            % Create reportBinningFcnLabel
            app.reportBinningFcnLabel = uilabel(app.reportBinningGrid);
            app.reportBinningFcnLabel.VerticalAlignment = 'bottom';
            app.reportBinningFcnLabel.WordWrap = 'on';
            app.reportBinningFcnLabel.FontSize = 11;
            app.reportBinningFcnLabel.Layout.Row = 1;
            app.reportBinningFcnLabel.Layout.Column = 2;
            app.reportBinningFcnLabel.Text = {'Função'; 'estatística:'};

            % Create reportBinningFcn
            app.reportBinningFcn = uidropdown(app.reportBinningGrid);
            app.reportBinningFcn.Items = {'min', 'mean-linear', 'median-linear', 'rms-linear', 'max'};
            app.reportBinningFcn.ValueChangedFcn = createCallbackFcn(app, @Config_ProjectParameterValueChanged, true);
            app.reportBinningFcn.FontSize = 11;
            app.reportBinningFcn.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.reportBinningFcn.BackgroundColor = [1 1 1];
            app.reportBinningFcn.Layout.Row = 2;
            app.reportBinningFcn.Layout.Column = 2;
            app.reportBinningFcn.Value = 'mean-linear';

            % Create prjFileCompressionModeLabel
            app.prjFileCompressionModeLabel = uilabel(app.reportGrid);
            app.prjFileCompressionModeLabel.WordWrap = 'on';
            app.prjFileCompressionModeLabel.FontSize = 11;
            app.prjFileCompressionModeLabel.Layout.Row = 5;
            app.prjFileCompressionModeLabel.Layout.Column = 1;
            app.prjFileCompressionModeLabel.Text = 'Compressão aplicada ao arquivo de saída do projeto?';

            % Create prjFileCompressionMode
            app.prjFileCompressionMode = uidropdown(app.reportGrid);
            app.prjFileCompressionMode.Items = {'Não', 'Sim'};
            app.prjFileCompressionMode.FontSize = 11;
            app.prjFileCompressionMode.BackgroundColor = [1 1 1];
            app.prjFileCompressionMode.Layout.Row = 5;
            app.prjFileCompressionMode.Layout.Column = 2;
            app.prjFileCompressionMode.Value = 'Não';

            % Create SubTab5
            app.SubTab5 = uitab(app.SubTabGroup);
            app.SubTab5.AutoResizeChildren = 'off';
            app.SubTab5.Title = 'MAPEAMENTO DE PASTAS';
            app.SubTab5.BackgroundColor = 'none';

            % Create SubGrid5
            app.SubGrid5 = uigridlayout(app.SubTab5);
            app.SubGrid5.ColumnWidth = {'1x', 20};
            app.SubGrid5.RowHeight = {17, 22, 22, 22, '1x'};
            app.SubGrid5.ColumnSpacing = 5;
            app.SubGrid5.RowSpacing = 5;
            app.SubGrid5.BackgroundColor = [1 1 1];

            % Create DATAHUBPOSTLabel
            app.DATAHUBPOSTLabel = uilabel(app.SubGrid5);
            app.DATAHUBPOSTLabel.VerticalAlignment = 'bottom';
            app.DATAHUBPOSTLabel.FontSize = 10;
            app.DATAHUBPOSTLabel.Layout.Row = 1;
            app.DATAHUBPOSTLabel.Layout.Column = 1;
            app.DATAHUBPOSTLabel.Text = 'DATAHUB - POST:';

            % Create DataHubPOST
            app.DataHubPOST = uieditfield(app.SubGrid5, 'text');
            app.DataHubPOST.Editable = 'off';
            app.DataHubPOST.FontSize = 11;
            app.DataHubPOST.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.DataHubPOST.Layout.Row = 2;
            app.DataHubPOST.Layout.Column = 1;

            % Create DataHubPOSTButton
            app.DataHubPOSTButton = uiimage(app.SubGrid5);
            app.DataHubPOSTButton.ScaleMethod = 'none';
            app.DataHubPOSTButton.ImageClickedFcn = createCallbackFcn(app, @Config_FolderButtonPushed, true);
            app.DataHubPOSTButton.Tag = 'DataHub_POST';
            app.DataHubPOSTButton.Enable = 'off';
            app.DataHubPOSTButton.Layout.Row = 2;
            app.DataHubPOSTButton.Layout.Column = 2;
            app.DataHubPOSTButton.ImageSource = 'folder-opened-16px.svg';

            % Create userPathLabel
            app.userPathLabel = uilabel(app.SubGrid5);
            app.userPathLabel.VerticalAlignment = 'bottom';
            app.userPathLabel.FontSize = 10;
            app.userPathLabel.Layout.Row = 3;
            app.userPathLabel.Layout.Column = 1;
            app.userPathLabel.Text = 'PASTA DO USUÁRIO:';

            % Create userPath
            app.userPath = uieditfield(app.SubGrid5, 'text');
            app.userPath.Editable = 'off';
            app.userPath.FontSize = 11;
            app.userPath.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.userPath.Layout.Row = 4;
            app.userPath.Layout.Column = 1;

            % Create userPathButton
            app.userPathButton = uiimage(app.SubGrid5);
            app.userPathButton.ScaleMethod = 'none';
            app.userPathButton.ImageClickedFcn = createCallbackFcn(app, @Config_FolderButtonPushed, true);
            app.userPathButton.Tag = 'userPath';
            app.userPathButton.Enable = 'off';
            app.userPathButton.Layout.Row = 4;
            app.userPathButton.Layout.Column = 2;
            app.userPathButton.ImageSource = 'folder-opened-16px.svg';

            % Create DockModule
            app.DockModule = uigridlayout(app.GridLayout);
            app.DockModule.RowHeight = {'1x'};
            app.DockModule.ColumnSpacing = 2;
            app.DockModule.Padding = [5 2 5 2];
            app.DockModule.Visible = 'off';
            app.DockModule.Layout.Row = [2 3];
            app.DockModule.Layout.Column = [3 4];
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
