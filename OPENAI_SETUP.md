# Configuração da API OpenAI

## Desenvolvimento Local

Para usar as funcionalidades de IA do Climetry em desenvolvimento local:

1. **Obtenha sua chave API da OpenAI**
   - Acesse https://platform.openai.com/api-keys
   - Crie uma nova chave API
   - Copie a chave gerada

2. **Configure a chave no código**
   
   Edite o arquivo `lib/src/core/services/openai_service.dart` e substitua a linha 12:
   
   ```dart
   static const String _apiKey = String.fromEnvironment(
     'OPENAI_API_KEY',
     defaultValue: '', // Coloque sua chave aqui para desenvolvimento
   );
   ```
   
   Por:
   
   ```dart
   static const String _apiKey = String.fromEnvironment(
     'OPENAI_API_KEY',
     defaultValue: 'SUA_CHAVE_AQUI', // Substitua por sua chave
   );
   ```

3. **⚠️ IMPORTANTE: Não faça commit da chave**
   
   Certifique-se de que o arquivo `openai_service.dart` está no `.gitignore` ou
   remova a chave antes de fazer commit.

## Produção

Para produção, use variáveis de ambiente:

### Flutter Web
```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=sua_chave_aqui
```

### Flutter iOS/Android
```bash
flutter run --dart-define=OPENAI_API_KEY=sua_chave_aqui
```

### Build para produção
```bash
flutter build apk --dart-define=OPENAI_API_KEY=sua_chave_aqui
flutter build ios --dart-define=OPENAI_API_KEY=sua_chave_aqui
flutter build web --dart-define=OPENAI_API_KEY=sua_chave_aqui
```

## Alternativa: Usar flutter_dotenv

1. Adicione ao `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.0.2
```

2. Crie arquivo `.env` na raiz do projeto:
```
OPENAI_API_KEY=sua_chave_aqui
```

3. Adicione `.env` ao `.gitignore`

4. Carregue no `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(MyApp());
}
```

5. Use em `openai_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  // ...
}
```

## Funcionalidades que usam OpenAI

- ✅ Dicas personalizadas para atividades baseadas no clima
- ✅ Sugestões de locais alternativos quando clima ameaça evento
- ✅ Análise meteorológica detalhada de alertas climáticos
- ✅ Cards dinâmicos de insights climáticos
- ✅ Narrativa do clima em linguagem natural

## Custos Estimados

Com GPT-3.5-turbo (modelo recomendado):
- ~$0.002 por requisição
- ~100 requisições/dia por usuário ativo
- ~$0.20/dia por usuário (estimativa conservadora)

Otimize com cache e limitação de taxa para reduzir custos.
