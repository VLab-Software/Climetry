import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfo {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final bool isRegistered; // Se já está registrado no app
  final String? userId; // User ID if already registered

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

class ContactsService {
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      final result = await Permission.contacts.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  Future<List<ContactInfo>> importContacts() async {
    try {
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        throw Exception('Permissão de contatos negada');
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final contactsList = <ContactInfo>[];

      for (final contact in contacts) {
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : null;
        final email = contact.emails.isNotEmpty
            ? contact.emails.first.address
            : null;

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

      contactsList.sort((a, b) => a.displayName.compareTo(b.displayName));

      return contactsList;
    } catch (e) {
      throw Exception('Error ao importar contatos: $e');
    }
  }

  String? _cleanPhoneNumber(String? phone) {
    if (phone == null) return null;
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<bool> sendWhatsAppInvite({
    required String phoneNumber,
    required String inviterName,
  }) async {
    try {
      final cleanPhone = _cleanPhoneNumber(phoneNumber);
      if (cleanPhone == null) return false;

      final message = Uri.encodeComponent(
        'Hello! I am $inviterName and I am using Climetry, an amazing app for '
        'planning events with detailed weather forecasts! 🌤️\n\n'
        'Download now and organize events together:\n'
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

  Future<bool> sendSMSInvite({
    required String phoneNumber,
    required String inviterName,
  }) async {
    try {
      final cleanPhone = _cleanPhoneNumber(phoneNumber);
      if (cleanPhone == null) return false;

      final message = Uri.encodeComponent(
        'Olá! Sou $inviterName. Baixe o Climetry para organizar ewinds com previsões climáticas: https://climetry.app/download',
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

  Future<bool> sendEmailInvite({
    required String email,
    required String inviterName,
  }) async {
    try {
      final subject = Uri.encodeComponent('Convite para o Climetry');
      final body = Uri.encodeComponent(
        'Olá!\n\n'
        'Sou $inviterName e gostaria de te convidar para usar o Climetry comigo! '
        'É um aplicativo incrível para planejar ewinds levando em conta as condições climáticas.\n\n'
        'Com o Climetry você pode:\n'
        '• Ver previsões detalhadas for your events\n'
        '• Receber alertas sobre mudanças no clima\n'
        '• Organizar ewinds com amigos\n'
        '• Tomar melhores decisões baseadas no clima\n\n'
        'Download now: https://climetry.app/download\n\n'
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

  Future<ContactInfo> checkIfRegistered(ContactInfo contact) async {
    return contact;
  }
}
