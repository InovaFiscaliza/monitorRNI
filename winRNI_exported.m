classdef winRNI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        Button_AddPoints                matlab.ui.control.Button
        GridLayout                      matlab.ui.container.GridLayout
        popupContainerGrid              matlab.ui.container.GridLayout
        SplashScreen                    matlab.ui.control.Image
        toolGrid                        matlab.ui.container.GridLayout
        PlotarKMLButton                 matlab.ui.control.Button
        CalcularMaioresnveisButton      matlab.ui.control.Button
        ImageOpenFile                   matlab.ui.control.Image
        AppInfo                         matlab.ui.control.Image
        FigurePosition                  matlab.ui.control.Image
        tool_tableNRows                 matlab.ui.control.Label
        jsBackDoor                      matlab.ui.control.HTML
        GravarButton                    matlab.ui.control.Image
        tool_Separator                  matlab.ui.control.Image
        tool_RFLinkButton               matlab.ui.control.Image
        tool_TableVisibility            matlab.ui.control.Image
        tool_ControlPanelVisibility     matlab.ui.control.Image
        UITable                         matlab.ui.control.Table
        axesToolbarGrid                 matlab.ui.container.GridLayout
        axesTool_RegionZoom             matlab.ui.control.Image
        axesTool_RestoreView            matlab.ui.control.Image
        plotPanel                       matlab.ui.container.Panel
        ControlTabGrid                  matlab.ui.container.GridLayout
        menu_MainGrid                   matlab.ui.container.GridLayout
        menu_Button5Grid                matlab.ui.container.GridLayout
        menu_Button5Icon                matlab.ui.control.Image
        menu_Button5Label               matlab.ui.control.Label
        menu_Button4Grid                matlab.ui.container.GridLayout
        menu_Button4Icon                matlab.ui.control.Image
        menu_Button4Label               matlab.ui.control.Label
        menu_Button3Grid                matlab.ui.container.GridLayout
        menu_Button3Icon                matlab.ui.control.Image
        menu_Button3Label               matlab.ui.control.Label
        menu_Button2Grid                matlab.ui.container.GridLayout
        menu_Button2Icon                matlab.ui.control.Image
        menu_Button2Label               matlab.ui.control.Label
        menu_Button1Grid                matlab.ui.container.GridLayout
        menu_Button1Icon                matlab.ui.control.Image
        menu_Button1Label               matlab.ui.control.Label
        menuUnderline                   matlab.ui.control.Image
        ControlTabGroup                 matlab.ui.container.TabGroup
        Tab_4                           matlab.ui.container.Tab
        GridLayout6                     matlab.ui.container.GridLayout
        config_geoAxesLabel_2           matlab.ui.control.Label
        TreeLocalRNI                    matlab.ui.container.CheckBoxTree
        Tab_1                           matlab.ui.container.Tab
        GridLayout2                     matlab.ui.container.GridLayout
        UNIDADEDESCENTRALIZADALabel     matlab.ui.control.Label
        Tree                            matlab.ui.container.CheckBoxTree
        LOCALIDADELabel                 matlab.ui.control.Label
        ListBox_GR_UO                   matlab.ui.control.ListBox
        Tab_2                           matlab.ui.container.Tab
        GridLayout7                     matlab.ui.container.GridLayout
        Panel_3                         matlab.ui.container.Panel
        GridLayout11                    matlab.ui.container.GridLayout
        EditField_DistPont              matlab.ui.control.NumericEditField
        DistnciamLabel                  matlab.ui.control.Label
        EditField_LongGrau              matlab.ui.control.NumericEditField
        LongitudeLabel                  matlab.ui.control.Label
        EditField_LatGrau               matlab.ui.control.NumericEditField
        LatitudeLabel_2                 matlab.ui.control.Label
        DropDown_Serv                   matlab.ui.control.DropDown
        ServioLabel                     matlab.ui.control.Label
        DropDown_Local                  matlab.ui.control.DropDown
        LocalidadeLabel                 matlab.ui.control.Label
        UFLabel                         matlab.ui.control.Label
        DropDown_UF                     matlab.ui.control.DropDown
        EditFieldNEstPont               matlab.ui.control.NumericEditField
        NEstaoLabel                     matlab.ui.control.Label
        Panel_2                         matlab.ui.container.Panel
        GridLayout10                    matlab.ui.container.GridLayout
        TipologiaLabel                  matlab.ui.control.Label
        DropDown_Tipo                   matlab.ui.control.DropDown
        EditField_LongGrau_2            matlab.ui.control.NumericEditField
        LongitudeLabel_2                matlab.ui.control.Label
        EditField_LatGrau_2             matlab.ui.control.NumericEditField
        LatitudeLabel                   matlab.ui.control.Label
        Image                           matlab.ui.control.Image
        Tree_CoordEnd                   matlab.ui.container.Tree
        PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel  matlab.ui.control.Label
        ESTAOSOBANLISELabel             matlab.ui.control.Label
        Tab_5                           matlab.ui.container.Tab
        GridLayout5                     matlab.ui.container.GridLayout
        Panel                           matlab.ui.container.Panel
        GridLayout9                     matlab.ui.container.GridLayout
        HTML                            matlab.ui.control.HTML
        REGISTROSELECIONADOLabel        matlab.ui.control.Label
        Tab_3                           matlab.ui.container.Tab
        Tab3_Grid                       matlab.ui.container.GridLayout
        config_geoAxesSubPanel          matlab.ui.container.Panel
        config_geoAxesSubGrid           matlab.ui.container.GridLayout
        play_Persistance_cLim_Grid2     matlab.ui.container.GridLayout
        Label                           matlab.ui.control.Label
        play_Persistance_cLim2          matlab.ui.control.Spinner
        play_Persistance_cLim1          matlab.ui.control.Spinner
        LimitesLabel                    matlab.ui.control.Label
        LegendadecorLabel               matlab.ui.control.Label
        DropDownLocalBarra              matlab.ui.control.DropDown
        config_Colormap                 matlab.ui.control.DropDown
        config_ColormapLabel            matlab.ui.control.Label
        config_Basemap                  matlab.ui.control.DropDown
        config_BasemapLabel             matlab.ui.control.Label
        config_FolderMapLabel           matlab.ui.control.Label
        config_FolderMapPanel           matlab.ui.container.Panel
        config_FolderMapGrid            matlab.ui.container.GridLayout
        config_Folder_userPathButton    matlab.ui.control.Image
        config_Folder_userPath          matlab.ui.control.DropDown
        config_Folder_userPathLabel     matlab.ui.control.Label
        config_Folder_pythonPathButton  matlab.ui.control.Image
        config_Folder_pythonPath        matlab.ui.control.EditField
        config_Folder_pythonPathLabel   matlab.ui.control.Label
        config_Folder_DataHubPOSTButton  matlab.ui.control.Image
        config_Folder_DataHubPOST       matlab.ui.control.EditField
        config_Folder_DataHubPOSTLabel  matlab.ui.control.Label
        config_Folder_DataHubGETButton  matlab.ui.control.Image
        config_Folder_DataHubGET        matlab.ui.control.EditField
        config_Folder_DataHubGETLabel   matlab.ui.control.Label
        misc_ElevationSourcePanel       matlab.ui.container.Panel
        GridLayout8                     matlab.ui.container.GridLayout
        EditFieldDist_PARNI             matlab.ui.control.NumericEditField
        EditFieldDistMedicoes           matlab.ui.control.NumericEditField
        DistPARNILabel                  matlab.ui.control.Label
        DisMedicoesLabel                matlab.ui.control.Label
        ANLISELabel                     matlab.ui.control.Label
        config_Refresh                  matlab.ui.control.Image
        config_geoAxesLabel             matlab.ui.control.Label
        filter_ContextMenu              matlab.ui.container.ContextMenu
        filter_delButton                matlab.ui.container.Menu
        filter_delAllButton             matlab.ui.container.Menu
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
        jsBackDoorFlag = {true, ...
                          true, ...
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
        
        restoreView    = struct('ID', {}, 'xLim', {}, 'yLim', {}, 'cLim', {})

        %-----------------------------------------------------------------%
        % ESPECIFICIDADES
        %-----------------------------------------------------------------%
        Data_PA_RNI            % Dados das estações do Plano Anual de RNI
        Path_Data_PA_RNI_Out

        Data_Meas_Probes       % Dados das medições obtidas pelas em campo pelas sondas       
        Data_Meas_cache        % Dados de todas as informações de Data_PA_RNI em cache 
        UTTable_Formated       % Dados de todas as informações da UITable inicial formatada em cache
        Data_Meas_cache_Select % Dados filtrados de Data_PA_RNI em cache
        Data_Meas_cache_All     % Dados de todas as informações Calculadas de de Data_PA_RNI em cache 
        Data_PA_RNI_Out         % Dados das  medições de RNI calculados que serão gravados no arquivo XLS  
        Data_Localidades        % Dados da Tabela das Localidades do Brasil
        Data_Serv_Rad_Tel       % Dados dos serviços de Radiodifusão e de Telecom fiscalizados pela Anatel
        EditFieldRow           % Dado do número da linha selecionada da tabela UITable
        mapAxes                % Eixo do mapa
        Data_Points            % Dados dos pontos (locais) de interesses nas demandas pontuais        
        metaData = struct('Filename', {}, 'Measures', {}, 'Sensor', {}, 'Data', {}, 'LatitudeLimits', {}, 'LongitudeLimits', {}, 'MetaDataProbe', {})
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
                            if isvalid(app.popupContainerGrid)
                                delete(app.popupContainerGrid)
                            end
                        otherwise
                            % ...
                    end
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

                    ccTools.compCustomizationV2(app.jsBackDoor, app.axesToolbarGrid, 'borderBottomLeftRadius', '5px', 'borderBottomRightRadius', '5px')

                otherwise
                    if any(app.jsBackDoorFlag{tabIndex})
                        app.jsBackDoorFlag{tabIndex} = false;

                        switch tabIndex
                            case 1 % FILE
                                ccTools.compCustomizationV2(app.jsBackDoor, app.ControlTabGroup, 'transparentHeader', 'transparent')

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
                startup_Controller(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Controller(app)
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
            startup_Files2Read(app)
            startup_AppProperties(app)
            startup_GUIComponents(app)

            switch app.executionMode
                case 'webApp'
                    % Força a exclusão do SplashScreen do MATLAB WebDesigner.
                    sendEventToHTMLSource(app.jsBackDoor, "delProgressDialog");

                    app.General.operationMode.Debug   = false;
                    app.General.operationMode.Dock    = true;

                    % A pasta do usuário não é configurável, mas obtida por 
                    % meio de chamada a uiputfile. Para criação de arquivos 
                    % temporários, cria-se uma pasta da sessão.
                    tempDir = tempname;
                    mkdir(tempDir)
                    app.General.fileFolder.userPath   = tempDir;

                otherwise    
                    % Resgata a pasta de trabalho do usuário (configurável).
                    userPaths = appUtil.UserPaths(app.General.fileFolder.userPath);
                    app.General.fileFolder.userPath = userPaths{end};

                    switch app.executionMode
                        case 'desktopStandaloneApp'
                            app.General.operationMode.Debug = false;
                        case 'MATLABEnvironment'
                            app.General.operationMode.Debug = true;
                    end
            end
            
            % Diminui a opacidade do SplashScreen. Esse processo dura
            % cerca de 1250 ms. São 50 iterações em que em cada uma 
            % delas a opacidade da imagem diminuir em 0.02. Entre cada 
            % iteração, 25 ms. E executa drawnow, forçando a renderização 
            % em tela dos componentes.
            sendEventToHTMLSource(app.jsBackDoor, 'turningBackgroundColorInvisible', struct('componentName', 'SplashScreen', 'componentDataTag', struct(app.popupContainerGrid).Controller.ViewModel.Id));
            drawnow

            % Torna visível o container do auxApp.popupContainer, forçando
            % a exclusão do SplashScreen.
            if isvalid(app.popupContainerGrid)
                pause(1)
                delete(app.popupContainerGrid)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Files2Read(app)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appUtil.generalSettingsLoad(class.Constants.appName, app.rootFolder);
            if ~isempty(msgWarning)
                appUtil.modalWindow(app.UIFigure, 'error', msgWarning);
            end

            app.General            = app.General_I;
            app.General.AppVersion = fcn.envVersion(app.rootFolder, 'full');
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            % app.rfDataHub
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

            % Controles:
            app.tool_TableVisibility.UserData = true;
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            startup_AxesCreation(app)

            % userPath
            if strcmp(app.executionMode, 'webApp')
                % Webapps não suporta uigetdir, então o mapeamento das pastas
                % POST/GET deve ser feito em arquivo externo de configuração...
                app.config_Folder_userPathButton.Enable = 0;
            else
                userPaths = appUtil.UserPaths(app.General.fileFolder.userPath);
                set(app.config_Folder_userPath, 'Items', userPaths, 'Value', userPaths{end})
                app.General.fileFolder.userPath = userPaths{end};
            end


            % MIGRADO DO STARTUP DE APPRNI.MLAPP
            app.HTML.HTMLSource = '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Modificar Tabela</title><style>#infoText {text-align: center; font-weight: bold; color: blue;}</style></head><body><p id="infoText">Para visualização das informações da estação monitorada clique em uma das linhas da tabela ao lado:</p></body></html>';

            % Realiza a leitura do arquivo csv do PA_RNI e cria a UITable
            [app.Data_PA_RNI, app.Path_Data_PA_RNI_Out] = fcn.ReadFile_PA_RNI(app.rootFolder, app.General.fileFolder.userPath);
            app.UITable.Data       = app.Data_PA_RNI;
            app.UITable.ColumnName = class.Constants.GUIColumnsAll;

            % Armazena no vetor app.Data_Localidades as localidades do Brasil
            app.Data_Localidades  = fcn.ReadFile_Loc_Serv(app.rootFolder, "Local");

            % Armazena no vetor app.Data_Serv_Rad_Tel a lista de seviços de Radiod. e de Telecom fiscalizados pela Anatel.
            app.Data_Serv_Rad_Tel = fcn.ReadFile_Loc_Serv(app.rootFolder, "Serv");

            % Armazena em cache todos os dados da tabela do PA_RNI
            app.Data_Meas_cache   = app.UITable.Data;

            % Formata dos dados a serem apresntados na UITable
            Format_UITable(app);
            app.UTTable_Formated = app.UITable.Data;
            
            % Insere em app.DropDown_UF a lista das UFs do Brasil
            app.DropDown_UF.Items = {'', 'AC', 'AL', 'AM', 'AP', 'BA', 'CE',	'ES', 'GO', 'MA', 'MG', 'MS', 'MT',	'PA', 'PB',	'PE', 'PI',	'PR', 'RJ', 'RN', 'RO',	'RR', 'RS', 'SC', 'SE',	'SP', 'TO'};
           
            % Insere em app.DropDown_Tipo.Items os tipos de locais
            app.DropDown_Tipo.Items = {'', 'Escola', 'Hospital', 'Creche', 'Escola', 'Casa', 'Apartamento', 'Outros'};
        end

        %-----------------------------------------------------------------%
        function startup_AxesCreation(app)
            % Eixo geográfico: MAPA
            app.plotPanel.AutoResizeChildren = 'off';
            app.mapAxes = plot.axes.Creation(app.plotPanel, 'Geographic', {'Units',    'normalized',             ...
                                                                           'Position', [0 0 1 1 ],               ...
                                                                           'Basemap',  app.config_Basemap.Value, ...
                                                                           'UserData', struct('CLimMode', 'auto', 'Colormap', '')});

            set(app.mapAxes.LatitudeAxis,  'TickLabels', {}, 'Color', 'none')
            set(app.mapAxes.LongitudeAxis, 'TickLabels', {}, 'Color', 'none')
            
            geolimits(app.mapAxes, 'auto')
            app.restoreView(1) = struct('ID', 'app.mapAxes', 'xLim', app.mapAxes.LatitudeLimits, 'yLim', app.mapAxes.LongitudeLimits, 'cLim', 'auto');

            plot.axes.Colormap(app.mapAxes, app.config_Colormap.Value)
            plot.axes.Colorbar(app.mapAxes, app.DropDownLocalBarra.Value)

            % Legenda
            legend(app.mapAxes, 'Location', 'southwest', 'Color', [.94,.94,.94], 'EdgeColor', [.9,.9,.9], 'NumColumns', 4, 'LineWidth', .5, 'FontSize', 7.5)

            % Axes interactions:
            plot.axes.Interactivity.DefaultCreation(app.mapAxes, [dataTipInteraction, zoomInteraction, panInteraction])
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % MIGRAÇÃO "APPRNI.MLAPP" >> "WINRNI.MLAPP"
        %-----------------------------------------------------------------%
        function Colors_FieldValue(app)                     
            % Define limtes geográficos conforme arquivos de medições
            geolimits(app.mapAxes, 'auto')

            % Configura inicialmente a barra de níveis no mapa
            app.mapAxes.CLimMode = 'auto';
            
            % Plota os pontos no mapAxes atribuindo cores aos E(V/m) em cada coordenada
            hPlot = geoscatter(app.mapAxes, app.Data_Meas_Probes.Latitude, app.Data_Meas_Probes.Longitude, [], app.Data_Meas_Probes.FieldValue, 'filled');
            hPlot.DataTipTemplate.DataTipRows(3).Label  = 'Nivel';
            hPlot.DataTipTemplate.DataTipRows(3).Format = '%2.2f V/m';

            app.restoreView(1) = struct('ID', 'app.mapAxes', 'xLim', app.mapAxes.LatitudeLimits, 'yLim', app.mapAxes.LongitudeLimits, 'cLim', 'auto');
        end

        %-----------------------------------------------------------------%
        function Format_UITable(app)            
            % Cria uma matriz de strings de vazios e insere novas colunas na UITable
            matrix_nan       = strings(height(app.UITable.Data), numel(class.Constants.GUINewColumns));
            app.UITable.Data = [app.UITable.Data array2table(matrix_nan)];

            app.UITable.ColumnName  = class.Constants.GUIColumnsSelect;
            visibleData             = app.UITable.Data(:, [2, 3, 4, 6, 9, 10, 11, 12, 13, 14, 15]);
            app.UITable.Data        = visibleData;
            app.UITable.ColumnWidth = class.Constants.GuiColumnWidthCalc;

            % Destaca a apresentação das colunas da tabela com cores
            s = uistyle("BackgroundColor","cyan");
            addStyle(app.UITable,s,"column",5:9)
            s = uistyle("BackgroundColor","yellow");
            addStyle(app.UITable,s,"column",10:11)        
        end
        
        %-----------------------------------------------------------------%
        function Calc_Dist_Emax(app, Dist_Max)
            % Armazena a distancia máxima em relação as estações, para avaliação das medições de RNI 
            Dist_Max_Level = Dist_Max; 
            
             % Testa se há algum arquivo de medições de RNI para cálculos
            if isempty(app.Data_Meas_Probes)
                uialert(app.UIFigure, ['Não foram encontrados arquivos referentes as medições! Insira os arquivos das medições' ...
                    ' e tente novamente!'], 'Go!','Icon','success')
               return
            end

            % Obtém os vetores dos dados das latitudes e longitudes das medições de RNI
            Lat_Meas_Probes  = app.Data_Meas_Probes.Latitude;
            Long_Meas_Probes = app.Data_Meas_Probes.Longitude;

            % Distancia máxima das estação em metros
            Dist_EMax = (Dist_Max_Level/111.12)/1000;

            format long;

            for jj=1:height(app.UITable.Data)

                % Obtém as latitudes e longitudes de cada estação do PA_RNI selecionados
                Lat_Estacao   = app.Data_Meas_cache_Select.('Latitude da Estação')(jj);
                Long_Estacao  = app.Data_Meas_cache_Select.('Longitude da Estação')(jj);

                % Define as coordenadas de Lat. e Long. máx. e Lat. e Long. min. em relação a dist_EMax
                Lat_Max  = Lat_Estacao + Dist_EMax;
                Lat_Min  = Lat_Estacao - Dist_EMax;
                Long_Max = Long_Estacao + Dist_EMax;
                Long_Min = Long_Estacao - Dist_EMax;

                % Filtra de app.Data_Meas_Probes apenas os dados das medições até a distância máx. e min. da estação
                filteredT     = app.Data_Meas_Probes((Lat_Meas_Probes >= Lat_Min & Lat_Meas_Probes <= Lat_Max) & (Long_Meas_Probes >= Long_Min & Long_Meas_Probes <= Long_Max), :);
                [~, maxIndexField] =  max(filteredT.FieldValue);

                if ~isempty(maxIndexField)
                    Lat_filteredT  = filteredT.Latitude;                    
                    Long_filteredT = filteredT.Longitude;
                    
                    % Realiza os cálculos entre a distância das coordenadas da estação e os pontos das medições do RNI
                    dist_Meas_St = deg2km(distance(Lat_Estacao, Long_Estacao, Lat_filteredT, Long_filteredT))*1000;

                    % Filtra apenas os dados das medições do RNI que esteja dentro do raio definido em dist_EMax
                    Dist_Max_fT    = filteredT((find(dist_Meas_St <= Dist_Max_Level)), :);

                    % Obtém as coordenadas e datatime associados ao índice e Field_Dist_Max
                    Field_Dist_Max = Dist_Max_fT.FieldValue;
                    Lat_Dist_Max   = Dist_Max_fT.Latitude;                    
                    Long_Dist_Max  = Dist_Max_fT.Longitude;
                    Data_Med_Max   = Dist_Max_fT.Timestamp;

                    % Obtém o indice do Emáx <= a Dist_EMax     
                    [~, maxIndexField]  =  max(Field_Dist_Max);

                    % Obtém do EMax as coordenadas e o datatime referentes ao indice maxIndex 
                    E_Level_Max   = Field_Dist_Max(maxIndexField);
                    Lat_Max_Calc  = Lat_Dist_Max(maxIndexField);
                    Long_Max_Calc = Long_Dist_Max(maxIndexField);
                    Data_Med_Calc = Data_Med_Max(maxIndexField);
                    ContMaior14Vm = sum(E_Level_Max >= Dist_Max_Level);

                    % Insere os valores das coordenadas, datatime, associados ao Emáx na UITable
                    if ~isempty(E_Level_Max)
                        app.UITable.Data.('Emáx (V/m)')(jj)      = E_Level_Max;
                        app.UITable.Data.('Latitude Emáx')(jj)   = Lat_Max_Calc;
                        app.UITable.Data.('Longitude Emáx')(jj)  = Long_Max_Calc;
                        app.UITable.Data.('> 14 V/M')(jj)        = ContMaior14Vm;
                        app.UITable.Data.('Data da Medição')(jj) = Data_Med_Calc; 
                        
                        % Inseri os valores calculados na tabela de cache app.Data_Meas_cache_Select
                        app.Data_Meas_cache_Select.('Emáx (V/m)')(jj)      = E_Level_Max;
                        app.Data_Meas_cache_Select.('Latitude Emáx')(jj)   = Lat_Max_Calc;
                        app.Data_Meas_cache_Select.('Longitude Emáx')(jj)  = Long_Max_Calc;
                        app.Data_Meas_cache_Select.('> 14 V/M')(jj)        = ContMaior14Vm;
                        app.Data_Meas_cache_Select.('Data da Medição')(jj) = Data_Med_Calc;   
                    end             
                end               
            end

            % Apresenta na UITable apenanas os dados das estações onde foram realizadas as avaliações de RNI
            app.UITable.Data = app.UITable.Data(~isnan(app.UITable.Data{:, 6}), :);
            app.Data_Meas_cache_Select = app.Data_Meas_cache_Select(~isnan(app.Data_Meas_cache_Select{:, 11}), :);
            app.UITable.ColumnEditable = [false false false false false false false false false true true];
          
            uialert(app.UIFigure, sprintf('Cálculos dos Campos elétricos máximos (EMax) realizados com sucesso para %d metros de distância das estações!', app.EditFieldDistMedicoes.Value), 'Tudo certo!', 'Icon', 'success');
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
                app.popupContainerGrid.Layout.Row = [1,7];
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

            delete(app)
            
        end

        % Image clicked function: menu_Button1Icon, menu_Button2Icon, 
        % ...and 3 other components
        function general_ControlPanelSelectionChanged(app, event)
            
            idx = str2double(event.Source.Tag);
            NN  = numel(app.menu_MainGrid.ColumnWidth);

            for ii = 1:NN
                switch ii
                    case idx
                        eval(sprintf('app.menu_Button%dGrid.ColumnWidth{2} = "1x";', ii))
                    otherwise
                        eval(sprintf('app.menu_Button%dGrid.ColumnWidth{2} = 0;',    ii))
                end
            end

            columnWidth      = repmat({22}, 1, NN);
            columnWidth(idx) = {'1x'};

            app.menu_MainGrid.ColumnWidth   = columnWidth;
            app.menuUnderline.Layout.Column = idx;
            app.ControlTabGroup.SelectedTab = app.ControlTabGroup.Children(idx);

            jsBackDoor_Customizations(app, idx)
            focus(app.jsBackDoor)
            
        end

        % Image clicked function: AppInfo, FigurePosition, 
        % ...and 3 other components
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
                    app.tool_TableVisibility.UserData = ~app.tool_TableVisibility.UserData;
                    if app.tool_TableVisibility.UserData
                        app.UITable.Visible = 1;
                        app.GridLayout.RowHeight(4:5) = {10,'.4x'};
                    else
                        app.UITable.Visible = 0;
                        app.GridLayout.RowHeight(4:5) = {0,0};
                    end

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

        % Image clicked function: ImageOpenFile
        function ImageOpenFileClicked2(app, event)
            
            % Armazena as informações de latitude e longitude das estações 
            St_RNI_Lat  = app.Data_PA_RNI.('Latitude da Estação');
            St_RNI_Long = app.Data_PA_RNI.('Longitude da Estação');

            % Abre o diretório dos arquivos das medições das sondas
            initialPath = fullfile(app.rootFolder, 'DataBase', 'Meas_Sondas');
            
            % Abrir a caixa de diálogo para selecionar múltiplos arquivos
            [fileName, folderName] = uigetfile({'*.txt';'*.csv';'*.mat';'*.*'}, ...
                                              'Selecione arquivos', initialPath, ...
                                              'MultiSelect', 'on');
            %Mantém a Tela principal (figure) em primeiro plano
            figure(app.UIFigure);
            
            % Verifica se algum arquivo foi selecionado
            if isequal(fileName, 0)
                uialert(app.UIFigure, 'Nenhum arquivo selecionado! Selecione algum arquivo de medição de RNI', 'Aviso')
                return
            end

            % Verifica o tipo de arquivo que foi selecionado
            if ischar(fileName)
                fileName = {fileName};
            end

            fileFullName = {};
            for ii = 1:length(fileName)
                fileFullName{ii} = fullfile(folderName, fileName{ii});
            end
                
            % Descarta os arquivos já lidos.
            idxExistFile = ~ismember(fileFullName, {app.metaData.Filename});
            fileFullName = fileFullName(idxExistFile);


            for pp = 1:numel(fileFullName)
                 % Extrai do arquivo a informação sobre o tipo de sonda que gerou o arquivo de medição
                 Type_Meas_Probes = fcn.TypeMeasProbe(app, fileFullName{pp});

                 % Obtém todas os dados relavantes dos arquivos das medições de RNI
                 app.metaData(end+1) = fcn.ReadFile_Meas_Probes(app, Type_Meas_Probes, fileFullName{pp}, pp, numel(fileFullName));                 
            end

            % Armazenar os dados de medições dos arquivos
            listOfTables = {app.metaData.Data};            
            app.Data_Meas_Probes = sortrows(vertcat(listOfTables{:}), 'Timestamp', 'descend');

            LocalMaisProximo = {};

            for jj = 1:numel(app.metaData)    
                LatitudeLimSt = app.metaData(jj).LatitudeLimits;
                LongitudeLimSt = app.metaData(jj).LongitudeLimits;

                Distance = distance(mean(LatitudeLimSt), mean(LongitudeLimSt), St_RNI_Lat, St_RNI_Long);
                
                % Calcular a diferença entre cada elemento do vetor e o número alvo
                [~, idxMinDistance] = min(abs(Distance));
                
                % Encontrar o valor mais próximo
                LocalMaisProximo{end+1} = sprintf('%s - %s', app.Data_PA_RNI.UF{idxMinDistance}, app.Data_PA_RNI.Municipio{idxMinDistance});
            end 
            LocalMaisProximo = unique(LocalMaisProximo);
            
            % Escreve na app.Tree as informações relacionadas a localidade
            delete(app.TreeLocalRNI.Children);

            % Criar um nó raiz
            rootNode = uitreenode(app.TreeLocalRNI, 'Text', 'Localidades');

            for ll = 1:numel(LocalMaisProximo)
                childNode{ll} = uitreenode(rootNode, 'Text', LocalMaisProximo{ll});
            end
            expand(app.TreeLocalRNI)

            % Seleciona todos os nós da TreeLocalRNI (CheckedNodes)
            app.TreeLocalRNI.CheckedNodes = app.TreeLocalRNI.Children;

            TreeLocalRNICheckedNodesChanged(app, event);

            % Define configurações do mapAxes
            Colors_FieldValue(app);

        end

        % Callback function: TreeLocalRNI
        function TreeLocalRNICheckedNodesChanged(app, event)
            
            selectedNodes = app.TreeLocalRNI.CheckedNodes;

            if ~isempty(selectedNodes)
                idxLogical_Cach = [];
            
            for pp = 1:numel(selectedNodes)
                idxLogical  = find(strcmp(strcat(app.Data_Meas_cache.UF, " - ", app.Data_Meas_cache.Municipio), string(selectedNodes(pp).Text)));
                idxLogical  = unique([idxLogical_Cach; idxLogical], 'stable');
                idxLogical_Cach = idxLogical;
            end
            if ~isempty(idxLogical_Cach)
                app.UITable.Data          = app.UTTable_Formated(idxLogical_Cach,:);
                app.Data_Meas_cache_Select = app.Data_Meas_cache(idxLogical_Cach,:);
            else
                app.UITable.Data          = app.UITable.Data;
                app.Data_Meas_cache_Select = app.Data_Meas_cache;
            end

            % calcula o Emax das estações e os valores de Datatime e coordenadas associadas aos Emáx 
            Dist_Max_Level = app.EditFieldDistMedicoes.Value;
            Calc_Dist_Emax(app, Dist_Max_Level);

            else
                app.UITable.Data = app.UTTable_Formated;
            end     

        end

        % Value changed function: ListBox_GR_UO
        function ListBox_GR_UOValueChanged(app, event)
            
            % Armazena em ER_UO as informações das URs da tabela do PA_RNI  
            ER_UO = app.Data_PA_RNI.('Unidade regional');

            app.UITable.Data       = app.Data_PA_RNI;
            Format_UITable(app);
            
            % Busca na Base de dados do PA_RNI as localidades da Unidade Operacional selecionada 
            Index_Local             = find(strcmp(ER_UO, app.ListBox_GR_UO.Value));
            app.UITable.Data        =  app.UITable.Data(Index_Local,:);
            app.Data_Meas_cache_All = app.Data_Meas_cache(Index_Local,:);
            Localidades             = unique(app.Data_Meas_cache.Municipio(Index_Local)); 

            delete(app.Tree.Children);

            % Criar um nó raiz 'Localidades'
            rootNode = uitreenode(app.Tree, 'Text', 'Localidades');
            
            % Escreve na app.Tree as informações relacionadas a localidade correpondente a Unidade Regional selecionada 
            for ii = 1:numel(Localidades)
                childNode{ii} = uitreenode(rootNode, 'Text', Localidades(ii));
            end
            expand(app.Tree)
            
        end

        % Callback function: Tree
        function TreeCheckedNodesChanged(app, event)
            
            % Aramazena os dados selecionado dos Checkboxes
            selectedNodes = app.Tree.CheckedNodes;

            if ~isempty(selectedNodes)
                idxLogical_Cach = [];

                % Busca na Base de dados do PA_RNI as localidades da Unidade Operacional selecionada
                GR_UO_Select     = string(app.ListBox_GR_UO.Value);
                idxLogical_GR_UO = find(strcmp(app.Data_Meas_cache_All.('Unidade regional'), GR_UO_Select));
                Data_PA_RNI_idx  = app.Data_Meas_cache_All(idxLogical_GR_UO,:);

                % Escreve na app.Tree as informações relacionadas a localidade correpondente a Unidade Regional selecionada
                for pp = 1:numel(selectedNodes)
                    idxLogical      = find(strcmp(Data_PA_RNI_idx.('Municipio'), string(selectedNodes(pp).Text)));
                    idxLogical      = unique([idxLogical_Cach; idxLogical], 'stable');
                    idxLogical_Cach = idxLogical;

                end

                if ~isempty(idxLogical_Cach)
                    app.UITable.Data           = Data_PA_RNI_idx(idxLogical,:);
                    app.Data_Meas_cache_Select = app.Data_Meas_cache_All(idxLogical,:);
                else
                    app.UITable.Data           = Data_PA_RNI_idx;
                    app.Data_Meas_cache_Select = app.Data_Meas_cache_All;
                end

                Format_UITable(app);

                % Chama a função Calc_Dist_Emax para realização dos cáculos
                Calc_Dist_Emax(app, app.EditFieldDist_PARNI.Value);

            else
                app.UITable.Data = app.UTTable_Formated;
            end

        end

        % Value changed function: EditFieldNEstPont
        function EditFieldDist_PARNIValueChanged2(app, event)
            
            % Recalcula o Emax das estações e os valores de Datatime e coordenadas associadas aos Emáx 
            Dist_Max_Level = app.EditFieldDist_PARNI.Value;
            Calc_Dist_Emax(app, Dist_Max_Level);
            app.TabGroup.SelectedTab =  app.MeasUFTab;

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

        % Button pushed function: Button_AddPoints
        function Button_AddPointsPushed(app, event)
            
            Incr_Node = app.EditFieldIncrPoints.Value+1;

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

            app.EditFieldIncrPoints.Value = app.EditFieldIncrPoints.Value +1; 

        end

        % Button pushed function: CalcularMaioresnveisButton
        function CalcularMaioresnveisButtonPushed(app, event)
            
            Dist_Max_Level = app.EditField_DistPont.Value;
            Latitude_Pont  = app.EditField_LatGrau.Value ; 
            Longitude_Pont = app.EditField_LongGrau.Value;

            app.UITable.Data = app.UITable.Data([],:);
            app.UITable.Data.UF(1)                = app.DropDown_UF.Value;
            app.UITable.Data.Municipio(1)         = app.DropDown_Local.Value;
            app.UITable.Data.('Serviço') (1)      = app.DropDown_Serv.Value;
            app.UITable.Data.('N° da Estacao')(1) = app.EditFieldNEstPont.Value;
  
            app.UITable.Data.('Data da Medição')(1) = "";
            app.UITable.Data.('Emáx (V/m)')(1)      = "";
            app.UITable.Data.('Latitude Emáx') (1)  = "";
            app.UITable.Data.('Longitude Emáx')(1)  = "";
            app.UITable.Data.('> 14 V/M')(1)        = 0;
            
            app.UITable.Data.('Justificativa (apenas NV)')(1) = "";
            app.UITable.Data.('Observações importantes') (1)  = "";

            app.Data_Meas_cache_Select.('N° da Estacao')(1) = app.EditFieldNEstPont.Value;
            app.Data_Meas_cache_Select.Municipio(1) = app.DropDown_Local.Value;
            app.Data_Meas_cache_Select.UF(1) = app.DropDown_UF.Value;
            app.Data_Meas_cache_Select.('Serviço')(1) = app.DropDown_Serv.Value;
            app.Data_Meas_cache_Select.('Latitude da Estação')(1) = Latitude_Pont;
            app.Data_Meas_cache_Select.('Longitude da Estação')(1) = Longitude_Pont;    

            Calc_Dist_Emax(app, app.EditField_DistPont.Value);

            app.GravarButton.Enable = false;

            % Antes de plotar, apaga os plots que não mais fazem sentido.
            plotTag = 'tableSelectionRow';
            delete(findobj(app.mapAxes.Children, 'Tag', plotTag))
            

            % Obtém as coordenadas da estação selecionada pra plotar no mapAxes
            Lat_Est  = app.EditField_LatGrau.Value;
            Long_Est = app.EditField_LongGrau.Value;
         
            % Obtém as coordeandas das coordenadas onde está o ponto de Emáx
            Lat_Est_EMax  =  app.UITable.Data.('Latitude Emáx');
            Long_Est_EMax =  app.UITable.Data.('Longitude Emáx');

            % Plot the point station
            EstPlot = geoscatter(app.mapAxes, Lat_Est, Long_Est, 'Marker', 'p', 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'Tag', plotTag);

            EstPlot.DataTipTemplate.DataTipRows(3) = sprintf('Estação nº: %d',app.Data_Meas_cache_Select.('N° da Estacao')(app.EditFieldRow));
            EstPlot.DataTipTemplate.DataTipRows = EstPlot.DataTipTemplate.DataTipRows([1, 2, 3]);

            % Desenha o cículo de raio Dist_Emax ao redor da estação 
            drawcircle(app.mapAxes, 'Position', [Lat_Est, Long_Est], ...
                                    'Radius', (app.EditFieldDistMedicoes.Value/100000), ...
                                    'Color', 'green', ...
                                    'FaceSelectable', 0, ...
                                    'InteractionsAllowed', 'none', ...
                                    'EdgeAlpha', 0, ...
                                    'Tag', plotTag)

            % Plot the points: ELIMINAR O LOOP!!!!

            % Adress_Point = geoscatter(app.mapAxes, app.Data_Points.Latitude, app.Data_Points.Longitude, 'Marker', 'diamond', 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'cyan', 'Tag', plotTag);
            % Adress_Point.DataTipTemplate.DataTipRows(3) = sprintf('Ponto nº: %d',yy);
            % Adress_Point.DataTipTemplate.DataTipRows = Adress_Point.DataTipTemplate.DataTipRows([1, 2, 3]);

            for yy=1:numel(app.Data_Points)
                Adress_Point = geoscatter(app.mapAxes, app.Data_Points(yy).Latitude, app.Data_Points(yy).Longitude, 'Marker', 'diamond', 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'cyan', 'Tag', plotTag);
                Adress_Point.DataTipTemplate.DataTipRows(3) = sprintf('Ponto nº: %d',yy);
                Adress_Point.DataTipTemplate.DataTipRows = Adress_Point.DataTipTemplate.DataTipRows([1, 2, 3]);
            end

            % Plot the point EMax
            EmaxPlot = geoscatter(app.mapAxes, Lat_Est_EMax, Long_Est_EMax, app.Data_Meas_cache_Select.('Emáx (V/m)')(app.EditFieldRow), 'LineWidth', 6, 'Marker','square', 'MarkerEdgeColor', 'yellow', 'Tag', plotTag);
            EmaxPlot.DataTipTemplate.DataTipRows = EstPlot.DataTipTemplate.DataTipRows([1, 2, 3]);
            EmaxPlot.DataTipTemplate.DataTipRows(3).Label = 'Nivel (Emáx)';
            EmaxPlot.DataTipTemplate.DataTipRows(3).Value = app.Data_Meas_cache_Select.('Emáx (V/m)')(app.EditFieldRow);
            EmaxPlot.DataTipTemplate.DataTipRows(3).Format = '%2.2f V/m';

            % Define limtes geográficos conforme arquivos de meidições
            % geolimits(app.mapAxes, [Lat_Est-0.05, Lat_Est+0.05], [Long_Est-0.05, Long_Est+0.05]);

        end

        % Button pushed function: PlotarKMLButton
        function PlotarKMLButtonPushed(app, event)
            
            % Criar arquivo KML
            error('Não operacional!')
            outputFileName = 'C:\P&D\AppRNI\DataBase\PA_RNI\mapa_pontos.kml';
            
            % Usar kmlwrite para gerar o arquivo KML
            kmlwrite(outputFileName, app.Data_Meas_Probes.Latitude, app.Data_Meas_Probes.Longitude);
            
            disp('Arquivo KML gerado com sucesso!');

        end

        % Image clicked function: GravarButton
        function GravarButtonPushed(app, event)
            
            % Lendo os dados existentes do arquivo CSV
            try
                opts = detectImportOptions(app.Path_Data_PA_RNI_Out);
                opts.PreserveVariableNames = true;
                app.Data_PA_RNI_Out = readtable(app.Path_Data_PA_RNI_Out, opts);
            catch
                startupFcn(app);
            end
      
            index_out = find(~isnan(app.UITable.Data.('Emáx (V/m)')));

            for pp = 1: numel(index_out)
                Idx_Station = find(strcmp(string(app.Data_Meas_cache.('N° da Estacao')),  string(app.UITable.Data.('N° da Estacao')(index_out(pp)))));

                app.Data_PA_RNI_Out.('Data da Medição'){Idx_Station} = app.UITable.Data.('Data da Medição')(index_out(pp));
                app.Data_PA_RNI_Out.('Emáx (V/m)'){Idx_Station} = app.UITable.Data.('Emáx (V/m)')(index_out(pp));
                app.Data_PA_RNI_Out.('Latitude Emáx'){Idx_Station} = app.UITable.Data.('Latitude Emáx')(index_out(pp));
                app.Data_PA_RNI_Out.('Longitude Emáx'){Idx_Station} = app.UITable.Data.('Longitude Emáx')(index_out(pp));
                app.Data_PA_RNI_Out.('> 14 V/M')(Idx_Station) = app.UITable.Data.('> 14 V/M')(index_out(pp));
                app.Data_PA_RNI_Out.('Justificativa (apenas NV)'){Idx_Station} = app.UITable.Data.('Justificativa (apenas NV)')(index_out(pp));
                app.Data_PA_RNI_Out.('Observações importantes'){Idx_Station} = app.UITable.Data.('Observações importantes')(index_out(pp));
            end
            
            % Escrevendo os dados atualizados de volta no arquivo xlsx
            writetable(app.Data_PA_RNI_Out, app.Path_Data_PA_RNI_Out);
            uialert(app.UIFigure, 'Arquivo XLSX atualizado com sucesso!', 'Feito!','Icon','success');

        end

        % Value changed function: EditFieldDistMedicoes
        function EditFieldDistMedicoesValueChanged2(app, event)
                        
            % Recalcula o Emax das estações e os valores de Datatime e coordenadas associadas aos Emáx 
            Dist_Max_Level = app.EditFieldDistMedicoes.Value;
            Calc_Dist_Emax(app, Dist_Max_Level);
            app.TabGroup.SelectedTab = app.MedicoesTab;

        end

        % Callback function
        function DropDownIntesidadeValueChanged(app, event)
            
            colormap(app.mapAxes, app.config_Colormap.Value);

        end

        % Value changed function: DropDownLocalBarra
        function DropDownLocalBarraValueChanged(app, event)

            plot.axes.Colorbar(app.mapAxes, app.DropDownLocalBarra.Value)

        end

        % Value changed function: play_Persistance_cLim1, 
        % ...and 1 other component
        function DropDownlocalNivelMenorValueChanged(app, event)
                        
            % Altera o range do intensidade de campo (V/m)
            if app.DropDownlocalNivelMenor.Value == "auto"
                app.mapAxes.CLimMode = 'auto';
            elseif app.DropDownlocalNivelMenor.Value ~= "auto" && app.DropDownlocalNivelMaior.Value ~= "auto"
                app.mapAxes.CLim = [str2double(app.DropDownlocalNivelMenor.Value), str2double(app.DropDownlocalNivelMaior.Value)];
            end

        end

        % Callback function: not associated with a component
        function DropDownlocalNivelMaiorValueChanged(app, event)
                        
            % Altera o range maior do intensidade de campo (V/m)
            if app.DropDownlocalNivelMaior.Value == "auto"
                app.mapAxes.CLimMode = 'auto';
            elseif app.DropDownlocalNivelMenor.Value ~= "auto" && app.DropDownlocalNivelMaior.Value ~= "auto"
                app.mapAxes.CLim = [str2double(app.DropDownlocalNivelMenor.Value), str2double(app.DropDownlocalNivelMaior.Value)];
            end

        end

        % Double-clicked callback: UITable
        function UITableDoubleClicked(app, event)
            
            app.EditFieldRow = event.InteractionInformation.DisplayRow;

            if isempty(app.Data_Meas_cache_Select)
                uialert(app.UIFigure, 'Realize o cálculo dos parâmetros de Emáx do(s) arquivo(s) RNI e após selecione com duplo click a visualização das infomeções da estação desejada', 'Aviso')
                return
            end
            
            % Escreve os textos referentes aos dados  app.Data_Meas_cache_Select da estação selecionada em htmlContent
            htmlContent = sprintf([ ...
                '<!DOCTYPE html><html lang="en"><head>'...
                '<meta charset="UTF-8">'...
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">'...
                '<title>Modificar Tabela</title>'...
                '<style>'...  
                'p.infoText { width: 100%%; text-align: left; font-weight: bold; color: red; margin: 10px 0; font-family: Times New Roman, sans-serif; font-size: 16px; }'... % Centraliza o texto, negrito, vermelho, Arial 12px
                'table { width: 100%%; border-collapse: collapse; margin-bottom: 18px; }'...
                'td { color: blue; font-weight: bold; border: 1px solid black; padding: 6px; text-align: left; }'...
                'td.greenText { color: green; }'... % Classe para texto verde
                '</style>'...
                '</head><body>'...
                '<p class="infoText">Dados da estação do Plano anual do RNI:</p>'...
                '<table>'...
                '<tr><td class="greenText">Estação N º: </td><td>%.0f</td></tr>'...
                '<tr><td class="greenText">Município/UF: </td><td>%s</td></tr>'...
                '<tr><td class="greenText">Serviço: </td><td>%s</td></tr>'...
                '<tr><td class="greenText">Latitude: </td><td>%.6f</td></tr>'...
                '<tr><td class="greenText">Longitude: </td><td>%.6f</td></tr>'...
                '</table>'...
                '<p class="infoText">Dados do monitoramento:</p>'...
                '<table>'...
                '<tr><td class="greenText">Data da medição: </td><td>%s</td></tr>'...
                '<tr><td class="greenText">Campo maior V/m: </td><td>%.3f</td></tr>'...
                '<tr><td class="greenText">Latitude Maior V/m: </td><td>%.6f</td></tr>'...
                '<tr><td class="greenText">Longitude maior V/m: </td><td>%.6f</td></tr>'...
                '<tr><td class="greenText">Medidas > 14 V/M: </td><td>%.0f</td></tr>'...
                '<tr><td class="greenText">Justificativa de NV: </td><td>%s</td></tr>'...
                '<tr><td class="greenText">Observações: </td><td>%s</td></tr>'...
                '</table>'...
                '</body></html>'], ...
                app.Data_Meas_cache_Select.('N° da Estacao')(app.EditFieldRow), ...
                strcat(app.Data_Meas_cache_Select.Municipio(app.EditFieldRow),"/",app.Data_Meas_cache_Select.UF(app.EditFieldRow)), ...
                app.Data_Meas_cache_Select.('Serviço')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Latitude da Estação')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Longitude da Estação')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Data da Medição')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Emáx (V/m)')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Latitude Emáx')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Longitude Emáx')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('> 14 V/M')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Justificativa (apenas NV)')(app.EditFieldRow), ...
                app.Data_Meas_cache_Select.('Observações importantes')(app.EditFieldRow));

                app.HTML.HTMLSource = htmlContent;

                % Obtém as coordenadas da estação selecionada pra plotar no mapAxes
                Lat_Est  = app.Data_Meas_cache_Select.('Latitude da Estação')(app.EditFieldRow);
                Long_Est = app.Data_Meas_cache_Select.('Longitude da Estação')(app.EditFieldRow);
         
                % Obtém as coordeandas das coordenadas onde está o ponto de Emáx
                Lat_Est_EMax  =  app.Data_Meas_cache_Select{app.EditFieldRow,11};
                Long_Est_EMax =  app.Data_Meas_cache_Select{app.EditFieldRow,12};
                
                % Antes de plotar, apaga os plots que não mais fazem sentido.
                plotTag = 'tableSelectionRow';
                delete(findobj(app.mapAxes.Children, 'Tag', plotTag))
                
                % Plot the point station
                EstPlot = geoscatter(app.mapAxes, Lat_Est, Long_Est, 'Marker', 'p', 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'Tag', plotTag);

                EstPlot.DataTipTemplate.DataTipRows(3) = sprintf('Estação nº: %d',app.Data_Meas_cache_Select.('N° da Estacao')(app.EditFieldRow));
                EstPlot.DataTipTemplate.DataTipRows = EstPlot.DataTipTemplate.DataTipRows([1, 2, 3]);

                % Desenha o cículo de raio Dist_Emax ao redor da estação 
                drawcircle(app.mapAxes, 'Position', [Lat_Est, Long_Est], ...
                                        'Radius', (app.EditFieldDistMedicoes.Value/100000), ...
                                        'Color', 'green', ...
                                        'FaceSelectable', 0, ...
                                        'InteractionsAllowed', 'none', ...
                                        'EdgeAlpha', 0, ...
                                        'Tag', plotTag)

                % Plot the point EMax
                EmaxPlot = geoscatter(app.mapAxes, Lat_Est_EMax, Long_Est_EMax, app.Data_Meas_cache_Select.('Emáx (V/m)')(app.EditFieldRow), 'LineWidth', 6, 'Marker','square', 'MarkerEdgeColor', 'yellow', 'Tag', plotTag);
                EmaxPlot.DataTipTemplate.DataTipRows = EstPlot.DataTipTemplate.DataTipRows([1, 2, 3]);
                EmaxPlot.DataTipTemplate.DataTipRows(3).Label = 'Nivel (Emáx)';
                EmaxPlot.DataTipTemplate.DataTipRows(3).Value = app.Data_Meas_cache_Select.('Emáx (V/m)')(app.EditFieldRow);
                EmaxPlot.DataTipTemplate.DataTipRows(3).Format = '%2.2f V/m';

                % Define limtes geográficos conforme arquivos de meidições
                % geolimits(app.mapAxes, [Lat_Est-0.05, Lat_Est+0.05], [Long_Est-0.05, Long_Est+0.05]);

                general_ControlPanelSelectionChanged(app, struct('Source', app.menu_Button4Icon))

        end

        % Image clicked function: config_Folder_DataHubGETButton, 
        % ...and 3 other components
        function config_getFolder(app, event)
            
            try
                relatedFolder = eval(sprintf('app.config_Folder_%s.Value', event.Source.Tag));                    
            catch
                relatedFolder = app.General.fileFolder.(event.Source.Tag);
            end
            
            if isfolder(relatedFolder)
                initialFolder = relatedFolder;
            elseif isfile(relatedFolder)
                initialFolder = fileparts(relatedFolder);
            else
                initialFolder = app.config_Folder_userPath.Value;
            end
            
            selectedFolder = uigetdir(initialFolder);
            figure(app.UIFigure)

            if selectedFolder
                switch event.Source
                    case app.config_Folder_DataHubGETButton
                        appName  = class.Constants.appName;
                        repoName = 'DataHub - GET';

                        if strcmp(app.General.fileFolder.DataHub_GET, selectedFolder) 
                            return
                        elseif all(cellfun(@(x) contains(selectedFolder, x), {repoName, appName}))
                            app.progressDialog.Visible = 'visible';

                            app.config_Folder_DataHubGET.Value = selectedFolder;
                            app.General.fileFolder.DataHub_GET = selectedFolder;
    
                            startup_mainVariables(app)
                            app.AppInfo.Tag = '';
    
                            config_DataHubWarningLamp(app)
                        else
                            appUtil.modalWindow(app.UIFigure, 'error', sprintf('Não identificado se tratar da pasta "%s" do repositório "%s".', appName, repoName));
                        end

                    case app.config_Folder_DataHubPOSTButton
                        appName  = class.Constants.appName;
                        repoName = 'DataHub - POST';

                        if strcmp(app.General.fileFolder.DataHub_POST, selectedFolder) 
                            return
                        elseif all(cellfun(@(x) contains(selectedFolder, x), {repoName, appName}))
                            app.config_Folder_DataHubPOST.Value = selectedFolder;
                            app.General.fileFolder.DataHub_POST = selectedFolder;
    
                            config_DataHubWarningLamp(app)
                        else
                            appUtil.modalWindow(app.UIFigure, 'error', sprintf('Não identificado se tratar da pasta "%s" do repositório "%s".', appName, repoName));
                        end

                    case app.config_Folder_userPathButton
                        set(app.config_Folder_userPath, 'Items', unique([app.config_Folder_userPath.Items, selectedFolder]), ...
                                                        'Value', selectedFolder)
                        app.General.fileFolder.userPath     = selectedFolder;

                    case app.config_Folder_pythonPathButton
                        pythonPath = fullfile(selectedFolder, ccTools.fcn.OperationSystem('pythonExecutable'));
                        if isfile(pythonPath)
                            app.progressDialog.Visible = 'visible';

                            app.config_Folder_pythonPath.Value = pythonPath;
                            app.General.fileFolder.pythonPath  = pythonPath;
                            
                            try
                                pyenv('Version', pythonPath);
                            catch ME
                                appUtil.modalWindow(app.UIFigure, 'error', 'O <i>app</i> deverá ser reinicializado para que a alteração tenha efeito.');
                            end

                        else
                            appUtil.modalWindow(app.UIFigure, 'error', 'Não encontrado o arquivo executável do Python.');
                            return
                        end
                end

                appUtil.generalSettingsSave(class.Constants.appName, app.rootFolder, app.General, app.executionMode)
                app.progressDialog.Visible = 'hidden';
            end

        end

        % Image clicked function: axesTool_RegionZoom, axesTool_RestoreView
        function axesTool_InteractionImageClicked(app, event)
            
            switch event.Source
                case app.axesTool_RestoreView
                    geolimits(app.mapAxes, app.restoreView(1).xLim, app.restoreView(1).yLim)

                case app.axesTool_RegionZoom
                    plot.axes.Interactivity.GeographicRegionZoomInteraction(app.mapAxes, app.axesTool_RegionZoom)
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
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'RNI';
            app.UIFigure.Icon = 'icon_48.png';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {5, 325, 10, 5, 50, '1x', 5};
            app.GridLayout.RowHeight = {5, 22, '1x', 10, '0.4x', 5, 34, 34};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create ControlTabGrid
            app.ControlTabGrid = uigridlayout(app.GridLayout);
            app.ControlTabGrid.ColumnWidth = {'1x'};
            app.ControlTabGrid.RowHeight = {2, 24, '1x'};
            app.ControlTabGrid.ColumnSpacing = 5;
            app.ControlTabGrid.RowSpacing = 0;
            app.ControlTabGrid.Padding = [0 0 0 0];
            app.ControlTabGrid.Layout.Row = [2 5];
            app.ControlTabGrid.Layout.Column = 2;
            app.ControlTabGrid.BackgroundColor = [1 1 1];

            % Create ControlTabGroup
            app.ControlTabGroup = uitabgroup(app.ControlTabGrid);
            app.ControlTabGroup.AutoResizeChildren = 'off';
            app.ControlTabGroup.Layout.Row = [2 3];
            app.ControlTabGroup.Layout.Column = 1;

            % Create Tab_4
            app.Tab_4 = uitab(app.ControlTabGroup);

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.Tab_4);
            app.GridLayout6.ColumnWidth = {'1x'};
            app.GridLayout6.RowHeight = {22, '1x'};
            app.GridLayout6.ColumnSpacing = 20;
            app.GridLayout6.RowSpacing = 5;
            app.GridLayout6.Padding = [0 0 0 0];
            app.GridLayout6.BackgroundColor = [1 1 1];

            % Create TreeLocalRNI
            app.TreeLocalRNI = uitree(app.GridLayout6, 'checkbox');
            app.TreeLocalRNI.FontSize = 11;
            app.TreeLocalRNI.Layout.Row = 2;
            app.TreeLocalRNI.Layout.Column = 1;

            % Assign Checked Nodes
            app.TreeLocalRNI.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeLocalRNICheckedNodesChanged, true);

            % Create config_geoAxesLabel_2
            app.config_geoAxesLabel_2 = uilabel(app.GridLayout6);
            app.config_geoAxesLabel_2.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel_2.WordWrap = 'on';
            app.config_geoAxesLabel_2.FontSize = 10;
            app.config_geoAxesLabel_2.Layout.Row = 1;
            app.config_geoAxesLabel_2.Layout.Column = 1;
            app.config_geoAxesLabel_2.Text = 'LISTA DE ARQUIVOS';

            % Create Tab_1
            app.Tab_1 = uitab(app.ControlTabGroup);

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.Tab_1);
            app.GridLayout2.ColumnWidth = {'1x'};
            app.GridLayout2.RowHeight = {22, 160, 22, '1x'};
            app.GridLayout2.RowSpacing = 5;
            app.GridLayout2.Padding = [0 0 0 0];
            app.GridLayout2.BackgroundColor = [1 1 1];

            % Create ListBox_GR_UO
            app.ListBox_GR_UO = uilistbox(app.GridLayout2);
            app.ListBox_GR_UO.Items = {'GR01', 'GR02', 'GR03', 'GR04', 'GR05', 'GR06', 'GR07', 'GR08', 'GR09', 'GR10', 'GR11', 'UO001', 'UO021', 'UO031', 'UO061', 'UO062', 'UO071', 'UO072', 'UO073', 'UO081', 'UO091', 'UO092', 'UO101', 'UO111', 'UO112', 'UO113'};
            app.ListBox_GR_UO.Multiselect = 'on';
            app.ListBox_GR_UO.ValueChangedFcn = createCallbackFcn(app, @ListBox_GR_UOValueChanged, true);
            app.ListBox_GR_UO.FontSize = 11;
            app.ListBox_GR_UO.Layout.Row = 2;
            app.ListBox_GR_UO.Layout.Column = 1;
            app.ListBox_GR_UO.Value = {};

            % Create LOCALIDADELabel
            app.LOCALIDADELabel = uilabel(app.GridLayout2);
            app.LOCALIDADELabel.VerticalAlignment = 'bottom';
            app.LOCALIDADELabel.FontSize = 10;
            app.LOCALIDADELabel.Layout.Row = 3;
            app.LOCALIDADELabel.Layout.Column = 1;
            app.LOCALIDADELabel.Text = 'LOCALIDADE';

            % Create Tree
            app.Tree = uitree(app.GridLayout2, 'checkbox');
            app.Tree.Layout.Row = 4;
            app.Tree.Layout.Column = 1;

            % Assign Checked Nodes
            app.Tree.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeCheckedNodesChanged, true);

            % Create UNIDADEDESCENTRALIZADALabel
            app.UNIDADEDESCENTRALIZADALabel = uilabel(app.GridLayout2);
            app.UNIDADEDESCENTRALIZADALabel.VerticalAlignment = 'bottom';
            app.UNIDADEDESCENTRALIZADALabel.FontSize = 10;
            app.UNIDADEDESCENTRALIZADALabel.Layout.Row = 1;
            app.UNIDADEDESCENTRALIZADALabel.Layout.Column = 1;
            app.UNIDADEDESCENTRALIZADALabel.Text = 'UNIDADE DESCENTRALIZADA';

            % Create Tab_2
            app.Tab_2 = uitab(app.ControlTabGroup);

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.Tab_2);
            app.GridLayout7.ColumnWidth = {'1x', 8};
            app.GridLayout7.RowHeight = {22, 166, 22, 66, 12, '1x'};
            app.GridLayout7.RowSpacing = 5;
            app.GridLayout7.Padding = [0 0 0 0];
            app.GridLayout7.BackgroundColor = [1 1 1];

            % Create ESTAOSOBANLISELabel
            app.ESTAOSOBANLISELabel = uilabel(app.GridLayout7);
            app.ESTAOSOBANLISELabel.VerticalAlignment = 'bottom';
            app.ESTAOSOBANLISELabel.FontSize = 10;
            app.ESTAOSOBANLISELabel.Layout.Row = 1;
            app.ESTAOSOBANLISELabel.Layout.Column = 1;
            app.ESTAOSOBANLISELabel.Text = 'ESTAÇÃO SOB ANÁLISE';

            % Create PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel = uilabel(app.GridLayout7);
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.VerticalAlignment = 'bottom';
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.FontSize = 10;
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Layout.Row = 3;
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Layout.Column = [1 2];
            app.PONTOSCRTICOSNOENTORNODAESTAOSOBANLISELabel.Text = 'PONTOS CRÍTICOS NO ENTORNO DA ESTAÇÃO SOB ANÁLISE';

            % Create Tree_CoordEnd
            app.Tree_CoordEnd = uitree(app.GridLayout7);
            app.Tree_CoordEnd.Layout.Row = 6;
            app.Tree_CoordEnd.Layout.Column = [1 2];

            % Create Image
            app.Image = uiimage(app.GridLayout7);
            app.Image.Layout.Row = 5;
            app.Image.Layout.Column = 2;
            app.Image.VerticalAlignment = 'bottom';
            app.Image.ImageSource = 'addSymbol_32.png';

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout7);
            app.Panel_2.Layout.Row = 4;
            app.Panel_2.Layout.Column = [1 2];

            % Create GridLayout10
            app.GridLayout10 = uigridlayout(app.Panel_2);
            app.GridLayout10.ColumnWidth = {'1x', 70, 70};
            app.GridLayout10.RowHeight = {17, 22};
            app.GridLayout10.RowSpacing = 5;
            app.GridLayout10.BackgroundColor = [1 1 1];

            % Create LatitudeLabel
            app.LatitudeLabel = uilabel(app.GridLayout10);
            app.LatitudeLabel.VerticalAlignment = 'bottom';
            app.LatitudeLabel.FontSize = 10;
            app.LatitudeLabel.Layout.Row = 1;
            app.LatitudeLabel.Layout.Column = 2;
            app.LatitudeLabel.Text = 'Latitude:';

            % Create EditField_LatGrau_2
            app.EditField_LatGrau_2 = uieditfield(app.GridLayout10, 'numeric');
            app.EditField_LatGrau_2.ValueDisplayFormat = '%.6f';
            app.EditField_LatGrau_2.HorizontalAlignment = 'left';
            app.EditField_LatGrau_2.FontSize = 11;
            app.EditField_LatGrau_2.Layout.Row = 2;
            app.EditField_LatGrau_2.Layout.Column = 2;

            % Create LongitudeLabel_2
            app.LongitudeLabel_2 = uilabel(app.GridLayout10);
            app.LongitudeLabel_2.VerticalAlignment = 'bottom';
            app.LongitudeLabel_2.FontSize = 10;
            app.LongitudeLabel_2.Layout.Row = 1;
            app.LongitudeLabel_2.Layout.Column = 3;
            app.LongitudeLabel_2.Text = 'Longitude:';

            % Create EditField_LongGrau_2
            app.EditField_LongGrau_2 = uieditfield(app.GridLayout10, 'numeric');
            app.EditField_LongGrau_2.ValueDisplayFormat = '%.6f';
            app.EditField_LongGrau_2.HorizontalAlignment = 'left';
            app.EditField_LongGrau_2.FontSize = 11;
            app.EditField_LongGrau_2.Layout.Row = 2;
            app.EditField_LongGrau_2.Layout.Column = 3;

            % Create DropDown_Tipo
            app.DropDown_Tipo = uidropdown(app.GridLayout10);
            app.DropDown_Tipo.Items = {''};
            app.DropDown_Tipo.FontSize = 11;
            app.DropDown_Tipo.BackgroundColor = [1 1 1];
            app.DropDown_Tipo.Layout.Row = 2;
            app.DropDown_Tipo.Layout.Column = 1;
            app.DropDown_Tipo.Value = '';

            % Create TipologiaLabel
            app.TipologiaLabel = uilabel(app.GridLayout10);
            app.TipologiaLabel.VerticalAlignment = 'bottom';
            app.TipologiaLabel.FontSize = 10;
            app.TipologiaLabel.Layout.Row = 1;
            app.TipologiaLabel.Layout.Column = 1;
            app.TipologiaLabel.Text = 'Tipologia:';

            % Create Panel_3
            app.Panel_3 = uipanel(app.GridLayout7);
            app.Panel_3.Layout.Row = 2;
            app.Panel_3.Layout.Column = [1 2];

            % Create GridLayout11
            app.GridLayout11 = uigridlayout(app.Panel_3);
            app.GridLayout11.ColumnWidth = {'1x', 70, 70};
            app.GridLayout11.RowHeight = {17, 22, 17, 22, 17, 22};
            app.GridLayout11.RowSpacing = 5;
            app.GridLayout11.BackgroundColor = [1 1 1];

            % Create NEstaoLabel
            app.NEstaoLabel = uilabel(app.GridLayout11);
            app.NEstaoLabel.VerticalAlignment = 'bottom';
            app.NEstaoLabel.FontSize = 10;
            app.NEstaoLabel.Layout.Row = 1;
            app.NEstaoLabel.Layout.Column = 1;
            app.NEstaoLabel.Text = 'Nº Estação:';

            % Create EditFieldNEstPont
            app.EditFieldNEstPont = uieditfield(app.GridLayout11, 'numeric');
            app.EditFieldNEstPont.ValueDisplayFormat = '%d';
            app.EditFieldNEstPont.ValueChangedFcn = createCallbackFcn(app, @EditFieldDist_PARNIValueChanged2, true);
            app.EditFieldNEstPont.HorizontalAlignment = 'left';
            app.EditFieldNEstPont.FontSize = 11;
            app.EditFieldNEstPont.Layout.Row = 2;
            app.EditFieldNEstPont.Layout.Column = 1;

            % Create DropDown_UF
            app.DropDown_UF = uidropdown(app.GridLayout11);
            app.DropDown_UF.Items = {};
            app.DropDown_UF.ValueChangedFcn = createCallbackFcn(app, @DropDown_UFValueChanged, true);
            app.DropDown_UF.FontSize = 11;
            app.DropDown_UF.BackgroundColor = [1 1 1];
            app.DropDown_UF.Layout.Row = 4;
            app.DropDown_UF.Layout.Column = 1;
            app.DropDown_UF.Value = {};

            % Create UFLabel
            app.UFLabel = uilabel(app.GridLayout11);
            app.UFLabel.VerticalAlignment = 'bottom';
            app.UFLabel.FontSize = 10;
            app.UFLabel.Layout.Row = 3;
            app.UFLabel.Layout.Column = 1;
            app.UFLabel.Text = 'UF:';

            % Create LocalidadeLabel
            app.LocalidadeLabel = uilabel(app.GridLayout11);
            app.LocalidadeLabel.VerticalAlignment = 'bottom';
            app.LocalidadeLabel.FontSize = 10;
            app.LocalidadeLabel.Layout.Row = 3;
            app.LocalidadeLabel.Layout.Column = 2;
            app.LocalidadeLabel.Text = 'Localidade:';

            % Create DropDown_Local
            app.DropDown_Local = uidropdown(app.GridLayout11);
            app.DropDown_Local.Items = {};
            app.DropDown_Local.FontSize = 11;
            app.DropDown_Local.BackgroundColor = [1 1 1];
            app.DropDown_Local.Layout.Row = 4;
            app.DropDown_Local.Layout.Column = [2 3];
            app.DropDown_Local.Value = {};

            % Create ServioLabel
            app.ServioLabel = uilabel(app.GridLayout11);
            app.ServioLabel.VerticalAlignment = 'bottom';
            app.ServioLabel.FontSize = 10;
            app.ServioLabel.Layout.Row = 5;
            app.ServioLabel.Layout.Column = 1;
            app.ServioLabel.Text = 'Serviço:';

            % Create DropDown_Serv
            app.DropDown_Serv = uidropdown(app.GridLayout11);
            app.DropDown_Serv.Items = {''};
            app.DropDown_Serv.FontSize = 11;
            app.DropDown_Serv.BackgroundColor = [1 1 1];
            app.DropDown_Serv.Layout.Row = 6;
            app.DropDown_Serv.Layout.Column = [1 2];
            app.DropDown_Serv.Value = '';

            % Create LatitudeLabel_2
            app.LatitudeLabel_2 = uilabel(app.GridLayout11);
            app.LatitudeLabel_2.VerticalAlignment = 'bottom';
            app.LatitudeLabel_2.FontSize = 10;
            app.LatitudeLabel_2.Layout.Row = 1;
            app.LatitudeLabel_2.Layout.Column = 2;
            app.LatitudeLabel_2.Text = 'Latitude:';

            % Create EditField_LatGrau
            app.EditField_LatGrau = uieditfield(app.GridLayout11, 'numeric');
            app.EditField_LatGrau.ValueDisplayFormat = '%.6f';
            app.EditField_LatGrau.HorizontalAlignment = 'left';
            app.EditField_LatGrau.FontSize = 11;
            app.EditField_LatGrau.Layout.Row = 2;
            app.EditField_LatGrau.Layout.Column = 2;

            % Create LongitudeLabel
            app.LongitudeLabel = uilabel(app.GridLayout11);
            app.LongitudeLabel.VerticalAlignment = 'bottom';
            app.LongitudeLabel.FontSize = 10;
            app.LongitudeLabel.Layout.Row = 1;
            app.LongitudeLabel.Layout.Column = 3;
            app.LongitudeLabel.Text = 'Longitude:';

            % Create EditField_LongGrau
            app.EditField_LongGrau = uieditfield(app.GridLayout11, 'numeric');
            app.EditField_LongGrau.ValueDisplayFormat = '%.6f';
            app.EditField_LongGrau.HorizontalAlignment = 'left';
            app.EditField_LongGrau.FontSize = 11;
            app.EditField_LongGrau.Layout.Row = 2;
            app.EditField_LongGrau.Layout.Column = 3;

            % Create DistnciamLabel
            app.DistnciamLabel = uilabel(app.GridLayout11);
            app.DistnciamLabel.FontSize = 10;
            app.DistnciamLabel.Layout.Row = 5;
            app.DistnciamLabel.Layout.Column = 3;
            app.DistnciamLabel.Text = 'Distância (m):';

            % Create EditField_DistPont
            app.EditField_DistPont = uieditfield(app.GridLayout11, 'numeric');
            app.EditField_DistPont.ValueDisplayFormat = '%.1f';
            app.EditField_DistPont.HorizontalAlignment = 'left';
            app.EditField_DistPont.FontSize = 11;
            app.EditField_DistPont.Layout.Row = 6;
            app.EditField_DistPont.Layout.Column = 3;

            % Create Tab_5
            app.Tab_5 = uitab(app.ControlTabGroup);

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.Tab_5);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {22, '1x'};
            app.GridLayout5.RowSpacing = 5;
            app.GridLayout5.Padding = [0 0 0 0];
            app.GridLayout5.BackgroundColor = [1 1 1];

            % Create REGISTROSELECIONADOLabel
            app.REGISTROSELECIONADOLabel = uilabel(app.GridLayout5);
            app.REGISTROSELECIONADOLabel.VerticalAlignment = 'bottom';
            app.REGISTROSELECIONADOLabel.FontSize = 10;
            app.REGISTROSELECIONADOLabel.Layout.Row = 1;
            app.REGISTROSELECIONADOLabel.Layout.Column = 1;
            app.REGISTROSELECIONADOLabel.Text = 'REGISTRO SELECIONADO';

            % Create Panel
            app.Panel = uipanel(app.GridLayout5);
            app.Panel.Layout.Row = 2;
            app.Panel.Layout.Column = 1;

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.Panel);
            app.GridLayout9.ColumnWidth = {'1x'};
            app.GridLayout9.RowHeight = {'1x'};
            app.GridLayout9.Padding = [0 0 0 0];
            app.GridLayout9.BackgroundColor = [1 1 1];

            % Create HTML
            app.HTML = uihtml(app.GridLayout9);
            app.HTML.Layout.Row = 1;
            app.HTML.Layout.Column = 1;

            % Create Tab_3
            app.Tab_3 = uitab(app.ControlTabGroup);
            app.Tab_3.AutoResizeChildren = 'off';

            % Create Tab3_Grid
            app.Tab3_Grid = uigridlayout(app.Tab_3);
            app.Tab3_Grid.ColumnWidth = {'1x', 16};
            app.Tab3_Grid.RowHeight = {22, 112, 22, 72, 22, '1x'};
            app.Tab3_Grid.ColumnSpacing = 5;
            app.Tab3_Grid.RowSpacing = 5;
            app.Tab3_Grid.Padding = [0 0 0 0];
            app.Tab3_Grid.BackgroundColor = [1 1 1];

            % Create config_geoAxesLabel
            app.config_geoAxesLabel = uilabel(app.Tab3_Grid);
            app.config_geoAxesLabel.VerticalAlignment = 'bottom';
            app.config_geoAxesLabel.WordWrap = 'on';
            app.config_geoAxesLabel.FontSize = 10;
            app.config_geoAxesLabel.Layout.Row = 1;
            app.config_geoAxesLabel.Layout.Column = [1 2];
            app.config_geoAxesLabel.Text = 'MAPA';

            % Create config_Refresh
            app.config_Refresh = uiimage(app.Tab3_Grid);
            app.config_Refresh.Visible = 'off';
            app.config_Refresh.Tooltip = {'Volta à configuração inicial'};
            app.config_Refresh.Layout.Row = 1;
            app.config_Refresh.Layout.Column = 2;
            app.config_Refresh.VerticalAlignment = 'bottom';
            app.config_Refresh.ImageSource = 'Refresh_18.png';

            % Create ANLISELabel
            app.ANLISELabel = uilabel(app.Tab3_Grid);
            app.ANLISELabel.VerticalAlignment = 'bottom';
            app.ANLISELabel.FontSize = 10;
            app.ANLISELabel.Layout.Row = 3;
            app.ANLISELabel.Layout.Column = 1;
            app.ANLISELabel.Text = 'ANÁLISE';

            % Create misc_ElevationSourcePanel
            app.misc_ElevationSourcePanel = uipanel(app.Tab3_Grid);
            app.misc_ElevationSourcePanel.AutoResizeChildren = 'off';
            app.misc_ElevationSourcePanel.Layout.Row = 4;
            app.misc_ElevationSourcePanel.Layout.Column = [1 2];

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.misc_ElevationSourcePanel);
            app.GridLayout8.ColumnWidth = {'1x', 110};
            app.GridLayout8.RowHeight = {22, 22};
            app.GridLayout8.RowSpacing = 5;
            app.GridLayout8.BackgroundColor = [1 1 1];

            % Create DisMedicoesLabel
            app.DisMedicoesLabel = uilabel(app.GridLayout8);
            app.DisMedicoesLabel.WordWrap = 'on';
            app.DisMedicoesLabel.FontSize = 10;
            app.DisMedicoesLabel.Layout.Row = 1;
            app.DisMedicoesLabel.Layout.Column = 1;
            app.DisMedicoesLabel.Text = 'Distância limite entre ponto de medição e estação sob análise (m):';

            % Create DistPARNILabel
            app.DistPARNILabel = uilabel(app.GridLayout8);
            app.DistPARNILabel.WordWrap = 'on';
            app.DistPARNILabel.FontSize = 10;
            app.DistPARNILabel.Layout.Row = 2;
            app.DistPARNILabel.Layout.Column = 1;
            app.DistPARNILabel.Text = 'Distância da estação (PA_RNI) (m):';

            % Create EditFieldDistMedicoes
            app.EditFieldDistMedicoes = uieditfield(app.GridLayout8, 'numeric');
            app.EditFieldDistMedicoes.ValueChangedFcn = createCallbackFcn(app, @EditFieldDistMedicoesValueChanged2, true);
            app.EditFieldDistMedicoes.FontSize = 11;
            app.EditFieldDistMedicoes.Layout.Row = 1;
            app.EditFieldDistMedicoes.Layout.Column = 2;
            app.EditFieldDistMedicoes.Value = 200;

            % Create EditFieldDist_PARNI
            app.EditFieldDist_PARNI = uieditfield(app.GridLayout8, 'numeric');
            app.EditFieldDist_PARNI.FontSize = 11;
            app.EditFieldDist_PARNI.Layout.Row = 2;
            app.EditFieldDist_PARNI.Layout.Column = 2;
            app.EditFieldDist_PARNI.Value = 200;

            % Create config_FolderMapPanel
            app.config_FolderMapPanel = uipanel(app.Tab3_Grid);
            app.config_FolderMapPanel.AutoResizeChildren = 'off';
            app.config_FolderMapPanel.Layout.Row = 6;
            app.config_FolderMapPanel.Layout.Column = [1 2];

            % Create config_FolderMapGrid
            app.config_FolderMapGrid = uigridlayout(app.config_FolderMapPanel);
            app.config_FolderMapGrid.ColumnWidth = {'1x', 20};
            app.config_FolderMapGrid.RowHeight = {17, 22, 17, 22, 17, 22, 17, 22};
            app.config_FolderMapGrid.ColumnSpacing = 5;
            app.config_FolderMapGrid.RowSpacing = 5;
            app.config_FolderMapGrid.Padding = [10 10 10 5];
            app.config_FolderMapGrid.BackgroundColor = [1 1 1];

            % Create config_Folder_DataHubGETLabel
            app.config_Folder_DataHubGETLabel = uilabel(app.config_FolderMapGrid);
            app.config_Folder_DataHubGETLabel.VerticalAlignment = 'bottom';
            app.config_Folder_DataHubGETLabel.FontSize = 10;
            app.config_Folder_DataHubGETLabel.Layout.Row = 1;
            app.config_Folder_DataHubGETLabel.Layout.Column = 1;
            app.config_Folder_DataHubGETLabel.Text = 'DataHub - GET:';

            % Create config_Folder_DataHubGET
            app.config_Folder_DataHubGET = uieditfield(app.config_FolderMapGrid, 'text');
            app.config_Folder_DataHubGET.Editable = 'off';
            app.config_Folder_DataHubGET.FontSize = 11;
            app.config_Folder_DataHubGET.Layout.Row = 2;
            app.config_Folder_DataHubGET.Layout.Column = 1;

            % Create config_Folder_DataHubGETButton
            app.config_Folder_DataHubGETButton = uiimage(app.config_FolderMapGrid);
            app.config_Folder_DataHubGETButton.ImageClickedFcn = createCallbackFcn(app, @config_getFolder, true);
            app.config_Folder_DataHubGETButton.Tag = 'DataHub_GET';
            app.config_Folder_DataHubGETButton.Layout.Row = 2;
            app.config_Folder_DataHubGETButton.Layout.Column = 2;
            app.config_Folder_DataHubGETButton.ImageSource = fullfile(pathToMLAPP, 'Icons', 'OpenFile_36x36.png');

            % Create config_Folder_DataHubPOSTLabel
            app.config_Folder_DataHubPOSTLabel = uilabel(app.config_FolderMapGrid);
            app.config_Folder_DataHubPOSTLabel.VerticalAlignment = 'bottom';
            app.config_Folder_DataHubPOSTLabel.FontSize = 10;
            app.config_Folder_DataHubPOSTLabel.Layout.Row = 3;
            app.config_Folder_DataHubPOSTLabel.Layout.Column = 1;
            app.config_Folder_DataHubPOSTLabel.Text = 'DataHub - POST:';

            % Create config_Folder_DataHubPOST
            app.config_Folder_DataHubPOST = uieditfield(app.config_FolderMapGrid, 'text');
            app.config_Folder_DataHubPOST.Editable = 'off';
            app.config_Folder_DataHubPOST.FontSize = 11;
            app.config_Folder_DataHubPOST.Layout.Row = 4;
            app.config_Folder_DataHubPOST.Layout.Column = 1;

            % Create config_Folder_DataHubPOSTButton
            app.config_Folder_DataHubPOSTButton = uiimage(app.config_FolderMapGrid);
            app.config_Folder_DataHubPOSTButton.ImageClickedFcn = createCallbackFcn(app, @config_getFolder, true);
            app.config_Folder_DataHubPOSTButton.Tag = 'DataHub_POST';
            app.config_Folder_DataHubPOSTButton.Layout.Row = 4;
            app.config_Folder_DataHubPOSTButton.Layout.Column = 2;
            app.config_Folder_DataHubPOSTButton.ImageSource = fullfile(pathToMLAPP, 'Icons', 'OpenFile_36x36.png');

            % Create config_Folder_pythonPathLabel
            app.config_Folder_pythonPathLabel = uilabel(app.config_FolderMapGrid);
            app.config_Folder_pythonPathLabel.VerticalAlignment = 'bottom';
            app.config_Folder_pythonPathLabel.FontSize = 10;
            app.config_Folder_pythonPathLabel.Layout.Row = 5;
            app.config_Folder_pythonPathLabel.Layout.Column = 1;
            app.config_Folder_pythonPathLabel.Text = 'Pasta do ambiente virtual Python (lib fiscaliza):';

            % Create config_Folder_pythonPath
            app.config_Folder_pythonPath = uieditfield(app.config_FolderMapGrid, 'text');
            app.config_Folder_pythonPath.Editable = 'off';
            app.config_Folder_pythonPath.FontSize = 11;
            app.config_Folder_pythonPath.Layout.Row = 6;
            app.config_Folder_pythonPath.Layout.Column = 1;

            % Create config_Folder_pythonPathButton
            app.config_Folder_pythonPathButton = uiimage(app.config_FolderMapGrid);
            app.config_Folder_pythonPathButton.ImageClickedFcn = createCallbackFcn(app, @config_getFolder, true);
            app.config_Folder_pythonPathButton.Tag = 'pythonPath';
            app.config_Folder_pythonPathButton.Layout.Row = 6;
            app.config_Folder_pythonPathButton.Layout.Column = 2;
            app.config_Folder_pythonPathButton.ImageSource = fullfile(pathToMLAPP, 'Icons', 'OpenFile_36x36.png');

            % Create config_Folder_userPathLabel
            app.config_Folder_userPathLabel = uilabel(app.config_FolderMapGrid);
            app.config_Folder_userPathLabel.VerticalAlignment = 'bottom';
            app.config_Folder_userPathLabel.FontSize = 10;
            app.config_Folder_userPathLabel.Layout.Row = 7;
            app.config_Folder_userPathLabel.Layout.Column = 1;
            app.config_Folder_userPathLabel.Text = 'Pasta do usuário:';

            % Create config_Folder_userPath
            app.config_Folder_userPath = uidropdown(app.config_FolderMapGrid);
            app.config_Folder_userPath.Items = {''};
            app.config_Folder_userPath.FontSize = 11;
            app.config_Folder_userPath.BackgroundColor = [1 1 1];
            app.config_Folder_userPath.Layout.Row = 8;
            app.config_Folder_userPath.Layout.Column = 1;
            app.config_Folder_userPath.Value = '';

            % Create config_Folder_userPathButton
            app.config_Folder_userPathButton = uiimage(app.config_FolderMapGrid);
            app.config_Folder_userPathButton.ImageClickedFcn = createCallbackFcn(app, @config_getFolder, true);
            app.config_Folder_userPathButton.Tag = 'userPath';
            app.config_Folder_userPathButton.Layout.Row = 8;
            app.config_Folder_userPathButton.Layout.Column = 2;
            app.config_Folder_userPathButton.ImageSource = fullfile(pathToMLAPP, 'Icons', 'OpenFile_36x36.png');

            % Create config_FolderMapLabel
            app.config_FolderMapLabel = uilabel(app.Tab3_Grid);
            app.config_FolderMapLabel.VerticalAlignment = 'bottom';
            app.config_FolderMapLabel.FontSize = 10;
            app.config_FolderMapLabel.Layout.Row = 5;
            app.config_FolderMapLabel.Layout.Column = 1;
            app.config_FolderMapLabel.Text = 'MAPEAMENTO DE PASTAS';

            % Create config_geoAxesSubPanel
            app.config_geoAxesSubPanel = uipanel(app.Tab3_Grid);
            app.config_geoAxesSubPanel.Layout.Row = 2;
            app.config_geoAxesSubPanel.Layout.Column = [1 2];

            % Create config_geoAxesSubGrid
            app.config_geoAxesSubGrid = uigridlayout(app.config_geoAxesSubPanel);
            app.config_geoAxesSubGrid.RowHeight = {17, 22, 17, 22};
            app.config_geoAxesSubGrid.RowSpacing = 5;
            app.config_geoAxesSubGrid.Padding = [10 10 10 5];
            app.config_geoAxesSubGrid.BackgroundColor = [1 1 1];

            % Create config_BasemapLabel
            app.config_BasemapLabel = uilabel(app.config_geoAxesSubGrid);
            app.config_BasemapLabel.VerticalAlignment = 'bottom';
            app.config_BasemapLabel.FontSize = 10;
            app.config_BasemapLabel.Layout.Row = 1;
            app.config_BasemapLabel.Layout.Column = 1;
            app.config_BasemapLabel.Text = 'Basemap:';

            % Create config_Basemap
            app.config_Basemap = uidropdown(app.config_geoAxesSubGrid);
            app.config_Basemap.Items = {'none', 'darkwater', 'streets-light', 'streets-dark', 'satellite', 'topographic', 'grayterrain'};
            app.config_Basemap.FontSize = 11;
            app.config_Basemap.BackgroundColor = [1 1 1];
            app.config_Basemap.Layout.Row = 2;
            app.config_Basemap.Layout.Column = 1;
            app.config_Basemap.Value = 'satellite';

            % Create config_ColormapLabel
            app.config_ColormapLabel = uilabel(app.config_geoAxesSubGrid);
            app.config_ColormapLabel.VerticalAlignment = 'bottom';
            app.config_ColormapLabel.FontSize = 10;
            app.config_ColormapLabel.Layout.Row = 1;
            app.config_ColormapLabel.Layout.Column = 2;
            app.config_ColormapLabel.Text = 'Mapa de cor:';

            % Create config_Colormap
            app.config_Colormap = uidropdown(app.config_geoAxesSubGrid);
            app.config_Colormap.Items = {'winter', 'parula', 'turbo', 'gray', 'hot', 'jet', 'summer'};
            app.config_Colormap.FontSize = 11;
            app.config_Colormap.BackgroundColor = [1 1 1];
            app.config_Colormap.Layout.Row = 2;
            app.config_Colormap.Layout.Column = 2;
            app.config_Colormap.Value = 'winter';

            % Create DropDownLocalBarra
            app.DropDownLocalBarra = uidropdown(app.config_geoAxesSubGrid);
            app.DropDownLocalBarra.Items = {'off', 'east', 'eastoutside', 'south', 'southoutside'};
            app.DropDownLocalBarra.ValueChangedFcn = createCallbackFcn(app, @DropDownLocalBarraValueChanged, true);
            app.DropDownLocalBarra.FontSize = 11;
            app.DropDownLocalBarra.BackgroundColor = [1 1 1];
            app.DropDownLocalBarra.Layout.Row = 4;
            app.DropDownLocalBarra.Layout.Column = 1;
            app.DropDownLocalBarra.Value = 'off';

            % Create LegendadecorLabel
            app.LegendadecorLabel = uilabel(app.config_geoAxesSubGrid);
            app.LegendadecorLabel.VerticalAlignment = 'bottom';
            app.LegendadecorLabel.FontSize = 10;
            app.LegendadecorLabel.Layout.Row = 3;
            app.LegendadecorLabel.Layout.Column = 1;
            app.LegendadecorLabel.Text = 'Legenda de cor:';

            % Create LimitesLabel
            app.LimitesLabel = uilabel(app.config_geoAxesSubGrid);
            app.LimitesLabel.VerticalAlignment = 'bottom';
            app.LimitesLabel.FontSize = 10;
            app.LimitesLabel.Layout.Row = 3;
            app.LimitesLabel.Layout.Column = 2;
            app.LimitesLabel.Text = 'Limites:';

            % Create play_Persistance_cLim_Grid2
            app.play_Persistance_cLim_Grid2 = uigridlayout(app.config_geoAxesSubGrid);
            app.play_Persistance_cLim_Grid2.ColumnWidth = {'1x', 10, '1x'};
            app.play_Persistance_cLim_Grid2.RowHeight = {'1x'};
            app.play_Persistance_cLim_Grid2.ColumnSpacing = 0;
            app.play_Persistance_cLim_Grid2.RowSpacing = 5;
            app.play_Persistance_cLim_Grid2.Padding = [0 0 0 0];
            app.play_Persistance_cLim_Grid2.Layout.Row = 4;
            app.play_Persistance_cLim_Grid2.Layout.Column = 2;
            app.play_Persistance_cLim_Grid2.BackgroundColor = [1 1 1];

            % Create play_Persistance_cLim1
            app.play_Persistance_cLim1 = uispinner(app.play_Persistance_cLim_Grid2);
            app.play_Persistance_cLim1.Step = 0.1;
            app.play_Persistance_cLim1.Limits = [0 Inf];
            app.play_Persistance_cLim1.ValueDisplayFormat = '%.3f';
            app.play_Persistance_cLim1.ValueChangedFcn = createCallbackFcn(app, @DropDownlocalNivelMenorValueChanged, true);
            app.play_Persistance_cLim1.FontSize = 11;
            app.play_Persistance_cLim1.Enable = 'off';
            app.play_Persistance_cLim1.Tooltip = {''};
            app.play_Persistance_cLim1.Layout.Row = 1;
            app.play_Persistance_cLim1.Layout.Column = 1;

            % Create play_Persistance_cLim2
            app.play_Persistance_cLim2 = uispinner(app.play_Persistance_cLim_Grid2);
            app.play_Persistance_cLim2.Limits = [0 Inf];
            app.play_Persistance_cLim2.ValueDisplayFormat = '%.3f';
            app.play_Persistance_cLim2.ValueChangedFcn = createCallbackFcn(app, @DropDownlocalNivelMenorValueChanged, true);
            app.play_Persistance_cLim2.FontSize = 11;
            app.play_Persistance_cLim2.Enable = 'off';
            app.play_Persistance_cLim2.Tooltip = {''};
            app.play_Persistance_cLim2.Layout.Row = 1;
            app.play_Persistance_cLim2.Layout.Column = 3;
            app.play_Persistance_cLim2.Value = 1;

            % Create Label
            app.Label = uilabel(app.play_Persistance_cLim_Grid2);
            app.Label.HorizontalAlignment = 'center';
            app.Label.FontSize = 10;
            app.Label.Enable = 'off';
            app.Label.Layout.Row = 1;
            app.Label.Layout.Column = 2;
            app.Label.Text = '-';

            % Create menu_MainGrid
            app.menu_MainGrid = uigridlayout(app.ControlTabGrid);
            app.menu_MainGrid.ColumnWidth = {'1x', 22, 22, 22, 22};
            app.menu_MainGrid.RowHeight = {'1x', 3};
            app.menu_MainGrid.ColumnSpacing = 1;
            app.menu_MainGrid.RowSpacing = 0;
            app.menu_MainGrid.Padding = [0 0 0 0];
            app.menu_MainGrid.Layout.Row = [1 2];
            app.menu_MainGrid.Layout.Column = 1;
            app.menu_MainGrid.BackgroundColor = [1 1 1];

            % Create menuUnderline
            app.menuUnderline = uiimage(app.menu_MainGrid);
            app.menuUnderline.ScaleMethod = 'scaleup';
            app.menuUnderline.Layout.Row = 2;
            app.menuUnderline.Layout.Column = 1;
            app.menuUnderline.ImageSource = 'LineH.png';

            % Create menu_Button1Grid
            app.menu_Button1Grid = uigridlayout(app.menu_MainGrid);
            app.menu_Button1Grid.ColumnWidth = {18, '1x'};
            app.menu_Button1Grid.RowHeight = {'1x'};
            app.menu_Button1Grid.ColumnSpacing = 3;
            app.menu_Button1Grid.Padding = [2 0 0 0];
            app.menu_Button1Grid.Layout.Row = 1;
            app.menu_Button1Grid.Layout.Column = 1;
            app.menu_Button1Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create menu_Button1Label
            app.menu_Button1Label = uilabel(app.menu_Button1Grid);
            app.menu_Button1Label.FontSize = 11;
            app.menu_Button1Label.Layout.Row = 1;
            app.menu_Button1Label.Layout.Column = 2;
            app.menu_Button1Label.Text = 'ARQUIVOS';

            % Create menu_Button1Icon
            app.menu_Button1Icon = uiimage(app.menu_Button1Grid);
            app.menu_Button1Icon.ScaleMethod = 'none';
            app.menu_Button1Icon.ImageClickedFcn = createCallbackFcn(app, @general_ControlPanelSelectionChanged, true);
            app.menu_Button1Icon.Tag = '1';
            app.menu_Button1Icon.Layout.Row = 1;
            app.menu_Button1Icon.Layout.Column = [1 2];
            app.menu_Button1Icon.HorizontalAlignment = 'left';
            app.menu_Button1Icon.ImageSource = fullfile(pathToMLAPP, 'Icons', 'mosaic_18Gray.png');

            % Create menu_Button2Grid
            app.menu_Button2Grid = uigridlayout(app.menu_MainGrid);
            app.menu_Button2Grid.ColumnWidth = {18, 0};
            app.menu_Button2Grid.RowHeight = {'1x'};
            app.menu_Button2Grid.ColumnSpacing = 3;
            app.menu_Button2Grid.Padding = [2 0 0 0];
            app.menu_Button2Grid.Layout.Row = 1;
            app.menu_Button2Grid.Layout.Column = 2;
            app.menu_Button2Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create menu_Button2Label
            app.menu_Button2Label = uilabel(app.menu_Button2Grid);
            app.menu_Button2Label.FontSize = 11;
            app.menu_Button2Label.Layout.Row = 1;
            app.menu_Button2Label.Layout.Column = 2;
            app.menu_Button2Label.Text = 'FILTRAGEM';

            % Create menu_Button2Icon
            app.menu_Button2Icon = uiimage(app.menu_Button2Grid);
            app.menu_Button2Icon.ScaleMethod = 'none';
            app.menu_Button2Icon.ImageClickedFcn = createCallbackFcn(app, @general_ControlPanelSelectionChanged, true);
            app.menu_Button2Icon.Tag = '2';
            app.menu_Button2Icon.Layout.Row = 1;
            app.menu_Button2Icon.Layout.Column = [1 2];
            app.menu_Button2Icon.HorizontalAlignment = 'left';
            app.menu_Button2Icon.ImageSource = 'Filter_18.png';

            % Create menu_Button3Grid
            app.menu_Button3Grid = uigridlayout(app.menu_MainGrid);
            app.menu_Button3Grid.ColumnWidth = {18, 0};
            app.menu_Button3Grid.RowHeight = {'1x'};
            app.menu_Button3Grid.ColumnSpacing = 3;
            app.menu_Button3Grid.Padding = [2 0 0 0];
            app.menu_Button3Grid.Layout.Row = 1;
            app.menu_Button3Grid.Layout.Column = 3;
            app.menu_Button3Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create menu_Button3Label
            app.menu_Button3Label = uilabel(app.menu_Button3Grid);
            app.menu_Button3Label.FontSize = 11;
            app.menu_Button3Label.Layout.Row = 1;
            app.menu_Button3Label.Layout.Column = 2;
            app.menu_Button3Label.Text = 'DEMANDAS PONTUAIS';

            % Create menu_Button3Icon
            app.menu_Button3Icon = uiimage(app.menu_Button3Grid);
            app.menu_Button3Icon.ScaleMethod = 'none';
            app.menu_Button3Icon.ImageClickedFcn = createCallbackFcn(app, @general_ControlPanelSelectionChanged, true);
            app.menu_Button3Icon.Tag = '3';
            app.menu_Button3Icon.Layout.Row = 1;
            app.menu_Button3Icon.Layout.Column = [1 2];
            app.menu_Button3Icon.HorizontalAlignment = 'left';
            app.menu_Button3Icon.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Channel_18.png');

            % Create menu_Button4Grid
            app.menu_Button4Grid = uigridlayout(app.menu_MainGrid);
            app.menu_Button4Grid.ColumnWidth = {18, 0};
            app.menu_Button4Grid.RowHeight = {'1x'};
            app.menu_Button4Grid.ColumnSpacing = 3;
            app.menu_Button4Grid.Padding = [2 0 0 0];
            app.menu_Button4Grid.Layout.Row = 1;
            app.menu_Button4Grid.Layout.Column = 4;
            app.menu_Button4Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create menu_Button4Label
            app.menu_Button4Label = uilabel(app.menu_Button4Grid);
            app.menu_Button4Label.FontSize = 11;
            app.menu_Button4Label.Layout.Row = 1;
            app.menu_Button4Label.Layout.Column = 2;
            app.menu_Button4Label.Text = 'REGISTRO SELECIONADO';

            % Create menu_Button4Icon
            app.menu_Button4Icon = uiimage(app.menu_Button4Grid);
            app.menu_Button4Icon.ScaleMethod = 'none';
            app.menu_Button4Icon.ImageClickedFcn = createCallbackFcn(app, @general_ControlPanelSelectionChanged, true);
            app.menu_Button4Icon.Tag = '4';
            app.menu_Button4Icon.Layout.Row = 1;
            app.menu_Button4Icon.Layout.Column = [1 2];
            app.menu_Button4Icon.HorizontalAlignment = 'left';
            app.menu_Button4Icon.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Pin_18.png');

            % Create menu_Button5Grid
            app.menu_Button5Grid = uigridlayout(app.menu_MainGrid);
            app.menu_Button5Grid.ColumnWidth = {18, 0};
            app.menu_Button5Grid.RowHeight = {'1x'};
            app.menu_Button5Grid.ColumnSpacing = 3;
            app.menu_Button5Grid.Padding = [2 0 0 0];
            app.menu_Button5Grid.Layout.Row = 1;
            app.menu_Button5Grid.Layout.Column = 5;
            app.menu_Button5Grid.BackgroundColor = [0.749 0.749 0.749];

            % Create menu_Button5Label
            app.menu_Button5Label = uilabel(app.menu_Button5Grid);
            app.menu_Button5Label.FontSize = 11;
            app.menu_Button5Label.Layout.Row = 1;
            app.menu_Button5Label.Layout.Column = 2;
            app.menu_Button5Label.Text = 'CONFIGURAÇÕES GERAIS';

            % Create menu_Button5Icon
            app.menu_Button5Icon = uiimage(app.menu_Button5Grid);
            app.menu_Button5Icon.ScaleMethod = 'none';
            app.menu_Button5Icon.ImageClickedFcn = createCallbackFcn(app, @general_ControlPanelSelectionChanged, true);
            app.menu_Button5Icon.Tag = '5';
            app.menu_Button5Icon.Layout.Row = 1;
            app.menu_Button5Icon.Layout.Column = [1 2];
            app.menu_Button5Icon.HorizontalAlignment = 'left';
            app.menu_Button5Icon.ImageSource = 'Settings_18.png';

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
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.DoubleClickedFcn = createCallbackFcn(app, @UITableDoubleClicked, true);
            app.UITable.Multiselect = 'off';
            app.UITable.ForegroundColor = [0.149 0.149 0.149];
            app.UITable.Layout.Row = 5;
            app.UITable.Layout.Column = [4 6];
            app.UITable.FontSize = 10;

            % Create toolGrid
            app.toolGrid = uigridlayout(app.GridLayout);
            app.toolGrid.ColumnWidth = {22, 22, 22, 5, 22, 22, 22, 22, '1x', 22, 22, 22};
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
            app.tool_TableVisibility.Layout.Column = 10;
            app.tool_TableVisibility.ImageSource = 'View_16.png';

            % Create tool_RFLinkButton
            app.tool_RFLinkButton = uiimage(app.toolGrid);
            app.tool_RFLinkButton.ScaleMethod = 'none';
            app.tool_RFLinkButton.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.tool_RFLinkButton.Tooltip = {'Perfil de terreno entre registro selecionado (TX) '; 'e estação de referência (RX)'};
            app.tool_RFLinkButton.Layout.Row = 2;
            app.tool_RFLinkButton.Layout.Column = 3;
            app.tool_RFLinkButton.VerticalAlignment = 'top';
            app.tool_RFLinkButton.ImageSource = 'Publish_HTML_16.png';

            % Create tool_Separator
            app.tool_Separator = uiimage(app.toolGrid);
            app.tool_Separator.Enable = 'off';
            app.tool_Separator.Layout.Row = [1 3];
            app.tool_Separator.Layout.Column = 4;
            app.tool_Separator.VerticalAlignment = 'bottom';
            app.tool_Separator.ImageSource = fullfile(pathToMLAPP, 'Icons', 'LineV.png');

            % Create GravarButton
            app.GravarButton = uiimage(app.toolGrid);
            app.GravarButton.ScaleMethod = 'none';
            app.GravarButton.ImageClickedFcn = createCallbackFcn(app, @GravarButtonPushed, true);
            app.GravarButton.Layout.Row = 2;
            app.GravarButton.Layout.Column = 5;
            app.GravarButton.ImageSource = 'Export_16.png';

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.toolGrid);
            app.jsBackDoor.Layout.Row = 2;
            app.jsBackDoor.Layout.Column = 8;

            % Create tool_tableNRows
            app.tool_tableNRows = uilabel(app.toolGrid);
            app.tool_tableNRows.HorizontalAlignment = 'right';
            app.tool_tableNRows.FontSize = 10;
            app.tool_tableNRows.FontColor = [0.6 0.6 0.6];
            app.tool_tableNRows.Layout.Row = [1 3];
            app.tool_tableNRows.Layout.Column = 9;
            app.tool_tableNRows.Text = 'Place holder pra alguma informação...';

            % Create FigurePosition
            app.FigurePosition = uiimage(app.toolGrid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.FigurePosition.Layout.Row = 2;
            app.FigurePosition.Layout.Column = 11;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'Icons', 'layout1_32.png');

            % Create AppInfo
            app.AppInfo = uiimage(app.toolGrid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @tool_InteractionImageClicked, true);
            app.AppInfo.Layout.Row = 2;
            app.AppInfo.Layout.Column = 12;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'Icons', 'Dots_32.png');

            % Create ImageOpenFile
            app.ImageOpenFile = uiimage(app.toolGrid);
            app.ImageOpenFile.ScaleMethod = 'none';
            app.ImageOpenFile.ImageClickedFcn = createCallbackFcn(app, @ImageOpenFileClicked2, true);
            app.ImageOpenFile.Layout.Row = 2;
            app.ImageOpenFile.Layout.Column = 2;
            app.ImageOpenFile.ImageSource = 'Import_16.png';

            % Create CalcularMaioresnveisButton
            app.CalcularMaioresnveisButton = uibutton(app.toolGrid, 'push');
            app.CalcularMaioresnveisButton.ButtonPushedFcn = createCallbackFcn(app, @CalcularMaioresnveisButtonPushed, true);
            app.CalcularMaioresnveisButton.Layout.Row = [1 3];
            app.CalcularMaioresnveisButton.Layout.Column = 6;
            app.CalcularMaioresnveisButton.Text = 'Calcular Maiores níveis';

            % Create PlotarKMLButton
            app.PlotarKMLButton = uibutton(app.toolGrid, 'push');
            app.PlotarKMLButton.ButtonPushedFcn = createCallbackFcn(app, @PlotarKMLButtonPushed, true);
            app.PlotarKMLButton.Layout.Row = [1 3];
            app.PlotarKMLButton.Layout.Column = 7;
            app.PlotarKMLButton.Text = 'Plotar KML';

            % Create popupContainerGrid
            app.popupContainerGrid = uigridlayout(app.GridLayout);
            app.popupContainerGrid.ColumnWidth = {'1x', 880, '1x'};
            app.popupContainerGrid.RowHeight = {'1x', 300, '1x'};
            app.popupContainerGrid.Padding = [10 31 10 10];
            app.popupContainerGrid.Layout.Row = 8;
            app.popupContainerGrid.Layout.Column = [1 7];
            app.popupContainerGrid.BackgroundColor = [1 1 1];

            % Create SplashScreen
            app.SplashScreen = uiimage(app.popupContainerGrid);
            app.SplashScreen.Layout.Row = 2;
            app.SplashScreen.Layout.Column = 2;
            app.SplashScreen.ImageSource = fullfile(pathToMLAPP, 'Icons', 'SplashScreen.gif');

            % Create Button_AddPoints
            app.Button_AddPoints = uibutton(app.UIFigure, 'push');
            app.Button_AddPoints.ButtonPushedFcn = createCallbackFcn(app, @Button_AddPointsPushed, true);
            app.Button_AddPoints.FontSize = 10;
            app.Button_AddPoints.Position = [-24 467 15 24];
            app.Button_AddPoints.Text = '+';

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
