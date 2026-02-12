classdef winMonitorRNI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        NavBar                   matlab.ui.container.GridLayout
        AppInfo                  matlab.ui.control.Image
        FigurePosition           matlab.ui.control.Image
        DataHubLamp              matlab.ui.control.Image
        jsBackDoor               matlab.ui.control.HTML
        Tab5Button               matlab.ui.control.StateButton
        Tab4Button               matlab.ui.control.StateButton
        ButtonsSeparator2        matlab.ui.control.Image
        Tab3Button               matlab.ui.control.StateButton
        Tab2Button               matlab.ui.control.StateButton
        ButtonsSeparator1        matlab.ui.control.Image
        Tab1Button               matlab.ui.control.StateButton
        AppName                  matlab.ui.control.Label
        AppIcon                  matlab.ui.control.Image
        TabGroup                 matlab.ui.container.TabGroup
        Tab1_File                matlab.ui.container.Tab
        file_Grid                matlab.ui.container.GridLayout
        FileMetadata             matlab.ui.control.Label
        FileTree                 matlab.ui.container.Tree
        SubTabGroup              matlab.ui.container.TabGroup
        SubTab1                  matlab.ui.container.Tab
        SubGrid1                 matlab.ui.container.GridLayout
        file_FileSortMethodIcon  matlab.ui.control.Image
        file_FileSortMethod      matlab.ui.control.DropDown
        file_ModuleIntro         matlab.ui.control.Label
        file_toolGrid            matlab.ui.container.GridLayout
        tool_MergeFiles          matlab.ui.control.Image
        tool_Separator           matlab.ui.control.Image
        tool_ReadFiles           matlab.ui.control.Image
        Tab2_MonitoringPlan      matlab.ui.container.Tab
        Tab3_ExternalRequest     matlab.ui.container.Tab
        Tab4_RFDataHub           matlab.ui.container.Tab
        Tab5_Config              matlab.ui.container.Tab
        ContextMenu              matlab.ui.container.ContextMenu
        contextmenu_merge        matlab.ui.container.Menu
        contextmenu_del          matlab.ui.container.Menu
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'mainApp'
        Context = 'FILE'
    end


    properties (Access = public)
        %-----------------------------------------------------------------%
        General
        General_I

        rootFolder
        tabGroupController
        renderCount = 0

        executionMode
        progressDialog
        popupContainer

        eFiscalizaObj

        projectData
        measData  = model.EMFieldData.empty

        rfDataHub
        rfDataHubLOG
        rfDataHubSummary
        rfDataHubAnnotation = table( ...
            string.empty, ...
            int32([]), ...
            struct('Latitude', {}, 'Longitude', {}, 'AntennaHeight', {}), ...
            'VariableNames', {'ID', 'Station', 'TXSite'} ...
        )
    end


    methods (Access = public)
        %-----------------------------------------------------------------%
        % COMUNICAÇÃO ENTRE PROCESSOS:
        % • ipcMainJSEventsHandler
        %   Eventos recebidos do objeto app.jsBackDoor por meio de chamada 
        %   ao método "sendEventToMATLAB" do objeto "htmlComponent" (no JS).
        %
        % • ipcMainMatlabCallsHandler
        %   Eventos recebidos dos apps secundários.
        %
        % • ipcMainMatlabCallAuxiliarApp
        %   Reencaminha eventos recebidos aos apps secundários, viabilizando
        %   comunicação entre apps secundários e, também, redirecionando os 
        %   eventos JS quando o app secundário é executado em modo DOCK (e, 
        %   por essa razão, usa o "jsBackDoor" do app principal).
        %
        % • ipcMainMatlabOpenPopupApp
        %   Abre um app secundário como popup, no mainApp.
        %-----------------------------------------------------------------%
        function ipcMainJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    % MATLAB-JS BRIDGE (matlabJSBridge.js)
                    case 'renderer'
                        MFilePath   = fileparts(mfilename('fullpath'));
                        parpoolFlag = false;

                        if ~app.renderCount
                            appEngine.activate(app, app.Role, MFilePath, parpoolFlag)
                        else
                            selectedNodes = app.FileTree.SelectedNodes;
                            if ~isempty(app.FileTree.SelectedNodes)
                                app.FileTree.SelectedNodes = [];
                                onTreeSelectionChanged(app)
                            end

                            appEngine.beforeReload(app, app.Role)
                            appEngine.activate(app, app.Role, MFilePath, parpoolFlag)

                            if ~isempty(selectedNodes)
                                app.FileTree.SelectedNodes = selectedNodes;
                                onTreeSelectionChanged(app)
                            end
                        end
                        
                        app.renderCount = app.renderCount+1;

                    case 'unload'
                        closeFcn(app)

                    case 'customForm'
                        switch event.HTMLEventData.uuid
                            case {'onFetchIssueDetails', 'onReportGenerate', 'onUploadArtifacts'}
                                eventName = event.HTMLEventData.uuid;
                                context = event.HTMLEventData.context;

                                varargin = {};
                                if isfield(event.HTMLEventData, 'varargin')
                                    varargin = event.HTMLEventData.varargin;
                                    if ~iscell(varargin)
                                        varargin = {varargin};
                                    end
                                end

                                reportHandleOperation(app, eventName, context, event.HTMLEventData, varargin{:})

                            case 'openDevTools'
                                if isequal(app.General.operationMode.DevTools, rmfield(event.HTMLEventData, 'uuid'))
                                    webWin = struct(struct(struct(app.UIFigure).Controller).PlatformHost).CEF;
                                    webWin.openDevTools();
                                end
                        end

                    case 'getNavigatorBasicInformation'
                        app.General.AppVersion.browser = event.HTMLEventData;

                    % MAINAPP
                    case 'mainApp.FileTree'
                        ContextMenu_DeleteSelectedTreeNode(app)

                    % AUXAPP.WINEXTERNALREQUEST
                    case 'auxApp.winExternalRequest.TreePoints'
                        ipcMainMatlabCallAuxiliarApp(app, 'EXTERNALREQUEST', 'JS', event)

                    otherwise
                        error('winMonitorRNI:UnexpectedEvent', 'Unexpected event "%s"', event.HTMLEventName)
                end
                drawnow

            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME));
            end
        end

        %-----------------------------------------------------------------%
        function varargout = ipcMainMatlabCallsHandler(app, callingApp, eventName, varargin)
            varargout = {};

            try
                switch eventName
                    case 'closeFcn'
                        auxAppTag    = varargin{1};
                        closeModule(app.tabGroupController, auxAppTag, app.General, 'normal')

                    case 'dockButtonPushed'
                        auxAppTag    = varargin{1};
                        varargout{1} = {app};

                    otherwise
                        switch class(callingApp)
                            % auxApp.winConfig (CONFIG)
                            case {'auxApp.winConfig', 'auxApp.winConfig_exported'}
                                switch eventName
                                    case 'checkDataHubLampStatus'
                                        updateWarningLampVisibility(app)
        
                                    case 'openDevTools'
                                        dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                                        dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');
                                        sendEventToHTMLSource(app.jsBackDoor, 'customForm', struct('UUID', 'openDevTools', 'Fields', dialogBox))
        
                                    case 'onSimulationMode'
                                        if app.General.operationMode.Simulation
                                            Toolbar_SelectFileToReadtool_ReadFilesClicked(app)
        
                                            % Muda programaticamente o modo p/ ARQUIVOS.
                                            app.Tab1Button.Value = true;                    
                                            onTabNavigatorButtonPushed(app, struct('Source', app.Tab1Button, 'PreviousValue', false))
                                        end
        
                                    case 'onRFDataHubUpdate'
                                        initializeRFDataHub(app)
                                        ipcMainMatlabCallAuxiliarApp(app, 'RFDATAHUB', 'MATLAB', eventName)
        
                                    case 'onFileSortMethodChanged'
                                        if ~strcmp(app.file_FileSortMethod.Value, app.General.context.FILE.sortMethod)
                                            app.file_FileSortMethod.Value = app.General.context.FILE.sortMethod;
                                            onFileSortMethodValueChanged(app)
                                        end
        
                                    case {'onAnalysisParameterChanged', ...
                                          'onAxesParameterChanged', ...
                                          'onPlotParameterChanged'}
                                        context = varargin{1};
                                        ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', eventName)
        
                                    otherwise
                                        error('winMonitorRNI:UnexpectedCall', 'Unexpected call "%s"', eventName)
                                end

                            case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported', ...
                                  'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported'}
                                switch eventName
                                    case 'onReportGenerate'
                                        context = varargin{1};
                                        indexes = varargin{2};
                                        reportGenerate(app, context, [], indexes)

                                    case 'onUploadArtifacts'
                                        context = varargin{1};
                                        reportUploadArtifacts(app, context, [], 'uploadDocument')
                                end


                            % DOCKS:OTHERS
                            case {'auxApp.dockListOfLocation', 'auxApp.dockListOfLocation_exported', ...
                                  'auxApp.dockReportLib',      'auxApp.dockReportLib_exported',      ...
                                  'auxApp.dockStationInfo',    'auxApp.dockStationInfo_exported'}
                                switch eventName
                                    case 'closeFcnCallFromPopupApp'
                                        context = varargin{1};
                                        moduleTag = varargin{2};
        
                                        switch context
                                            case {app.Role, app.Context}
                                                hApp = app;
                                                app.popupContainer.Parent.Visible = 0;
                                            otherwise
                                                hApp = getAppHandle(app.tabGroupController, context);
                                                ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', eventName)
                                        end
                                        
                                        if ~isempty(hApp)
                                            deleteContextMenu(app.tabGroupController, hApp.UIFigure, moduleTag)
                                        end

                                    case {'onLocationListModeChanged', ...
                                          'onStationCoordinatesEdited', ...
                                          'onStationInfoChanged', ...
                                          'onStationSelectionChanged'}
                                        context = varargin{1};
                                        varargin = [{eventName}, varargin(2:end)];
                                        ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', varargin{:})

                                    % auxApp.dockReportLib
                                    case {'onProjectRestart', 'onProjectLoad', 'onFinalReportFileChanged'}
                                        context  = varargin{1};
                                        varargin = [{eventName}, varargin(2:end)];
                                        ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', varargin{:})
                                        
                                    case 'onUpdateLastVisitedFolder'
                                        filePath = varargin{1};
                                        updateLastVisitedFolder(app, filePath)

                                    case 'onFetchIssueDetails'
                                        context  = varargin{1};
                                        reportFetchIssueDetails(app, context, [])

                                    otherwise
                                        error('winMonitorRNI:UnexpectedCall', 'Unexpected call "%s"', eventName)
                                end
            
                            otherwise
                                error('winMonitorRNI:UnexpectedCaller', 'Unexpected caller "%s"', class(callingApp))
                        end
                end

            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);            
            end

            % Caso um app auxiliar esteja em modo DOCK, o progressDialog do
            % app auxiliar coincide com o do appAnalise. Força-se, portanto, 
            % a condição abaixo para evitar possível bloqueio da tela.
            app.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function ipcMainMatlabCallAuxiliarApp(app, auxAppName, communicationType, varargin)
            hAuxApp = getAppHandle(app.tabGroupController, auxAppName);

            if ~isempty(hAuxApp)
                switch communicationType
                    case 'MATLAB'
                        operationType = varargin{1};
                        ipcSecondaryMatlabCallsHandler(hAuxApp, app, operationType, varargin{2:end});
                    case 'JS'
                        event = varargin{1};
                        ipcSecondaryJSEventsHandler(hAuxApp, event)
                end
            end
        end

        %-----------------------------------------------------------------%
        function ipcMainMatlabOpenPopupApp(app, callingApp, auxAppName, varargin)
            arguments
                app
                callingApp
                auxAppName char {mustBeMember(auxAppName, {'ReportLib', 'ListOfLocation', 'StationInfo'})}
            end

            arguments (Repeating)
                varargin 
            end

            switch auxAppName
                case 'ReportLib'
                    screenWidth  = 460;
                    screenHeight = 602;
                case 'ListOfLocation'
                    screenWidth  = 540;
                    screenHeight = 440;
                case 'StationInfo'
                    screenWidth  = 540;
                    screenHeight = 440;
            end

            requestVisibilityChange(callingApp.progressDialog, 'visible', 'unlocked')
            ui.PopUpContainer(callingApp, class.Constants.appName, screenWidth, screenHeight)

            % Executa o app auxiliar.
            inputArguments = [{app, callingApp}, varargin];
            auxDockAppName = sprintf('auxApp.dock%s', auxAppName);
            
            if app.General.operationMode.Debug
                eval(sprintf('auxApp.dock%s(inputArguments{:})', auxAppName))
            else
                eval([auxDockAppName '_exported(callingApp.popupContainer, inputArguments{:})'])
                
                callingApp.popupContainer.UserData.auxDockAppName = auxDockAppName;
                callingApp.popupContainer.Parent.Visible = 1;
            end

            requestVisibilityChange(callingApp.progressDialog, 'hidden', 'unlocked')
        end
    end

    
    methods (Access = public)
        %-----------------------------------------------------------------%
        function navigateToTab(app, clickedButton)
            onTabNavigatorButtonPushed(app, struct('Source', clickedButton, 'PreviousValue', false))
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
                        app.Tab1Button;
                        app.Tab2Button;
                        app.Tab3Button;
                        app.Tab4Button;
                        app.Tab5Button;
                        app.FileTree;
                        app.FileMetadata;
                        app.tool_ReadFiles;
                        app.tool_MergeFiles
                    };                            
                    ui.CustomizationBase.getElementsDataTag(elToModify);

                    try
                        ui.TextView.startup(app.jsBackDoor, app.FileMetadata, appName);
                    catch
                    end

                    try
                        sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                            struct('appName', appName, 'dataTag', app.tool_ReadFiles.UserData.id,  'tooltip', struct('defaultPosition', 'top', 'textContent', 'Seleciona arquivos')), ...
                            struct('appName', appName, 'dataTag', app.tool_MergeFiles.UserData.id, 'tooltip', struct('defaultPosition', 'top', 'textContent', 'Mescla localidade de agrupamento')), ...
                            struct('appName', appName, 'dataTag', app.Tab1Button.UserData.id, 'generation', 1, 'class', 'tab-navigator-button'), ...
                            struct('appName', appName, 'dataTag', app.Tab2Button.UserData.id, 'generation', 1, 'class', 'tab-navigator-button'), ...
                            struct('appName', appName, 'dataTag', app.Tab3Button.UserData.id, 'generation', 1, 'class', 'tab-navigator-button'), ...
                            struct('appName', appName, 'dataTag', app.Tab4Button.UserData.id, 'generation', 1, 'class', 'tab-navigator-button'), ...
                            struct('appName', appName, 'dataTag', app.Tab5Button.UserData.id, 'generation', 1, 'class', 'tab-navigator-button'), ...
                            struct('appName', appName, 'dataTag', app.FileTree.UserData.id, 'listener', struct('componentName', 'mainApp.FileTree', 'keyEvents', {{'Delete', 'Backspace'}})) ...
                        });
                    catch
                    end

                otherwise
                    % Previsto pensando em evolução, caso adicionado uitab
                    % ao app.SubTabGrid...
            end
        end

        %-----------------------------------------------------------------%
        function loadConfigurationFile(app, appName, MFilePath)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appEngine.util.generalSettingsLoad(appName, app.rootFolder);
            if ~isempty(msgWarning)
                ui.Dialog(app.UIFigure, 'error', msgWarning);
            end

            % Para criação de arquivos temporários, cria-se uma pasta da 
            % sessão.
            tempDir = tempname;
            mkdir(tempDir)
            app.General_I.fileFolder.tempPath  = tempDir;
            app.General_I.fileFolder.MFilePath = MFilePath;

            switch app.executionMode
                case 'webApp'
                    % Força a exclusão do SplashScreen do MATLAB Web Server.
                    sendEventToHTMLSource(app.jsBackDoor, "delProgressDialog");

                    app.General_I.operationMode.Debug = false;
                    app.General_I.operationMode.Dock  = true;
                    
                    % A pasta do usuário não é configurável, mas obtida por 
                    % meio de chamada a uiputfile. 
                    app.General_I.fileFolder.userPath = tempDir;

                    % A renderização do plot no MATLAB WebServer, enviando-o à uma 
                    % sessão do webapp como imagem Base64, é crítica por depender 
                    % das comunicações WebServer-webapp e WebServer-BaseMapServer. 
                    % Ao configurar o Basemap como "none", entretanto, elimina-se a 
                    % necessidade de comunicação com BaseMapServer, além de tornar 
                    % mais eficiente a comunicação com webapp porque as imagens
                    % Base64 são menores (uma imagem com Basemap "sattelite" pode 
                    % ter 500 kB, enquanto uma imagem sem Basemap pode ter 25 kB).
                    app.General_I.plot.geographicAxes.basemap = 'none';
                    app.General_I.reportLib.basemap           = 'none';

                otherwise    
                    % Resgata a pasta de trabalho do usuário (configurável).
                    userPaths = appEngine.util.UserPaths(app.General_I.fileFolder.userPath);
                    app.General_I.fileFolder.userPath = userPaths{end};

                    switch app.executionMode
                        case 'desktopStandaloneApp'
                            app.General_I.operationMode.Debug = false;
                        case 'MATLABEnvironment'
                            app.General_I.operationMode.Debug = true;
                    end
            end

            % "RFDataHub.mat"
            global RFDataHub
            global RFDataHub_info
        
            if isempty(RFDataHub) || isempty(RFDataHub_info)
                model.RFDataHub.read(appName, app.rootFolder, tempDir)
            end

            app.General            = app.General_I;
            app.General.AppVersion = util.getAppVersion(app.rootFolder, MFilePath, tempDir);
            sendEventToHTMLSource(app.jsBackDoor, 'getNavigatorBasicInformation')
        end

        %-----------------------------------------------------------------%
        function initializeAppProperties(app)
            initializeRFDataHub(app)
            app.projectData = model.Project(app, app.rootFolder, app.General);
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            app.tabGroupController = ui.TabNavigator(app.NavBar, app.TabGroup, app.progressDialog);
            addComponent(app.tabGroupController, "Built-in", "",                          app.Tab1Button, "AlwaysOn", struct('On', '', 'Off', ''), matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winMonitoringPlan",  app.Tab2Button, "AlwaysOn", struct('On', '', 'Off', ''), app.Tab1Button,                      2)
            addComponent(app.tabGroupController, "External", "auxApp.winExternalRequest", app.Tab3Button, "AlwaysOn", struct('On', '', 'Off', ''), app.Tab1Button,                      3)
            addComponent(app.tabGroupController, "External", "auxApp.winRFDataHub",       app.Tab4Button, "AlwaysOn", struct('On', '', 'Off', ''), app.Tab1Button,                      4)
            addComponent(app.tabGroupController, "External", "auxApp.winConfig",          app.Tab5Button, "AlwaysOn", struct('On', '', 'Off', ''), app.Tab1Button,                      5)
            app.tabGroupController.inlineSVG = true;

            addStyle(app.FileTree, uistyle('Interpreter', 'html'))
        end


        %-----------------------------------------------------------------%
        function applyInitialLayout(app)
            updateWarningLampVisibility(app)
            app.file_FileSortMethod.Value = app.General.context.FILE.sortMethod;
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function initializeRFDataHub(app)
            global RFDataHub
            global RFDataHubLog

            app.rfDataHub        = RFDataHub;
            app.rfDataHubLOG     = RFDataHubLog;
            app.rfDataHubSummary = summary(RFDataHub(:, {'Source', 'State'}));

            % A coluna "Source" possui agrupamentos da fonte dos dados,
            % decorrente da mesclagem de estações.
            tempSourceList = cellfun(@(x) strsplit(x, ' | '), app.rfDataHubSummary.Source.Categories, 'UniformOutput', false);
            app.rfDataHubSummary.Source.RawCategories = unique(horzcat(tempSourceList{:}))';
        end

        %-----------------------------------------------------------------%
        function refreshProjectFiles(app, indexes, updateType)
            arguments
                app
                indexes
                updateType char {mustBeMember(updateType, {'onFileListAdded', ...
                                                           'onFileListRemoved', ...
                                                           'onFileListUnmerged', ...
                                                           'onFileListMerged'})}
            end

            buildFileTree(app, indexes)

            if ismember(updateType, {'onFileListAdded', 'onFileListRemoved'})
                updateAnalysis(app.projectData, app.measData, app.General, updateType);
            end
            
            ipcMainMatlabCallAuxiliarApp(app, 'MONITORINGPLAN',  'MATLAB', updateType)
            ipcMainMatlabCallAuxiliarApp(app, 'EXTERNALREQUEST', 'MATLAB', updateType)
        end
        
        %-----------------------------------------------------------------%
        function buildFileTree(app, selectedNodeData)
            arguments
                app
                selectedNodeData = []
            end

            if ~isempty(app.FileTree.Children)
                app.FileMetadata.UserData = [];
                delete(app.FileTree.Children)
            end

            selectedNode = [];

            switch app.file_FileSortMethod.Value
                case 'ARQUIVO'
                    for ii = 1:numel(app.measData)
                        treeNode = createFileTreeNodes(app, ii, app.FileTree, 'FILE');

                        if ismember(ii, selectedNodeData)
                            selectedNode = [selectedNode, treeNode];
                        end
                    end

                case 'LOCALIDADE'
                    locationList = {app.measData.Location};
                    locations    = unique(locationList);

                    for ii = 1:numel(locations)
                        location = locations{ii};
                        locationIndexes  = find(strcmp(locationList, location));
                        [~, idSort]      = sort(arrayfun(@(x) x.Data.Timestamp(1), app.measData(locationIndexes)));
                        locationIndexes  = locationIndexes(idSort);

                        locationTreeNode = uitreenode(app.FileTree, 'Text', location, ...
                                                                     'NodeData', locationIndexes, ...
                                                                     'ContextMenu', app.ContextMenu);

                        for jj = locationIndexes
                            treeNode = createFileTreeNodes(app, jj, locationTreeNode, 'LOCATION');
    
                            if ismember(jj, selectedNodeData)
                                selectedNode = [selectedNode, treeNode];
                            end
                        end
                    end
            end

            expand(app.FileTree, 'all')

            if ~isempty(app.measData)
                if ~isempty(selectedNode)
                    app.FileTree.SelectedNodes = selectedNode;
                else
                    if isempty(app.FileTree.Children(1).Children)
                        app.FileTree.SelectedNodes = app.FileTree.Children(1);
                    else
                        app.FileTree.SelectedNodes = app.FileTree.Children(1).Children(1);
                    end
                end
            end

            onTreeSelectionChanged(app)
        end

        %-----------------------------------------------------------------%
        function treeNode = createFileTreeNodes(app, index, treeNodeParent, treeNodePreffixType)
            arguments
                app
                index
                treeNodeParent
                treeNodePreffixType char {mustBeMember(treeNodePreffixType, {'FILE', 'LOCATION'})}
            end

            currentMeasData = app.measData(index);
            
            switch treeNodePreffixType
                case 'FILE'
                    treeNodePreffix = currentMeasData.FileName;
                case 'LOCATION'
                    treeNodePreffix = currentMeasData.ObservationTime;
            end
            
            [taskBegin, taskEnd] = bounds(currentMeasData.Data.Timestamp);
            
            mergeStatusIcon = '';
            if ~strcmp(currentMeasData.Location, currentMeasData.Location_I)
                mergeStatusIcon = '  ➕';
            end

            treeText = sprintf('%s  - ⌛%s  -  📐%s%s', treeNodePreffix, string(taskEnd-taskBegin), sprintf('[%.1f - %.1f] V/m', currentMeasData.FieldValueLimits(:)), mergeStatusIcon);
            treeNode = uitreenode(treeNodeParent, 'Text', treeText, ...
                                                  'NodeData', index, ...
                                                  'ContextMenu', app.ContextMenu);
        end

        %-----------------------------------------------------------------%
        function indexes = getSelectedEMFieldDataIndexes(app)
            indexes = [];
            if ~isempty(app.FileTree.SelectedNodes)
                indexes = unique([app.FileTree.SelectedNodes.NodeData]);
            end
        end

        %-----------------------------------------------------------------%
        % MISCELÂNEAS
        %-----------------------------------------------------------------%
        function updateWarningLampVisibility(app)
            app.DataHubLamp.Visible = ~isfolder(app.General.fileFolder.DataHub_POST);
        end

        %-----------------------------------------------------------------%
        function updateToolbar(app)
            indexes = getSelectedEMFieldDataIndexes(app);

            nonEmptySelection = ~isempty(indexes);
            nonScalarSelection = ~isscalar(indexes);

            locationMergedStatus = false;
            if ~isempty(indexes)
                locationMergedStatus = any(arrayfun(@(x) ~strcmp(x.Location, x.Location_I), app.measData(indexes)));
            end

            app.tool_MergeFiles.Enable   = nonEmptySelection && (nonScalarSelection || locationMergedStatus);
            app.contextmenu_merge.Enable = app.tool_MergeFiles.Enable;
            app.contextmenu_del.Enable   = nonEmptySelection;
        end

        %-----------------------------------------------------------------%
        function updateLastVisitedFolder(app, filePath)
            app.General_I.fileFolder.lastVisited = filePath;
            app.General.fileFolder.lastVisited   = filePath;

            appEngine.util.generalSettingsSave(class.Constants.appName, app.rootFolder, app.General_I, app.executionMode)
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % SISTEMA DE GESTÃO DA FISCALIZAÇÃO (eFiscaliza/SEI)
        %-----------------------------------------------------------------%
        function createEFiscalizaObject(app, credentials)
            if ~isempty(credentials)
                app.eFiscalizaObj = ws.eFiscaliza(credentials.login, credentials.password);
            end
        end

        %-----------------------------------------------------------------%
        function reportDispatchOperation(app, eventName, varargin)
            arguments
                app
                eventName {mustBeMember(eventName, {'onReportGenerate', 'onUploadArtifacts'})}
            end

            arguments (Repeating)
                varargin
            end

            if isempty(app.eFiscalizaObj) || ~isvalid(app.eFiscalizaObj)
                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');

                customFormData = struct('UUID', eventName, 'Fields', dialogBox, 'Context', app.Context);
                if ~isempty(varargin)
                    customFormData.Varargin = varargin;
                end

                sendEventToHTMLSource(app.jsBackDoor, 'customForm', customFormData)

            else
                reportHandleOperation(app, eventName, app.Context, [], varargin{:})
            end
        end

        %-----------------------------------------------------------------%
        function reportHandleOperation(app, eventName, context, credentials, varargin)
            arguments
                app
                eventName {mustBeMember(eventName, {'onFetchIssueDetails', 'onReportGenerate', 'onUploadArtifacts'})}
                context {mustBeMember(context, {'MONITORINGPLAN', 'EXTERNALREQUEST'})}
                credentials
            end

            arguments (Repeating)
                varargin
            end

            switch eventName
                case 'onFetchIssueDetails'
                    reportFetchIssueDetails(app, context, credentials)

                case 'onReportGenerate'
                    indexes = varargin{1};
                    reportGenerate(app, context, credentials, indexes);
        
                case 'onUploadArtifacts'
                    reportUploadArtifacts(app, context, credentials, 'uploadDocument');
            end
        end

        %-----------------------------------------------------------------%
        function reportFetchIssueDetails(app, context, credentials)
            callingApp = getAppHandle(app.tabGroupController, context);
            if isempty(callingApp)
                callingApp = app;
            end

            callingApp.progressDialog.Visible = 'visible';

            createEFiscalizaObject(app, credentials)
            system = app.projectData.modules.(context).ui.system;
            issue  = app.projectData.modules.(context).ui.issue;
            [details, msgError] = getOrFetchIssueDetails(app.projectData, system, issue, app.eFiscalizaObj);

            if app ~= callingApp
                ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', 'onFetchIssueDetails', system, issue, details, msgError)

            else
                if isempty(msgError)
                    msg = util.HtmlTextGenerator.issueDetails(system, issue, details);
                    icon = 'info';
                else
                    app.eFiscalizaObj = [];
                    msg = msgError;
                    icon = 'error';
                end
                ui.Dialog(app.UIFigure, icon, msg);
            end

            callingApp.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function reportGenerate(app, context, credentials, indexes)
            callingApp = getAppHandle(app.tabGroupController, context);
            if isempty(callingApp)
                callingApp = app;
            end

            callingApp.progressDialog.Visible = 'visible';

            createEFiscalizaObject(app, credentials)
            try
                reportLibConnection.Controller.Run(app, callingApp, context, app.measData(indexes))
                if app == callingApp
                    updateToolbar(app)
                else
                    ipcMainMatlabCallAuxiliarApp(app, context, 'MATLAB', 'onReportGenerate')
                end

            catch ME
                app.eFiscalizaObj = [];
                ui.Dialog(callingApp.UIFigure, 'error', getReport(ME));
            end

            callingApp.progressDialog.Visible = 'hidden';
        end

        %-----------------------------------------------------------------%
        function reportUploadArtifacts(app, context, credentials, operation)
            callingApp = getAppHandle(app.tabGroupController, context);
            if isempty(callingApp)
                callingApp = app;
            end

            callingApp.progressDialog.Visible = 'visible';

            createEFiscalizaObject(app, credentials)
            [status1, icon1, msg1] = reportUploadToSEI(app, context, operation);
            ui.Dialog(callingApp.UIFigure, icon1, msg1);

            callingApp.progressDialog.Visible = 'hidden';
            
            if status1 && strcmp(app.projectData.modules.(context).ui.system, 'eFiscaliza')
                [status2, msg2] = reportUploadFilesToSharepoint(app, context);

                if ~status2
                    ui.Dialog(callingApp.UIFigure, 'error', msg2);
                end
            end
        end

        %-------------------------------------------------------------------------%
        function [status, icon, msg] = reportUploadToSEI(app, context, operation)
            try
                env = strsplit(app.projectData.modules.(context).ui.system);
                if isscalar(env)
                    env = 'PD';
                else
                    env = env{2};
                end

                system = app.projectData.modules.(context).ui.system;
                unit = app.projectData.modules.(context).ui.unit;
                issue = app.projectData.modules.(context).ui.issue;
                issueInfo = struct( ...
                    'type', 'ATIVIDADE DE INSPEÇÃO', ...
                    'id', issue ...
                );

                switch operation
                    case 'uploadDocument'
                        HTMLFile = getGeneratedDocumentFileName(app.projectData, '.html', context);

                        [~, modelIdx]   = ismember(app.projectData.modules.(context).ui.reportModel, {app.projectData.report.templates.Name});
                        docType         = app.projectData.report.templates(modelIdx).DocumentType;
                        [~, docTypeIdx] = ismember(docType, {app.General.eFiscaliza.internal.typeIdMapping.type});

                        docSpec = app.General.eFiscaliza;
                        docSpec.originId = docSpec.internal.originId;
                        docSpec.typeId = app.General.eFiscaliza.internal.typeIdMapping(docTypeIdx).id;

                        response = run(app.eFiscalizaObj, env, operation, issueInfo, unit, docSpec, HTMLFile);

                    otherwise
                        error('Unexpected call')
                end

                if ~contains(response, 'Documento cadastrado no SEI', 'IgnoreCase', true)
                    error(response)
                end

                updateUploadedFiles(app.projectData, context, system, issue, response)

                status = true;
                icon   = 'success';
                msg    = response;

            catch ME
                app.eFiscalizaObj = [];
                
                status = false;
                icon   = 'error';
                msg    = ME.message;
            end
        end

        %------------------------------------------------------------------------%
        function [status, msg] = reportUploadFilesToSharepoint(app, context)
            sharepointFileList = { ...
                getGeneratedDocumentFileName(app.projectData, '.teams',   context), ...
                getGeneratedDocumentFileName(app.projectData, '.json',    context), ...
                getGeneratedDocumentFileName(app.projectData, 'rawFiles', context)  ...
            };

            statusList = false(1, numel(sharepointFileList));
            msgList = {};
        
            for ii = 1:numel(sharepointFileList)
                [statusList(ii), msgWarning] = copyfile(sharepointFileList{ii}, app.General.fileFolder.DataHub_POST, 'f');
        
                if ~statusList(ii)
                    msgList{end+1} = msgWarning;
                end
            end
        
            status = all(statusList);
            msg = strjoin(msgList, '\n\n');
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            try
                appEngine.boot(app, app.Role)
            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end

        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            if strcmp(app.progressDialog.Visible, 'visible')
                app.progressDialog.Visible = 'hidden';
                return
            end

            % msgQuestion = '';
            % if checkIfUpdateNeeded(app.projectData, app.measData)
            %     msgQuestion = sprintf([ ...
            %         'O projeto "%s" foi modificado (nome, arquivo de saída, ' ...
            %         'lista de arquivos de entrada ou tabelas de anotação das ' ...
            %         'contas de resultado). Caso o aplicativo seja encerrado ' ...
            %         'agora, todas as alterações serão descartadas.\n\n' ...
            %         'Deseja realmente fechar o aplicativo?' ...
            %         ], app.projectData.name);
            % 
            % elseif ~strcmp(app.executionMode, 'webApp')
            %     msgQuestion = 'Deseja fechar o aplicativo?';
            % end
msgQuestion = 'Deseja fechar o aplicativo?';
            if ~isempty(msgQuestion)                
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 1, 2);
                if userSelection == "Não"
                    return
                end
            end

            % Aspectos gerais (comum em todos os apps):
            appEngine.beforeDeleteApp(app.progressDialog, app.General_I.fileFolder.tempPath, app.tabGroupController, app.executionMode)
            delete(app)
            
        end

        % Callback function: AppInfo, DataHubLamp, FigurePosition, 
        % ...and 5 other components
        function onTabNavigatorButtonPushed(app, event)

            switch event.Source
                case {app.Tab1Button, app.Tab2Button, app.Tab3Button, app.Tab4Button, app.Tab5Button}
                    openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, app)

                case app.DataHubLamp
                    msg = [ ...
                        'Pendente mapear a pasta POST do SharePoint, de modo a viabilizar:<br>' ...
                        '•&thinsp;Upload do relatório final para o SEI.' ...
                    ];
                    ui.Dialog(app.UIFigure, 'error', msg);

                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appEngine.util.setWindowPosition(app.UIFigure)
                    focus(findobj(app.NavBar.Children, 'Type', 'uistatebutton', 'Value', true))

                case app.AppInfo
                    appInfo = util.HtmlTextGenerator.AppInfo( ...
                        app.General, ...
                        app.rootFolder, ...
                        app.executionMode, ...
                        app.renderCount, ...
                        app.projectData, ...
                        "popup" ...
                    );
                    ui.Dialog(app.UIFigure, 'info', appInfo);
            end

        end

        % Selection changed function: FileTree
        function onTreeSelectionChanged(app, event)

            indexes = getSelectedEMFieldDataIndexes(app);

            if isempty(indexes)
                app.FileMetadata.Text     = '';
                app.FileMetadata.UserData = [];

            else
                if isequal(app.FileMetadata.UserData, indexes)
                    return
                end

                app.FileMetadata.Text     = util.HtmlTextGenerator.SelectedFile(app.measData(indexes));
                app.FileMetadata.UserData = indexes;
            end

            updateToolbar(app)
            
        end

        % Value changed function: file_FileSortMethod
        function onFileSortMethodValueChanged(app, event)
            
            indexes = getSelectedEMFieldDataIndexes(app);
            buildFileTree(app, indexes)

        end

        % Image clicked function: tool_ReadFiles
        function Toolbar_SelectFileToReadtool_ReadFilesClicked(app, event)

            d = [];
            fileFullName = {};

            if app.General.operationMode.Simulation
                app.General.operationMode.Simulation = false;
                
                [projectFolder, ...
                 programDataFolder] = appEngine.util.Path(class.Constants.appName, app.rootFolder);
                simulationFolders   = {programDataFolder, projectFolder};

                for ii = 1:numel(simulationFolders)
                    filePath    = fullfile(simulationFolders{ii}, 'Simulation');    
                    listOfFiles = dir(filePath);
                    fileName    = {listOfFiles.name};
                    fileName    = fileName(endsWith(lower(fileName), '.txt'));
                    
                    if ~isempty(fileName)
                        fileFullName = fullfile(filePath, fileName);
                        break
                    end
                end

                if isempty(fileFullName)
                    msgWarning = 'Nenhum arquivo de simulação foi identificado.';
                    ui.Dialog(app.UIFigure, "warning", msgWarning);
                    return
                end

            else
                switch app.General.context.FILE.input
                    case 'file'
                        [~, filePath, ~, fileName] = ui.Dialog( ...
                            app.UIFigure, ...
                            'uigetfile', ...
                            '', ...
                            {'*.txt;*.csv;*.mat', 'monitorRNI (*.txt,*.csv,*.mat)'}, ...
                            app.General.fileFolder.lastVisited, ...
                            {'MultiSelect', 'on'} ...
                        );
            
                        if isempty(fileName)
                            return
                        elseif ~iscell(fileName)
                            fileName = {fileName};
                        end
                        fileFullName = fullfile(filePath, fileName);
    
                    case 'folder'
                        filePath = uigetdir(app.General.fileFolder.lastVisited);
                        figure(app.UIFigure)
    
                        if isequal(filePath, 0)
                            return
                        end
    
                        d = ui.Dialog(app.UIFigure, "progressdlg", "Em andamento...");
                        [fileFullName, fileName] = util.getFilesFromFolder(filePath);
                end
                updateLastVisitedFolder(app, filePath)
            end

            if isempty(d)
                d = ui.Dialog(app.UIFigure, "progressdlg", "Em andamento...");
            end

            filesError = struct('File', {}, 'Error', {});

            for ii = 1:numel(fileFullName)
                d.Message = textFormatGUI.HTMLParagraph(sprintf('Em andamento a leitura do arquivo %d de %d:<br>• <b>%s</b>', ii, numel(fileFullName), fileName{ii}));

                [~, ~, fileExt] = fileparts(fileFullName{ii});
                switch fileExt
                    case '.mat'
                        [app.measData, msg] = load(app.projectData, app.measData, fileFullName{ii});
                    
                    otherwise % '.txt', '.csv' etc
                        [app.measData, msg] = addFiles(app.measData, fileFullName{ii});
                end

                if ~isempty(msg)
                    filesError(end+1) = struct('File', sprintf('"%s"', fileName{ii}), 'Error', msg);
                    continue
                end
            end

            % LOG
            if ~isempty(filesError)
                msgWarning = sprintf('Arquivos que apresentaram erro na leitura:\n%s\n\n', strjoin(strcat({'•&thinsp;<b>'}, {filesError.File}, {'</b>: <i>'}, {filesError.Error}), '</i>\n\n'));
                ui.Dialog(app.UIFigure, "error", msgWarning);
            end
            
            % Atualiza app.FileTree.
            if numel(fileFullName) > numel(filesError)
                indexes = getSelectedEMFieldDataIndexes(app);
                refreshProjectFiles(app, indexes, 'onFileListAdded')
            end

            delete(d)

        end

        % Callback function: contextmenu_merge, tool_MergeFiles
        function Toolbar_MergeFilesImageClicked(app, event)
            
            % O processo de "mesclagem" é apenas o controle da localidade
            % de agrupamento, não tendo impacto na análise, mas apenas na
            % visualização da informação no app (e no relatório).

            indexes = getSelectedEMFieldDataIndexes(app);

            locationMergedStatus = any(arrayfun(@(x) ~strcmp(x.Location, x.Location_I), app.measData(indexes)));
            if locationMergedStatus
                msgQuestion   = util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'MergedStatusOn');
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);

                if userSelection == "Não"
                    return
                end

                delLocationCache(app.projectData, app.measData, indexes)                
                for ii = indexes
                    app.measData(ii).Location = app.measData(ii).Location_I;
                end
                refreshProjectFiles(app, indexes, 'onFileListUnmerged')
            end

            if numel(indexes) >= 2
                locationList = unique({app.measData(indexes).Location});
                if isscalar(locationList)
                    ui.Dialog(app.UIFigure, 'info', util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'ScalarLocation'));
                    return
                elseif numel(locationList) > 3
                    ui.Dialog(app.UIFigure, 'info', util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'MoreThanThreeLocations'));
                    return
                end

                msgQuestion   = util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'FinalConfirmationBeforeEdition');
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, [locationList, {'Cancelar'}], numel(locationList)+1, numel(locationList)+1);

                if userSelection == "Cancelar"
                    return
                end

                for ii = indexes
                    app.measData(ii).Location = userSelection;
                end
                refreshProjectFiles(app, indexes, 'onFileListMerged')
            end

        end

        % Menu selected function: contextmenu_del
        function ContextMenu_DeleteSelectedTreeNode(app, event)
            
            if ~isempty(app.FileTree.SelectedNodes)
                app.progressDialog.Visible = 'visible';

                indexes = [app.FileTree.SelectedNodes.NodeData];
                app.measData(indexes) = [];
                refreshProjectFiles(app, [], 'onFileListRemoved')

                app.progressDialog.Visible = 'hidden';
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Color = [0.96078431372549 0.96078431372549 0.96078431372549];
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'monitorRNI';
            app.UIFigure.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'icon_48.png');
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {54, '1x'};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Layout.Row = [1 2];
            app.TabGroup.Layout.Column = 1;

            % Create Tab1_File
            app.Tab1_File = uitab(app.TabGroup);
            app.Tab1_File.AutoResizeChildren = 'off';
            app.Tab1_File.Title = 'FILE';

            % Create file_Grid
            app.file_Grid = uigridlayout(app.Tab1_File);
            app.file_Grid.ColumnWidth = {10, '1x', '1x', 10, '0.25x', 360, 10};
            app.file_Grid.RowHeight = {94, 10, '1x', 10, 34};
            app.file_Grid.ColumnSpacing = 0;
            app.file_Grid.RowSpacing = 0;
            app.file_Grid.Padding = [0 0 0 40];
            app.file_Grid.BackgroundColor = [1 1 1];

            % Create file_toolGrid
            app.file_toolGrid = uigridlayout(app.file_Grid);
            app.file_toolGrid.ColumnWidth = {22, 5, 22, '1x'};
            app.file_toolGrid.RowHeight = {4, 17, 2};
            app.file_toolGrid.ColumnSpacing = 5;
            app.file_toolGrid.RowSpacing = 0;
            app.file_toolGrid.Padding = [10 5 10 5];
            app.file_toolGrid.Layout.Row = 5;
            app.file_toolGrid.Layout.Column = [1 7];
            app.file_toolGrid.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];

            % Create tool_ReadFiles
            app.tool_ReadFiles = uiimage(app.file_toolGrid);
            app.tool_ReadFiles.ScaleMethod = 'none';
            app.tool_ReadFiles.ImageClickedFcn = createCallbackFcn(app, @Toolbar_SelectFileToReadtool_ReadFilesClicked, true);
            app.tool_ReadFiles.Layout.Row = [1 3];
            app.tool_ReadFiles.Layout.Column = 1;
            app.tool_ReadFiles.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Import_16.png');

            % Create tool_Separator
            app.tool_Separator = uiimage(app.file_toolGrid);
            app.tool_Separator.ScaleMethod = 'none';
            app.tool_Separator.Enable = 'off';
            app.tool_Separator.Layout.Row = [1 3];
            app.tool_Separator.Layout.Column = 2;
            app.tool_Separator.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV.svg');

            % Create tool_MergeFiles
            app.tool_MergeFiles = uiimage(app.file_toolGrid);
            app.tool_MergeFiles.ScaleMethod = 'none';
            app.tool_MergeFiles.ImageClickedFcn = createCallbackFcn(app, @Toolbar_MergeFilesImageClicked, true);
            app.tool_MergeFiles.Enable = 'off';
            app.tool_MergeFiles.Layout.Row = [1 3];
            app.tool_MergeFiles.Layout.Column = 3;
            app.tool_MergeFiles.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Merge_18.png');

            % Create SubTabGroup
            app.SubTabGroup = uitabgroup(app.file_Grid);
            app.SubTabGroup.AutoResizeChildren = 'off';
            app.SubTabGroup.Layout.Row = 1;
            app.SubTabGroup.Layout.Column = [2 6];

            % Create SubTab1
            app.SubTab1 = uitab(app.SubTabGroup);
            app.SubTab1.AutoResizeChildren = 'off';
            app.SubTab1.Title = 'ARQUIVOS';
            app.SubTab1.BackgroundColor = 'none';
            app.SubTab1.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];

            % Create SubGrid1
            app.SubGrid1 = uigridlayout(app.SubTab1);
            app.SubGrid1.ColumnWidth = {22, 150, '1x'};
            app.SubGrid1.RowHeight = {22, 22};
            app.SubGrid1.ColumnSpacing = 5;
            app.SubGrid1.RowSpacing = 5;
            app.SubGrid1.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create file_ModuleIntro
            app.file_ModuleIntro = uilabel(app.SubGrid1);
            app.file_ModuleIntro.VerticalAlignment = 'top';
            app.file_ModuleIntro.WordWrap = 'on';
            app.file_ModuleIntro.FontSize = 11;
            app.file_ModuleIntro.FontColor = [0.149 0.149 0.149];
            app.file_ModuleIntro.Layout.Row = 1;
            app.file_ModuleIntro.Layout.Column = [1 3];
            app.file_ModuleIntro.Text = 'Este aplicativo permite a leitura de arquivos gerados em medições de campo elétrico no âmbito do PM-RNI.';

            % Create file_FileSortMethod
            app.file_FileSortMethod = uidropdown(app.SubGrid1);
            app.file_FileSortMethod.Items = {'ARQUIVO', 'LOCALIDADE'};
            app.file_FileSortMethod.ValueChangedFcn = createCallbackFcn(app, @onFileSortMethodValueChanged, true);
            app.file_FileSortMethod.FontSize = 10;
            app.file_FileSortMethod.BackgroundColor = [0.9804 0.9804 0.9804];
            app.file_FileSortMethod.Layout.Row = 2;
            app.file_FileSortMethod.Layout.Column = 2;
            app.file_FileSortMethod.Value = 'LOCALIDADE';

            % Create file_FileSortMethodIcon
            app.file_FileSortMethodIcon = uiimage(app.SubGrid1);
            app.file_FileSortMethodIcon.ScaleMethod = 'none';
            app.file_FileSortMethodIcon.Layout.Row = 2;
            app.file_FileSortMethodIcon.Layout.Column = 1;
            app.file_FileSortMethodIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'sort_az_ascending.png');

            % Create FileTree
            app.FileTree = uitree(app.file_Grid);
            app.FileTree.Multiselect = 'on';
            app.FileTree.SelectionChangedFcn = createCallbackFcn(app, @onTreeSelectionChanged, true);
            app.FileTree.FontSize = 11;
            app.FileTree.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.FileTree.Layout.Row = 3;
            app.FileTree.Layout.Column = [2 3];

            % Create FileMetadata
            app.FileMetadata = uilabel(app.file_Grid);
            app.FileMetadata.VerticalAlignment = 'top';
            app.FileMetadata.WordWrap = 'on';
            app.FileMetadata.FontSize = 11;
            app.FileMetadata.Layout.Row = 3;
            app.FileMetadata.Layout.Column = [5 6];
            app.FileMetadata.Interpreter = 'html';
            app.FileMetadata.Text = '';

            % Create Tab2_MonitoringPlan
            app.Tab2_MonitoringPlan = uitab(app.TabGroup);
            app.Tab2_MonitoringPlan.AutoResizeChildren = 'off';
            app.Tab2_MonitoringPlan.Title = 'MONITORINGPLAN';

            % Create Tab3_ExternalRequest
            app.Tab3_ExternalRequest = uitab(app.TabGroup);
            app.Tab3_ExternalRequest.AutoResizeChildren = 'off';
            app.Tab3_ExternalRequest.Title = 'EXTERNALREQUEST';

            % Create Tab4_RFDataHub
            app.Tab4_RFDataHub = uitab(app.TabGroup);
            app.Tab4_RFDataHub.AutoResizeChildren = 'off';
            app.Tab4_RFDataHub.Title = 'RFDATAHUB';

            % Create Tab5_Config
            app.Tab5_Config = uitab(app.TabGroup);
            app.Tab5_Config.AutoResizeChildren = 'off';
            app.Tab5_Config.Title = 'CONFIG';

            % Create NavBar
            app.NavBar = uigridlayout(app.GridLayout);
            app.NavBar.ColumnWidth = {22, 74, '1x', 34, 5, 34, 34, 5, 34, 34, '1x', 20, 20, 1, 20, 20};
            app.NavBar.RowHeight = {5, 7, 20, 7, 5};
            app.NavBar.ColumnSpacing = 5;
            app.NavBar.RowSpacing = 0;
            app.NavBar.Padding = [10 5 5 5];
            app.NavBar.Tag = 'COLORLOCKED';
            app.NavBar.Layout.Row = 1;
            app.NavBar.Layout.Column = 1;
            app.NavBar.BackgroundColor = [0.2 0.2 0.2];

            % Create AppIcon
            app.AppIcon = uiimage(app.NavBar);
            app.AppIcon.Layout.Row = [1 5];
            app.AppIcon.Layout.Column = 1;
            app.AppIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'icon_48.png');

            % Create AppName
            app.AppName = uilabel(app.NavBar);
            app.AppName.WordWrap = 'on';
            app.AppName.FontSize = 11;
            app.AppName.FontColor = [1 1 1];
            app.AppName.Layout.Row = [1 5];
            app.AppName.Layout.Column = [2 3];
            app.AppName.Interpreter = 'html';
            app.AppName.Text = {'monitorRNI v. 1.0.0'; '<font style="font-size: 9px;">R2024a</font>'};

            % Create Tab1Button
            app.Tab1Button = uibutton(app.NavBar, 'state');
            app.Tab1Button.ValueChangedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.Tab1Button.Tag = 'FILE';
            app.Tab1Button.Tooltip = {'Leitura de arquivos'};
            app.Tab1Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'folder-active-24px-yellow.svg');
            app.Tab1Button.Text = '';
            app.Tab1Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab1Button.FontSize = 11;
            app.Tab1Button.Layout.Row = [2 4];
            app.Tab1Button.Layout.Column = 4;
            app.Tab1Button.Value = true;

            % Create ButtonsSeparator1
            app.ButtonsSeparator1 = uiimage(app.NavBar);
            app.ButtonsSeparator1.ScaleMethod = 'none';
            app.ButtonsSeparator1.Enable = 'off';
            app.ButtonsSeparator1.Layout.Row = [2 4];
            app.ButtonsSeparator1.Layout.Column = 5;
            app.ButtonsSeparator1.VerticalAlignment = 'bottom';
            app.ButtonsSeparator1.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create Tab2Button
            app.Tab2Button = uibutton(app.NavBar, 'state');
            app.Tab2Button.ValueChangedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.Tab2Button.Tag = 'MONITORINGPLAN';
            app.Tab2Button.Tooltip = {'PM-RNI'};
            app.Tab2Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'graph-line-24px-white.svg');
            app.Tab2Button.Text = '';
            app.Tab2Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab2Button.FontSize = 11;
            app.Tab2Button.Layout.Row = [2 4];
            app.Tab2Button.Layout.Column = 6;

            % Create Tab3Button
            app.Tab3Button = uibutton(app.NavBar, 'state');
            app.Tab3Button.ValueChangedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.Tab3Button.Tag = 'EXTERNALREQUEST';
            app.Tab3Button.Tooltip = {'Demanda externa'};
            app.Tab3Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'report-24px-2hite.svg');
            app.Tab3Button.Text = '';
            app.Tab3Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab3Button.FontSize = 11;
            app.Tab3Button.Layout.Row = [2 4];
            app.Tab3Button.Layout.Column = 7;

            % Create ButtonsSeparator2
            app.ButtonsSeparator2 = uiimage(app.NavBar);
            app.ButtonsSeparator2.ScaleMethod = 'none';
            app.ButtonsSeparator2.Enable = 'off';
            app.ButtonsSeparator2.Layout.Row = [2 4];
            app.ButtonsSeparator2.Layout.Column = 8;
            app.ButtonsSeparator2.VerticalAlignment = 'bottom';
            app.ButtonsSeparator2.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create Tab4Button
            app.Tab4Button = uibutton(app.NavBar, 'state');
            app.Tab4Button.ValueChangedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.Tab4Button.Tag = 'RFDATAHUB';
            app.Tab4Button.Tooltip = {'RFDataHub'};
            app.Tab4Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'database-24px-white.svg');
            app.Tab4Button.Text = '';
            app.Tab4Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab4Button.FontSize = 11;
            app.Tab4Button.Layout.Row = [2 4];
            app.Tab4Button.Layout.Column = 9;

            % Create Tab5Button
            app.Tab5Button = uibutton(app.NavBar, 'state');
            app.Tab5Button.ValueChangedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.Tab5Button.Tag = 'CONFIG';
            app.Tab5Button.Tooltip = {'Configurações gerais'};
            app.Tab5Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'gear-24px-white.svg');
            app.Tab5Button.IconAlignment = 'right';
            app.Tab5Button.Text = '';
            app.Tab5Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab5Button.FontSize = 11;
            app.Tab5Button.Layout.Row = [2 4];
            app.Tab5Button.Layout.Column = 10;

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.NavBar);
            app.jsBackDoor.Layout.Row = 3;
            app.jsBackDoor.Layout.Column = 12;

            % Create DataHubLamp
            app.DataHubLamp = uiimage(app.NavBar);
            app.DataHubLamp.ImageClickedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.DataHubLamp.Visible = 'off';
            app.DataHubLamp.Layout.Row = 3;
            app.DataHubLamp.Layout.Column = 13;
            app.DataHubLamp.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'red-circle-blink.gif');

            % Create FigurePosition
            app.FigurePosition = uiimage(app.NavBar);
            app.FigurePosition.ScaleMethod = 'none';
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.FigurePosition.Visible = 'off';
            app.FigurePosition.Layout.Row = 3;
            app.FigurePosition.Layout.Column = 15;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'screen-normal-24px-white.svg');

            % Create AppInfo
            app.AppInfo = uiimage(app.NavBar);
            app.AppInfo.ScaleMethod = 'none';
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @onTabNavigatorButtonPushed, true);
            app.AppInfo.Layout.Row = 3;
            app.AppInfo.Layout.Column = 16;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'kebab-vertical-24px-white.svg');

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'winMonitorRNI';

            % Create contextmenu_merge
            app.contextmenu_merge = uimenu(app.ContextMenu);
            app.contextmenu_merge.MenuSelectedFcn = createCallbackFcn(app, @Toolbar_MergeFilesImageClicked, true);
            app.contextmenu_merge.Enable = 'off';
            app.contextmenu_merge.Text = '🔀 Mesclar';

            % Create contextmenu_del
            app.contextmenu_del = uimenu(app.ContextMenu);
            app.contextmenu_del.MenuSelectedFcn = createCallbackFcn(app, @ContextMenu_DeleteSelectedTreeNode, true);
            app.contextmenu_del.Enable = 'off';
            app.contextmenu_del.Text = '❌ Excluir';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winMonitorRNI_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
