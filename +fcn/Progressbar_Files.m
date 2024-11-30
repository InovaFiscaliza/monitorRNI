    function ProgressoBarraStatus = Progressbar_Files(app)            
            % Criar o diálogo de progresso
            d = uiprogressdlg(app.UIFigure, 'Title', 'Aguarde a importação dos dados das medições!', ...
                'Message', 'Opening the application', ...
                'Indeterminate', 'off', ... % Para ter uma barra de progresso que aumenta gradualmente
                'Value', 0);  % Valor inicial do progresso

            StepsProgress = 100;
            numOccurrences = round(StepsProgress);
            ProgressoBarraStatus = {numOccurrences d}; 
         
end
