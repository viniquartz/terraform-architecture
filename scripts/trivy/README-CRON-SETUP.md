# Configuração Cron Job - Trivy Database Update

# Red Hat Enterprise Linux 9

## 📋 Pré-requisitos

1. Script instalado em: `/usr/local/bin/update-trivy-db.sh`
2. Usuário jenkins deve existir no sistema
3. Diretório de cache: `/home/jenkins/trivy_cache`
4. Trivy instalado e disponível no PATH

---

## 🚀 Instalação e Configuração

### 1. Copiar e preparar o script

```bash
# Como root ou com sudo
sudo cp scripts/trivy/update-trivy-db.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/update-trivy-db.sh
sudo chown root:root /usr/local/bin/update-trivy-db.sh
```

### 2. Criar diretórios necessários

```bash
# Criar diretório de logs
sudo mkdir -p /var/log/trivy
sudo chown jenkins:jenkins /var/log/trivy
sudo chmod 755 /var/log/trivy

# Criar diretório de cache (se não existir)
sudo mkdir -p /home/jenkins/trivy_cache
sudo chown -R jenkins:jenkins /home/jenkins/trivy_cache
sudo chmod 755 /home/jenkins/trivy_cache

# Verificar instalação do Trivy
trivy --version
```

### 3. Testar o script manualmente

```bash
# Executar como root (ou usuário com permissões)
sudo /usr/local/bin/update-trivy-db.sh

# Verificar logs
sudo tail -f /var/log/trivy/trivy-db-update.log

# Verificar se o banco de dados foi baixado
ls -lh /home/jenkins/trivy_cache/db/
```

### 4. Configurar Cron Job

#### Opção A: Cron do sistema (Recomendado para produção)

```bash
# Editar crontab como root
sudo crontab -e

# Adicionar uma das seguintes linhas:

# Executar todo domingo às 2h da manhã (Recomendado)
0 2 * * 0 /usr/local/bin/update-trivy-db.sh >> /var/log/trivy/cron.log 2>&1

# Ou executar toda quarta-feira às 3h da manhã
0 3 * * 3 /usr/local/bin/update-trivy-db.sh >> /var/log/trivy/cron.log 2>&1

# Ou executar diariamente às 1h da manhã (se precisar DB sempre atualizado)
0 1 * * * /usr/local/bin/update-trivy-db.sh >> /var/log/trivy/cron.log 2>&1
```

#### Opção B: Systemd Timer (Alternativa moderna)

```bash
# 1. Criar service unit
sudo tee /etc/systemd/system/trivy-db-update.service > /dev/null <<'EOF'
[Unit]
Description=Trivy Vulnerability Database Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-trivy-db.sh
User=root
StandardOutput=journal
StandardError=journal
SyslogIdentifier=trivy-update

[Install]
WantedBy=multi-user.target
EOF

# 2. Criar timer unit
sudo tee /etc/systemd/system/trivy-db-update.timer > /dev/null <<'EOF'
[Unit]
Description=Trivy DB Update Timer
Requires=trivy-db-update.service

[Timer]
# Executar toda semana no domingo às 2h
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 3. Habilitar e iniciar o timer
sudo systemctl daemon-reload
sudo systemctl enable trivy-db-update.timer
sudo systemctl start trivy-db-update.timer

# 4. Verificar status
sudo systemctl status trivy-db-update.timer
sudo systemctl list-timers | grep trivy
```

---

## 🔍 Verificação e Monitoramento

### Ver status do cron job

```bash
# Ver cron jobs ativos
sudo crontab -l

# Ver logs do cron (Red Hat 9)
sudo journalctl -u crond -f

# Ver logs específicos do script
sudo tail -f /var/log/trivy/trivy-db-update.log
```

### Monitorar execução do systemd timer

```bash
# Ver status do timer
sudo systemctl status trivy-db-update.timer

# Ver logs da última execução
sudo journalctl -u trivy-db-update.service -n 50

# Ver próximas execuções agendadas
sudo systemctl list-timers --all | grep trivy

# Executar manualmente para teste
sudo systemctl start trivy-db-update.service
```

### Verificar banco de dados

```bash
# Ver metadata do banco de dados
cat /home/jenkins/trivy_cache/db/metadata.json | jq .

# Ver tamanho do cache
du -sh /home/jenkins/trivy_cache/

# Ver arquivos no cache
tree /home/jenkins/trivy_cache/ -L 2
```

---

## 🛡️ SELinux (Se habilitado no Red Hat 9)

```bash
# Verificar se SELinux está ativo
getenforce

# Se retornar "Enforcing", adicionar contextos:
sudo semanage fcontext -a -t bin_t "/usr/local/bin/update-trivy-db.sh"
sudo restorecon -v /usr/local/bin/update-trivy-db.sh

sudo semanage fcontext -a -t var_log_t "/var/log/trivy(/.*)?"
sudo restorecon -Rv /var/log/trivy
```

---

## 📊 Troubleshooting

### Script não executa

```bash
# Verificar permissões
ls -l /usr/local/bin/update-trivy-db.sh

# Verificar se é executável
file /usr/local/bin/update-trivy-db.sh

# Testar manualmente
sudo bash -x /usr/local/bin/update-trivy-db.sh
```

### Cron não executa

```bash
# Verificar se crond está rodando
sudo systemctl status crond

# Reiniciar crond
sudo systemctl restart crond

# Ver logs de erros
sudo journalctl -u crond --since "1 hour ago"
```

### Erros de rede

```bash
# Testar conectividade
curl -I https://github.com
curl -I https://api.github.com
curl -I https://objects.githubusercontent.com

# Ver logs detalhados
sudo tail -100 /var/log/trivy/trivy-db-update.log
```

### Lock file travado

```bash
# Verificar se há processo travado
ps aux | grep trivy

# Remover lock manualmente (cuidado!)
sudo rm -f /var/run/trivy-update.lock
```

---

## 📈 Recomendações

1. **Frequência**: Executar 1x por semana é suficiente (domingos às 2h)
2. **Logs**: Implementar rotação com logrotate para /var/log/trivy
3. **Alertas**: Integrar com Teams/Dynatrace para falhas
4. **Backup**: Fazer backup do cache antes de updates (opcional)
5. **Monitoramento**: Adicionar check no Dynatrace/Zabbix

---

## 🔄 Integração com Pipeline

Com o cron job ativo, suas pipelines usarão o cache automaticamente:

```groovy
// No Jenkinsfile, o volume mount já está configurado:
args '-v /home/jenkins/trivy_cache:/home/jenkins/.cache/trivy'

// O Trivy usará o DB do cache automaticamente:
trivy config . --cache-dir /home/jenkins/.cache/trivy
```

**Vantagens:**

- ✅ Pipeline não precisa baixar DB (economia de 4-5 minutos)
- ✅ DB sempre atualizado antes do horário comercial
- ✅ Menor carga na rede durante horário de trabalho
- ✅ Falhas de rede não impactam pipelines

---

## 📋 Checklist de Instalação

- [ ] Script copiado para `/usr/local/bin/`
- [ ] Permissões executáveis configuradas
- [ ] Diretórios `/var/log/trivy` e `/home/jenkins/trivy_cache` criados
- [ ] Teste manual do script executado com sucesso
- [ ] Cron job ou systemd timer configurado
- [ ] Primeira execução verificada nos logs
- [ ] Banco de dados baixado em `/home/jenkins/trivy_cache/db/`
- [ ] URLs liberadas no firewall (GitHub endpoints)
- [ ] SELinux configurado (se aplicável)
- [ ] Monitoramento/alertas configurados (opcional)
