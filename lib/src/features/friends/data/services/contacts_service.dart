import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo de contato simplificado
class ContactInfo {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final bool isRegistered; // Se já está registrado no app
  final String? userId; // ID do usuário se já estiver registrado

  const ContactInfo({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.isRegistered = false,
    this.userId,
  });

  ContactInfo copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    String? email,
    bool? isRegistered,
    String? userId,
  }) {
    return ContactInfo(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isRegistered: isRegistered ?? this.isRegistered,
      userId: userId ?? this.userId,
    );
  }
}

/// Serviço para importar e gerenciar contatos do dispositivo
class ContactsService {
  /// Verificar e solicitar permissão de contatos
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      final result = await Permission.contacts.request();
      return result.isGranted;
    }

    // Se foi negado permanentemente, abrir configurações
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Importar todos os contatos do dispositivo
  Future<List<ContactInfo>> importContacts() async {
    try {
      // Verificar permissão
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        throw Exception('Permissão de contatos negada');
      }

      // Buscar contatos
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Converter para modelo simplificado
      final contactsList = <ContactInfo>[];

      for (final contact in contacts) {
        // Pegar primeiro telefone e email disponíveis
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : null;
        final email = contact.emails.isNotEmpty
            ? contact.emails.first.address
            : null;

        // Só adicionar se tiver pelo menos um método de contato
        if (phone != null || email != null) {
          contactsList.add(
            ContactInfo(
              id: contact.id,
              displayName: contact.displayName,
              phoneNumber: _cleanPhoneNumber(phone),
              email: email,
            ),
          );
        }
      }

      // Ordenar por nome
      contactsList.sort((a, b) => a.displayName.compareTo(b.displayName));

      return contactsList;
    } catch (e) {
      throw Exception('Erro ao importar contatos: $e');
    }
  }

  /// Limpar número de telefone (remover caracteres especiais)
  String? _cleanPhoneNumber(String? phone) {
    if (phone == null) return null;
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Enviar convite via WhatsApp
  Future<bool> sendWhatsAppInvite({
    required String phoneNumber,
    required String inviterName,
  }) async {
    try {
      final cleanPhone = _cleanPhoneNumber(phoneNumber);
      if (cleanPhone == null) return false;

      final message = Uri.encodeComponent(
        'Olá! Sou $inviterName e estou usando o Climetry, um app incrível para '
        'planejar eventos com previsões climáticas detalhadas! 🌤️\n\n'
        'Baixe agora e vamos organizar eventos juntos:\n'
        'https://climetry.app/download',
      );

      final whatsappUrl = 'https://wa.me/$cleanPhone?text=$message';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Enviar convite via SMS (fallback se não tiver WhatsApp)
  Future<bool> sendSMSInvite({
    required String phoneNumber,
    required String inviterName,
  }) async {
    try {
      final cleanPhone = _cleanPhoneNumber(phoneNumber);
      if (cleanPhone == null) return false;

      final message = Uri.encodeComponent(
        'Olá! Sou $inviterName. Baixe o Climetry para organizar eventos com previsões climáticas: https://climetry.app/download',
      );

      final smsUrl = 'sms:$cleanPhone?body=$message';
      final uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Enviar convite por email
  Future<bool> sendEmailInvite({
    required String email,
    required String inviterName,
  }) async {
    try {
      final subject = Uri.encodeComponent('Convite para o Climetry');
      final body = Uri.encodeComponent(
        'Olá!\n\n'
        'Sou $inviterName e gostaria de te convidar para usar o Climetry comigo! '
        'É um aplicativo incrível para planejar eventos levando em conta as condições climáticas.\n\n'
        'Com o Climetry você pode:\n'
        '• Ver previsões detalhadas para seus eventos\n'
        '• Receber alertas sobre mudanças no clima\n'
        '• Organizar eventos com amigos\n'
        '• Tomar melhores decisões baseadas no clima\n\n'
        'Baixe agora: https://climetry.app/download\n\n'
        'Nos vemos lá! 🌤️',
      );

      final emailUrl = 'mailto:$email?subject=$subject&body=$body';
      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verificar se um contato já está registrado no app
  /// (Este método será integrado com o FriendsService)
  Future<ContactInfo> checkIfRegistered(ContactInfo contact) async {
    // TODO: Implementar verificação no Firebase
    // Por enquanto retorna como não registrado
    return contact;
  }
}
