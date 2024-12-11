classdef winRNI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        GridLayout            matlab.ui.container.GridLayout
        popupContainerGrid    matlab.ui.container.GridLayout
        SplashScreen          matlab.ui.control.Image
        menu_Grid             matlab.ui.container.GridLayout
        dockModule_Undock     matlab.ui.control.Image
        dockModule_Close      matlab.ui.control.Image
        AppInfo               matlab.ui.control.Image
        FigurePosition        matlab.ui.control.Image
        jsBackDoor            matlab.ui.control.HTML
        menu_Button4          matlab.ui.control.StateButton
        menu_Separator2       matlab.ui.control.Image
        menu_Button3          matlab.ui.control.StateButton
        menu_Button2          matlab.ui.control.StateButton
        menu_Separator1       matlab.ui.control.Image
        menu_Button1          matlab.ui.control.StateButton
        TabGroup              matlab.ui.container.TabGroup
        Tab1_File             matlab.ui.container.Tab
        file_Grid             matlab.ui.container.GridLayout
        file_panelGrid        matlab.ui.container.GridLayout
        file_MetadataPanel    matlab.ui.container.Panel
        file_MetadataGrid     matlab.ui.container.GridLayout
        file_Metadata         matlab.ui.control.HTML
        file_MetadataLabel    matlab.ui.control.Label
        file_docGrid          matlab.ui.container.GridLayout
        file_Tree             matlab.ui.container.Tree
        file_TreeLabel        matlab.ui.control.Label
        file_TitleGrid        matlab.ui.container.GridLayout
        file_Title            matlab.ui.control.Label
        file_TitleIcon        matlab.ui.control.Image
        file_toolGrid         matlab.ui.container.GridLayout
        file_OpenFileButton   matlab.ui.control.Image
        Tab2_MonitoringPlan   matlab.ui.container.Tab
        Tab3_ExternalRequest  matlab.ui.container.Tab
        Tab4_Config           matlab.ui.container.Tab
        file_ContextMenu      matlab.ui.container.ContextMenu
        file_TreeNodeDelete   matlab.ui.container.Menu
    end

    
    properties (Access = public)
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

        % O MATLAB não renderiza alguns dos componentes de abas (do TabGroup) 
        % não visíveis. E a customização de componentes, usando a lib ccTools, 
        % somente é possível após a sua renderização. Controla-se a aplicação 
        % da customizaçao por meio dessa propriedade jsBackDoorFlag.
        tabGroupController
        jsBackDoorFlag = {true, ...
                          true, ...
                          true, ...
                          true};

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog

        rfDataHub
        rfDataHubLOG
        rfDataHubSummary

        %-----------------------------------------------------------------%
        % ESPECIFICIDADES
        %-----------------------------------------------------------------%
        % Instância da classe class.measData contendo a organização da
        % informação lida dos arquivos de medida. O cacheData armazena tudo
        % o que foi lido, e o measData apenas aquilo que consta na lista de
        % arquivos.
        cacheData = class.measData.empty
        measData  = class.measData.empty

        % Dados das estações do Plano Anual de RNI:
        % (pendente criar possibilidade de atualizar planilha, no módulo
        % auxApp.winConfig)
        stationTable
    end

    
    methods (Access = private)
        %-----------------------------------------------------------------%
        % JSBACKDOOR
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            app.jsBackDoor.HTMLSource           = ccTools.fcn.jsBackDoorHTMLSource();
            app.jsBackDoor.HTMLEventReceivedFcn = @(~, evt)jsBackDoor_Listener(app, evt);
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Listener(app, event)
            switch event.HTMLEventName
                case 'credentialDialog'
                    fiscalizaLibConnection.report_Connect(app, event.HTMLEventData, 'OpenConnection')

                case 'BackgroundColorTurnedInvisible'
                    switch event.HTMLEventData
                        case 'SplashScreen'
                            if isvalid(app.SplashScreen)
                                delete(app.SplashScreen)
                                app.popupContainerGrid.Visible = 0;
                            end
                        otherwise
                            % ...
                    end

                case 'app.file_Tree'
                    file_ContextMenu_delTreeNodeSelected(app)
            end
            drawnow
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app, tabIndex)
            % O menu gráfico controla, programaticamente, qual das abas de
            % app.ControlTabGroup estará visível. 

            % Lembrando que o MATLAB renderiza em tela apenas as abas visíveis.
            % Por isso as customizações de abas e suas subabas somente é possível 
            % após a renderização da aba.
            switch tabIndex
                case 0 % STARTUP
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

                    ccTools.compCustomizationV2(app.jsBackDoor, app.popupContainerGrid, 'backgroundColor', 'rgba(255,255,255,0.65)')

                otherwise
                    if any(app.jsBackDoorFlag{tabIndex})
                        app.jsBackDoorFlag{tabIndex} = false;

                        switch tabIndex
                            case 1 % FILE
                                app.file_Tree.UserData = struct(app.file_Tree).Controller.ViewModel.Id;
                                sendEventToHTMLSource(app.jsBackDoor, 'addKeyDownListener', struct('componentName', 'app.file_Tree', 'componentDataTag', app.file_Tree.UserData, 'keyEvents', "Delete"))

                            otherwise
                                % ...
                        end
                    end
            end
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

                drawnow
    
                app.executionMode = appUtil.ExecutionMode(app.UIFigure);
                switch app.executionMode
                    case 'webApp'
                        % ...
    
                    otherwise
                        % Configura o tamanho mínimo da janela.
                        app.FigurePosition.Visible = 1;
                        appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
                end
    
                appName           = class.Constants.appName;
                MFilePath         = fileparts(mfilename('fullpath'));
                app.rootFolder    = appUtil.RootFolder(appName, MFilePath);
                
                % Customiza as aspectos estéticos de alguns dos componentes da GUI 
                % (diretamente em JS).
                jsBackDoor_Customizations(app, 0)
                jsBackDoor_Customizations(app, 1)
    
                % Leitura do arquivo "GeneralSettings.json".
                startup_ConfigFileRead(app)
                startup_AppProperties(app)
                startup_GUIComponents(app)
                
                % Torna visível o container do auxApp.popupContainer, forçando
                % a exclusão do SplashScreen.
                sendEventToHTMLSource(app.jsBackDoor, 'turningBackgroundColorInvisible', struct('componentName', 'SplashScreen', 'componentDataTag', struct(app.SplashScreen).Controller.ViewModel.Id));
                drawnow
    
                % Força a exclusão do SplashScreen.
                if isvalid(app.SplashScreen)
                    pause(1)
                    delete(app.SplashScreen)
                    app.popupContainerGrid.Visible = 0;
                end
            end
        end

        %-----------------------------------------------------------------%
        function startup_ConfigFileRead(app)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appUtil.generalSettingsLoad(class.Constants.appName, app.rootFolder);
            if ~isempty(msgWarning)
                appUtil.modalWindow(app.UIFigure, 'error', msgWarning);
            end

            % Para criação de arquivos temporários, cria-se uma pasta da 
            % sessão.
            tempDir = tempname;
            mkdir(tempDir)
            app.General_I.fileFolder.tempPath = tempDir;

            switch app.executionMode
                case 'webApp'
                    % Força a exclusão do SplashScreen do MATLAB WebDesigner.
                    sendEventToHTMLSource(app.jsBackDoor, "delProgressDialog");

                    % Webapp também não suporta outras janelas, de forma que os 
                    % módulos auxiliares devem ser abertos na própria janela
                    % do appAnalise.
                    app.dockModule_Undock.Visible     = 0;

                    app.General_I.operationMode.Debug = false;
                    app.General_I.operationMode.Dock  = true;
                    
                    % A pasta do usuário não é configurável, mas obtida por 
                    % meio de chamada a uiputfile. 
                    app.General_I.fileFolder.userPath = tempDir;

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

            app.General            = app.General_I;
            app.General.AppVersion = fcn.envVersion(app.rootFolder, 'full');
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            global RFDataHub
            global RFDataHubLog
            
            app.rfDataHub = RFDataHub;
            app.rfDataHubLOG = RFDataHubLog;
            
            % Contorna erro da função inROI, que retorna como se todos os
            % pontos estivessem internos ao ROI, quando as coordenadas
            % estão em float32. No float64 isso não acontece... aberto BUG
            % na Mathworks, que indicou estar ciente.
            app.rfDataHub.Latitude    = double(app.rfDataHub.Latitude);
            app.rfDataHub.Longitude   = double(app.rfDataHub.Longitude);

            % app.rfDataHubSummary
            app.rfDataHubSummary = summary(RFDataHub);
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            % Cria o objeto que conecta o TabGroup com o GraphicMenu.
            app.tabGroupController = tabGroupGraphicMenu(app.menu_Grid, app.TabGroup, app.progressDialog, @app.jsBackDoor_Customizations, '');

            addComponent(app.tabGroupController, "Built-in", "",                          app.menu_Button1, "AlwaysOn", struct('On', 'OpenFile_32Yellow.png',         'Off', 'OpenFile_32White.png'),          matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winMonitoringPlan",  app.menu_Button2, "AlwaysOn", struct('On', 'DriveTestDensity_32Yellow.png', 'Off', 'DriveTestDensity_32White.png'),  app.menu_Button1,                    2)
            addComponent(app.tabGroupController, "External", "auxApp.winExternalRequest", app.menu_Button3, "AlwaysOn", struct('On', 'Report_32Yellow.png',           'Off', 'Report_32White.png'),            app.menu_Button1,                    3)
            addComponent(app.tabGroupController, "External", "auxApp.winConfig",          app.menu_Button4, "AlwaysOn", struct('On', 'Settings_36Yellow.png',         'Off', 'Settings_36White.png'),          app.menu_Button1,                    4)
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        function inputArguments = menu_auxAppInputArguments(app, auxAppName)
            arguments
                app
                auxAppName char {mustBeMember(auxAppName, {'FILE', 'MONITORINGPLAN', 'EXTERNALREQUEST', 'CONFIG'})}
            end

            switch auxAppName
                case {'FILE', 'MONITORINGPLAN', 'EXTERNALREQUEST', 'CONFIG'}
                    inputArguments = {app};
            end
        end

        %-----------------------------------------------------------------%
        function file_TreeBuilding(app)
            delete(app.file_Tree.Children);

            for ii = 1:numel(app.measData)
                uitreenode(app.file_Tree, 'Text',        app.measData(ii).Filename, ...
                                          'NodeData',    ii,                        ...
                                          'ContextMenu', app.file_ContextMenu);
            end

            if ~isempty(app.measData)
                app.file_Tree.SelectedNodes = app.file_Tree.Children(1);
                file_TreeSelectionChanged(app)

                app.menu_Button2.Enable = 1;
                app.menu_Button3.Enable = 1;
            else
                app.file_Metadata.HTMLSource = ' ';
                app.menu_Button2.Enable = 0;
                app.menu_Button3.Enable = 0;
            end
        end

        %-----------------------------------------------------------------%
        function misc_updateLastVisitedFolder(app, filePath)
            app.General_I.fileFolder.lastVisited = filePath;
            app.General.fileFolder.lastVisited   = filePath;

            appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.General_I, app.executionMode)
        end
    end


    methods (Access = public)
        %-----------------------------------------------------------------%
        function appBackDoor(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    case {'auxApp.winMonitoringPlan',  'auxApp.winMonitoringPlan_exported',  ...
                          'auxApp.winExternalRequest', 'auxApp.winExternalRequest_exported', ...
                          'auxApp.winConfig',          'auxApp.winConfig_exported'}

                        switch operationType
                            case 'closeFcn'
                                auxAppTag = varargin{1};
                                closeModule(app.tabGroupController, auxAppTag, app.General)

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
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            
            try
                % WARNING MESSAGES
                appUtil.disablingWarningMessages()

                % <GUI>
                app.UIFigure.Position(4) = 660;
                app.popupContainerGrid.Layout.Row = [1,2];
                app.GridLayout.RowHeight(end) = [];
                % </GUI>

                appUtil.winPosition(app.UIFigure)
                jsBackDoor_Initialization(app)
                startup_timerCreation(app)

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end

        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            % PROGRESS DIALOG
            delete(app.progressDialog)

            % DELETE TEMP FILES
            rmdir(app.General_I.fileFolder.tempPath, 's');

            % DELETE APPS
            if isdeployed
                delete(findall(groot, 'Type', 'Figure'))
            else
                delete(app.tabGroupController)                
            end

            % MATLAB RUNTIME
            % Ao fechar um webapp, o MATLAB WebServer demora uns 10 segundos para
            % fechar o Runtime que suportava a sessão do webapp. Dessa forma, a 
            % liberação do recurso, que ocorre com a inicialização de uma nova 
            % sessão do Runtime, fica comprometida.
            appUtil.killingMATLABRuntime(app.executionMode)

            delete(app)
            
        end

        % Value changed function: menu_Button1, menu_Button2, 
        % ...and 2 other components
        function menu_mainButtonPushed(app, event)

            clickedButton  = event.Source;
            auxAppTag      = clickedButton.Tag;
            inputArguments = menu_auxAppInputArguments(app, auxAppTag);

            openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, inputArguments{:})

        end

        % Image clicked function: AppInfo, FigurePosition
        function menu_ToolbarImageCliced(app, event)
            
            focus(app.jsBackDoor)

            switch event.Source
                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appUtil.winPosition(app.UIFigure)

                case app.AppInfo
                    if isempty(app.AppInfo.Tag)
                        app.progressDialog.Visible = 'visible';
                        app.AppInfo.Tag = fcn.htmlCode_appInfo(app.General, app.rootFolder, app.executionMode);
                        app.progressDialog.Visible = 'hidden';
                    end

                    msgInfo = app.AppInfo.Tag;
                    appUtil.modalWindow(app.UIFigure, 'info', msgInfo);
            end

        end

        % Image clicked function: dockModule_Close, dockModule_Undock
        function menu_DockButtonPushed(app, event)
            
            clickedButton = findobj(app.menu_Grid, 'Type', 'uistatebutton', 'Value', true);
            auxAppTag     = clickedButton.Tag;

            switch event.Source
                case app.dockModule_Undock
                    appGeneral = app.General;
                    appGeneral.operationMode.Dock = false;

                    inputArguments = menu_auxAppInputArguments(app, auxAppTag);
                    closeModule(app.tabGroupController, auxAppTag, app.General)
                    openModule(app.tabGroupController, clickedButton, false, appGeneral, inputArguments{:})

                case app.dockModule_Close
                    closeModule(app.tabGroupController, auxAppTag, app.General)
            end

        end

        % Selection changed function: file_Tree
        function file_TreeSelectionChanged(app, event)
            
            % !! PONTO DE EVOLUÇÃO !!
            % Criar um HTML destacando informações relevantes do arquivo -
            % tamanho, por exemplo - e da campanha de medição - sensor,
            % período, limites, nível máximo etc.
            % !! PONTO DE EVOLUÇÃO !!

            idx = app.file_Tree.SelectedNodes.NodeData;            
            app.file_Metadata.HTMLSource = sprintf(['<p style="font-family: Helvetica, Arial, sans-serif; font-size: 11; text-align: justify; ' ...
                                                    'line-height: 12px; margin: 5px; word-break: break-all;">Arquivo: %s<br>Sensor: %s<br>'     ...
                                                    'Localidade: %s</p>'], app.measData(idx).Filename, app.measData(idx).Sensor, app.measData(idx).Location);
            
        end

        % Menu selected function: file_TreeNodeDelete
        function file_ContextMenu_delTreeNodeSelected(app, event)
            
            if ~isempty(app.file_Tree.SelectedNodes)
                idx = app.file_Tree.SelectedNodes.NodeData;
                app.measData(idx) = [];
                file_TreeBuilding(app)
            end

        end

        % Image clicked function: file_OpenFileButton
        function file_OpenFileButtonImageClicked(app, event)

            [fileName, filePath] = uigetfile({'*.txt';'*.csv';'*.mat';'*.*'}, ...
                                              '', app.General.fileFolder.lastVisited, 'MultiSelect', 'on');
            figure(app.UIFigure)

            if isequal(fileName, 0)
                return
            elseif ~iscell(fileName)
                fileName = {fileName};
            end
            misc_updateLastVisitedFolder(app, filePath)            

            % !! PONTO DE EVOLUÇÃO !!
            % O progressdialog deve ser único. E não ser criado por arquivo... 
            % as coisas relacionadas à GUI devem, preferencialmente, permanecer 
            % no MLAPP.
            % !! PONTO DE EVOLUÇÃO !!
            
            fileFullName = fullfile(filePath, fileName);
            filesInCache = {};

            for ii = 1:numel(fileFullName)
                % (a) Verifica se arquivo já foi lido, comparando o seu
                %     nome com a variável app.cacheData.
                [~, idxCache] = ismember(fileFullName{ii}, {app.cacheData.Filename});
                if ~idxCache
                    % Extrai do arquivo a informação sobre o tipo de sonda que gerou o arquivo de medição
                    Type_Meas_Probes = fcn.TypeMeasProbe(app, fileFullName{ii});
    
                    % Obtém todas os dados relavantes dos arquivos das medições de RNI
                    app.cacheData(end+1) = fcn.ReadFile_Meas_Probes(app, Type_Meas_Probes, fileFullName{ii}, ii, numel(fileFullName));
                    idxCache = numel(app.cacheData);
                end

                % (b) Verifica se arquivo já está ativo, comparando o seu
                %     nome com a variável app.measData.
                [~, idxFile] = ismember(fileFullName{ii}, {app.measData.Filename});
                if ~idxFile
                    app.measData(end+1) = app.cacheData(idxCache);
                else
                    filesInCache{end+1} = fileFullName{ii};
                end
            end

            if ~isempty(filesInCache)
                msgWarning = sprintf('Arquivos já lidos:\n%s', textFormatGUI.cellstr2Bullets(filesInCache));
                appUtil.modalWindow(app.UIFigure, "warning", msgWarning);
            end
            
            % Atualiza app.file_Tree.
            file_TreeBuilding(app)

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
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'RNI';
            app.UIFigure.Icon = 'icon_48.png';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {44, '1x', 44};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

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
            app.file_Grid.ColumnWidth = {'1x', 325};
            app.file_Grid.RowHeight = {'1x', 34};
            app.file_Grid.RowSpacing = 5;
            app.file_Grid.Padding = [0 0 0 24];
            app.file_Grid.BackgroundColor = [1 1 1];

            % Create file_toolGrid
            app.file_toolGrid = uigridlayout(app.file_Grid);
            app.file_toolGrid.ColumnWidth = {22, '1x'};
            app.file_toolGrid.RowHeight = {'1x', 17, '1x'};
            app.file_toolGrid.ColumnSpacing = 5;
            app.file_toolGrid.RowSpacing = 0;
            app.file_toolGrid.Padding = [5 6 5 6];
            app.file_toolGrid.Layout.Row = 2;
            app.file_toolGrid.Layout.Column = [1 2];

            % Create file_OpenFileButton
            app.file_OpenFileButton = uiimage(app.file_toolGrid);
            app.file_OpenFileButton.ScaleMethod = 'none';
            app.file_OpenFileButton.ImageClickedFcn = createCallbackFcn(app, @file_OpenFileButtonImageClicked, true);
            app.file_OpenFileButton.Tooltip = {'Seleciona arquivos'};
            app.file_OpenFileButton.Layout.Row = 2;
            app.file_OpenFileButton.Layout.Column = 1;
            app.file_OpenFileButton.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Import_16.png');

            % Create file_docGrid
            app.file_docGrid = uigridlayout(app.file_Grid);
            app.file_docGrid.ColumnWidth = {320, '1x'};
            app.file_docGrid.RowHeight = {22, 22, '1x'};
            app.file_docGrid.ColumnSpacing = 5;
            app.file_docGrid.RowSpacing = 5;
            app.file_docGrid.Padding = [5 0 0 0];
            app.file_docGrid.Layout.Row = 1;
            app.file_docGrid.Layout.Column = 1;
            app.file_docGrid.BackgroundColor = [1 1 1];

            % Create file_TitleGrid
            app.file_TitleGrid = uigridlayout(app.file_docGrid);
            app.file_TitleGrid.ColumnWidth = {18, '1x'};
            app.file_TitleGrid.RowHeight = {'1x'};
            app.file_TitleGrid.ColumnSpacing = 5;
            app.file_TitleGrid.RowSpacing = 5;
            app.file_TitleGrid.Padding = [2 2 2 2];
            app.file_TitleGrid.Tag = 'COLORLOCKED';
            app.file_TitleGrid.Layout.Row = 1;
            app.file_TitleGrid.Layout.Column = 1;
            app.file_TitleGrid.BackgroundColor = [0.749 0.749 0.749];

            % Create file_TitleIcon
            app.file_TitleIcon = uiimage(app.file_TitleGrid);
            app.file_TitleIcon.Layout.Row = 1;
            app.file_TitleIcon.Layout.Column = 1;
            app.file_TitleIcon.HorizontalAlignment = 'left';
            app.file_TitleIcon.ImageSource = fullfile(pathToMLAPP, 'Icons', 'addFiles_32.png');

            % Create file_Title
            app.file_Title = uilabel(app.file_TitleGrid);
            app.file_Title.FontSize = 11;
            app.file_Title.Layout.Row = 1;
            app.file_Title.Layout.Column = 2;
            app.file_Title.Text = 'ARQUIVOS';

            % Create file_TreeLabel
            app.file_TreeLabel = uilabel(app.file_docGrid);
            app.file_TreeLabel.VerticalAlignment = 'bottom';
            app.file_TreeLabel.FontSize = 10;
            app.file_TreeLabel.Layout.Row = 2;
            app.file_TreeLabel.Layout.Column = 1;
            app.file_TreeLabel.Text = 'LISTA DE ARQUIVOS';

            % Create file_Tree
            app.file_Tree = uitree(app.file_docGrid);
            app.file_Tree.SelectionChangedFcn = createCallbackFcn(app, @file_TreeSelectionChanged, true);
            app.file_Tree.FontSize = 10;
            app.file_Tree.Layout.Row = 3;
            app.file_Tree.Layout.Column = [1 2];

            % Create file_panelGrid
            app.file_panelGrid = uigridlayout(app.file_Grid);
            app.file_panelGrid.ColumnWidth = {'1x', 16};
            app.file_panelGrid.RowHeight = {22, 22, '1x'};
            app.file_panelGrid.ColumnSpacing = 5;
            app.file_panelGrid.RowSpacing = 5;
            app.file_panelGrid.Padding = [0 0 5 0];
            app.file_panelGrid.Layout.Row = 1;
            app.file_panelGrid.Layout.Column = 2;
            app.file_panelGrid.BackgroundColor = [1 1 1];

            % Create file_MetadataLabel
            app.file_MetadataLabel = uilabel(app.file_panelGrid);
            app.file_MetadataLabel.VerticalAlignment = 'bottom';
            app.file_MetadataLabel.FontSize = 10;
            app.file_MetadataLabel.Layout.Row = 2;
            app.file_MetadataLabel.Layout.Column = 1;
            app.file_MetadataLabel.Text = 'METADADOS';

            % Create file_MetadataPanel
            app.file_MetadataPanel = uipanel(app.file_panelGrid);
            app.file_MetadataPanel.Layout.Row = 3;
            app.file_MetadataPanel.Layout.Column = [1 2];

            % Create file_MetadataGrid
            app.file_MetadataGrid = uigridlayout(app.file_MetadataPanel);
            app.file_MetadataGrid.ColumnWidth = {'1x'};
            app.file_MetadataGrid.RowHeight = {'1x'};
            app.file_MetadataGrid.Padding = [0 0 0 0];
            app.file_MetadataGrid.BackgroundColor = [1 1 1];

            % Create file_Metadata
            app.file_Metadata = uihtml(app.file_MetadataGrid);
            app.file_Metadata.HTMLSource = ' ';
            app.file_Metadata.Layout.Row = 1;
            app.file_Metadata.Layout.Column = 1;

            % Create Tab2_MonitoringPlan
            app.Tab2_MonitoringPlan = uitab(app.TabGroup);
            app.Tab2_MonitoringPlan.AutoResizeChildren = 'off';
            app.Tab2_MonitoringPlan.Title = 'MONITORINGPLAN';

            % Create Tab3_ExternalRequest
            app.Tab3_ExternalRequest = uitab(app.TabGroup);
            app.Tab3_ExternalRequest.Title = 'EXTERNALREQUEST';

            % Create Tab4_Config
            app.Tab4_Config = uitab(app.TabGroup);
            app.Tab4_Config.Title = 'CONFIG';

            % Create menu_Grid
            app.menu_Grid = uigridlayout(app.GridLayout);
            app.menu_Grid.ColumnWidth = {28, 5, 28, 28, 5, 28, '1x', 20, 20, 20, 0, 0};
            app.menu_Grid.RowHeight = {7, '1x', 7};
            app.menu_Grid.ColumnSpacing = 5;
            app.menu_Grid.RowSpacing = 0;
            app.menu_Grid.Padding = [5 5 5 5];
            app.menu_Grid.Tag = 'COLORLOCKED';
            app.menu_Grid.Layout.Row = 1;
            app.menu_Grid.Layout.Column = 1;
            app.menu_Grid.BackgroundColor = [0.2 0.2 0.2];

            % Create menu_Button1
            app.menu_Button1 = uibutton(app.menu_Grid, 'state');
            app.menu_Button1.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button1.Tag = 'FILE';
            app.menu_Button1.Tooltip = {'Leitura de arquivos'};
            app.menu_Button1.Icon = fullfile(pathToMLAPP, 'Icons', 'OpenFile_32Yellow.png');
            app.menu_Button1.IconAlignment = 'top';
            app.menu_Button1.Text = '';
            app.menu_Button1.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button1.FontSize = 11;
            app.menu_Button1.Layout.Row = [1 3];
            app.menu_Button1.Layout.Column = 1;
            app.menu_Button1.Value = true;

            % Create menu_Separator1
            app.menu_Separator1 = uiimage(app.menu_Grid);
            app.menu_Separator1.ScaleMethod = 'fill';
            app.menu_Separator1.Enable = 'off';
            app.menu_Separator1.Layout.Row = [1 3];
            app.menu_Separator1.Layout.Column = 2;
            app.menu_Separator1.VerticalAlignment = 'bottom';
            app.menu_Separator1.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV_White.png');

            % Create menu_Button2
            app.menu_Button2 = uibutton(app.menu_Grid, 'state');
            app.menu_Button2.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button2.Tag = 'MONITORINGPLAN';
            app.menu_Button2.Enable = 'off';
            app.menu_Button2.Tooltip = {'PM-RNI'};
            app.menu_Button2.Icon = fullfile(pathToMLAPP, 'Icons', 'DriveTestDensity_32White.png');
            app.menu_Button2.IconAlignment = 'right';
            app.menu_Button2.Text = '';
            app.menu_Button2.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button2.FontSize = 11;
            app.menu_Button2.Layout.Row = [1 3];
            app.menu_Button2.Layout.Column = 3;

            % Create menu_Button3
            app.menu_Button3 = uibutton(app.menu_Grid, 'state');
            app.menu_Button3.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button3.Tag = 'EXTERNALREQUEST';
            app.menu_Button3.Enable = 'off';
            app.menu_Button3.Tooltip = {'Demanda externa'};
            app.menu_Button3.Icon = fullfile(pathToMLAPP, 'Icons', 'Report_32White.png');
            app.menu_Button3.IconAlignment = 'right';
            app.menu_Button3.Text = '';
            app.menu_Button3.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button3.FontSize = 11;
            app.menu_Button3.Layout.Row = [1 3];
            app.menu_Button3.Layout.Column = 4;

            % Create menu_Separator2
            app.menu_Separator2 = uiimage(app.menu_Grid);
            app.menu_Separator2.ScaleMethod = 'fill';
            app.menu_Separator2.Enable = 'off';
            app.menu_Separator2.Layout.Row = [1 3];
            app.menu_Separator2.Layout.Column = 5;
            app.menu_Separator2.VerticalAlignment = 'bottom';
            app.menu_Separator2.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV_White.png');

            % Create menu_Button4
            app.menu_Button4 = uibutton(app.menu_Grid, 'state');
            app.menu_Button4.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button4.Tag = 'CONFIG';
            app.menu_Button4.Tooltip = {'Configurações gerais'};
            app.menu_Button4.Icon = fullfile(pathToMLAPP, 'Icons', 'Settings_36White.png');
            app.menu_Button4.IconAlignment = 'right';
            app.menu_Button4.Text = '';
            app.menu_Button4.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button4.FontSize = 11;
            app.menu_Button4.Layout.Row = [1 3];
            app.menu_Button4.Layout.Column = 6;

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.menu_Grid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 8;

            % Create FigurePosition
            app.FigurePosition = uiimage(app.menu_Grid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.FigurePosition.Visible = 'off';
            app.FigurePosition.Layout.Row = 2;
            app.FigurePosition.Layout.Column = 9;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layout1_32White.png');

            % Create AppInfo
            app.AppInfo = uiimage(app.menu_Grid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.AppInfo.Layout.Row = 2;
            app.AppInfo.Layout.Column = 10;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Dots_32White.png');

            % Create dockModule_Close
            app.dockModule_Close = uiimage(app.menu_Grid);
            app.dockModule_Close.ScaleMethod = 'none';
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Close.Tag = 'DRIVETEST';
            app.dockModule_Close.Tooltip = {'Fecha módulo'};
            app.dockModule_Close.Layout.Row = 2;
            app.dockModule_Close.Layout.Column = 12;
            app.dockModule_Close.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Delete_12SVG_white.svg');

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.menu_Grid);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Undock.Tag = 'DRIVETEST';
            app.dockModule_Undock.Tooltip = {'Reabre módulo em outra janela'};
            app.dockModule_Undock.Layout.Row = 2;
            app.dockModule_Undock.Layout.Column = 11;
            app.dockModule_Undock.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Undock_18White.png');

            % Create popupContainerGrid
            app.popupContainerGrid = uigridlayout(app.GridLayout);
            app.popupContainerGrid.ColumnWidth = {'1x', 880, '1x'};
            app.popupContainerGrid.RowHeight = {'1x', 300, '1x'};
            app.popupContainerGrid.Padding = [10 31 10 10];
            app.popupContainerGrid.Layout.Row = 3;
            app.popupContainerGrid.Layout.Column = 1;
            app.popupContainerGrid.BackgroundColor = [1 1 1];

            % Create SplashScreen
            app.SplashScreen = uiimage(app.popupContainerGrid);
            app.SplashScreen.Layout.Row = 2;
            app.SplashScreen.Layout.Column = 2;
            app.SplashScreen.ImageSource = fullfile(pathToMLAPP, 'Icons', 'SplashScreen.gif');

            % Create file_ContextMenu
            app.file_ContextMenu = uicontextmenu(app.UIFigure);

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
        function app = winRNI_exported(varargin)

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
