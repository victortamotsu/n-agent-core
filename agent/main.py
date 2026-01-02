# Workaround para bug no bedrock-agentcore-starter-toolkit v0.2.5
# 
# Bug: _get_module_path_from_config em cli/runtime/dev_command.py não resolve
# paths relativos para absolutos antes de chamar relative_to(), causando
# ValueError quando config_path é absoluto e entrypoint é relativo.
#
# Issue: Quando config_path = Path.cwd() / '.bedrock_agentcore.yaml' (absoluto)
# e entrypoint = 'src/main.py' (relativo), o relative_to() falha e cai no
# fallback de usar stem:app (main:app) ao invés de src.main:app.
#
# Este arquivo serve como wrapper que re-exporta o app de src/main.py,
# permitindo que o toolkit encontre o app corretamente.
#
# TODO: Remover após correção do bug no toolkit upstream.
# GitHub: https://github.com/awslabs/bedrock-agentcore-starter-toolkit

from src.main import app  # noqa: F401

# O 'app' é re-exportado automaticamente pelo import acima
