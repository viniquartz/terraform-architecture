terraform {
  backend "azurerm" {
    # Backend configurado dinamicamente:
    # - Scripts POC: geram backend-config.tfbackend automaticamente
    # - Pipelines Jenkins: injetam configuração durante execução do job
  }
}
