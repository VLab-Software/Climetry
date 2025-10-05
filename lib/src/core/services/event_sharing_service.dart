import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/activities/domain/entities/activity.dart';
import 'package:intl/intl.dart';

/// Service for sharing events to calendars and social media
class EventSharingService {
  /// Add event to device calendar (Google Calendar on Android, Apple Calendar on iOS)
  Future<bool> addToCalendar(Activity activity) async {
    try {
      final Event event = Event(
        title: activity.title,
        description: activity.description ?? 'Evento criado no Climetry',
        location: activity.location,
        startDate: activity.date,
        endDate: activity.endTime != null
            ? _parseEndDateTime(activity.date, activity.endTime!)
            : activity.date.add(const Duration(hours: 1)),
        iosParams: const IOSParams(
          reminder: Duration(minutes: 30),
          url: 'https://climetry.app',
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      return await Add2Calendar.addEvent2Cal(event);
    } catch (e) {
      print('Erro ao adicionar ao calendário: $e');
      return false;
    }
  }

  /// Share event via WhatsApp with deep link for non-registered users
  Future<void> shareViaWhatsApp({
    required Activity activity,
    String? recipientPhone,
  }) async {
    final String inviteLink = _generateInviteLink(activity);
    final String message = _buildWhatsAppMessage(activity, inviteLink);

    try {
      if (recipientPhone != null && recipientPhone.isNotEmpty) {
        // Share to specific contact
        await _shareToWhatsAppContact(recipientPhone, message);
      } else {
        // Generic share (user chooses contact)
        await _shareGenericWhatsApp(message);
      }
    } catch (e) {
      print('Erro ao compartilhar no WhatsApp: $e');
      // Fallback: use generic share
      await Share.share(message);
    }
  }

  /// Share event via generic share sheet (SMS, email, etc)
  Future<void> shareEvent(Activity activity) async {
    final String inviteLink = _generateInviteLink(activity);
    final String message = _buildShareMessage(activity, inviteLink);
    
    await Share.share(
      message,
      subject: '📅 Convite: ${activity.title}',
    );
  }

  // ============ PRIVATE HELPERS ============

  DateTime _parseEndDateTime(DateTime date, String endTimeStr) {
    try {
      final parts = endTimeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return date.add(const Duration(hours: 1));
    }
  }

  String _generateInviteLink(Activity activity) {
    // Deep link format: climetry://event?id=xxx
    // For web fallback: https://climetry.app/event?id=xxx
    final String eventId = activity.id;
    return 'https://climetry.app/join?event=$eventId';
  }

  String _buildWhatsAppMessage(Activity activity, String inviteLink) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = activity.startTime ?? 'Horário não definido';

    return '''
🎉 *Você foi convidado para um evento!*

📅 *${activity.title}*
📍 ${activity.location}
🕐 ${dateFormat.format(activity.date)} às $timeFormat

${activity.description != null ? '📝 ${activity.description}\n\n' : ''}🔗 *Aceite o convite aqui:*
$inviteLink

${_getWeatherAlertEmoji(activity)} Monitoramento climático ativo!

---
_Não tem conta? Clique no link para criar gratuitamente e participar!_
''';
  }

  String _buildShareMessage(Activity activity, String inviteLink) {
    final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');
    
    return '''
📅 Convite: ${activity.title}

📍 Local: ${activity.location}
🕐 Data: ${dateFormat.format(activity.date)}

${activity.description != null ? 'Descrição: ${activity.description}\n\n' : ''}Aceite o convite: $inviteLink

Não tem conta? Cadastre-se gratuitamente no Climetry!
''';
  }

  Future<void> _shareToWhatsAppContact(String phone, String message) async {
    // Remove caracteres não numéricos
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // WhatsApp URL scheme
    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp não está instalado');
    }
  }

  Future<void> _shareGenericWhatsApp(String message) async {
    // WhatsApp generic share
    final whatsappUrl = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to generic share
      await Share.share(message);
    }
  }

  String _getWeatherAlertEmoji(Activity activity) {
    if (activity.monitoredConditions.contains(WeatherCondition.rain)) {
      return '🌧️';
    } else if (activity.monitoredConditions.contains(WeatherCondition.temperature)) {
      return '🌡️';
    } else if (activity.monitoredConditions.contains(WeatherCondition.wind)) {
      return '💨';
    }
    return '⛅';
  }
}
