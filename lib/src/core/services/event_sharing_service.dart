import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/activities/domain/entities/activity.dart';
import 'package:intl/intl.dart';

class EventSharingService {
  Future<bool> addToCalendar(Activity activity) async {
    try {
      final Event event = Event(
        title: activity.title,
        description: activity.description ?? 'Ewind criado no Climetry',
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
      print('Error adding to calendar: $e');
      return false;
    }
  }

  Future<void> shareViaWhatsApp({
    required Activity activity,
    String? recipientPhone,
  }) async {
    final String inviteLink = _generateInviteLink(activity);
    final String message = _buildWhatsAppMessage(activity, inviteLink);

    try {
      if (recipientPhone != null && recipientPhone.isNotEmpty) {
        await _shareToWhatsAppContact(recipientPhone, message);
      } else {
        await _shareGenericWhatsApp(message);
      }
    } catch (e) {
      print('Error ao compartilhar no WhatsApp: $e');
      await Share.share(message);
    }
  }

  Future<void> shareEvent(Activity activity) async {
    final String inviteLink = _generateInviteLink(activity);
    final String message = _buildShareMessage(activity, inviteLink);
    
    await Share.share(
      message,
      subject: '📅 Convite: ${activity.title}',
    );
  }


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
    final String eventId = activity.id;
    return 'https://climetry.app/join?event=$eventId';
  }

  String _buildWhatsAppMessage(Activity activity, String inviteLink) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = activity.startTime ?? 'Time not set';

    return '''
🎉 *Você foi convidado para um ewind!*

📅 *${activity.title}*
📍 ${activity.location}
🕐 ${dateFormat.format(activity.date)} às $timeFormat

${activity.description != null ? '📝 ${activity.description}\n\n' : ''}🔗 *Accept the invitation here:*
$inviteLink

${_getWeatherAlertEmoji(activity)} Monitoramento climático ativo!

---
_Don't have an account? Click the link to create one for free and join!_
''';
  }

  String _buildShareMessage(Activity activity, String inviteLink) {
    final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');
    
    return '''
📅 Convite: ${activity.title}

📍 Local: ${activity.location}
🕐 Date: ${dateFormat.format(activity.date)}

${activity.description != null ? 'Description: ${activity.description}\n\n' : ''}Aceite o convite: $inviteLink

Don't have an account? Sign up for free on Climetry!
''';
  }

  Future<void> _shareToWhatsAppContact(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp is not installed');
    }
  }

  Future<void> _shareGenericWhatsApp(String message) async {
    final whatsappUrl = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
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
