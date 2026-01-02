import os
import json
import boto3
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Configure Google Gen AI SDK to use Vertex AI
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"


def test_gemini():
    """Test Gemini/Vertex AI integration using Google Gen AI SDK."""
    
    print("=" * 60)
    print("🧪 Iniciando Teste de Integração Gemini/Vertex AI")
    print("=" * 60)
    
    # Step 1: Buscar credenciais do Secrets Manager
    print("\n📦 [1/5] Buscando credenciais do AWS Secrets Manager...")
    try:
        secrets_client = boto3.client('secretsmanager', region_name='us-east-1')
        response = secrets_client.get_secret_value(SecretId='n-agent/google-cloud-credentials')
        credentials_json = json.loads(response['SecretString'])
        print(f"✅ Credenciais obtidas para: {credentials_json['client_email']}")
        project_id = credentials_json['project_id']
    except Exception as e:
        print(f"❌ Erro ao buscar credenciais: {e}")
        return False
    
    # Step 2: Salvar credenciais como arquivo (necessário para SDK)
    print("\n📝 [2/5] Salvando credenciais temporariamente...")
    try:
        import tempfile
        # Usar diretório temporário do sistema (funciona em Windows e Linux)
        temp_dir = tempfile.gettempdir()
        creds_path = os.path.join(temp_dir, "gcp-credentials.json")
        with open(creds_path, "w") as f:
            json.dump(credentials_json, f)
        
        # Configurar variável de ambiente
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = creds_path
        os.environ["GOOGLE_CLOUD_PROJECT"] = project_id
        print(f"✅ Credenciais preparadas para: {project_id}")
    except Exception as e:
        print(f"❌ Erro ao salvar credenciais: {e}")
        return False
    
    # Step 3: Importar e configurar Google Gen AI SDK
    print("\n🔐 [3/5] Inicializando Google Gen AI SDK...")
    try:
        from google import genai
        
        client = genai.Client(
            project=project_id,
            location="us-central1"
        )
        print(f"✅ Google Gen AI SDK configurado para: {project_id} (us-central1)")
    except ImportError:
        print("❌ Google Gen AI SDK não instalado. Instale com:")
        print("   pip install google-genai")
        return False
    except Exception as e:
        print(f"❌ Erro ao configurar SDK: {e}")
        return False
    
    # Step 4: Listar modelos disponíveis
    print("\n📋 [4/5] Listando modelos disponíveis...")
    try:
        models = client.models.list()
        available_models = []
        
        for model in models:
            model_name = model.name
            # Filtrar apenas modelos Gemini
            if "gemini" in model_name.lower():
                available_models.append(model_name)
        
        if available_models:
            print(f"✅ {len(available_models)} modelos Gemini encontrados:")
            for model in available_models[:10]:  # Mostrar primeiros 10
                print(f"   - {model}")
        else:
            print("⚠️  Nenhum modelo Gemini encontrado")
            return False
    except Exception as e:
        print(f"❌ Erro ao listar modelos: {e}")
        return False
    
    # Step 5: Testar geração de conteúdo com modelo mais recente
    print("\n💬 [5/5] Testando geração de conteúdo...")
    try:
        # Usar o modelo mais recente disponível
        model_to_test = "gemini-2.5-flash"  # Modelo recomendado
        
        response = client.models.generate_content(
            model=model_to_test,
            contents="Responda brevemente: O que é Inteligência Artificial? Limite sua resposta a 2 linhas."
        )
        
        if response.text:
            print(f"✅ Resposta do modelo {model_to_test}:")
            print(f"   {response.text[:200]}...")  # Primeiras 200 caracteres
            
            print("\n" + "=" * 60)
            print("🎉 Integração Gemini/Vertex AI Funcionando!")
            print("=" * 60)
            print("\n📝 Próximas etapas:")
            print("   1. Modelo testado com sucesso: gemini-2.5-flash")
            print("   2. Integrar em seu Router Agent")
            print("   3. Implementar fallback Bedrock → Gemini")
            print("   4. Configurar em produção com Service Account")
            
            # Limpar arquivo temporário
            try:
                os.remove(creds_path)
            except:
                pass
            
            return True
        else:
            print(f"❌ Nenhuma resposta do modelo")
            return False
    except Exception as e:
        print(f"❌ Erro ao testar geração de conteúdo: {e}")
        return False


if __name__ == "__main__":
    success = test_gemini()
    exit(0 if success else 1)
