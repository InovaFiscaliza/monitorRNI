classdef winMonitorRNI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        MenuGrid                 matlab.ui.container.GridLayout
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
        file_Metadata            matlab.ui.control.Label
        file_Tree                matlab.ui.container.Tree
        TabGroup2                matlab.ui.container.TabGroup
        ARQUIVOSTab              matlab.ui.container.Tab
        GridLayout2              matlab.ui.container.GridLayout
        file_FileSortMethodIcon  matlab.ui.control.Image
        file_FileSortMethod      matlab.ui.control.DropDown
        file_ModuleIntro         matlab.ui.control.Label
        file_toolGrid            matlab.ui.container.GridLayout
        file_Separator1          matlab.ui.control.Image
        file_MergeFiles          matlab.ui.control.Image
        file_OpenFileButton      matlab.ui.control.Image
        Tab2_MonitoringPlan      matlab.ui.container.Tab
        Tab3_ExternalRequest     matlab.ui.container.Tab
        Tab4_RFDataHub           matlab.ui.container.Tab
        Tab5_Config              matlab.ui.container.Tab
        ContextMenu              matlab.ui.container.ContextMenu
        contextmenu_del          matlab.ui.container.Menu
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'mainApp'
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
        rfDataHub
        rfDataHubLOG
        rfDataHubSummary
        cacheData = model.measData.empty
        measData  = model.measData.empty
    end


    methods
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
                            selectedNodes = app.file_Tree.SelectedNodes;
                            if ~isempty(app.file_Tree.SelectedNodes)
                                app.file_Tree.SelectedNodes = [];
                                file_TreeSelectionChanged(app)
                            end

                            appEngine.beforeReload(app, app.Role)
                            appEngine.activate(app, app.Role, MFilePath, parpoolFlag)

                            if ~isempty(selectedNodes)
                                app.file_Tree.SelectedNodes = selectedNodes;
                                file_TreeSelectionChanged(app)
                            end
                        end
                        
                        app.renderCount = app.renderCount+1;

                    case 'unload'
                        closeFcn(app)
                    
                    case 'customForm'
                        switch event.HTMLEventData.uuid
                            case 'eFiscalizaSignInPage'
                                report_uploadInfoController(app, event.HTMLEventData, 'uploadDocument', event.HTMLEventData.context)

                            case 'openDevTools'
                                if isequal(app.General.operationMode.DevTools, rmfield(event.HTMLEventData, 'uuid'))
                                    webWin = struct(struct(struct(app.UIFigure).Controller).PlatformHost).CEF;
                                    webWin.openDevTools();
                                end
                        end

                    case 'getNavigatorBasicInformation'
                        app.General.AppVersion.browser = event.HTMLEventData;

                    % MAINAPP
                    case 'mainApp.file_Tree'
                        file_ContextMenu_delTreeNodeSelected(app)

                    % AUXAPP.WINEXTERNALREQUEST
                    case 'auxApp.winExternalRequest.TreePoints'
                        ipcMainMatlabCallAuxiliarApp(app, 'EXTERNALREQUEST', 'JS', event)

                    otherwise
                        error('UnexpectedEvent')
                end
                drawnow

            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME));
            end
        end

        %-----------------------------------------------------------------%
        function varargout = ipcMainMatlabCallsHandler(app, callingApp, operationType, varargin)
            varargout = {};

            try
                switch class(callingApp)
                    % auxApp.winConfig
                    case {'auxApp.winConfig', 'auxApp.winConfig_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "CONFIG", app.General)

                            case 'dockButtonPushed'
                                auxAppTag = varargin{1};
                                varargout{1} = auxAppInputArguments(app, auxAppTag);

                            case 'checkDataHubLampStatus'
                                DataHubWarningLamp(app)

                            case 'openDevTools'
                                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');
                                sendEventToHTMLSource(app.jsBackDoor, 'customForm', struct('UUID', 'openDevTools', 'Fields', dialogBox))

                            case 'simulationModeChanged'
                                if app.General.operationMode.Simulation
                                    file_OpenFileButtonImageClicked(app)

                                    % Muda programaticamente o modo p/ ARQUIVOS.
                                    app.Tab1Button.Value = true;                    
                                    tabNavigatorButtonPushed(app, struct('Source', app.Tab1Button, 'PreviousValue', false))
                                end

                            case 'RFDataHubUpdated'
                                if ~isempty(app.AppInfo.Tag)
                                    app.AppInfo.Tag = '';
                                end

                            case 'fileSortMethodChanged'
                                if ~strcmp(app.file_FileSortMethod.Value, app.General.File.sortMethod)
                                    app.file_FileSortMethod.Value = app.General.File.sortMethod;
                                    file_FileSortMethodValueChanged(app)
                                end

                            case {'MonitoringPlan:AnalysisParameterChanged', ...
                                  'MonitoringPlan:AxesParameterChanged', ...
                                  'MonitoringPlan:PlotParameterChanged'}
                                ipcMainMatlabCallAuxiliarApp(app, 'MONITORINGPLAN', 'MATLAB', operationType)

                            case {'ExternalRequest:AnalysisParameterChanged', ...
                                  'ExternalRequest:AxesParameterChanged', ...
                                  'ExternalRequest:PlotParameterChanged'}
                                ipcMainMatlabCallAuxiliarApp(app, 'EXTERNALREQUEST', 'MATLAB', operationType)

                            otherwise
                                error('UnexpectedCall')
                        end

                    % auxApp.winMonitoringPlan
                    case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "MONITORINGPLAN", app.General)

                            case 'dockButtonPushed'
                                auxAppTag = varargin{1};
                                varargout{1} = auxAppInputArguments(app, auxAppTag);

                            otherwise
                                error('UnexpectedCall')
                        end

                    % auxApp.winExternalRequest
                    case {'auxApp.winExternalRequest',  'auxApp.winExternalRequest_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "EXTERNALREQUEST", app.General)

                            case 'dockButtonPushed'
                                auxAppTag = varargin{1};
                                varargout{1} = auxAppInputArguments(app, auxAppTag);

                            otherwise
                                error('UnexpectedCall')
                        end

                    % auxApp.winRFDataHub
                    case {'auxApp.winRFDataHub', 'auxApp.winRFDataHub_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "RFDATAHUB", app.General)

                            case 'dockButtonPushed'
                                auxAppTag = varargin{1};
                                varargout{1} = auxAppInputArguments(app, auxAppTag);

                            otherwise
                                error('UnexpectedCall')
                        end
    
                    otherwise
                        error('UnexpectedCall')
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
            hAuxApp = auxAppHandle(app, auxAppName);

            if ~isempty(hAuxApp)
                switch communicationType
                    case 'MATLAB'
                        operationType = varargin{1};
                        ipcSecundaryMatlabCallsHandler(hAuxApp, app, operationType, varargin{2:end});
                    case 'JS'
                        event = varargin{1};
                        ipcSecundaryJSEventsHandler(hAuxApp, event)
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
                    screenHeight = 308;
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
            tabNavigatorButtonPushed(app, struct('Source', clickedButton, 'PreviousValue', false))
        end

        %-----------------------------------------------------------------%
        function applyJSCustomizations(app, tabIndex)
            persistent customizationStatus
            if isempty(customizationStatus)
                customizationStatus = [false, false, false, false];
            end

            switch tabIndex
                case 0 % STARTUP
                    sendEventToHTMLSource(app.jsBackDoor, 'startup', app.executionMode);
                    customizationStatus = [false, false, false, false];

                otherwise
                    if customizationStatus(tabIndex)
                        return
                    end

                    customizationStatus(tabIndex) = true;
                    switch tabIndex
                        case 1 % FILE
                            elToModify = {app.popupContainerGrid, app.file_Tree, app.file_Metadata};                            
                            ui.CustomizationBase.getElementsDataTag(elToModify);

                            appName = class(app);
                            if isvalid(app.popupContainerGrid)
                                try
                                    sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', {struct('appName', appName, 'dataTag', elToModify{1}.UserData.id, 'style', struct('backgroundColor', 'rgba(255,255,255,0.65)'))});
                                catch
                                end
                            end

                            try
                                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', {struct('appName', appName, 'dataTag', elToModify{2}.UserData.id, 'listener', struct('componentName', 'mainApp.file_Tree', 'keyEvents', {{'Delete', 'Backspace'}}))});
                            catch ME
                                ui.Dialog(app.UIFigure, 'error', getReport(ME));
                            end

                            try
                                ui.TextView.startup(app.jsBackDoor, elToModify{3}, appName);
                            catch ME
                                ui.Dialog(app.UIFigure, 'error', getReport(ME));
                            end

                        otherwise
                            % Customização dos módulos que são renderizados
                            % nesta figura são controladas pelos próprios
                            % módulos.
                    end
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
                    app.General_I.Plot.GeographicAxes.Basemap = 'none';
                    app.General_I.Report.Basemap              = 'none';

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
            % RFDataHub
            global RFDataHub
            global RFDataHubLog

            app.rfDataHub        = RFDataHub;
            app.rfDataHubLOG     = RFDataHubLog;
            app.rfDataHubSummary = summary(RFDataHub(:, {'Source', 'State'}));

            % A coluna "Source" possui agrupamentos da fonte dos dados,
            % decorrente da mesclagem de estações.
            tempSourceList = cellfun(@(x) strsplit(x, ' | '), app.rfDataHubSummary.Source.Categories, 'UniformOutput', false);
            app.rfDataHubSummary.Source.RawCategories = unique(horzcat(tempSourceList{:}))';

            % app.projectData
            app.projectData = model.projectLib(app, app.rootFolder, app.General);
        end

        %-----------------------------------------------------------------%
        function initializeUIComponents(app)
            app.tabGroupController = ui.TabNavigator(app.MenuGrid, app.TabGroup, app.progressDialog, @app.applyJSCustomizations, []);
            addComponent(app.tabGroupController, "Built-in", "",                          app.Tab1Button, "AlwaysOn", struct('On', 'OpenFile_32Yellow.png',      'Off', 'OpenFile_32White.png'),      matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winMonitoringPlan",  app.Tab2Button, "AlwaysOn", struct('On', 'Detection_32Yellow.png',     'Off', 'Detection_32White.png'),     app.Tab1Button,                    2)
            addComponent(app.tabGroupController, "External", "auxApp.winExternalRequest", app.Tab3Button, "AlwaysOn", struct('On', 'exceptionList_32Yellow.png', 'Off', 'exceptionList_32White.png'), app.Tab1Button,                    3)
            addComponent(app.tabGroupController, "External", "auxApp.winRFDataHub",       app.Tab4Button, "AlwaysOn", struct('On', 'mosaic_32Yellow.png',        'Off', 'mosaic_32White.png'),        app.Tab1Button,                    4)
            addComponent(app.tabGroupController, "External", "auxApp.winConfig",          app.Tab5Button, "AlwaysOn", struct('On', 'Settings_36Yellow.png',      'Off', 'Settings_36White.png'),      app.Tab1Button,                    5)

            addStyle(app.file_Tree, uistyle('Interpreter', 'html'))
        end


        %-----------------------------------------------------------------%
        function applyInitialLayout(app)
            DataHubWarningLamp(app)
            app.file_FileSortMethod.Value = app.General.File.sortMethod;
        end

        %-----------------------------------------------------------------%
        function DataHubWarningLamp(app)
            if isfolder(app.General.fileFolder.DataHub_POST)
                app.DataHubLamp.Visible = 0;
            else
                app.DataHubLamp.Visible = 1;
            end
        end

        %-----------------------------------------------------------------%
        function file_ProjectRestart(app, indexes, updateType)
            arguments
                app
                indexes
                updateType char {mustBeMember(updateType, {'FileListChanged:Add', ...
                                                           'FileListChanged:Del', ...
                                                           'FileListChanged:Unmerge', ...
                                                           'FileListChanged:Merge'})}
            end

            file_TreeBuilding(app, indexes)

            if ismember(updateType, {'FileListChanged:Add', 'FileListChanged:Del'})
                updateAnalysis( ...
                    app.projectData, ...
                    app.measData, ...
                    app.General, ...
                    updateType ...
                );
            end
            
            ipcMainMatlabCallAuxiliarApp(app, 'MONITORINGPLAN',  'MATLAB', updateType)
            ipcMainMatlabCallAuxiliarApp(app, 'EXTERNALREQUEST', 'MATLAB', updateType)
        end
        
        %-----------------------------------------------------------------%
        function file_TreeBuilding(app, selectedNodeData)
            arguments
                app
                selectedNodeData = []
            end

            if ~isempty(app.file_Tree.Children)
                app.file_Metadata.UserData = [];
                delete(app.file_Tree.Children)
            end

            selectedNode = [];

            switch app.file_FileSortMethod.Value
                case 'ARQUIVO'
                    for ii = 1:numel(app.measData)
                        treeNode = file_createTreeElements(app, ii, app.file_Tree, 'FILE');

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

                        locationTreeNode = uitreenode(app.file_Tree, 'Text', location, ...
                                                                     'NodeData', locationIndexes, ...
                                                                     'ContextMenu', app.ContextMenu);

                        for jj = locationIndexes
                            treeNode = file_createTreeElements(app, jj, locationTreeNode, 'LOCATION');
    
                            if ismember(jj, selectedNodeData)
                                selectedNode = [selectedNode, treeNode];
                            end
                        end
                    end
            end

            expand(app.file_Tree, 'all')

            if ~isempty(app.measData)
                if ~isempty(selectedNode)
                    app.file_Tree.SelectedNodes = selectedNode;
                else
                    if isempty(app.file_Tree.Children(1).Children)
                        app.file_Tree.SelectedNodes = app.file_Tree.Children(1);
                    else
                        app.file_Tree.SelectedNodes = app.file_Tree.Children(1).Children(1);
                    end
                end
            end

            file_TreeSelectionChanged(app)
        end

        %-----------------------------------------------------------------%
        function treeNode = file_createTreeElements(app, index, treeNodeParent, treeNodePreffixType)
            arguments
                app
                index
                treeNodeParent
                treeNodePreffixType char {mustBeMember(treeNodePreffixType, {'FILE', 'LOCATION'})}
            end

            currentMeasData = app.measData(index);
            
            switch treeNodePreffixType
                case 'FILE'
                    treeNodePreffix = currentMeasData.Filename;
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
        function indexes = file_findSelectedNodeData(app)
            indexes = [];
            if ~isempty(app.file_Tree.SelectedNodes)
                indexes = unique([app.file_Tree.SelectedNodes.NodeData]);
            end
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
        % TABGROUPCONTROLLER
        %-----------------------------------------------------------------%
        function hAuxApp = auxAppHandle(app, auxAppName)
            arguments
                app
                auxAppName string {mustBeMember(auxAppName, ["MONITORINGPLAN", "EXTERNALREQUEST", "RFDATAHUB", "CONFIG"])}
            end

            hAuxApp = app.tabGroupController.Components.appHandle{app.tabGroupController.Components.Tag == auxAppName};
        end

        %-----------------------------------------------------------------%
        function inputArguments = auxAppInputArguments(app, auxAppName)
            arguments
                app
                auxAppName char {mustBeMember(auxAppName, {'FILE', 'MONITORINGPLAN', 'EXTERNALREQUEST', 'RFDATAHUB', 'CONFIG'})}
            end
            
            [auxAppIsOpen, ...
             auxAppHandle] = checkStatusModule(app.tabGroupController, auxAppName);

            inputArguments = {app};

            switch auxAppName
                case 'RFDATAHUB'
                    if auxAppIsOpen
                        filterTable         = auxAppHandle.filterTable;
                        rfDataHubAnnotation = auxAppHandle.rfDataHubAnnotation;
                        inputArguments      = {app, filterTable, rfDataHubAnnotation};
                    end

                otherwise
                    % ...
            end
        end
    end


    methods
        %-----------------------------------------------------------------%
        % SISTEMA DE GESTÃO DA FISCALIZAÇÃO (eFiscaliza/SEI)
        %-----------------------------------------------------------------%                
        function status = report_checkEFiscalizaIssueId(app, issue)
            status = (issue > 0) && (issue < inf);
        end

        %-----------------------------------------------------------------%
        function report_uploadInfoController(app, credentials, operation, context)
            communicationStatus = report_sendHTMLDocToSEIviaEFiscaliza(app, credentials, operation, context);
            if communicationStatus && strcmp(app.projectData.modules.(context).ui.system, 'eFiscaliza')
                report_sendFilesToSharepoint(app, context)
            end
        end

        %-------------------------------------------------------------------------%
        function communicationStatus = report_sendHTMLDocToSEIviaEFiscaliza(app, credentials, operation, context)
            app.progressDialog.Visible = 'visible';
            communicationStatus = false;

            try
                if ~isempty(credentials)
                    app.eFiscalizaObj = ws.eFiscaliza(credentials.login, credentials.password);
                end

                % Parâmetros configurados no módulo auxiliar:
                env   = strsplit(app.projectData.modules.(context).ui.system);
                if numel(env) < 2; env = 'PD';
                else;              env = env{2};
                end
                unit  = app.projectData.modules.(context).ui.unit;
                issue = struct('type', 'ATIVIDADE DE INSPEÇÃO', 'id', app.projectData.modules.(context).ui.issue);                

                switch operation
                    case 'uploadDocument'
                        fileName = getGeneratedDocumentFileName(app.projectData, '.html', context);
                        docSpec  = app.General.eFiscaliza;
                        docSpec.originId = docSpec.internal.originId;
                        docSpec.typeId   = docSpec.internal.typeId;

                        msg = run(app.eFiscalizaObj, env, operation, issue, unit, docSpec, fileName);
        
                    otherwise
                        error('Unexpected call')
                end
                
                if ~contains(msg, 'Documento cadastrado no SEI', 'IgnoreCase', true)
                    error(msg)
                end

                modalWindowIcon     = 'success';
                modalWindowMessage  = msg;
                communicationStatus = true;

            catch ME
                app.eFiscalizaObj   = [];
                
                modalWindowIcon     = 'error';
                modalWindowMessage  = ME.message;
            end

            ui.Dialog(app.UIFigure, modalWindowIcon, modalWindowMessage);
            app.progressDialog.Visible = 'hidden';
        end

        %------------------------------------------------------------------------%
        function report_sendFilesToSharepoint(app, context)
            % Evita subir por engano, quando no ambiente de desenvolvimento,
            % de arquivos na pasta "POST".
            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                sharepointFolder = app.General.fileFolder.DataHub_POST;
            catch
                sharepointFolder = app.General.fileFolder.userPath;
            end

            sharepointFileList = getGeneratedDocumentFileName(app.projectData, 'rawFiles', context);
            if strcmp(context, 'MonitoringPlan')
                sharepointFileList = [sharepointFileList, {getGeneratedDocumentFileName(app.projectData, '.xlsx', context)}];
            end
            
            for ii = 1:numel(sharepointFileList)
                tempFilename = sharepointFileList{ii};

                try
                    if isfile(tempFilename)
                        copyfile(tempFilename, sharepointFolder, 'f');
    
                        if ~endsWith(tempFilename, '.xlsx')
                            [~, basename]  = fileparts(tempFilename);
                            jsonFilename   = [basename '.json'];
                            [~, fileIndex] = ismember(tempFilename, {app.measData.Filename});
    
                            if fileIndex
                                fileWriter.RawFileMetaData(fullfile(sharepointFolder, jsonFilename), app.measData(fileIndex));
                            end
                        end
                    end
                catch ME
                    ui.Dialog(app.UIFigure, 'error', getReport(ME))
                end
            end
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

            if ~strcmp(app.executionMode, 'webApp') && ~isempty(app.measData)
                msgQuestion   = 'Deseja fechar o aplicativo?';
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 1, 2);
                if userSelection == "Não"
                    return
                end
            end

            % Aspectos gerais (comum em todos os apps):
            appEngine.util.beforeDeleteApp(app.progressDialog, app.General_I.fileFolder.tempPath, app.tabGroupController, app.executionMode)
            delete(app)
            
        end

        % Value changed function: Tab1Button, Tab2Button, Tab3Button, 
        % ...and 2 other components
        function tabNavigatorButtonPushed(app, event)

            clickedButton  = event.Source;
            auxAppTag      = clickedButton.Tag;
            inputArguments = auxAppInputArguments(app, auxAppTag);

            openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, inputArguments{:})

        end

        % Image clicked function: AppInfo, FigurePosition
        function menuImageClicked(app, event)
            
            switch event.Source
                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appEngine.util.setWindowPosition(app.UIFigure)

                case app.AppInfo
                    appInfo = util.HtmlTextGenerator.AppInfo(app.General, app.rootFolder, app.executionMode, app.renderCount, "popup");
                    ui.Dialog(app.UIFigure, 'info', appInfo);
            end

        end

        % Selection changed function: file_Tree
        function file_TreeSelectionChanged(app, event)

            indexes = file_findSelectedNodeData(app);
            app.file_MergeFiles.Enable = 0;

            if isempty(indexes)
                app.file_Metadata.Text     = '';
                app.file_Metadata.UserData = [];

            else
                if isequal(app.file_Metadata.UserData, indexes)
                    return
                end

                app.file_Metadata.Text     = util.HtmlTextGenerator.SelectedFile(app.measData(indexes));
                app.file_Metadata.UserData = indexes;

                locationMergedStatus = any(arrayfun(@(x) ~strcmp(x.Location, x.Location_I), app.measData(indexes)));
                if ~isscalar(indexes) || locationMergedStatus
                    app.file_MergeFiles.Enable = 1;
                end
            end
            
        end

        % Menu selected function: contextmenu_del
        function file_ContextMenu_delTreeNodeSelected(app, event)
            
            if ~isempty(app.file_Tree.SelectedNodes)
                indexes = [app.file_Tree.SelectedNodes.NodeData];
                app.measData(indexes) = [];
                file_ProjectRestart(app, [], 'FileListChanged:Del')
            end

        end

        % Image clicked function: file_OpenFileButton
        function file_OpenFileButtonImageClicked(app, event)

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
                switch app.General.File.input
                    case 'file'
                        [fileName, filePath] = uigetfile({'*.txt';'*.csv';'*.mat';'*.*'}, ...
                                                          '', app.General.fileFolder.lastVisited, 'MultiSelect', 'on');
                        figure(app.UIFigure)
            
                        if isequal(fileName, 0)
                            return
                        elseif ~iscellstr(fileName)
                            fileName = cellstr(fileName);
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

            filesInCache = {};
            filesError   = struct('File', {}, 'Error', {});

            for ii = 1:numel(fileFullName)
                d.Message = textFormatGUI.HTMLParagraph(sprintf('Em andamento a leitura do arquivo %d de %d:<br>• <b>%s</b>', ii, numel(fileFullName), fileName{ii}));

                % Verifica se arquivo já foi lido, comparando o seu nome com 
                % a variável app.cacheData.
                [~, idxCache] = ismember(fileName{ii}, {app.cacheData.Filename});
                if ~idxCache
                    try
                        app.cacheData(end+1) = fileReader.CSV.Controller(fileFullName{ii});
                    catch ME
                        filesError(end+1) = struct('File', fileName{ii}, 'Error', ME.message);
                        continue
                    end
                    idxCache = numel(app.cacheData);
                end

                % Verifica se arquivo já está ativo, comparando o seu nome com 
                % a variável app.measData.
                [~, idxFile] = ismember(fileName{ii}, {app.measData.Filename});
                if ~idxFile
                    app.measData(end+1) = app.cacheData(idxCache);
                else
                    filesInCache{end+1} = fileName{ii};
                end
            end

            % LOG
            msgWarning = '';
            if ~isempty(filesError)
                msgWarning = sprintf('Arquivos que apresentaram erro na leitura:\n%s\n\n', strjoin(strcat({'<font style="font-size: 11px;">•&thinsp;'}, {filesError.File}, {': '}, {filesError.Error}), '</font>\n'));
            end

            if ~isempty(filesInCache)
                msgWarning = [msgWarning, sprintf('Arquivos já lidos:\n%s', textFormatGUI.cellstr2Bullets(filesInCache))];
            end

            if ~isempty(msgWarning)
                ui.Dialog(app.UIFigure, "warning", msgWarning);
            end
            
            indexes = file_findSelectedNodeData(app);
            file_ProjectRestart(app, indexes, 'FileListChanged:Add')

            delete(d)

        end

        % Value changed function: file_FileSortMethod
        function file_FileSortMethodValueChanged(app, event)
            
            indexes = file_findSelectedNodeData(app);
            file_TreeBuilding(app, indexes)

        end

        % Image clicked function: file_MergeFiles
        function file_MergeFilesImageClicked(app, event)
            
            % O processo de "mesclagem" é apenas o controle da localidade
            % de agrupamento, não tendo impacto na análise, mas apenas na
            % visualização da informação no app (e no relatório).

            indexes = file_findSelectedNodeData(app);

            locationMergedStatus = any(arrayfun(@(x) ~strcmp(x.Location, x.Location_I), app.measData(indexes)));
            if locationMergedStatus
                msgQuestion   = util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'MergedStatusOn');
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);

                if userSelection == "Sim"
                    delLocationCache(app.projectData, app.measData, indexes)
                    
                    for ii = indexes
                        app.measData(ii).Location = app.measData(ii).Location_I;
                    end
                    file_ProjectRestart(app, indexes, 'FileListChanged:Unmerge')
                    return
                end
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
                file_ProjectRestart(app, indexes, 'FileListChanged:Merge')
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

            % Create file_OpenFileButton
            app.file_OpenFileButton = uiimage(app.file_toolGrid);
            app.file_OpenFileButton.ScaleMethod = 'none';
            app.file_OpenFileButton.ImageClickedFcn = createCallbackFcn(app, @file_OpenFileButtonImageClicked, true);
            app.file_OpenFileButton.Tooltip = {'Seleciona arquivos'};
            app.file_OpenFileButton.Layout.Row = 2;
            app.file_OpenFileButton.Layout.Column = 1;
            app.file_OpenFileButton.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Import_16.png');

            % Create file_MergeFiles
            app.file_MergeFiles = uiimage(app.file_toolGrid);
            app.file_MergeFiles.ImageClickedFcn = createCallbackFcn(app, @file_MergeFilesImageClicked, true);
            app.file_MergeFiles.Enable = 'off';
            app.file_MergeFiles.Tooltip = {'Mescla informações'};
            app.file_MergeFiles.Layout.Row = [1 3];
            app.file_MergeFiles.Layout.Column = 3;
            app.file_MergeFiles.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Merge_32.png');

            % Create file_Separator1
            app.file_Separator1 = uiimage(app.file_toolGrid);
            app.file_Separator1.ScaleMethod = 'none';
            app.file_Separator1.Enable = 'off';
            app.file_Separator1.Layout.Row = [1 3];
            app.file_Separator1.Layout.Column = 2;
            app.file_Separator1.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV.svg');

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.file_Grid);
            app.TabGroup2.AutoResizeChildren = 'off';
            app.TabGroup2.Layout.Row = 1;
            app.TabGroup2.Layout.Column = [2 6];

            % Create ARQUIVOSTab
            app.ARQUIVOSTab = uitab(app.TabGroup2);
            app.ARQUIVOSTab.AutoResizeChildren = 'off';
            app.ARQUIVOSTab.Title = 'ARQUIVOS';
            app.ARQUIVOSTab.BackgroundColor = 'none';
            app.ARQUIVOSTab.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.ARQUIVOSTab);
            app.GridLayout2.ColumnWidth = {22, 150, '1x'};
            app.GridLayout2.RowHeight = {22, 22};
            app.GridLayout2.ColumnSpacing = 5;
            app.GridLayout2.RowSpacing = 5;
            app.GridLayout2.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create file_ModuleIntro
            app.file_ModuleIntro = uilabel(app.GridLayout2);
            app.file_ModuleIntro.VerticalAlignment = 'top';
            app.file_ModuleIntro.WordWrap = 'on';
            app.file_ModuleIntro.FontSize = 11;
            app.file_ModuleIntro.FontColor = [0.149 0.149 0.149];
            app.file_ModuleIntro.Layout.Row = 1;
            app.file_ModuleIntro.Layout.Column = [1 3];
            app.file_ModuleIntro.Text = 'Este aplicativo permite a leitura de arquivos gerados em medições de campo elétrico no âmbito do PM-RNI.';

            % Create file_FileSortMethod
            app.file_FileSortMethod = uidropdown(app.GridLayout2);
            app.file_FileSortMethod.Items = {'ARQUIVO', 'LOCALIDADE'};
            app.file_FileSortMethod.ValueChangedFcn = createCallbackFcn(app, @file_FileSortMethodValueChanged, true);
            app.file_FileSortMethod.FontSize = 10;
            app.file_FileSortMethod.BackgroundColor = [0.9804 0.9804 0.9804];
            app.file_FileSortMethod.Layout.Row = 2;
            app.file_FileSortMethod.Layout.Column = 2;
            app.file_FileSortMethod.Value = 'LOCALIDADE';

            % Create file_FileSortMethodIcon
            app.file_FileSortMethodIcon = uiimage(app.GridLayout2);
            app.file_FileSortMethodIcon.ScaleMethod = 'none';
            app.file_FileSortMethodIcon.Layout.Row = 2;
            app.file_FileSortMethodIcon.Layout.Column = 1;
            app.file_FileSortMethodIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'sort_az_ascending.png');

            % Create file_Tree
            app.file_Tree = uitree(app.file_Grid);
            app.file_Tree.Multiselect = 'on';
            app.file_Tree.SelectionChangedFcn = createCallbackFcn(app, @file_TreeSelectionChanged, true);
            app.file_Tree.FontSize = 11;
            app.file_Tree.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.file_Tree.Layout.Row = 3;
            app.file_Tree.Layout.Column = [2 3];

            % Create file_Metadata
            app.file_Metadata = uilabel(app.file_Grid);
            app.file_Metadata.VerticalAlignment = 'top';
            app.file_Metadata.WordWrap = 'on';
            app.file_Metadata.FontSize = 11;
            app.file_Metadata.Layout.Row = 3;
            app.file_Metadata.Layout.Column = [5 6];
            app.file_Metadata.Interpreter = 'html';
            app.file_Metadata.Text = '';

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

            % Create MenuGrid
            app.MenuGrid = uigridlayout(app.GridLayout);
            app.MenuGrid.ColumnWidth = {22, 74, '1x', 34, 5, 34, 34, 5, 34, 34, '1x', 20, 20, 1, 20, 20};
            app.MenuGrid.RowHeight = {5, 7, 20, 7, 5};
            app.MenuGrid.ColumnSpacing = 5;
            app.MenuGrid.RowSpacing = 0;
            app.MenuGrid.Padding = [10 5 5 5];
            app.MenuGrid.Tag = 'COLORLOCKED';
            app.MenuGrid.Layout.Row = 1;
            app.MenuGrid.Layout.Column = 1;
            app.MenuGrid.BackgroundColor = [0.2 0.2 0.2];

            % Create AppIcon
            app.AppIcon = uiimage(app.MenuGrid);
            app.AppIcon.Layout.Row = [1 5];
            app.AppIcon.Layout.Column = 1;
            app.AppIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'icon_48.png');

            % Create AppName
            app.AppName = uilabel(app.MenuGrid);
            app.AppName.WordWrap = 'on';
            app.AppName.FontSize = 11;
            app.AppName.FontColor = [1 1 1];
            app.AppName.Layout.Row = [1 5];
            app.AppName.Layout.Column = [2 3];
            app.AppName.Interpreter = 'html';
            app.AppName.Text = {'monitorRNI v. 1.0.0'; '<font style="font-size: 9px;">R2024a</font>'};

            % Create Tab1Button
            app.Tab1Button = uibutton(app.MenuGrid, 'state');
            app.Tab1Button.ValueChangedFcn = createCallbackFcn(app, @tabNavigatorButtonPushed, true);
            app.Tab1Button.Tag = 'FILE';
            app.Tab1Button.Tooltip = {'Leitura de arquivos'};
            app.Tab1Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'OpenFile_32Yellow.png');
            app.Tab1Button.IconAlignment = 'top';
            app.Tab1Button.Text = '';
            app.Tab1Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab1Button.FontSize = 11;
            app.Tab1Button.Layout.Row = [2 4];
            app.Tab1Button.Layout.Column = 4;
            app.Tab1Button.Value = true;

            % Create ButtonsSeparator1
            app.ButtonsSeparator1 = uiimage(app.MenuGrid);
            app.ButtonsSeparator1.ScaleMethod = 'none';
            app.ButtonsSeparator1.Enable = 'off';
            app.ButtonsSeparator1.Layout.Row = [2 4];
            app.ButtonsSeparator1.Layout.Column = 5;
            app.ButtonsSeparator1.VerticalAlignment = 'bottom';
            app.ButtonsSeparator1.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create Tab2Button
            app.Tab2Button = uibutton(app.MenuGrid, 'state');
            app.Tab2Button.ValueChangedFcn = createCallbackFcn(app, @tabNavigatorButtonPushed, true);
            app.Tab2Button.Tag = 'MONITORINGPLAN';
            app.Tab2Button.Tooltip = {'PM-RNI'};
            app.Tab2Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Detection_32White.png');
            app.Tab2Button.IconAlignment = 'right';
            app.Tab2Button.Text = '';
            app.Tab2Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab2Button.FontSize = 11;
            app.Tab2Button.Layout.Row = [2 4];
            app.Tab2Button.Layout.Column = 6;

            % Create Tab3Button
            app.Tab3Button = uibutton(app.MenuGrid, 'state');
            app.Tab3Button.ValueChangedFcn = createCallbackFcn(app, @tabNavigatorButtonPushed, true);
            app.Tab3Button.Tag = 'EXTERNALREQUEST';
            app.Tab3Button.Tooltip = {'Demanda externa'};
            app.Tab3Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'exceptionList_32White.png');
            app.Tab3Button.IconAlignment = 'right';
            app.Tab3Button.Text = '';
            app.Tab3Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab3Button.FontSize = 11;
            app.Tab3Button.Layout.Row = [2 4];
            app.Tab3Button.Layout.Column = 7;

            % Create ButtonsSeparator2
            app.ButtonsSeparator2 = uiimage(app.MenuGrid);
            app.ButtonsSeparator2.ScaleMethod = 'none';
            app.ButtonsSeparator2.Enable = 'off';
            app.ButtonsSeparator2.Layout.Row = [2 4];
            app.ButtonsSeparator2.Layout.Column = 8;
            app.ButtonsSeparator2.VerticalAlignment = 'bottom';
            app.ButtonsSeparator2.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create Tab4Button
            app.Tab4Button = uibutton(app.MenuGrid, 'state');
            app.Tab4Button.ValueChangedFcn = createCallbackFcn(app, @tabNavigatorButtonPushed, true);
            app.Tab4Button.Tag = 'RFDATAHUB';
            app.Tab4Button.Tooltip = {'RFDataHub'};
            app.Tab4Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'mosaic_32White.png');
            app.Tab4Button.IconAlignment = 'right';
            app.Tab4Button.Text = '';
            app.Tab4Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab4Button.FontSize = 11;
            app.Tab4Button.Layout.Row = [2 4];
            app.Tab4Button.Layout.Column = 9;

            % Create Tab5Button
            app.Tab5Button = uibutton(app.MenuGrid, 'state');
            app.Tab5Button.ValueChangedFcn = createCallbackFcn(app, @tabNavigatorButtonPushed, true);
            app.Tab5Button.Tag = 'CONFIG';
            app.Tab5Button.Tooltip = {'Configurações gerais'};
            app.Tab5Button.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Settings_36White.png');
            app.Tab5Button.IconAlignment = 'right';
            app.Tab5Button.Text = '';
            app.Tab5Button.BackgroundColor = [0.2 0.2 0.2];
            app.Tab5Button.FontSize = 11;
            app.Tab5Button.Layout.Row = [2 4];
            app.Tab5Button.Layout.Column = 10;

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.MenuGrid);
            app.jsBackDoor.Layout.Row = 3;
            app.jsBackDoor.Layout.Column = 12;

            % Create DataHubLamp
            app.DataHubLamp = uiimage(app.MenuGrid);
            app.DataHubLamp.Visible = 'off';
            app.DataHubLamp.Tooltip = {'Pendente mapear o Sharepoint'};
            app.DataHubLamp.Layout.Row = 3;
            app.DataHubLamp.Layout.Column = [13 14];
            app.DataHubLamp.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'red-circle-blink.gif');

            % Create FigurePosition
            app.FigurePosition = uiimage(app.MenuGrid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @menuImageClicked, true);
            app.FigurePosition.Visible = 'off';
            app.FigurePosition.Layout.Row = 3;
            app.FigurePosition.Layout.Column = 15;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'layout1_32White.png');

            % Create AppInfo
            app.AppInfo = uiimage(app.MenuGrid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @menuImageClicked, true);
            app.AppInfo.Layout.Row = 3;
            app.AppInfo.Layout.Column = 16;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Dots_32White.png');

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.Tag = 'winMonitorRNI';

            % Create contextmenu_del
            app.contextmenu_del = uimenu(app.ContextMenu);
            app.contextmenu_del.MenuSelectedFcn = createCallbackFcn(app, @file_ContextMenu_delTreeNodeSelected, true);
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
