classdef dockListOfLocation_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        GridLayout        matlab.ui.container.GridLayout
        LocationPanel     matlab.ui.container.GridLayout
        btnOK             matlab.ui.control.Button
        Location          matlab.ui.control.ListBox
        LocationLabel     matlab.ui.control.Label
        Delete            matlab.ui.control.Image
        Add               matlab.ui.control.Image
        RefLocation       matlab.ui.control.ListBox
        RefLocationLabel  matlab.ui.control.Label
        btnClose          matlab.ui.control.Image
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Container
        isDocked = true

        mainApp     % winRNI
        callingApp  % winMonitoringPlan | winMonitoringPlan_exported

        projectData
    end
    
    
    methods (Access = private)
        %-----------------------------------------------------------------%
        function updateForm(app)
            currentListOfLocations = sort(union(app.projectData.listOfLocations.Manual, app.projectData.listOfLocations.Automatic));

            app.RefLocation.Items = setdiff(app.projectData.referenceListOfLocations, currentListOfLocations, 'stable');
            app.Location.Items    = currentListOfLocations;
        end

        %-----------------------------------------------------------------%
        function updateLayout(app, editionType)
            switch editionType
                case 'RefLocationSelectionChanged'
                    app.Add.Enable        = 1;
                    app.Delete.Enable     = 0;
                    app.Location.Value    = {};

                case 'LocationSelectionChanged'
                    app.Add.Enable        = 0;
                    app.Delete.Enable     = 1;
                    app.RefLocation.Value = {};

                otherwise % 'AddedLocation' | 'DeletedLocation'
                    app.Add.Enable        = 0;
                    app.Delete.Enable     = 0;
                    app.Location.Value    = {};
                    app.RefLocation.Value = {};
            end
        end

        %-----------------------------------------------------------------%
        function CallingMainApp(app, callType, updateFlag, returnFlag, varargin)
            appBackDoor(app.callingApp, app, callType, updateFlag, returnFlag, varargin{:})
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, callingApp)
            
            app.mainApp     = callingApp.mainApp;
            app.callingApp  = callingApp;
            app.projectData = callingApp.mainApp.projectData;
            
            updateForm(app)
            
        end

        % Callback function: UIFigure, btnClose, btnOK
        function closeFcn(app, event)
            
            CallingMainApp(app, 'CLOSE', false, false)
            delete(app)
            
        end

        % Callback function: Add, Delete, Location, RefLocation
        function Callbacks(app, event)
            
            switch event.Source
                case app.RefLocation
                    updateLayout(app, 'RefLocationSelectionChanged')

                case app.Location
                    updateLayout(app, 'LocationSelectionChanged')

                case app.Add
                    if ~isempty(app.RefLocation.Value)
                        app.projectData.listOfLocations.Manual = union(app.projectData.listOfLocations.Manual, app.RefLocation.Value);
                        updateForm(app)
                        updateLayout(app, 'AddedLocation')

                        CallingMainApp(app, 'ListOfLocationChanged', true, true)                        
                    end

                case app.Delete
                    if ~isempty(app.Location.Value)
                        app.projectData.listOfLocations.Manual = setdiff(app.projectData.listOfLocations.Manual, app.Location.Value);
                        updateForm(app)
                        updateLayout(app, 'DeletedLocation')

                        CallingMainApp(app, 'ListOfLocationChanged', true, true)
                    end
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
                app.UIFigure.Position = [100 100 540 440];
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
            app.GridLayout.ColumnWidth = {'1x', 30};
            app.GridLayout.RowHeight = {30, '1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.BackgroundColor = [0.902 0.902 0.902];

            % Create btnClose
            app.btnClose = uiimage(app.GridLayout);
            app.btnClose.ScaleMethod = 'none';
            app.btnClose.ImageClickedFcn = createCallbackFcn(app, @closeFcn, true);
            app.btnClose.Tag = 'Close';
            app.btnClose.Layout.Row = 1;
            app.btnClose.Layout.Column = 2;
            app.btnClose.ImageSource = 'Delete_12SVG.svg';

            % Create LocationPanel
            app.LocationPanel = uigridlayout(app.GridLayout);
            app.LocationPanel.ColumnWidth = {247, 16, '1x', 90};
            app.LocationPanel.RowHeight = {32, 22, 22, '1x', 22};
            app.LocationPanel.ColumnSpacing = 5;
            app.LocationPanel.RowSpacing = 5;
            app.LocationPanel.Layout.Row = 2;
            app.LocationPanel.Layout.Column = [1 2];
            app.LocationPanel.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create RefLocationLabel
            app.RefLocationLabel = uilabel(app.LocationPanel);
            app.RefLocationLabel.VerticalAlignment = 'bottom';
            app.RefLocationLabel.FontSize = 10;
            app.RefLocationLabel.Layout.Row = 1;
            app.RefLocationLabel.Layout.Column = 1;
            app.RefLocationLabel.Interpreter = 'html';
            app.RefLocationLabel.Text = {'LOCALIDADES DE REFERÊNCIA:'; '<font style="color: gray; font-size: 9px;">(relacionadas às estações previstas no PM-RNI)</font>'};

            % Create RefLocation
            app.RefLocation = uilistbox(app.LocationPanel);
            app.RefLocation.Items = {};
            app.RefLocation.Multiselect = 'on';
            app.RefLocation.ValueChangedFcn = createCallbackFcn(app, @Callbacks, true);
            app.RefLocation.FontSize = 11;
            app.RefLocation.Layout.Row = [2 4];
            app.RefLocation.Layout.Column = 1;
            app.RefLocation.Value = {};

            % Create Add
            app.Add = uiimage(app.LocationPanel);
            app.Add.ImageClickedFcn = createCallbackFcn(app, @Callbacks, true);
            app.Add.Enable = 'off';
            app.Add.Tooltip = {'Adiciona localidades selecionadas'};
            app.Add.Layout.Row = 2;
            app.Add.Layout.Column = 2;
            app.Add.ImageSource = 'play_32.png';

            % Create Delete
            app.Delete = uiimage(app.LocationPanel);
            app.Delete.ImageClickedFcn = createCallbackFcn(app, @Callbacks, true);
            app.Delete.Enable = 'off';
            app.Delete.Tooltip = {'Exclui localidades selecionadas'};
            app.Delete.Layout.Row = 3;
            app.Delete.Layout.Column = 2;
            app.Delete.ImageSource = 'Delete_32Red.png';

            % Create LocationLabel
            app.LocationLabel = uilabel(app.LocationPanel);
            app.LocationLabel.VerticalAlignment = 'bottom';
            app.LocationLabel.FontSize = 10;
            app.LocationLabel.Layout.Row = 1;
            app.LocationLabel.Layout.Column = [3 4];
            app.LocationLabel.Interpreter = 'html';
            app.LocationLabel.Text = {'LOCALIDADES SOB ANÁLISE:'; '<font style="color: gray; font-size: 9px;">(relacionadas às estações previstas no PM-RNI)</font>'};

            % Create Location
            app.Location = uilistbox(app.LocationPanel);
            app.Location.Items = {};
            app.Location.Multiselect = 'on';
            app.Location.ValueChangedFcn = createCallbackFcn(app, @Callbacks, true);
            app.Location.FontSize = 11;
            app.Location.Layout.Row = [2 4];
            app.Location.Layout.Column = [3 4];
            app.Location.Value = {};

            % Create btnOK
            app.btnOK = uibutton(app.LocationPanel, 'push');
            app.btnOK.ButtonPushedFcn = createCallbackFcn(app, @closeFcn, true);
            app.btnOK.Tag = 'OK';
            app.btnOK.IconAlignment = 'right';
            app.btnOK.BackgroundColor = [0.9804 0.9804 0.9804];
            app.btnOK.Layout.Row = 5;
            app.btnOK.Layout.Column = 4;
            app.btnOK.Text = 'OK';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dockListOfLocation_exported(Container, varargin)

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
