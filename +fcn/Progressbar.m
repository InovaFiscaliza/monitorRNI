function ProgressoBarraStatus = Progressbar(app, File_Sondas)
            % Criar a figura da barra de progresso
            % Tamanho da tela
            screenSize = get(0, 'ScreenSize');
            screenWidth = screenSize(3);
            screenHeight = screenSize(4);
            
            % Define o tamanho da figura
            figWidth = 400;
            figHeight = 110;
            
            % Calcula a posição para centralizar a figura na tela
            figLeft = (screenWidth - figWidth) / 2;
            figBottom = (screenHeight - figHeight) / 2;
            
            % Cria a figura centralizada e desabilita a maximização
            fig = uifigure('Position', [figLeft, figBottom, figWidth, figHeight], 'Resize', 'off');
            
            % Criar o diálogo de progresso
            d = uiprogressdlg(fig, 'Title', 'Aguarde a importação dos dados das medições!', ...
                'Message', 'Opening the application', ...
                'Indeterminate', 'off', ... % Para ter uma barra de progresso que aumenta gradualmente
                'Value', 0);  % Valor inicial do progresso
            
            drawnow
            
            % Ler o conteúdo do arquivo para uma string
            fileContent = fileread(File_Sondas);

            % Encontrar as ocorrências da palavra-chave
            occurrences = numel(strfind(fileContent, sprintf('\n')));

            % Encontrar as ocorrências da palavra-chave 'PAUSED'
            occurrences_PAUSED = numel(strfind(fileContent, 'PAUSED'));

            % Total de linahs com iformações úteis no arquivo
            occurrences = occurrences - occurrences_PAUSED;
                
            StepsProgress = 100;
            % Número do Sterps do Progressbar
            numOccurrences = round(occurrences/StepsProgress);

            contsteps = 0;
            count_ocorrencia = 0;
            corrent_Step = 0;
end