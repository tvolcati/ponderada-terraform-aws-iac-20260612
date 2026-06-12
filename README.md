# Ponderada - Terraform na AWS

## Objetivo
Executar o tutorial oficial **Create infrastructure** da HashiCorp com Terraform na AWS, documentando o fluxo completo com evidencias de terminal, descricoes curtas e uma secao especifica dos recursos provisionados.

Tutorial utilizado: [Create infrastructure | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create)

## Estrutura do projeto
- `terraform.tf`: define a versao do Terraform e o provider AWS.
- `main.tf`: define o provider, consulta a AMI Ubuntu e cria a instancia EC2.
- `.terraform.lock.hcl`: registra a versao exata do provider utilizado.
- `artifacts/images/`: prints gerados a partir das saidas reais do terminal.
- `scripts/render_terminal_svg.sh`: script usado para transformar saidas de terminal em imagens SVG.

## Passo a passo executado

### 1. Validacao das ferramentas e credenciais
Primeiro validei a instalacao do Terraform, do AWS CLI e as credenciais disponiveis na maquina para garantir que o provisionamento poderia ser executado.

Comando principal:
```bash
aws configure list
```

![Validacao das credenciais AWS](artifacts/images/01_aws_credentials_check.svg)

### 2. Criacao dos arquivos Terraform
A estrutura seguiu o tutorial oficial, separando a configuracao do Terraform em `terraform.tf` e a infraestrutura em `main.tf`.

Arquivos criados:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}
```

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "learn-terraform"
  }
}
```

### 3. Formatacao e inicializacao do projeto
Depois de criar os arquivos, executei `terraform fmt` para padronizar a formatacao e `terraform init` para baixar o provider da AWS e inicializar o workspace.

Comandos principais:
```bash
terraform fmt
terraform init
```

![Terraform init](artifacts/images/02_terraform_init.svg)

### 4. Validacao da configuracao
Com o workspace inicializado, rodei `terraform validate` para garantir que a sintaxe e as referencias internas da configuracao estavam corretas.

Comando principal:
```bash
terraform validate
```

Resultado: `Success! The configuration is valid.`

### 5. Primeiro apply e ajuste necessario no tutorial
Ao seguir o tutorial literalmente, o primeiro `terraform apply` falhou porque a AWS recusou `t2.micro` como elegivel ao Free Tier nesta conta/regiao.

Comando principal:
```bash
terraform apply tfplan
```

![Erro com t2.micro](artifacts/images/03_apply_error_t2_micro.svg)

Para concluir o laboratorio de forma funcional em **12/06/2026**, consultei os tipos `free-tier-eligible` em `us-west-2` e ajustei o tipo da instancia para `t3.micro`, que foi aceito pela AWS nessa execucao.

Comando de apoio:
```bash
aws ec2 describe-instance-types \
  --region us-west-2 \
  --filters Name=free-tier-eligible,Values=true \
  --query 'InstanceTypes[].InstanceType' \
  --output text
```

![Tipos elegiveis ao free tier](artifacts/images/04_free_tier_types.svg)

### 6. Novo plan e apply com sucesso
Depois do ajuste, executei novamente `terraform plan` e `terraform apply`, desta vez com sucesso.

Comandos principais:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

![Terraform plan apos ajuste](artifacts/images/05_terraform_plan.svg)

![Terraform apply com sucesso](artifacts/images/06_terraform_apply_success.svg)

### 7. Inspecao do estado Terraform
Apos o provisionamento, consultei o estado do Terraform para confirmar os objetos acompanhados e os atributos da instancia criada.

Comandos principais:
```bash
terraform state list
terraform state show aws_instance.app_server
```

![Terraform state list](artifacts/images/07_terraform_state_list.svg)

### 8. Confirmacao do recurso na AWS
Tambem consultei a AWS com `describe-instances` para cruzar o resultado do Terraform com o estado efetivo da nuvem.

Comando principal:
```bash
aws ec2 describe-instances \
  --region us-west-2 \
  --filters Name=tag:Name,Values=learn-terraform
```

![Describe instances](artifacts/images/08_aws_describe_instances.svg)

### 9. Limpeza do ambiente
Como boa pratica, finalizei a atividade destruindo a infraestrutura provisionada para evitar custo residual na conta AWS.

Comando principal:
```bash
terraform destroy -auto-approve
```

![Terraform destroy](artifacts/images/09_terraform_destroy.svg)

Confirmacao final na AWS:

![Instancia encerrada](artifacts/images/10_aws_describe_instances_after_destroy.svg)

## Recursos provisionados via Terraform
Durante a execucao bem-sucedida, o Terraform provisionou diretamente o recurso `aws_instance.app_server`.

| Item | Evidencia observada | Valor obtido |
| --- | --- | --- |
| Recurso principal | `terraform state list` | `aws_instance.app_server` |
| Tipo da instancia | `terraform state show` e `describe-instances` | `t3.micro` |
| AMI | `terraform state show` | `ami-096f5760b00bcd95c` |
| Zona de disponibilidade | `terraform state show` | `us-west-2a` |
| Estado durante a validacao | `describe-instances` | `running` |
| Instance ID | `terraform state show` | `i-00036219dc46c0669` |
| Subnet | `terraform state show` | `subnet-0b03f5403aa95d557` |
| VPC | `describe-instances` | `vpc-0c4dbe28a84d1881f` |
| Security group associado | `terraform state show` | `default` / `sg-06685c3714c8f6a43` |
| Interface de rede primaria | `terraform state show` | `eni-0c59071baae446b1c` |
| Volume raiz | `terraform state show` | `vol-0595b4445f5583bff` |
| Tamanho do volume raiz | `terraform state show` | `8 GiB` |
| Tipo do volume raiz | `terraform state show` | `gp3` |
| Tag aplicada | `terraform state show` | `Name = learn-terraform` |

## Observacoes finais
- O tutorial foi seguido fielmente na estrutura, nos comandos e no fluxo geral.
- O unico ajuste tecnico necessario foi trocar `t2.micro` por `t3.micro`, porque em **12/06/2026** a propria AWS retornou erro dizendo que `t2.micro` nao estava elegivel ao Free Tier nessa execucao.
- O ambiente foi criado, validado, documentado e destruido ao final.
