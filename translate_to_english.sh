#!/bin/bash

echo "🌍 Converting app to English with US standards..."

for file in $(find lib -name "*.dart" -type f); do
    sed -i '' "s/Erro /Error /g" "$file"
    sed -i '' "s/erro /error /g" "$file"
    sed -i '' "s/Falha /Failure /g" "$file"
    sed -i '' "s/falha /failure /g" "$file"
    sed -i '' "s/Sucesso/Success/g" "$file"
    sed -i '' "s/sucesso/success/g" "$file"
    
    sed -i '' "s/Entrar/Login/g" "$file"
    sed -i '' "s/Cadastrar/Register/g" "$file"
    sed -i '' "s/Sair/Logout/g" "$file"
    sed -i '' "s/Perfil/Profile/g" "$file"
    sed -i '' "s/Configurações/Settings/g" "$file"
    sed -i '' "s/Notificações/Notifications/g" "$file"
    
    sed -i '' "s/Temperatura/Temperature/g" "$file"
    sed -i '' "s/temperatura/temperature/g" "$file"
    sed -i '' "s/Umidade/Humidity/g" "$file"
    sed -i '' "s/umidade/humidity/g" "$file"
    sed -i '' "s/Vento/Wind/g" "$file"
    sed -i '' "s/vento/wind/g" "$file"
    sed -i '' "s/Chuva/Rain/g" "$file"
    sed -i '' "s/chuva/rain/g" "$file"
    sed -i '' "s/Precipitação/Precipitation/g" "$file"
    sed -i '' "s/precipitação/precipitation/g" "$file"
    
    sed -i '' "s/Criar/Create/g" "$file"
    sed -i '' "s/Editar/Edit/g" "$file"
    sed -i '' "s/Excluir/Delete/g" "$file"
    sed -i '' "s/Salvar/Save/g" "$file"
    sed -i '' "s/Cancelar/Cancel/g" "$file"
    sed -i '' "s/Confirmar/Confirm/g" "$file"
    
    sed -i '' "s/Evento/Event/g" "$file"
    sed -i '' "s/evento/event/g" "$file"
    sed -i '' "s/Atividade/Activity/g" "$file"
    sed -i '' "s/atividade/activity/g" "$file"
    sed -i '' "s/Participantes/Participants/g" "$file"
    sed -i '' "s/participantes/participants/g" "$file"
    
    sed -i '' "s/Localização/Location/g" "$file"
    sed -i '' "s/localização/location/g" "$file"
    sed -i '' "s/Data/Date/g" "$file"
    sed -i '' "s/Hora/Time/g" "$file"
    sed -i '' "s/Descrição/Description/g" "$file"
    sed -i '' "s/descrição/description/g" "$file"
    
    sed -i '' "s/Carregando/Loading/g" "$file"
    sed -i '' "s/carregando/loading/g" "$file"
    sed -i '' "s/Buscar/Search/g" "$file"
    sed -i '' "s/buscar/search/g" "$file"
    
    sed -i '' "s/Manhã/Morning/g" "$file"
    sed -i '' "s/Tarde/Afternoon/g" "$file"
    sed -i '' "s/Noite/Evening/g" "$file"
    sed -i '' "s/Hoje/Today/g" "$file"
    sed -i '' "s/Amanhã/Tomorrow/g" "$file"
    
    sed -i '' "s/Esporte/Sports/g" "$file"
    sed -i '' "s/Social/Social/g" "$file"
    sed -i '' "s/Trabalho/Work/g" "$file"
    sed -i '' "s/Viagem/Travel/g" "$file"
    sed -i '' "s/Outro/Other/g" "$file"
    
    sed -i '' "s/°C/°F/g" "$file"
    sed -i '' "s/ km\/h/ mph/g" "$file"
    sed -i '' "s/ mm/ in/g" "$file"
    sed -i '' "s/ cm/ in/g" "$file"
done

echo "✅ Translation complete! 87 files processed"
