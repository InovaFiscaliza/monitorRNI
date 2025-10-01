classdef winMonitorRNI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        popupContainerGrid       matlab.ui.container.GridLayout
        SplashScreen             matlab.ui.control.Image
        menu_Grid                matlab.ui.container.GridLayout
        jsBackDoor               matlab.ui.control.HTML
        DataHubLamp              matlab.ui.control.Image
        FigurePosition           matlab.ui.control.Image
        AppInfo                  matlab.ui.control.Image
        menu_AppName             matlab.ui.control.Label
        menu_AppIcon             matlab.ui.control.Image
        menu_Button5             matlab.ui.control.StateButton
        menu_Button4             matlab.ui.control.StateButton
        menu_Separator2          matlab.ui.control.Image
        menu_Button3             matlab.ui.control.StateButton
        menu_Button2             matlab.ui.control.StateButton
        menu_Separator1          matlab.ui.control.Image
        menu_Button1             matlab.ui.control.StateButton
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
        file_ContextMenu         matlab.ui.container.ContextMenu
        file_TreeNodeDelete      matlab.ui.container.Menu
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        % PROPRIEDADES COMUNS A TODOS OS APPS
        %-----------------------------------------------------------------%
        General
        General_I

        rootFolder

        % Essa propriedade registra o tipo de execução da aplicação, podendo
        % ser: 'built-in', 'desktopApp' ou 'webApp'.
        executionMode
        
        % A função do timer é executada uma única vez após a renderização
        % da figura, lendo arquivos de configuração, iniciando modo de operação
        % paralelo etc. A ideia é deixar o MATLAB focar apenas na criação dos 
        % componentes essenciais da GUI (especificados em "createComponents"), 
        % mostrando a GUI para o usuário o mais rápido possível.
        timerObj

        % Controla a seleção da TabGroup a partir do menu.
        tabGroupController

        % Garante que startup_controller será executada uma única vez.
        rendererFlag = false

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog
        popupContainer

        % Objeto que possibilita integração com o eFiscaliza.
        eFiscalizaObj

        %-----------------------------------------------------------------%
        % PROPRIEDADES ESPECÍFICAS
        %-----------------------------------------------------------------%
        projectData

        rfDataHub
        rfDataHubLOG
        rfDataHubSummary

        % Instância da classe model.measData contendo a organização da
        % informação lida dos arquivos de medida. O cacheData armazena tudo
        % o que foi lido, e o measData apenas aquilo que consta na lista de
        % arquivos.
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
        %-----------------------------------------------------------------%
        function ipcMainJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    % JSBACKDOOR (compCustomization.js)
                    case 'renderer'
                        if ~app.rendererFlag
                            app.rendererFlag = true;
                            startup_Controller(app)
                        end

                    case 'unload'
                        closeFcn(app)

                    case 'BackgroundColorTurnedInvisible'
                        switch event.HTMLEventData
                            case 'SplashScreen'
                                if isvalid(app.popupContainerGrid)
                                    delete(app.popupContainerGrid)
                                end

                            otherwise
                                error('UnexpectedEvent')
                        end
                    
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
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));
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
                                    set(app.menu_Button1, 'Enable', 1, 'Value', 1)                    
                                    menu_mainButtonPushed(app, struct('Source', app.menu_Button1, 'PreviousValue', false))
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
                appUtil.modalWindow(app.UIFigure, 'error', ME.message);            
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
    end

    
    methods (Access = private)
        %-----------------------------------------------------------------%
        % JSBACKDOOR
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            app.jsBackDoor.HTMLSource           = appUtil.jsBackDoorHTMLSource();
            app.jsBackDoor.HTMLEventReceivedFcn = @(~, evt)ipcMainJSEventsHandler(app, evt);
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_AppCustomizations(app, tabIndex)
            persistent customizationStatus
            if isempty(customizationStatus)
                customizationStatus = [false, false, false, false];
            end

            switch tabIndex
                case 0 % STARTUP
                    sendEventToHTMLSource(app.jsBackDoor, 'startup', app.executionMode);
                    app.progressDialog  = ccTools.ProgressDialog(app.jsBackDoor);
                    customizationStatus = [false, false, false, false];

                otherwise
                    if customizationStatus(tabIndex)
                        return
                    end

                    customizationStatus(tabIndex) = true;
                    switch tabIndex
                        case 1 % FILE
                            elToModify = {app.popupContainerGrid,  ...
                                          app.file_Tree,           ...                                          
                                          app.file_Metadata};                % ui.TextView
                            elDataTag  = ui.CustomizationBase.getElementsDataTag(elToModify);

                            if ~isempty(elDataTag)
                                appName = class(app);
                                
                                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', { ...
                                    struct('appName', appName, 'dataTag', elDataTag{1}, 'style', struct('backgroundColor', 'rgba(255,255,255,0.65)')), ...
                                    struct('appName', appName, 'dataTag', elDataTag{2}, 'listener', struct('componentName', 'mainApp.file_Tree', 'keyEvents', {{'Delete', 'Backspace'}})), ...
                                });

                                ui.TextView.startup(app.jsBackDoor, elToModify{3}, appName);
                            end

                        otherwise
                            % Customização dos módulos que são renderizados
                            % nesta figura são controladas pelos próprios
                            % módulos.
                    end
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO DO APP
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

            % Essa propriedade registra o tipo de execução da aplicação, podendo
            % ser: 'built-in', 'desktopApp' ou 'webApp'.
            app.executionMode = appUtil.ExecutionMode(app.UIFigure);
            if ~strcmp(app.executionMode, 'webApp')
                app.FigurePosition.Visible = 1;
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            % Identifica o local deste arquivo .MLAPP, caso se trate das versões 
            % "built-in" ou "webapp", ou do .EXE relacionado, caso se trate da
            % versão executável (neste caso, o ctfroot indicará o local do .MLAPP).
            appName = class.Constants.appName;
            MFilePath = fileparts(mfilename('fullpath'));
            app.rootFolder = appUtil.RootFolder(appName, MFilePath);

            % Customizações...
            jsBackDoor_AppCustomizations(app, 0)
            jsBackDoor_AppCustomizations(app, 1)
            pause(.100)

            startup_ConfigFileRead(app, appName, MFilePath)
            startup_AppProperties(app)
            startup_GUIComponents(app)

            sendEventToHTMLSource(app.jsBackDoor, 'turningBackgroundColorInvisible', struct('componentName', 'SplashScreen', 'componentDataTag', struct(app.SplashScreen).Controller.ViewModel.Id));
            drawnow

            % Por fim, exclui-se o splashscreen.
            if isvalid(app.popupContainerGrid)
                pause(1)
                delete(app.popupContainerGrid)
            end
        end

        %-----------------------------------------------------------------%
        function startup_ConfigFileRead(app, appName, MFilePath)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appUtil.generalSettingsLoad(appName, app.rootFolder);
            if ~isempty(msgWarning)
                appUtil.modalWindow(app.UIFigure, 'error', msgWarning);
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
                    userPaths = appUtil.UserPaths(app.General_I.fileFolder.userPath);
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
        function startup_AppProperties(app)            
            % RFDataHub
            global RFDataHub
            global RFDataHubLog

            app.rfDataHub        = RFDataHub;
            app.rfDataHubLOG     = RFDataHubLog;
            app.rfDataHubSummary = summary(RFDataHub);

            % A coluna "Source" possui agrupamentos da fonte dos dados,
            % decorrente da mesclagem de estações.
            tempSourceList = cellfun(@(x) strsplit(x, ' | '), app.rfDataHubSummary.Source.Categories, 'UniformOutput', false);
            app.rfDataHubSummary.Source.RawCategories = unique(horzcat(tempSourceList{:}))';

            % A coluna "Location" não está sendo corretamente ordenada por
            % conta dos caracteres especiais.
            tempLocationList = textAnalysis.preProcessedData(app.rfDataHubSummary.Location.Categories);
            [app.rfDataHubSummary.Location.CacheCategories, idxSort] = sort(tempLocationList);
            app.rfDataHubSummary.Location.Categories = app.rfDataHubSummary.Location.Categories(idxSort);

            % app.projectData
            app.projectData = model.projectLib(app, app.rootFolder, app.General);
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            % Cria o objeto que conecta o TabGroup com o GraphicMenu.
            app.tabGroupController = tabGroupGraphicMenu(app.menu_Grid, app.TabGroup, app.progressDialog, @app.jsBackDoor_AppCustomizations, '');

            addComponent(app.tabGroupController, "Built-in", "",                          app.menu_Button1, "AlwaysOn", struct('On', 'OpenFile_32Yellow.png',      'Off', 'OpenFile_32White.png'),      matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winMonitoringPlan",  app.menu_Button2, "AlwaysOn", struct('On', 'Detection_32Yellow.png',     'Off', 'Detection_32White.png'),     app.menu_Button1,                    2)
            addComponent(app.tabGroupController, "External", "auxApp.winExternalRequest", app.menu_Button3, "AlwaysOn", struct('On', 'exceptionList_32Yellow.png', 'Off', 'exceptionList_32White.png'), app.menu_Button1,                    3)
            addComponent(app.tabGroupController, "External", "auxApp.winRFDataHub",       app.menu_Button4, "AlwaysOn", struct('On', 'mosaic_32Yellow.png',        'Off', 'mosaic_32White.png'),        app.menu_Button1,                    4)
            addComponent(app.tabGroupController, "External", "auxApp.winConfig",          app.menu_Button5, "AlwaysOn", struct('On', 'Settings_36Yellow.png',      'Off', 'Settings_36White.png'),      app.menu_Button1,                    5)

            DataHubWarningLamp(app)
            app.file_FileSortMethod.Value = app.General.File.sortMethod;
            addStyle(app.file_Tree, uistyle('Interpreter', 'html'))
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
                                                                     'ContextMenu', app.file_ContextMenu);

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
                                                  'ContextMenu', app.file_ContextMenu);
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

            appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.General_I, app.executionMode)
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
            if communicationStatus && strcmp(eFiscalizaVersion, 'eFiscaliza')
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

            appUtil.modalWindow(app.UIFigure, modalWindowIcon, modalWindowMessage);
            app.progressDialog.Visible = 'hidden';
        end

        %------------------------------------------------------------------------%
        function report_sendFilesToSharepoint(app, context)
            % Fucionalidade aplicável apenas ao módulo "PM-RNI"...
            if ~strcmp(context, 'MonitoringPlan')
                return
            end

            % Evita subir por engano, quando no ambiente de desenvolvimento,
            % de arquivos na pasta "POST"
            try
                if ~isdeployed()
                    error('ForceDebugMode')
                end
                outputFolder = app.General.fileFolder.DataHub_POST;
            catch
                outputFolder = app.General.fileFolder.userPath;
            end

            xlsxFilename = getGeneratedDocumentFileName(app.projectData, '.xlsx',    context);
            rawFileList  = getGeneratedDocumentFileName(app.projectData, 'rawFiles', context);
            fileList     = {app.measData.Filename};
            
            try
                fileWriter.MonitoringPlan(xlsxFilename, relatedStationTable, [], app.mainApp.General.(context).FieldValue);

                for ii = 1:numel(rawFileList)
                    rawFilename = rawFileList{ii};
                    [~, rawFilenameIndex] = ismember(rawFilename, fileList);
                    
                    if isfile(rawFilename) && rawFilenameIndex > 0
                        [~, baseFilename] = fileparts(rawFilename);
                        jsonFilename = [baseFilename '.json'];
        
                        copyfile(rawFilename, outputFolder, 'f');                
                        fileWriter.RawFileMetaData(fullfile(outputFolder, jsonFilename), app.measData(rawFilenameIndex));
                    end
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME))
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            try
                % WARNING MESSAGES
                appUtil.disablingWarningMessages()

                % <GUI>
                app.popupContainerGrid.Layout.Row = [1,2];
                app.GridLayout.RowHeight(end) = [];

                app.menu_AppName.Text = sprintf('%s v. %s\n<font style="font-size: 9px;">%s</font>', ...
                    class.Constants.appName, class.Constants.appVersion, class.Constants.appRelease);
                % </GUI>

                appUtil.winPosition(app.UIFigure)
                startup_timerCreation(app)

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
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
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 1, 2);
                if userSelection == "Não"
                    return
                end
            end

            % Aspectos gerais (comum em todos os apps):
            appUtil.beforeDeleteApp(app.progressDialog, app.General_I.fileFolder.tempPath, app.tabGroupController, app.executionMode)
            delete(app)
            
        end

        % Value changed function: menu_Button1, menu_Button2, 
        % ...and 3 other components
        function menu_mainButtonPushed(app, event)

            clickedButton  = event.Source;
            auxAppTag      = clickedButton.Tag;
            inputArguments = auxAppInputArguments(app, auxAppTag);

            openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, inputArguments{:})

        end

        % Image clicked function: AppInfo, FigurePosition
        function menu_ToolbarImageCliced(app, event)
            
            switch event.Source
                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appUtil.winPosition(app.UIFigure)

                case app.AppInfo
                    if isempty(app.AppInfo.Tag)
                        app.progressDialog.Visible = 'visible';
                        app.AppInfo.Tag = util.HtmlTextGenerator.AppInfo(app.General, app.rootFolder, app.executionMode, "popup");
                        app.progressDialog.Visible = 'hidden';
                    end

                    msgInfo = app.AppInfo.Tag;
                    appUtil.modalWindow(app.UIFigure, 'info', msgInfo);
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

        % Menu selected function: file_TreeNodeDelete
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
                 programDataFolder] = appUtil.Path(class.Constants.appName, app.rootFolder);
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
                    appUtil.modalWindow(app.UIFigure, "warning", msgWarning);
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
    
                        d = appUtil.modalWindow(app.UIFigure, "progressdlg", "Em andamento...");
                        [fileFullName, fileName] = util.getFilesFromFolder(filePath);
                end
                updateLastVisitedFolder(app, filePath)
            end

            if isempty(d)
                d = appUtil.modalWindow(app.UIFigure, "progressdlg", "Em andamento...");
            end

            filesInCache = {};
            filesError   = struct('File', {}, 'Error', {});

            for ii = 1:numel(fileFullName)
                d.Message = sprintf('Em andamento a leitura do arquivo %d de %d:<br>• <b>%s</b>', ii, numel(fileFullName), fileName{ii});

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
                appUtil.modalWindow(app.UIFigure, "warning", msgWarning);
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
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'Sim', 'Não'}, 2, 2);

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
                    appUtil.modalWindow(app.UIFigure, 'info', util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'ScalarLocation'));
                    return
                elseif numel(locationList) > 3
                    appUtil.modalWindow(app.UIFigure, 'info', util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'MoreThanThreeLocations'));
                    return
                end

                msgQuestion   = util.HtmlTextGenerator.MergedFiles(app.measData(indexes), 'FinalConfirmationBeforeEdition');
                userSelection = appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, [locationList, {'Cancelar'}], numel(locationList)+1, numel(locationList)+1);

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
            app.GridLayout.RowHeight = {54, '1x', 44};
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

            % Create menu_Grid
            app.menu_Grid = uigridlayout(app.GridLayout);
            app.menu_Grid.ColumnWidth = {22, 74, '1x', 34, 5, 34, 34, 5, 34, 34, '1x', 20, 20, 1, 20, 20};
            app.menu_Grid.RowHeight = {5, 7, 20, 7, 5};
            app.menu_Grid.ColumnSpacing = 5;
            app.menu_Grid.RowSpacing = 0;
            app.menu_Grid.Padding = [10 5 5 5];
            app.menu_Grid.Tag = 'COLORLOCKED';
            app.menu_Grid.Layout.Row = 1;
            app.menu_Grid.Layout.Column = 1;
            app.menu_Grid.BackgroundColor = [0.2 0.2 0.2];

            % Create menu_Button1
            app.menu_Button1 = uibutton(app.menu_Grid, 'state');
            app.menu_Button1.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button1.Tag = 'FILE';
            app.menu_Button1.Tooltip = {'Leitura de arquivos'};
            app.menu_Button1.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'OpenFile_32Yellow.png');
            app.menu_Button1.IconAlignment = 'top';
            app.menu_Button1.Text = '';
            app.menu_Button1.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button1.FontSize = 11;
            app.menu_Button1.Layout.Row = [2 4];
            app.menu_Button1.Layout.Column = 4;
            app.menu_Button1.Value = true;

            % Create menu_Separator1
            app.menu_Separator1 = uiimage(app.menu_Grid);
            app.menu_Separator1.ScaleMethod = 'none';
            app.menu_Separator1.Enable = 'off';
            app.menu_Separator1.Layout.Row = [2 4];
            app.menu_Separator1.Layout.Column = 5;
            app.menu_Separator1.VerticalAlignment = 'bottom';
            app.menu_Separator1.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create menu_Button2
            app.menu_Button2 = uibutton(app.menu_Grid, 'state');
            app.menu_Button2.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button2.Tag = 'MONITORINGPLAN';
            app.menu_Button2.Tooltip = {'PM-RNI'};
            app.menu_Button2.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Detection_32White.png');
            app.menu_Button2.IconAlignment = 'right';
            app.menu_Button2.Text = '';
            app.menu_Button2.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button2.FontSize = 11;
            app.menu_Button2.Layout.Row = [2 4];
            app.menu_Button2.Layout.Column = 6;

            % Create menu_Button3
            app.menu_Button3 = uibutton(app.menu_Grid, 'state');
            app.menu_Button3.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button3.Tag = 'EXTERNALREQUEST';
            app.menu_Button3.Tooltip = {'Demanda externa'};
            app.menu_Button3.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'exceptionList_32White.png');
            app.menu_Button3.IconAlignment = 'right';
            app.menu_Button3.Text = '';
            app.menu_Button3.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button3.FontSize = 11;
            app.menu_Button3.Layout.Row = [2 4];
            app.menu_Button3.Layout.Column = 7;

            % Create menu_Separator2
            app.menu_Separator2 = uiimage(app.menu_Grid);
            app.menu_Separator2.ScaleMethod = 'none';
            app.menu_Separator2.Enable = 'off';
            app.menu_Separator2.Layout.Row = [2 4];
            app.menu_Separator2.Layout.Column = 8;
            app.menu_Separator2.VerticalAlignment = 'bottom';
            app.menu_Separator2.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create menu_Button4
            app.menu_Button4 = uibutton(app.menu_Grid, 'state');
            app.menu_Button4.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button4.Tag = 'RFDATAHUB';
            app.menu_Button4.Tooltip = {'RFDataHub'};
            app.menu_Button4.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'mosaic_32White.png');
            app.menu_Button4.IconAlignment = 'right';
            app.menu_Button4.Text = '';
            app.menu_Button4.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button4.FontSize = 11;
            app.menu_Button4.Layout.Row = [2 4];
            app.menu_Button4.Layout.Column = 9;

            % Create menu_Button5
            app.menu_Button5 = uibutton(app.menu_Grid, 'state');
            app.menu_Button5.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button5.Tag = 'CONFIG';
            app.menu_Button5.Tooltip = {'Configurações gerais'};
            app.menu_Button5.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Settings_36White.png');
            app.menu_Button5.IconAlignment = 'right';
            app.menu_Button5.Text = '';
            app.menu_Button5.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button5.FontSize = 11;
            app.menu_Button5.Layout.Row = [2 4];
            app.menu_Button5.Layout.Column = 10;

            % Create menu_AppIcon
            app.menu_AppIcon = uiimage(app.menu_Grid);
            app.menu_AppIcon.Layout.Row = [1 5];
            app.menu_AppIcon.Layout.Column = 1;
            app.menu_AppIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'icon_48.png');

            % Create menu_AppName
            app.menu_AppName = uilabel(app.menu_Grid);
            app.menu_AppName.WordWrap = 'on';
            app.menu_AppName.FontSize = 11;
            app.menu_AppName.FontColor = [1 1 1];
            app.menu_AppName.Layout.Row = [1 5];
            app.menu_AppName.Layout.Column = [2 3];
            app.menu_AppName.Interpreter = 'html';
            app.menu_AppName.Text = {'monitorRNI v. 1.0.0'; '<font style="font-size: 9px;">R2024a</font>'};

            % Create AppInfo
            app.AppInfo = uiimage(app.menu_Grid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.AppInfo.Layout.Row = 3;
            app.AppInfo.Layout.Column = 16;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Dots_32White.png');

            % Create FigurePosition
            app.FigurePosition = uiimage(app.menu_Grid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.FigurePosition.Visible = 'off';
            app.FigurePosition.Layout.Row = 3;
            app.FigurePosition.Layout.Column = 15;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'layout1_32White.png');

            % Create DataHubLamp
            app.DataHubLamp = uiimage(app.menu_Grid);
            app.DataHubLamp.Visible = 'off';
            app.DataHubLamp.Tooltip = {'Pendente mapear o Sharepoint'};
            app.DataHubLamp.Layout.Row = 3;
            app.DataHubLamp.Layout.Column = [13 14];
            app.DataHubLamp.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'red-circle-blink.gif');

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.menu_Grid);
            app.jsBackDoor.Layout.Row = 3;
            app.jsBackDoor.Layout.Column = 12;

            % Create popupContainerGrid
            app.popupContainerGrid = uigridlayout(app.GridLayout);
            app.popupContainerGrid.ColumnWidth = {'1x', 880, '1x'};
            app.popupContainerGrid.RowHeight = {'1x', 300, '1x'};
            app.popupContainerGrid.Layout.Row = 3;
            app.popupContainerGrid.Layout.Column = 1;
            app.popupContainerGrid.BackgroundColor = [1 1 1];

            % Create SplashScreen
            app.SplashScreen = uiimage(app.popupContainerGrid);
            app.SplashScreen.Layout.Row = 2;
            app.SplashScreen.Layout.Column = 2;
            app.SplashScreen.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'SplashScreen.gif');

            % Create file_ContextMenu
            app.file_ContextMenu = uicontextmenu(app.UIFigure);
            app.file_ContextMenu.Tag = 'winMonitorRNI';

            % Create file_TreeNodeDelete
            app.file_TreeNodeDelete = uimenu(app.file_ContextMenu);
            app.file_TreeNodeDelete.MenuSelectedFcn = createCallbackFcn(app, @file_ContextMenu_delTreeNodeSelected, true);
            app.file_TreeNodeDelete.Text = 'Excluir';

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
