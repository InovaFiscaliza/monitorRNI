function ProgressoBarraStatus = Progressbar(app, nFiles)
    % Número de passos no loop
    nSteps = 10;

    % Criar a barra de progresso
    hWaitbar = waitbar(0, 'Progresso...');

    % Loop para atualizar a barra de progresso
    for k = 1:nSteps
        % Simulação de um processamento (pause pode ser substituído por sua tarefa)
        pause(0.1);
        
        % Atualizar a barra de progresso
        updateProgressBar(hWaitbar, k, nSteps, nFiles);
    end

    % Fechar a barra de progresso
    close(hWaitbar);
end

function updateProgressBar(hWaitbar, currentStep, totalSteps, nFiles)
    progress = currentStep / totalSteps;
    waitbar(progress, hWaitbar, sprintf('Lendro Arquivo %d%% / Progresso: %d%%', nFiles, round(progress * 10)));
end